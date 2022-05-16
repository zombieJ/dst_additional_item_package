local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Fusious Deer Stone",
		DESC = "It looks like smoked",
	},
	chinese = {
		NAME = "漆黑的鹿",
		DESC = "看起来有被烟熏的痕迹",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_OLDONE_DEER = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_DEER = LANG.DESC

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_oldone_deer.zip"),
}

--------------------------------- 事件 ---------------------------------
local function syncStatus(inst)
    local animName = "idle"

    if inst._aipLevel == 2 then
        animName = "full"
    elseif inst._aipLevel == 1 then
        animName = "half"
    end

    if not inst.AnimState:IsCurrentAnimation(animName) then
        inst.AnimState:PlayAnimation(animName)
    end
end

local function onNear(inst, player)
    inst.components.aipc_timer:NamedInterval("PlayerNear", 3, function()
        local x, y, z = inst.Transform:GetWorldPosition()
        local fires = TheSim:FindEntities(x, y, z, 5, { "fire" })
        fires = aipFilterTable(fires, function(fire)
            return fire.components.burnable ~= nil and fire.components.burnable:IsBurning()
        end)

        -- 附近有火源 并且 自身温度 > 80 则可以变化（测试下来可以超过 80 度）
        local firing = #fires > 0
        local temperature = inst.components.temperature:GetCurrent()
        --  and inst.components.temperature:GetCurrent() >= 80
        local offset = firing and 1 or -1
        inst._aipLevel = math.max(0, inst._aipLevel + offset)
        inst._aipLevel = math.min(2, inst._aipLevel)

        if temperature < 80 then -- 80 度以下强制不会到最终阶段
            inst._aipLevel = math.min(1, inst._aipLevel)
        end

        if temperature < 60 then -- 60 度以下一定是漆黑状态
            inst._aipLevel = 0
        end

        syncStatus(inst)
    end)
end

local function onFar(inst)
    inst.components.aipc_timer:KillName("PlayerNear")
end


--------------------------------- 实例 ---------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("aip_oldone_deer")
    inst.AnimState:SetBuild("aip_oldone_deer")
    inst.AnimState:PlayAnimation("idle")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("playerprox")
    inst.components.playerprox:SetDist(20, 30)
    inst.components.playerprox:SetOnPlayerNear(onNear)
    inst.components.playerprox:SetOnPlayerFar(onFar)

    inst:AddComponent("aipc_timer")


    inst:AddComponent("temperature")
    inst.components.temperature.current = TheWorld.state.temperature
    inst.components.temperature.inherentinsulation = TUNING.INSULATION_MED
    inst.components.temperature.inherentsummerinsulation = TUNING.INSULATION_MED

    MakeHauntableLaunch(inst)

    inst._aipLevel = 0

    return inst
end

return Prefab("aip_oldone_deer", fn, assets)
