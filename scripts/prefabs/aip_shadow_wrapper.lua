local foldername = KnownModIndex:GetModActualName(TUNING.ZOMBIEJ_ADDTIONAL_PACKAGE)

------------------------------------ 配置 ------------------------------------
-- 魔法关闭
local additional_magic = GetModConfigData("additional_magic", foldername)
if additional_magic ~= "open" then
	return nil
end

local language = GetModConfigData("language", foldername)

local LANG_MAP = {
	english = {
		NAME = "Shadow Wrapper",
		DESCRIBE = "Do not spawn me!",
	},
	chinese = {
		NAME = "暗影动画",
		DESCRIBE = "不要创建我！",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english
local LANG_ENG = LANG_MAP.english

-----------------------------------------------------------
local assets = {
	Asset("ANIM", "anim/shadow_skinchangefx.zip"),
}

local prefabs = {}

function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	-- TODO: Fix this
	inst.AnimState:SetBank("shadow_skinchangefx")
	inst.AnimState:SetBuild("shadow_skinchangefx")
	inst.AnimState:PlayAnimation("idle")

	if not TheWorld.ismastersim then
		return inst
	end

	inst.SoundEmitter:PlaySound("dontstarve/common/together/skin_change")
	inst:DoTaskInTime(44 * FRAMES, function()
		if inst.OnFinish then
			inst.OnFinish(inst)
		end
	end)

	return inst
end

return Prefab("aip_shadow_wrapper", fn, assets, prefabs)