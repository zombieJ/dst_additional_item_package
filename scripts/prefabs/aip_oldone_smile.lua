local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Rift Smiler",
		DESC = "Indescribable!",
	},
	chinese = {
		NAME = "裂隙笑颜",
		DESC = "不可名状！",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_OLDONE_SMILE = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_SMILE = LANG.DESC

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_oldone_smile.zip"),
}

---------------------------------- 事件 ----------------------------------
local function syncErosion(inst, alpha)
    inst.AnimState:SetErosionParams(
        math.min(1 - alpha, 1),
        -0.125, -1.0)
    inst.AnimState:SetMultColour(1, 1, 1, alpha)
end

local function fadeIn(inst)
    inst._aip_fade_cnt = inst._aip_fade_cnt + 0.04
    syncErosion(inst, inst._aip_fade_cnt)

    if inst._aip_fade_cnt >= 1 then
        return false
    end
end

local function doBrain(inst)
    aipQueue({
        -------------------------- 尚未启动 --------------------------
        function()
            aipPrint("GGG@!!")
            -- inst.components.locomotor:GoToPoint(
            --     Vector3(0, 0, 0),
            --     nil,
            --     false
            -- )
            inst:ForceFacePoint(0, 0, 0)
            inst.Physics:SetMotorVel(
                1,
                0,
                0
            )
            return true
        end,
    })
end

---------------------------------- 实例 ----------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    inst.DynamicShadow:SetSize(4, 2)

    MakeFlyingGiantCharacterPhysics(inst, 500, 1.4)

    inst.AnimState:SetBank("aip_oldone_smile")
    inst.AnimState:SetBuild("aip_oldone_smile")
    inst.AnimState:PlayAnimation("idle", true)

    inst:AddTag("aip_oldone_smile")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("aipc_timer")

    inst:AddComponent("locomotor")
    inst.components.locomotor:EnableGroundSpeedMultiplier(false)
    inst.components.locomotor:SetTriggersCreep(false)
    inst.components.locomotor.pathcaps = { ignorewalls = true, allowocean = true }
    inst.components.locomotor.walkspeed = TUNING.BEEQUEEN_SPEED

    -- 闪烁特效
    syncErosion(inst, 0)
    inst._aip_fade_cnt = 0
    inst.components.aipc_timer:NamedInterval("fadeIn", 0.1, fadeIn)
    inst.components.aipc_timer:NamedInterval("doBrain", 0.25, doBrain)

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("aip_oldone_smile", fn, assets)
