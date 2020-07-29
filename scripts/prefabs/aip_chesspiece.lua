local foldername = KnownModIndex:GetModActualName(TUNING.ZOMBIEJ_ADDTIONAL_PACKAGE)

------------------------------------ 配置 ------------------------------------
-- 食物关闭
local additional_food = aipGetModConfig("additional_food")
if additional_food ~= "open" then
	return nil
end

-- 雕塑关闭
local additional_chesspieces = aipGetModConfig("additional_chesspieces")
if additional_chesspieces ~= "open" then
	return nil
end

local language = aipGetModConfig("language")

-- 语言
local LANG_MAP = {
	["english"] = {
		["aip_moon"] = {
			["NAME"] = "Moon Ash",
			["REC_DESC"] = "Provide weak light",
			["DESC"] = "Is that Contemporary Art?",
		},
		["aip_doujiang"] = {
			["NAME"] = "Dou Jiang",
			["REC_DESC"] = "Happy is life target",
			["DESC"] = "Looks like turn into stone",
		},
		["aip_deer"] = {
			["NAME"] = "Watcher",
			["REC_DESC"] = "Looks like alive",
			["DESC"] = "What's it waiting for?",
		},
	},
	["spanish"] = {
		["aip_moon"] = {
			["NAME"] = "Ceniza lunar",
			["REC_DESC"] = "Proporciona una luz tenue",
			["DESC"] = "Eso es arte contemporaneo?",
		},
		["aip_doujiang"] = {
			["NAME"] = "Dou Jiang",
			["REC_DESC"] = "La felicidad es el objetivo de la vida",
			["DESC"] = "Parece que se hubiese vuelto piedra",
		},
		["aip_deer"] = {
			["NAME"] = "Observador",
			["REC_DESC"] = "Parece algo vivo",
			["DESC"] = "¿A qué está esperando?",
		},
	},
	["chinese"] = {
		["aip_moon"] = {
			["NAME"] = "月光星尘",
			["REC_DESC"] = "可以提供微弱的光芒",
			["DESC"] = "这是当代艺术吗？",
		},
		["aip_doujiang"] = {
			["NAME"] = "豆酱",
			["REC_DESC"] = "无忧无虑的生活最是向往",
			["DESC"] = "看起来就像是被石化了",
		},
		["aip_deer"] = {
			["NAME"] = "守望者",
			["REC_DESC"] = "凡灵皆有生命",
			["DESC"] = "它似乎在等着什么",
		},
	},
	["russian"] = {
		["aip_moon"] = {
			["NAME"] = "Лунный Пепел",
			["REC_DESC"] = "Излучает слабый свет.",
			["DESC"] = "Это современное искусство?",
		},
		["aip_doujiang"] = {
			["NAME"] = "Доу Цзян",
			["REC_DESC"] = "Веселье - это цель его жизни.",
			["DESC"] = "Такое чувство, будто он превратился в камень.",
		},
		["aip_deer"] = {
			["NAME"] = "Смотритель",
			["REC_DESC"] = "Выглядит как живой!",
			["DESC"] = "Чего он ждёт?",
		},
	},	
}

local LANG = LANG_MAP[language] or LANG_MAP.english
local LANG_ENG = LANG_MAP.english

---------------------------------- 物品列表 -----------------------------------
local PIECES =
{
	{
		name = "aip_moon",
		moonevent = false,
		recipe = {Ingredient(TECH_INGREDIENT.SCULPTING, 2), Ingredient("moonrocknugget", 9), Ingredient("frozen_heart", 1, "images/inventoryimages/frozen_heart.xml")},
		common_postinit = function(inst)
			-- 月光星尘会发光
			inst.entity:AddLight()
			inst.Light:Enable(true)
			inst.Light:SetRadius(2)
			inst.Light:SetFalloff(.9)
			inst.Light:SetIntensity(0.75)
			inst.Light:SetColour(15 / 255, 160 / 255, 180 / 255)
		end,
	},
	{
		name = "aip_doujiang",
		moonevent = false,
		recipe = {Ingredient(TECH_INGREDIENT.SCULPTING, 2), Ingredient("plantmeat_cooked", 1), Ingredient("pinecone", 1)},
		common_postinit = function(inst, material)
			-- if material ~= "moonglass" then
			-- 	return
			-- end

			-- 添加箱子能力
			inst:AddComponent("container")
			inst.components.container:WidgetSetup("aip_doujiang_chesspiece")
		end,
	},
	{
		name = "aip_deer",
		moonevent = false,
		recipe = {Ingredient(TECH_INGREDIENT.SCULPTING, 2), Ingredient("boneshard", 2), Ingredient("beardhair", 1)},
	},
}

