local PREFAB = "aip_cozy_nest"

local SKINS = {
	{
		id = "pillow",
		name = {
			english = "Pillow Cozy Nest",
			chinese = "枕头小窝",
		},
	},
	{
		id = "colorful",
		prefab = PREFAB.."_colorful",
		name = {
			english = "Colorful Cozy Nest",
			chinese = "彩色小窝",
		},
	},
	{
		id = "pile",
		prefab = PREFAB.."_pile",
		name = {
			english = "Pillow Pile Cozy Nest",
			chinese = "枕头堆小窝",
		},
	},
	{
		id = "rare",
		prefab = PREFAB.."_rare",
		name = {
			english = "Precious Cozy Nest",
			chinese = "珍品小窝",
		},
	},
	{
		id = "red",
		prefab = PREFAB.."_red",
		name = {
			english = "Red Cozy Nest",
			chinese = "红色小窝",
		},
	},
	{
		id = "patch",
		prefab = PREFAB.."_patch",
		name = {
			english = "Patchwork Cozy Nest",
			chinese = "补丁小窝",
		},
	},
}

local BUILD_SKINS = {}
for _, skin in ipairs(SKINS) do
	if skin.prefab ~= nil then
		table.insert(BUILD_SKINS, skin.prefab)
	end
end

local function registerPrefabSkins()
	PREFAB_SKINS[PREFAB] = BUILD_SKINS
	PREFAB_SKINS_IDS[PREFAB] = {}

	for index, skin in ipairs(BUILD_SKINS) do
		PREFAB_SKINS_IDS[PREFAB][skin] = index
	end
end

local function registerInventoryAtlases()
	if RegisterInventoryItemAtlas == nil then
		return
	end

	RegisterInventoryItemAtlas("images/inventoryimages/"..PREFAB..".xml", PREFAB..".tex")

	for _, skin in ipairs(BUILD_SKINS) do
		RegisterInventoryItemAtlas("images/inventoryimages/"..skin..".xml", skin..".tex")
	end
end

local function registerStrings(language, description)
	for _, skin in ipairs(SKINS) do
		if skin.prefab ~= nil then
			if STRINGS.SKIN_NAMES ~= nil then
				STRINGS.SKIN_NAMES[skin.prefab] = skin.name[language] or skin.name.english
			end
			if description ~= nil and STRINGS.SKIN_DESCRIPTIONS ~= nil then
				STRINGS.SKIN_DESCRIPTIONS[skin.prefab] = description
			end
		end
	end
end

return {
	PREFAB = PREFAB,
	SKINS = SKINS,
	BUILD_SKINS = BUILD_SKINS,
	DEFAULT_SKIN = SKINS[1].id,
	RegisterPrefabSkins = registerPrefabSkins,
	RegisterInventoryAtlases = registerInventoryAtlases,
	RegisterStrings = registerStrings,
}
