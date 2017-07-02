local foldername = KnownModIndex:GetModActualName(TUNING.ZOMBIEJ_ADDTIONAL_PACKAGE)

-- 配置
local language = GetModConfigData("language", foldername)

local LANG_MAP = {
	["english"] = {
		["NAME"] = "Incinerator",
		["DESC"] = "Burn everything into ash!",
		["DESCRIBE"] = "Why we do not just burn the home to make ash?",
		["INCINERATOR_NOT_BURN"] = "Hmmm, finally find something can't burn",
	},
	["chinese"] = {
		["NAME"] = "焚烧炉",
		["DESC"] = "把一切都烧成灰！",
		["DESCRIBE"] = "想要灰为什么不直接烧家？",
		["INCINERATOR_NOT_BURN"] = "终于有烧不掉的东西了",
	},
}

local LANG = LANG_MAP[language]

-- 文字描述
STRINGS.NAMES.INCINERATOR = LANG.NAME
STRINGS.RECIPE_DESC.INCINERATOR = LANG.DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.INCINERATOR = LANG.DESCRIBE
STRINGS.CHARACTERS.GENERIC.ACTIONFAIL.GIVE.INCINERATOR_NOT_BURN = LANG.INCINERATOR_NOT_BURN

-- 配方
local incinerator = Recipe("incinerator", {Ingredient("rocks", 5), Ingredient("twigs", 2), Ingredient("ash", 1)}, RECIPETABS.LIGHT, TECH.SCIENCE_ONE, "incinerator_placer")
incinerator.atlas = "images/inventoryimages/incinerator.xml"

-----------------------------------------------------------
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

local function AcceptTest(inst, item)
	if item.prefab == "chester_eyebone" then
		return false, "INCINERATOR_NOT_BURN"
	end

	return true
end

local function OnGetItemFromPlayer(inst, giver, item)
	inst.AnimState:PlayAnimation("consume")
	inst.AnimState:PushAnimation("idle", false)
	inst.SoundEmitter:PlaySound("dontstarve/common/fireAddFuel")
	inst.components.lootdropper:SpawnLootPrefab("ash")

	inst.components.burnable:SetFXLevel(3)
	-- inst.components.burnable:SetBurnTime(20)
end

local function onhammered(inst, worker)
	inst.components.lootdropper:DropLoot()
	local x, y, z = inst.Transform:GetWorldPosition()
	SpawnPrefab("ash").Transform:SetPosition(x, y, z)
	local fx = SpawnPrefab("collapse_small")
	fx.Transform:SetPosition(x, y, z)
	fx:SetMaterial("stone")
	inst:Remove()
end

local function onextinguish(inst)
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
		inst.components.burnable:Ignite()
		inst.components.burnable:SetFXLevel(3)
	end
end

local function fn()
	local inst = CreateEntity()
	
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	-- inst.entity:AddMiniMapEntity()
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
	inst.components.burnable:AddBurnFX("campfirefire", Vector3(0, 0, 0), "firefx", true)
	inst:ListenForEvent("onextinguish", onextinguish)

	-- 可交易
	inst:AddComponent("trader")
	inst.components.trader:SetAcceptTest(AcceptTest)
	inst.components.trader.onaccept = OnGetItemFromPlayer
	inst.components.trader.acceptnontradable = true

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