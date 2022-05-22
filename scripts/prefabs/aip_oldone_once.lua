local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Eye Stone",
		DESC = "Everything, Everywhere, All at Once",
	},
	chinese = {
		NAME = "石头",
		DESC = "瞬息全宇宙",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_OLDONE_ONCE = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_ONCE = LANG.DESC

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_oldone_once.zip"),
}

-------------------------------------- 事件 --------------------------------------
local function onSelect(inst, viewer)
    if
        viewer ~= nil and viewer:HasTag("player")
    then
        inst.components.inspectable.descriptionfn = nil
        if viewer ~= nil and viewer.components.aipc_oldone ~= nil then
            viewer.components.aipc_oldone:DoDelta(1)
        end

        inst.AnimState:PlayAnimation("turn")
        inst:ListenForEvent("animover", function()
            aipReplacePrefab(inst, "aip_shadow_wrapper").DoShow()
        end)
    end
end

-------------------------------------- 实例 --------------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 0.6)

    inst.AnimState:SetBank("aip_oldone_once")
    inst.AnimState:SetBuild("aip_oldone_once")
    inst.AnimState:PlayAnimation("idle")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst.components.inspectable.descriptionfn = onSelect

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("aip_oldone_once", fn, assets)