--------------------------------- 遍历创建者 ----------------------------------
for pieceid = 1,#PIECES do
	local piece = PIECES[pieceid]

	-- 只处理有name的
	local name = piece.name
	if name then
		local recipe = Recipe("chesspiece_"..name.."_builder", piece.recipe, RECIPETABS.SCULPTING, TECH.SCULPTING_ONE, nil, nil, true, nil, nil, nil, "chesspiece_"..name..".tex")
		recipe.atlas = "images/inventoryimages/chesspiece_"..name..".xml"

		local upperCase = string.upper(name)
		local lang = LANG[name] or LANG_ENG[name]

		STRINGS.NAMES["CHESSPIECE_"..upperCase] = lang.NAME
		STRINGS.RECIPE_DESC["CHESSPIECE_"..upperCase] = lang.REC_DESC
		STRINGS.CHARACTERS.GENERIC.DESCRIBE["CHESSPIECE_"..upperCase] = lang.DESC
		STRINGS.NAMES["CHESSPIECE_"..upperCase.."_BUILDER"] = lang.NAME
		STRINGS.RECIPE_DESC["CHESSPIECE_"..upperCase.."_BUILDER"] = lang.REC_DESC
		STRINGS.CHARACTERS.GENERIC.DESCRIBE["CHESSPIECE_"..upperCase.."_BUILDER"] = lang.DESC
	end
end

------------------------------------ 模板 ------------------------------------
local MOON_EVENT_RADIUS = 12
local MOON_EVENT_MINPIECES = 3

local MATERIALS =
{
	{name="marble",		prefab="marble"},
	{name="stone",		prefab="cutstone"},
	{name="moonglass",	prefab="moonglass"},
}

local PHYSICS_RADIUS = .45

local function GetBuildName(pieceid, materialid)
	local piece = PIECES[pieceid]
	if not piece or not piece.name then
		return ""
	end

	local build = "swap_chesspiece_" .. piece.name

	if materialid then
		build = build .. "_" .. MATERIALS[materialid].name
	end

	return build
end

local function SetMaterial(inst, materialid)
	inst.materialid = materialid
	inst.AnimState:SetBuild(GetBuildName(inst.pieceid, materialid))

	inst.components.lootdropper:SetLoot({MATERIALS[materialid].prefab})
end

local function DoStruggle(inst, count)
	if inst.forcebreak then
		if inst.components.workable ~= nil then
			inst.AnimState:PlayAnimation("jiggle")
			inst.SoundEmitter:PlaySound("dontstarve/common/together/sculptures/shake")
			inst:DoTaskInTime(inst.AnimState:GetCurrentAnimationLength() * 0.8, function(inst)
				if inst and inst.components.workable then
					inst.components.workable:Destroy(inst)
				end
			end)
		end
	else
		local x, y, z = inst.Transform:GetWorldPosition()
		local ents = TheSim:FindEntities(x, y, z, MOON_EVENT_RADIUS, { "chess_moonevent" }, { "INLIMBO" })
		inst.AnimState:PlayAnimation("jiggle")
		inst.SoundEmitter:PlaySound("dontstarve/common/together/sculptures/shake")
		inst._task =
			count > 1 and
			inst:DoTaskInTime(inst.AnimState:GetCurrentAnimationLength(), DoStruggle, count - 1) or
			inst:DoTaskInTime(inst.AnimState:GetCurrentAnimationLength() + math.random() + .6, DoStruggle, math.max(1, math.random(3) - 1))
	end
