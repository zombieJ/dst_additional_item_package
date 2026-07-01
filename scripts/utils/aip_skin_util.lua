local SkinUtil = {}

local configsByPrefab = {}

local function containsValue(list, value)
	if type(list) ~= "table" then
		return false
	end

	for _, item in ipairs(list) do
		if item == value then
			return true
		end
	end

	return false
end

local function containsSkin(skinsList, skinName)
	if type(skinsList) ~= "table" then
		return false
	end

	for _, skin in ipairs(skinsList) do
		if type(skin) == "table" and skin.item == skinName then
			return true
		end
	end

	return false
end

function SkinUtil.CreateConfig(options)
	local prefab = options.prefab
	local skins = options.skins
	local defaultSkin = options.default_skin or skins[1].id
	local buildSkins = {}
	local skinIndex = {}
	local skinIdByPrefab = {}
	local skinPrefabById = {}

	for index, skin in ipairs(skins) do
		skinIndex[skin.id] = index

		if skin.prefab ~= nil then
			table.insert(buildSkins, skin.prefab)
			skinIndex[skin.prefab] = index
			skinIdByPrefab[skin.prefab] = skin.id
			skinPrefabById[skin.id] = skin.prefab
		end
	end

	local config = {
		PREFAB = prefab,
		SKINS = skins,
		BUILD_SKINS = buildSkins,
		DEFAULT_SKIN = defaultSkin,
		SKIN_INDEX = skinIndex,
		SKIN_ID_BY_PREFAB = skinIdByPrefab,
		SKIN_PREFAB_BY_ID = skinPrefabById,
		SKIN_TAGS = options.skin_tags or { string.upper(prefab), "CRAFTABLE" },
		SKIN_TYPE = options.skin_type or "item",
		SKIN_RARITY = options.rarity or "Complimentary",
		RELEASE_GROUP = options.release_group or 0,
		ALIASES = options.aliases or {},
	}

	function config.GetSkin(skin)
		local index = skinIndex[skin]
		return index ~= nil and skins[index].id or defaultSkin
	end

	function config.GetSkinPrefab(skin)
		return skinPrefabById[config.GetSkin(skin)]
	end

	function config.GetNextSkin(skin)
		local index = skinIndex[config.GetSkin(skin)] or 1
		index = index % #skins + 1
		return skins[index].id
	end

	function config.GetNextBuildSkin(skinName)
		if skinName == nil then
			return buildSkins[1]
		end

		for index, buildSkin in ipairs(buildSkins) do
			if buildSkin == skinName then
				return buildSkins[index + 1]
			end
		end

		return buildSkins[1]
	end

	function config.RegisterPrefabSkins()
		local prefabSkins = PREFAB_SKINS[prefab]
		if type(prefabSkins) ~= "table" then
			prefabSkins = {}
			PREFAB_SKINS[prefab] = prefabSkins
		end

		for _, skin in ipairs(buildSkins) do
			if not containsValue(prefabSkins, skin) then
				table.insert(prefabSkins, skin)
			end
		end

		if type(PREFAB_SKINS_IDS[prefab]) ~= "table" then
			PREFAB_SKINS_IDS[prefab] = {}
		end
		for index, skin in ipairs(prefabSkins) do
			PREFAB_SKINS_IDS[prefab][skin] = index
		end
	end

	function config.RegisterInventoryAtlases()
		if RegisterInventoryItemAtlas == nil then
			return
		end

		RegisterInventoryItemAtlas("images/inventoryimages/"..prefab..".xml", prefab..".tex")

		for _, skin in ipairs(buildSkins) do
			RegisterInventoryItemAtlas("images/inventoryimages/"..skin..".xml", skin..".tex")
		end
	end

	function config.RegisterStrings(language, description)
		for _, skin in ipairs(skins) do
			if skin.prefab ~= nil and skin.name ~= nil then
				if STRINGS.SKIN_NAMES ~= nil then
					STRINGS.SKIN_NAMES[skin.prefab] = skin.name[language] or skin.name.english
				end
				if description ~= nil and STRINGS.SKIN_DESCRIPTIONS ~= nil then
					STRINGS.SKIN_DESCRIPTIONS[skin.prefab] = description
				end
			end
		end
	end

	function config.GetInventoryAtlasAssets(includeBase)
		local assets = {}

		if includeBase then
			table.insert(assets, Asset("ATLAS", "images/inventoryimages/"..prefab..".xml"))
		end

		for _, skin in ipairs(buildSkins) do
			table.insert(assets, Asset("ATLAS", "images/inventoryimages/"..skin..".xml"))
		end

		return assets
	end

	return config
end

function SkinUtil.RegisterBuildSkinConfig(config, language, description)
	config.RegisterPrefabSkins()
	config.RegisterInventoryAtlases()
	config.RegisterStrings(language, description)
	configsByPrefab[config.PREFAB] = config
	for _, alias in ipairs(config.ALIASES or {}) do
		configsByPrefab[alias] = config
	end
	return config
end

function SkinUtil.GetConfig(prefab)
	return configsByPrefab[prefab]
