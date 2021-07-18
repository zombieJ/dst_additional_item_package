-- local beecommon = require "brains/beecommon"

local assets = {
    Asset("ANIM", "anim/aip_mini_doujiang.zip"),
}

local prefabs = {}

-- 配置
local language = aipGetModConfig("language")

local LANG_MAP = {
	english = {
		NAME = "Likeght",
		DESC = "He need help",
		BALLOON = "TAT, My balloon...",
	},
	chinese = {
		NAME = "若光",
		DESC = "需要帮帮他",
		BALLOON = "555，我的气球...",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

-- 文字描述
STRINGS.NAMES.AIP_MINI_DOUJIANG = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_MINI_DOUJIANG = LANG.DESC
STRINGS.AIP_MINI_DOUJIANG_BALLOON = LANG.BALLOON

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst, 50, .5)

    inst.DynamicShadow:SetSize(1.5, .75)
    inst.Transform:SetFourFaced()

    inst.AnimState:SetBank("aip_mini_doujiang")
    inst.AnimState:SetBuild("aip_mini_doujiang")
    inst.AnimState:PlayAnimation("idle", true)
    -- inst.AnimState:SetRayTestOnBB(true) 小物体会直接用盒装模型碰撞检测

    inst.entity:SetPristine()

	inst:AddComponent("talker")
	inst.components.talker.fontsize = 30
	inst.components.talker.font = TALKINGFONT
	inst.components.talker.colour = Vector3(.9, 1, .9)
	inst.components.talker.offset = Vector3(0, -200, 0)

    if not TheWorld.ismastersim then
        return inst
    end

    -- inst:AddComponent("locomotor")
    -- inst.components.locomotor:EnableGroundSpeedMultiplier(false)
    -- inst.components.locomotor:SetTriggersCreep(false)
    -- inst:SetStateGraph("SGbee")

    inst:AddComponent("inspectable")

	-- 闪烁特效
	-- inst.AnimState:SetErosionParams(0.06, 0, -1.0)
	inst.AnimState:SetErosionParams(0, -0.125, -1.0)

	inst:DoPeriodicTask(5, function()
		inst.components.talker:Say(STRINGS.AIP_MINI_DOUJIANG_BALLOON)
	end)

    return inst
end

return Prefab("aip_mini_doujiang", fn, assets, prefabs)