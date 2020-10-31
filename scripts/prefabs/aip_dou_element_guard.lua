-- 公测开启
local open_beta = aipGetModConfig("open_beta")
if open_beta ~= "open" then
	return nil
end

------------------------------------ 配置 ------------------------------------
-- 雕塑关闭
local additional_chesspieces = aipGetModConfig("additional_chesspieces")
if additional_chesspieces ~= "open" then
	return nil
end

local language = aipGetModConfig("language")

local LANG_MAP = {
	english = {
		NAME = "Element Spirit",
		DESC = "Why help me?",
	},
	chinese = {
		NAME = "元素之灵",
		DESC = "为什么帮我？",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

-- 文字描述
STRINGS.NAMES.AIP_DOU_ELEMENT_GUARD = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_DOU_ELEMENT_GUARD = LANG.DESC

---------------------------------- 资源 ----------------------------------
local assets = {
	Asset("ANIM", "anim/aip_dou_element_fire_guard.zip"),
}

---------------------------------- 特效 ----------------------------------
local createEffectVest = require("utils/aip_vest_util").createEffectVest

local function OnEffect(inst)
	if inst.entity:IsVisible() then
		local vest = createEffectVest("aip_dou_scepter_projectile", "aip_dou_scepter_projectile", "disappear")

		local x, y, z = inst.Transform:GetWorldPosition()
		vest.Transform:SetPosition(x + (0.5 - math.random()) * 0.8, y + 2, z + (0.5 - math.random()) * 0.8)
		vest.Physics:SetMotorVel(0, -3, 0)
		vest.AnimState:OverrideMultColour(1, 0.8, 0, 1)
	end
end


---------------------------------- 实体 ----------------------------------
local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()
	inst.entity:AddLight()

	inst.Light:SetIntensity(.75)
	inst.Light:SetColour(200 / 255, 150 / 255, 50 / 255)
	inst.Light:SetFalloff(.5)
	inst.Light:SetRadius(1)

	inst.AnimState:SetBank("aip_dou_element_fire_guard")
	inst.AnimState:SetBuild("aip_dou_element_fire_guard")

	inst.AnimState:PlayAnimation("idle", true)
	-- inst.AnimState:PlayAnimation("place")
	-- inst.AnimState:PushAnimation("idle", true)

	-- 客户端的特效
	if not TheNet:IsDedicated() then
		inst.periodTask = inst:DoPeriodicTask(0.2, OnEffect)
	end

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("inspectable")

	return inst
end

return Prefab("aip_dou_element_fire_guard", fn, assets)