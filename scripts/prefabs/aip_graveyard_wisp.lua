local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Wispy",
		DESC = "Can I catch you?",
	},
	chinese = {
		NAME = "鬼火",
		DESC = "我能抓到你吗？",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_GRAVEYARD_WISP = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_GRAVEYARD_WISP = LANG.DESC

-- 资源
local assets = {
    -- Asset("ANIM", "anim/aip_graveyard_wisp.zip"),
	-- Asset("ATLAS", "images/inventoryimages/aip_graveyard_wisp.xml"),
}

------------------------------------- 实例 -------------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    -- inst.entity:AddDynamicShadow()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    MakeCharacterPhysics(inst, 1, .25)

    inst.AnimState:SetBank("coldfire_fire")
    inst.AnimState:SetBuild("coldfire_fire")
    inst.AnimState:PlayAnimation("level1", true)
    inst.AnimState:OverrideMultColour(1, .6, 1, 1)

    -- inst.DynamicShadow:Enable(false)

    inst.Light:SetColour(111/255, 111/255, 227/255)
    inst.Light:SetIntensity(0.75)
    inst.Light:SetFalloff(0.5)
    inst.Light:SetRadius(2)
    inst.Light:Enable(true)

    -- inst.DynamicShadow:SetSize(.8, .5)

    -- inst:AddTag("show_spoilage")
    -- inst:AddTag("spore")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("knownlocations")

    inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
    inst.components.locomotor:EnableGroundSpeedMultiplier(false)
    inst.components.locomotor:SetTriggersCreep(false)
    inst.components.locomotor.walkspeed = 2

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.canbepickedup = false

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.NET)
    inst.components.workable:SetWorkLeft(1)
    inst.components.workable:SetOnFinishCallback(onworked)

    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(TUNING.SEG_TIME * 3)
    inst.components.perishable:StartPerishing()
    inst.components.perishable:SetOnPerishFn(inst.Remove)

    inst:ListenForEvent("onputininventory", onpickup)
    inst:ListenForEvent("ondropped", ondropped)

    inst:SetStateGraph("SGspore")
    inst:SetBrain(brain)

    return inst
end

return Prefab("aip_graveyard_wisp", fn, assets)
