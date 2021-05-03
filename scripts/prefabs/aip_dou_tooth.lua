------------------------------------ 配置 ------------------------------------
-- 开发模式
local dev_mode = aipGetModConfig("dev_mode") == "enabled"

local language = aipGetModConfig("language")

local LANG_MAP = {
	["english"] = {
		["NAME"] = "Shadow Broken Tooth",
		["DESC"] = "Left part of the key!",
	},
	["chinese"] = {
		["NAME"] = "暗影碎牙",
		["DESC"] = "钥匙的剩余那一部分！",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

-- 资源
local assets = {
	Asset("ATLAS", "images/inventoryimages/aip_dou_tooth.xml"),
	Asset("ANIM", "anim/aip_dou_tooth.zip"),
}

local prefabs = { "aip_dou_scepter" }

-- 文字描述
STRINGS.NAMES.AIP_DOU_TOOTH = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_DOU_TOOTH = LANG.DESC

-----------------------------------------------------------
local function canActOn(inst, doer, target)
	return target:HasTag("aip_dou_scepter")
end

local function onDoTargetAction(inst, doer, target)
	-- server only
	if not TheWorld.ismastersim then
		return inst
	end

	-- 施法者需要说两句话
	-- 改变权杖形状
	inst.SoundEmitter:PlaySound("dontstarve/common/ancienttable_repair")
	inst:Remove()
end

function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()
	
	MakeInventoryPhysics(inst)

	inst.AnimState:SetBank("aip_dou_tooth")
	inst.AnimState:SetBuild("aip_dou_tooth")
	inst.AnimState:PlayAnimation("idle")

	inst.entity:SetPristine()

	inst:AddComponent("aipc_action_client")
	inst.components.aipc_action_client.canActOn = canActOn

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("aipc_action")
	inst.components.aipc_action.onDoTargetAction = onDoTargetAction

	inst:AddComponent("inspectable")

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_dou_tooth.xml"

	MakeHauntableLaunchAndIgnite(inst)

	return inst
end

return Prefab("aip_dou_tooth", fn, assets, prefabs)

--[[


c_give"aip_dou_scepter"
c_give"aip_dou_tooth"


]]