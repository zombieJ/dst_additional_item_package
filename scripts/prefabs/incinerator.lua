local foldername = KnownModIndex:GetModActualName(TUNING.ZOMBIEJ_ADDTIONAL_PACKAGE)

-- 配置
local additional_building = GetModConfigData("additional_building", foldername)
if additional_building ~= "open" then
	return nil
end

local language = GetModConfigData("language", foldername)

local LANG_MAP = {
	["english"] = {
		["NAME"] = "Incinerator",
		["DESC"] = "Burn everything into ash!",
		["DESCRIBE"] = "Why we do not just burn the home to make ash?",
		["ACTIONFAIL"] = {
			["GENERIC"] = "Hmmm, finally find something can't burn",
			["WAXWELL"] = "Hmmm, finally find something can't burn",
			["WOLFGANG"] = "Hmmm, finally find something can't burn",
			["WX78"] = "Hmmm, finally find something can't burn",
			["WILLOW"] = "Hmmm, finally find something can't burn",
			["WENDY"] = "Hmmm, finally find something can't burn",
			["WOODIE"] = "Hmmm, finally find something can't burn",
			["WICKERBOTTOM"] = "Hmmm, finally find something can't burn",
			["WATHGRITHR"] = "Hmmm, finally find something can't burn",
			["WEBBER"] = "Hmmm, finally find something can't burn",
		},
	},
	["spanish"] = {
		["NAME"] = "Incinerador",
		["DESC"] = "Calcina hasta volverlo cenizas!",
		["DESCRIBE"] = "¿Porqué no quemamos de paso la base para hacerla cenizas?",
		["ACTIONFAIL"] = {
			["GENERIC"] = "Vaya, finalmente he encontrado algo que no puedo incinerar",
			["WAXWELL"] = "Vaya, finalmente he encontrado algo que no puedo incinerar",
			["WOLFGANG"] = "Vaya, finalmente he encontrado algo que no puedo incinerar",
			["WX78"] = "Vaya, finalmente he encontrado algo que no puedo incinerar",
			["WILLOW"] = "Vaya, finalmente he encontrado algo que no puedo incinerar",
			["WENDY"] = "Vaya, finalmente he encontrado algo que no puedo incinerar",
			["WOODIE"] = "Vaya, finalmente he encontrado algo que no puedo incinerar",
			["WICKERBOTTOM"] = "Vaya, finalmente he encontrado algo que no puedo incinerar",
			["WATHGRITHR"] = "Vaya, finalmente he encontrado algo que no puedo incinerar",
			["WEBBER"] = "Vaya, finalmente he encontrado algo que no puedo incinerar",
		},
	},
	["russian"] = {
		["NAME"] = "Мусоросжигатель",
		["DESC"] = "Преврати всё в пепел!",
		["DESCRIBE"] = "Почему я не могу просто сжечь дом, чтобы получить пепел?",
		["ACTIONFAIL"] = {
			["GENERIC"] = "Хм, видимо есть то, что я не могу сжечь.",
			["WAXWELL"] = "Хм, видимо есть то, что я не могу сжечь.",
			["WOLFGANG"] = "Хм, видимо есть то, что я не могу сжечь.",
			["WX78"] = "Хм, видимо есть то, что я не могу сжечь.",
			["WILLOW"] = "Хм, видимо есть то, что я не могу сжечь.",
			["WENDY"] = "Хм, видимо есть то, что я не могу сжечь.",
			["WOODIE"] = "Хм, видимо есть то, что я не могу сжечь.",
			["WICKERBOTTOM"] = "Хм, видимо есть то, что я не могу сжечь.",
			["WATHGRITHR"] = "Хм, видимо есть то, что я не могу сжечь.",
			["WEBBER"] = "Хм, видимо есть то, что я не могу сжечь.",
		},
	},
	["portuguese"] = {
		["NAME"] = "Incinerador",
		["DESC"] = "Queimar tudo em cinzas!",
		["DESCRIBE"] = "Por que não queimamos a casa para fazer cinzas?",
		["ACTIONFAIL"] = {
			["GENERIC"] = "Hmmm, finalmente achei algo que não queima",
			["WAXWELL"] = "Hmmm, finalmente achei algo que não queima",
			["WOLFGANG"] = "Hmmm, finalmente achei algo que não queima",
			["WX78"] = "Hmmm, finalmente achei algo que não queima",
			["WILLOW"] = "Hmmm, finalmente achei algo que não queima",
			["WENDY"] = "Hmmm, finalmente achei algo que não queima",
			["WOODIE"] = "Hmmm, finalmente achei algo que não queima",
			["WICKERBOTTOM"] = "Hmmm, finalmente achei algo que não queima",
			["WATHGRITHR"] = "Hmmm, finalmente achei algo que não queima",
			["WEBBER"] = "Hmmm, finalmente achei algo que não queima",
		},
	},
	["korean"] = {
		["NAME"] = "소각로",
		["DESC"] = "모든걸 재로 태워버려!",
		["DESCRIBE"] = "재가 필요하면 그냥 집채로 태우는건 어때?",
		["ACTIONFAIL"] = {
			["GENERIC"] = "흠,,,,드디어 태울 수 없는걸 찾았어",
			["WAXWELL"] = "흠,,,,드디어 태울 수 없는걸 찾은건가",
			["WOLFGANG"] = "흠,,,,드디어 태울 수 없는걸 찾았어",
			["WX78"] = "흠,,,,드디어 태울 수 없는걸 발견.기억한다",
			["WILLOW"] = "흠,,,,드디어 태울 수 없는걸 찾았어",
			["WENDY"] = "흠,,,,드디어 태울 수 없는걸 찾은걸까",
			["WOODIE"] = "흠,,,,드디어 태울 수 없는걸 찾았어",
			["WICKERBOTTOM"] = "흠,,,,드디어 태울 수 없는게 나타났네",
			["WATHGRITHR"] = "흠,,,,드디어 태울 수 없는걸 찾았어", 
			["WEBBER"] = "흠,,,,드디어 태울 수 없는걸 찾았어",
		},
	},
	["chinese"] = {
		["NAME"] = "焚烧炉",
		["DESC"] = "把一切都烧成灰！",
		["DESCRIBE"] = "想要灰为什么不直接烧家？",
		["ACTIONFAIL"] = {
			["GENERIC"] = "这东西看来烧不掉",
			["WAXWELL"] = "终于有烧不掉的东西了",
			["WOLFGANG"] = "它吃不下它！",
			["WX78"] = "错误的参数",
			["WILLOW"] = "不能燃烧的东西有什么意义！",
			["WENDY"] = "火焰也不能带走它的美丽",
			["WOODIE"] = "看来烧不掉",
			["WICKERBOTTOM"] = "烧不掉就赞美它",
			["WATHGRITHR"] = "它无法变成离子态",
			["WEBBER"] = "无法燃烧的恐惧",
			["WINONA"] = "总有事情无法挑战",
		},
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

-- 文字描述
STRINGS.NAMES.INCINERATOR = LANG.NAME
STRINGS.RECIPE_DESC.INCINERATOR = LANG.DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.INCINERATOR = LANG.DESCRIBE

STRINGS.CHARACTERS.GENERIC.ACTIONFAIL.GIVE.INCINERATOR_NOT_BURN = LANG.ACTIONFAIL.GENERIC
STRINGS.CHARACTERS.WAXWELL.ACTIONFAIL.GIVE.INCINERATOR_NOT_BURN = LANG.ACTIONFAIL.WAXWELL or LANG.ACTIONFAIL.GENERIC
STRINGS.CHARACTERS.WOLFGANG.ACTIONFAIL.GIVE.INCINERATOR_NOT_BURN = LANG.ACTIONFAIL.WOLFGANG or LANG.ACTIONFAIL.GENERIC
STRINGS.CHARACTERS.WX78.ACTIONFAIL.GIVE.INCINERATOR_NOT_BURN = LANG.ACTIONFAIL.WX78 or LANG.ACTIONFAIL.GENERIC
STRINGS.CHARACTERS.WILLOW.ACTIONFAIL.GIVE.INCINERATOR_NOT_BURN = LANG.ACTIONFAIL.WILLOW or LANG.ACTIONFAIL.GENERIC
STRINGS.CHARACTERS.WENDY.ACTIONFAIL.GIVE.INCINERATOR_NOT_BURN = LANG.ACTIONFAIL.WENDY or LANG.ACTIONFAIL.GENERIC
STRINGS.CHARACTERS.WOODIE.ACTIONFAIL.GIVE.INCINERATOR_NOT_BURN = LANG.ACTIONFAIL.WOODIE or LANG.ACTIONFAIL.GENERIC
STRINGS.CHARACTERS.WICKERBOTTOM.ACTIONFAIL.GIVE.INCINERATOR_NOT_BURN = LANG.ACTIONFAIL.WICKERBOTTOM or LANG.ACTIONFAIL.GENERIC
STRINGS.CHARACTERS.WATHGRITHR.ACTIONFAIL.GIVE.INCINERATOR_NOT_BURN = LANG.ACTIONFAIL.WATHGRITHR or LANG.ACTIONFAIL.GENERIC
STRINGS.CHARACTERS.WEBBER.ACTIONFAIL.GIVE.INCINERATOR_NOT_BURN = LANG.ACTIONFAIL.WEBBER or LANG.ACTIONFAIL.GENERIC
STRINGS.CHARACTERS.WINONA.ACTIONFAIL.GIVE.INCINERATOR_NOT_BURN = LANG.ACTIONFAIL.WINONA or LANG.ACTIONFAIL.GENERIC

-- 配方
local incinerator = Recipe("incinerator", {Ingredient("rocks", 5), Ingredient("twigs", 2), Ingredient("ash", 1)}, RECIPETABS.LIGHT, TECH.SCIENCE_ONE, "incinerator_placer")
incinerator.atlas = "images/inventoryimages/incinerator.xml"

-----------------------------------------------------------------------
require "prefabutil"

local assets =
{
	Asset("ANIM", "anim/incinerator.zip"),
	Asset("ATLAS", "images/inventoryimages/incinerator.xml"),
	Asset("IMAGE", "images/inventoryimages/incinerator.tex"),
}

local prefabs =
{
	"campfirefire",
	"collapse_small",
	"ash",
}

local function onBurnItems(inst)
	local hasItems = false
	local returnItems = {}

	-- 计算生产的物料
	if inst.components.aipc_action and inst.components.container then
		local ings = {}
		for k, item in pairs(inst.components.container.slots) do
			local stackSize = item.components.stackable and item.components.stackable:StackSize() or 1
			local lootItem = "ash"

			-- 根据马头剩余耐久度概率提供谜之声帽
			if item.prefab == "aip_horse_head" and item.components.fueled then
				local ptg = item.components.fueled:GetPercent()
				ptg = ptg * ptg * 0.9
				if ptg >= math.random() then
					lootItem = "aip_som"
				end
			end

			returnItems[lootItem] = (returnItems[lootItem] or 0) + stackSize
			hasItems = true
		end
	end

	-- 掉东西咯
	if hasItems then
		inst.AnimState:PlayAnimation("consume")
		inst.AnimState:PushAnimation("idle", false)
		inst.SoundEmitter:PlaySound("dontstarve/common/fireAddFuel")

		for prefab, prefabCount in pairs(returnItems) do
			local currentCount = prefabCount
			local loot = inst.components.lootdropper:SpawnLootPrefab(prefab)
			local lootMaxSize = 1

			if loot.components.stackable then
				lootMaxSize = loot.components.stackable.maxsize
			end
			loot:Remove()

			-- 批量掉落
			while(currentCount > 0)
			do
				local dropCount = math.min(currentCount, lootMaxSize)
				local dropLootItem = inst.components.lootdropper:SpawnLootPrefab(prefab)
				if dropLootItem.components.stackable then
					dropLootItem.components.stackable:SetStackSize(dropCount)
				end

				currentCount = currentCount - dropCount
			end
		end

		inst.components.container:Close()
		inst.components.container:DestroyContents()

		inst.components.burnable:Extinguish()
		inst:DoTaskInTime(0, function ()
			inst.components.burnable:Ignite()
			inst.components.burnable:SetFXLevel(1)
		end)
	end
end

-- 火焰者
local function onextinguish(inst)
end

-- 建筑
local function onhammered(inst, worker)
	inst.components.lootdropper:DropLoot()
	local x, y, z = inst.Transform:GetWorldPosition()
	SpawnPrefab("ash").Transform:SetPosition(x, y, z)
	local fx = SpawnPrefab("collapse_small")
	fx.Transform:SetPosition(x, y, z)
	fx:SetMaterial("stone")
	inst:Remove()
end

local function onhit(inst, worker)
	inst.AnimState:PlayAnimation("hit")
	inst.AnimState:PushAnimation("idle")
end

local function onbuilt(inst)
	inst.AnimState:PlayAnimation("place")
	inst.AnimState:PushAnimation("idle", false)
	inst.SoundEmitter:PlaySound("dontstarve/common/fireAddFuel")
end

local function OnInit(inst)
	if inst.components.burnable ~= nil then
		inst.components.burnable:FixFX()
	end
end

local function fn()
	local inst = CreateEntity()
	
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	-- 碰撞体积
	MakeObstaclePhysics(inst, .3)

	-- 动画
	inst.AnimState:SetBank("incinerator")
	inst.AnimState:SetBuild("incinerator")
	inst.AnimState:PlayAnimation("idle", false)

	-- 标签
	inst:AddTag("structure")

	MakeSnowCoveredPristine(inst)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	-- 可燃烧
	inst:AddComponent("burnable")
	inst.components.burnable:AddBurnFX("fire", Vector3(0, 0.3, 0) )
	inst.components.burnable:SetBurnTime(10)
	inst:ListenForEvent("onextinguish", onextinguish)

	-- 容器
	inst:AddComponent("container")
	inst.components.container:WidgetSetup("incinerator")

	-- 烹饪
	inst:AddComponent("aipc_action")
	inst.components.aipc_action.onDoAction = onBurnItems


	-- 掉东西
	inst:AddComponent("lootdropper")

	-- 被锤子
	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
	inst.components.workable:SetWorkLeft(4)
	inst.components.workable:SetOnFinishCallback(onhammered)
	inst.components.workable:SetOnWorkCallback(onhit)

	-- 可伤害
	inst:AddComponent("hauntable")
	inst.components.hauntable.cooldown = TUNING.HAUNT_COOLDOWN_HUGE

	-- 可检查
	inst:AddComponent("inspectable")

	inst:ListenForEvent("onbuilt", onbuilt)
	inst:DoTaskInTime(0, OnInit)

	return inst
end

return Prefab("incinerator", fn, assets, prefabs),
	MakePlacer("incinerator_placer", "incinerator", "incinerator", "idle")