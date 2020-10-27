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
	Asset("ANIM", "anim/aip_dou_element_guard.zip"),
}

---------------------------------- 实体 ----------------------------------
local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	inst.AnimState:SetBank("aip_dou_element_guard")
	inst.AnimState:SetBuild("aip_dou_element_guard")
	inst.AnimState:PlayAnimation("idle")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("inspectable")

	return inst
end

return Prefab("aip_dou_element_guard", fn, assets)