end

function SkinUtil.AppendBuildSkins(recipe, skinsList)
	local config = recipe ~= nil and SkinUtil.GetConfig(recipe.product) or nil
	if config == nil then
		return skinsList
	end
	if skinsList == nil then
		skinsList = {}
	elseif type(skinsList) ~= "table" then
		return skinsList
	end

	for _, skinName in ipairs(config.BUILD_SKINS) do
		if not containsSkin(skinsList, skinName) then
			table.insert(skinsList, {
				type = "item",
				item = skinName,
				timestamp = 0,
			})
		end
	end

	return skinsList
end

function SkinUtil.ApplyBuiltSkin(data)
	local item = data ~= nil and data.item or nil
	local config = item ~= nil and SkinUtil.GetConfig(item.prefab) or nil

	if config ~= nil and item.SetAipSkin ~= nil then
		item:SetAipSkin(data.skin)
		return true
	end

	return false
end

function SkinUtil.CreatePrefabSkinner(config, options)
	options = options or {}

	local skinner = {}
	local netField = options.net_field or "_aipSkin"
	local currentField = options.current_field or "_aipCurrentSkin"
	local dirtyEvent = options.dirty_event or config.PREFAB.."_skindirty"
	local playFn = options.play_fn
	local sound = options.sound or "dontstarve/common/together/skin_change"

	function skinner.Apply(inst, skin, ...)
		skin = config.GetSkin(skin)
		inst[currentField] = skin
		inst._aipDeploySkin = skin
		playFn(inst, skin, ...)
	end

	function skinner.ApplySkinName(inst, skin)
		skin = config.GetSkin(skin)
		local skinPrefab = config.GetSkinPrefab(skin)

		inst.skinname = skinPrefab
		inst.linked_skinname = skinPrefab
		inst.skin_id = nil
		inst.alt_skin_ids = nil
		inst.skin_build_name = nil
	end

	function skinner.Set(inst, skin)
		skin = config.GetSkin(skin)
		inst[currentField] = skin
		inst._aipDeploySkin = skin

		if TheWorld.ismastersim then
			skinner.ApplySkinName(inst, skin)

			if inst[netField] ~= nil then
				inst[netField]:set(skin)
			end
		end

		playFn(inst, skin)
	end

	function skinner.Next(inst)
		skinner.Set(inst, config.GetNextSkin(inst[currentField]))

		if inst.SoundEmitter ~= nil then
			inst.SoundEmitter:PlaySound(sound)
		end
	end

	function skinner.PlayCurrent(inst, ...)
		playFn(inst, inst[currentField], ...)
	end

	function skinner.OnSave(inst, data)
		data.skin = inst[currentField]
	end

	function skinner.OnLoad(inst, data)
		if inst.skinname ~= nil then
			skinner.Set(inst, inst.skinname)
		elseif data ~= nil and data.skin ~= nil then
			skinner.Set(inst, data.skin)
		end
	end

	function skinner.SetupNetwork(inst)
		inst[netField] = net_string(inst.GUID, config.PREFAB.."."..netField, dirtyEvent)
		inst:ListenForEvent(dirtyEvent, function(inst)
			skinner.Apply(inst, inst[netField]:value())
		end)

		skinner.Apply(inst, config.DEFAULT_SKIN)

		inst.scrapbook_anim = config.DEFAULT_SKIN
		inst.SetAipSkin = skinner.Set
		inst.NextAipSkin = skinner.Next
		inst.NextSkin = skinner.Next

		if options.set_fn_name ~= nil then
			inst[options.set_fn_name] = skinner.Set
		end
		if options.next_fn_name ~= nil then
			inst[options.next_fn_name] = skinner.Next
		end
	end

	function skinner.SetupMaster(inst)
		if inst[netField] ~= nil then
			-- 主机端保留 prefab skin 或读档流程已经写入的皮肤。
			local skin = inst.skinname or inst.linked_skinname or inst._aipDeploySkin or inst[currentField] or config.DEFAULT_SKIN
			inst[netField]:set(config.GetSkin(skin))
		end
	end

	function skinner.CreatePrefabSkins()
		local prefabs = {}
		local clearFnName = config.PREFAB.."_clear_fn"

		rawset(_G, clearFnName, function(inst)
			skinner.Set(inst, config.DEFAULT_SKIN)
		end)

		for _, skin in ipairs(config.SKINS) do
			if skin.prefab ~= nil then
				local skinId = config.SKIN_ID_BY_PREFAB[skin.prefab]

				table.insert(prefabs, CreatePrefabSkin(skin.prefab, {
					base_prefab = config.PREFAB,
					type = config.SKIN_TYPE,
					rarity = config.SKIN_RARITY,
					init_fn = function(inst)
						skinner.Set(inst, skinId)
					end,
					skin_tags = config.SKIN_TAGS,
					assets = {
						Asset("ATLAS", "images/inventoryimages/"..skin.prefab..".xml"),
					},
					release_group = config.RELEASE_GROUP,
				}))
			end
		end

		return prefabs
	end

	return skinner
end

return SkinUtil
