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
	["russian"] = {
		["NAME"] = "Теневой сломанный зуб",
		["DESC"] = "Левая часть ключа!",
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

	-- 随机赋能
	if target._aipEmpower ~= nil then
		target._aipEmpower(target, doer)
	end

	aipRemove(inst)
end

local function OnUse(inst, target) -- 恢复 50% 损失的理智值
	if target.components.sanity ~= nil then
		local ptg = 1 - target.components.sanity:GetPercentWithPenalty()
		local max = target.components.sanity:GetMaxWithPenalty()
		target.components.sanity:DoDelta(max * ptg * 0.5)
	end
end

local function fn()
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

	inst:AddComponent("stackable")

	inst:AddComponent("aipc_action")
	inst.components.aipc_action.onDoTargetAction = onDoTargetAction

	inst:AddComponent("inspectable")

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_dou_tooth.xml"

	inst:AddComponent("healer")
	inst.components.healer:SetHealthAmount(5)
	inst.components.healer.onhealfn = OnUse

	MakeHauntableLaunchAndIgnite(inst)

	return inst
end

return Prefab("aip_dou_tooth", fn, assets, prefabs)

--[[


c_give"aip_dou_scepter"
c_give("aip_dou_tooth", 20)


c_give("aip_dou_split_inscription", 5)



c_give"krampus_sack"

]]