end

local function StartStruggle(inst)
	if inst._task == nil then
		inst._task = inst:DoTaskInTime(math.random(), DoStruggle, 1)
	end
end

local function StopStruggle(inst)
	if inst._task ~= nil and inst.forcebreak ~= true then
		inst._task:Cancel()
		inst._task = nil
	end
end

local function CheckMorph(inst)
	if PIECES[inst.pieceid].moonevent 
		and TheWorld.state.isnewmoon and
		not inst:IsAsleep() then

		StartStruggle(inst)
	else
		StopStruggle(inst)
	end
end

local function onequip(inst, owner)
	owner.AnimState:OverrideSymbol("swap_body", GetBuildName(inst.pieceid, inst.materialid), "swap_body")
end

local function onunequip(inst, owner)
	owner.AnimState:ClearOverrideSymbol("swap_body")
end

local function onworkfinished(inst)
	if inst._task ~= nil or inst.forcebreak then
		inst.SoundEmitter:PlaySound("dontstarve/wilson/rock_break")

		local creature = SpawnPrefab("shadow_"..PIECES[inst.pieceid].name)
		creature.Transform:SetPosition(inst.Transform:GetWorldPosition())
		creature.Transform:SetRotation(inst.Transform:GetRotation())
		creature.sg:GoToState("taunt")

		local player = creature:GetNearestPlayer(true)
		if player ~= nil and creature:IsNear(player, 20) then
			creature.components.combat:SetTarget(player)
		end

		local x, y, z = inst.Transform:GetWorldPosition()
		local ents = TheSim:FindEntities(x, y, z, MOON_EVENT_RADIUS, { "chess_moonevent" })
		for i, v in ipairs(ents) do
			v.forcebreak = true
		end
	end

	inst.components.lootdropper:DropLoot()
	local fx = SpawnPrefab("collapse_small")
	fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
	fx:SetMaterial("stone")
	inst:Remove()
end

local function getstatus(inst)
	return (inst._task ~= nil and "STRUGGLE")
		or nil
end

local function OnShadowChessRoar(inst, forcebreak)
	inst.forcebreak = true
	StartStruggle(inst)
end

local function onsave(inst, data)
	data.materialid = inst.materialid
	data.pieceid = inst.pieceid
end

local function onload(inst, data)
	if data ~= nil then
		inst.pieceid = data.pieceid
		SetMaterial(inst, data.materialid or 1)
	end
end

