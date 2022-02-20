local foldername = KnownModIndex:GetModActualName(TUNING.ZOMBIEJ_ADDTIONAL_PACKAGE)

------------------------------------ 配置 ------------------------------------
-- 魔法关闭
local additional_magic = aipGetModConfig("additional_magic")
if additional_magic ~= "open" then
	return nil
end

local language = aipGetModConfig("language")

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
	Asset("ANIM", "anim/aip_shadow_wrapper.zip"),
}

local prefabs = {}

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	-- TODO: Fix this
	inst.AnimState:SetBank("aip_shadow_wrapper")
	inst.AnimState:SetBuild("aip_shadow_wrapper")
	inst.AnimState:PlayAnimation("wrap")

	if not TheWorld.ismastersim then
		return inst
	end

	-- Play hide
	inst.DoHide = function()
		inst.SoundEmitter:PlaySound("dontstarve/common/together/skin_change")
		inst:DoTaskInTime(24 * FRAMES, function()
			if inst.OnFinish then
				inst.OnFinish(inst)
			end
		end)

		inst:DoTaskInTime(45 * FRAMES, function()
			inst:Remove()
		end)
	end

	-- Play show
	inst.DoShow = function(scale)
		scale = scale or 1
		inst.Transform:SetScale(scale, scale, scale)

		inst.SoundEmitter:PlaySound("dontstarve/maxwell/shadowmax_despawn")
		inst.AnimState:PlayAnimation("end")

		inst:DoTaskInTime(10 * FRAMES, function()
			inst:Remove()
		end)
	end

	return inst
end

return Prefab("aip_shadow_wrapper", fn, assets, prefabs)