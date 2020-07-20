------------------------------------ 配置 ------------------------------------
-- 体验关闭
local additional_experiment = aipGetModConfig("additional_experiment")
if additional_experiment ~= "open" then
	return nil
end

-- 建筑关闭
local additional_building = aipGetModConfig("additional_building")
if additional_building ~= "open" then
	return nil
end

local language = aipGetModConfig("language")

local LANG_MAP = {
	["english"] = {
		["NAME"] = "Woodener",
		["DESC"] = "a shy totem pole",
		["DESCRIBE"] = "You can give, but not ask for.",
		["ACTIONFAIL"] = {
			["GENERIC"] = "He only accept log.",
		},
	},
	["chinese"] = {
		["NAME"] = "木图腾",
		["DESC"] = "一根害羞的图腾柱",
		["DESCRIBE"] = "你可以给予，却不该索取。",
		["ACTIONFAIL"] = {
			["GENERIC"] = "他只接受木头",
			["WAXWELL"] = "它只要木头这种廉价货",
			["WOLFGANG"] = "除了木头，它什么都塞不下！",
			["WX78"] = "参数 = 木头",
			["WILLOW"] = "用木头喂他或者烧了它！",
			["WENDY"] = "塞木头或许会有用",
			["WOODIE"] = "它也想要木头",
			["WICKERBOTTOM"] = "它的食谱是木头",
			["WATHGRITHR"] = "我吃肉，你吃木头！",
			["WEBBER"] = "它需要更多的木头",
			["WINONA"] = "木头建筑吃木头",
		},
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

-- 文字描述
STRINGS.NAMES.AIP_WOODENER = LANG.NAME
STRINGS.RECIPE_DESC.AIP_WOODENER = LANG.DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_WOODENER = LANG.DESCRIBE

STRINGS.CHARACTERS.GENERIC.ACTIONFAIL.GIVE.AIP_WOODENER_LOG_ONLY = LANG.ACTIONFAIL.GENERIC
STRINGS.CHARACTERS.WAXWELL.ACTIONFAIL.GIVE.AIP_WOODENER_LOG_ONLY = LANG.ACTIONFAIL.WAXWELL or LANG.ACTIONFAIL.GENERIC
STRINGS.CHARACTERS.WOLFGANG.ACTIONFAIL.GIVE.AIP_WOODENER_LOG_ONLY = LANG.ACTIONFAIL.WOLFGANG or LANG.ACTIONFAIL.GENERIC
STRINGS.CHARACTERS.WX78.ACTIONFAIL.GIVE.AIP_WOODENER_LOG_ONLY = LANG.ACTIONFAIL.WX78 or LANG.ACTIONFAIL.GENERIC
STRINGS.CHARACTERS.WILLOW.ACTIONFAIL.GIVE.AIP_WOODENER_LOG_ONLY = LANG.ACTIONFAIL.WILLOW or LANG.ACTIONFAIL.GENERIC
STRINGS.CHARACTERS.WENDY.ACTIONFAIL.GIVE.AIP_WOODENER_LOG_ONLY = LANG.ACTIONFAIL.WENDY or LANG.ACTIONFAIL.GENERIC
STRINGS.CHARACTERS.WOODIE.ACTIONFAIL.GIVE.AIP_WOODENER_LOG_ONLY = LANG.ACTIONFAIL.WOODIE or LANG.ACTIONFAIL.GENERIC
STRINGS.CHARACTERS.WICKERBOTTOM.ACTIONFAIL.GIVE.AIP_WOODENER_LOG_ONLY = LANG.ACTIONFAIL.WICKERBOTTOM or LANG.ACTIONFAIL.GENERIC
STRINGS.CHARACTERS.WATHGRITHR.ACTIONFAIL.GIVE.AIP_WOODENER_LOG_ONLY = LANG.ACTIONFAIL.WATHGRITHR or LANG.ACTIONFAIL.GENERIC
STRINGS.CHARACTERS.WEBBER.ACTIONFAIL.GIVE.AIP_WOODENER_LOG_ONLY = LANG.ACTIONFAIL.WEBBER or LANG.ACTIONFAIL.GENERIC
STRINGS.CHARACTERS.WINONA.ACTIONFAIL.GIVE.AIP_WOODENER_LOG_ONLY = LANG.ACTIONFAIL.WINONA or LANG.ACTIONFAIL.GENERIC

-- 配方
local aip_woodener = Recipe("aip_woodener", {Ingredient("goldnugget", 5), Ingredient("livinglog", 2), Ingredient("boards", 3)}, RECIPETABS.MAGIC, TECH.MAGIC_TWO, "aip_woodener_placer")
aip_woodener.atlas = "images/inventoryimages/aip_woodener.xml"

-----------------------------------------------------------------------
require "prefabutil"

local assets =
{
	Asset("ANIM", "anim/aip_woodener.zip"),
	Asset("ATLAS", "images/inventoryimages/aip_woodener.xml"),
	Asset("IMAGE", "images/inventoryimages/aip_woodener.tex"),
}

local prefabs =
{
	"collapse_small",
}

-- 建筑
local function onhammered(inst, worker)
	inst.components.lootdropper:DropLoot()
	local x, y, z = inst.Transform:GetWorldPosition()
	local fx = SpawnPrefab("collapse_small")
	fx.Transform:SetPosition(x, y, z)
	fx:SetMaterial("wood")
	inst:Remove()
end

local function onhit(inst, worker)
	inst.AnimState:PlayAnimation("hit")
	inst.AnimState:PushAnimation("idle")
end

local function onbuilt(inst)
	inst.AnimState:PlayAnimation("place")
	inst.AnimState:PushAnimation("idle", false)
	inst.SoundEmitter:PlaySound("dontstarve/common/chest_craft")
end

local function OnInit(inst)
	if inst.components.burnable ~= nil then
		inst.components.burnable:FixFX()
	end
end

local function onCreateWoodead(inst)
	local usageTimes = 0

	-- 计算生产的物料
	if inst.components.aipc_action and inst.components.container then
		for k, item in pairs(inst.components.container.slots) do
			local stackSize = item.components.stackable and item.components.stackable:StackSize() or 1

			if item.prefab == "livinglog" then
				usageTimes = usageTimes + stackSize * 5
			elseif item.prefab == "driftwood_log" then
				usageTimes = usageTimes + stackSize * 2
			else
				usageTimes = usageTimes + stackSize
			end
		end
	end

	if usageTimes > 0 then
		inst.AnimState:PlayAnimation("consume")
		inst.AnimState:PushAnimation("idle", false)

		inst:DoTaskInTime(0.3, function ()
			inst.SoundEmitter:PlaySound("dontstarve/common/sign_craft")
			local dropLootItem = inst.components.lootdropper:SpawnLootPrefab("aip_oar_woodead")
			local usage = usageTimes * 57
			dropLootItem.components.finiteuses:SetMaxUses(usage)
			dropLootItem.components.finiteuses:SetUses(usage)
		end)

		inst.components.container:Close()
		inst.components.container:DestroyContents()
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
	inst.AnimState:SetBank("aip_woodener")
	inst.AnimState:SetBuild("aip_woodener")
	inst.AnimState:PlayAnimation("idle", false)

	-- 标签
	inst:AddTag("structure")

	MakeSnowCoveredPristine(inst)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	-- 容器
	inst:AddComponent("container")
	inst.components.container:WidgetSetup("aip_woodener")

	-- 烹饪
	inst:AddComponent("aipc_action")
	inst.components.aipc_action.onDoAction = onCreateWoodead

	-- 掉东西
	inst:AddComponent("lootdropper")

	-- 被锤子
	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
	inst.components.workable:SetWorkLeft(4)
	inst.components.workable:SetOnFinishCallback(onhammered)
	inst.components.workable:SetOnWorkCallback(onhit)

	-- 可作祟
	inst:AddComponent("hauntable")
	inst.components.hauntable.cooldown = TUNING.HAUNT_COOLDOWN_HUGE

	-- 可检查
	inst:AddComponent("inspectable")
	inst:ListenForEvent("onbuilt", onbuilt)

	-- 可燃烧
	MakeMediumBurnable(inst)

	return inst
end

return Prefab("aip_woodener", fn, assets, prefabs),
	MakePlacer("aip_woodener_placer", "aip_woodener", "aip_woodener", "idle")