local function makepiece(pieceid, materialid)
	local build = GetBuildName(pieceid, materialid)

	local assets =
	{
		Asset("ATLAS", "images/inventoryimages/chesspiece_"..PIECES[pieceid].name..".xml"),
		Asset("INV_IMAGE", "chesspiece_"..PIECES[pieceid].name),
	}

	local prefabs = 
	{
		"collapse_small",
	}
	if materialid then
		table.insert(prefabs, MATERIALS[materialid].prefab)
		table.insert(assets, Asset("ANIM", "anim/"..build..".zip"))
	else
		for m = 1, #MATERIALS do
			local p = "chesspiece_" .. PIECES[pieceid].name .. "_" .. MATERIALS[m].name
			table.insert(prefabs, p)
		end
	end
	if PIECES[pieceid].moonevent then
		table.insert(prefabs, "shadow_"..PIECES[pieceid].name)
	end

	local function fn()
		local inst = CreateEntity()

		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddSoundEmitter()
		inst.entity:AddNetwork()

		MakeHeavyObstaclePhysics(inst, PHYSICS_RADIUS)

		inst.AnimState:SetBank("chesspiece")
		inst.AnimState:SetBuild("swap_chesspiece_"..PIECES[pieceid].name.."_marble")
		inst.AnimState:PlayAnimation("idle")

		inst:AddTag("heavy")
		if PIECES[pieceid].moonevent then
			inst:AddTag("chess_moonevent")
			inst:AddTag("event_trigger")
		end

		inst:SetPrefabName("chesspiece_"..PIECES[pieceid].name)

		if PIECES[pieceid].common_postinit ~= nil then
			PIECES[pieceid].common_postinit(inst, materialid and MATERIALS[materialid].name)
		end

		inst.entity:SetPristine()

		if not TheWorld.ismastersim then
			return inst
		end

		inst:AddComponent("heavyobstaclephysics")
		inst.components.heavyobstaclephysics:SetRadius(PHYSICS_RADIUS)

		inst:AddComponent("inspectable")
		inst.components.inspectable.getstatus = getstatus

		inst:AddComponent("lootdropper")

		inst:AddComponent("inventoryitem")
		inst.components.inventoryitem.cangoincontainer = false
		inst.components.inventoryitem:ChangeImageName("chesspiece_"..PIECES[pieceid].name)
		inst.components.inventoryitem.atlasname = "images/inventoryimages/chesspiece_"..PIECES[pieceid].name..".xml"

		inst:AddComponent("equippable")
		inst.components.equippable.equipslot = EQUIPSLOTS.BODY
		inst.components.equippable:SetOnEquip(onequip)
		inst.components.equippable:SetOnUnequip(onunequip)
		inst.components.equippable.walkspeedmult = TUNING.HEAVY_SPEED_MULT

		inst:AddComponent("workable")
		inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
		inst.components.workable:SetWorkLeft(1)
		inst.components.workable:SetOnFinishCallback(onworkfinished)

		inst:AddComponent("hauntable")
		inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

		inst.OnLoad = onload
		inst.OnSave = onsave

		if not TheWorld:HasTag("cave") then
			if PIECES[pieceid].moonevent then
				inst.OnEntityWake = CheckMorph
				inst.OnEntitySleep = CheckMorph
				inst:WatchWorldState("isnewmoon", CheckMorph)
			end

			inst:ListenForEvent("shadowchessroar", OnShadowChessRoar)
		end

		inst.pieceid = pieceid
		if materialid then
			SetMaterial(inst, materialid)
		end

		if PIECES[pieceid].master_postinit ~= nil then
			PIECES[pieceid].master_postinit(inst)
		end

		return inst
	end

	local prefabname = materialid and ("chesspiece_"..PIECES[pieceid].name.."_"..MATERIALS[materialid].name) or ("chesspiece_"..PIECES[pieceid].name)
	return Prefab(prefabname, fn, assets, prefabs)
end

--------------------------------------------------------------------------

local function builderonbuilt(inst, builder)
	local prototyper = builder.components.builder.current_prototyper
	if prototyper ~= nil and prototyper.CreateItem ~= nil then
		prototyper:CreateItem("chesspiece_"..PIECES[inst.pieceid].name)
	else
		local piece = SpawnPrefab("chesspiece_"..PIECES[inst.pieceid].name)
		piece.Transform:SetPosition(builder.Transform:GetWorldPosition())
	end

	inst:Remove()
end

local function makebuilder(pieceid)
	local function fn()
		local inst = CreateEntity()

		inst.entity:AddTransform()

		inst:AddTag("CLASSIFIED")

		--[[Non-networked entity]]
		inst.persists = false

		--Auto-remove if not spawned by builder
		inst:DoTaskInTime(0, inst.Remove)

		if not TheWorld.ismastersim then
			return inst
		end

		inst.pieceid = pieceid
		inst.OnBuiltFn = builderonbuilt

		return inst
	end

	return Prefab("chesspiece_"..PIECES[pieceid].name.."_builder", fn, nil, { "chesspiece_"..PIECES[pieceid].name })
end

--------------------------------------------------------------------------

local chesspieces = {}
for p = 1,#PIECES do
	local piece = PIECES[p]

	-- 只处理有name的
	if piece.name then
		table.insert(chesspieces, makepiece(p))
		table.insert(chesspieces, makebuilder(p))
		for m = 1,#MATERIALS do
			table.insert(chesspieces, makepiece(p, m))
		end
	end
end

return unpack(chesspieces)
