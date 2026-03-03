local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Bloodstone",
		DESC = "It will resonate with the mystery factor",
	},
	chinese = {
		NAME = "血精石",
		DESC = "它会与谜团因子产生共鸣",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_BLOODSTONE = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_BLOODSTONE = LANG.DESC

TUNING.AIP_BLOODSTONE_USES = 200

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_bloodstone.zip"),
	Asset("ATLAS", "images/inventoryimages/aip_bloodstone.xml"),
}


-------------------------------- 方法 --------------------------------
local function canBeActOn(inst, doer)
	return true
end

local function onDoAction(inst, doer)
    if doer.components.health ~= nil then
        local uses = inst.components.finiteuses:GetUses()

        if uses > 0 then
            doer.components.health:DoDelta(uses, false, inst.prefab)
            inst.components.finiteuses:SetPercent(0)
            aipSpawnPrefab(doer, "farm_plant_happy")
        end
    end
end

-------------------------------- 实例 --------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("aip_bloodstone")
    inst.AnimState:SetBuild("aip_bloodstone")
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryFloatable(inst, "med", 0.3, 1)

    inst:AddTag("aip_bloodstone")

    inst.entity:SetPristine()

    inst:AddComponent("aipc_action_client")
	inst.components.aipc_action_client.canBeActOn = canBeActOn

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("aipc_action")
	inst.components.aipc_action.onDoAction = onDoAction

    inst:AddComponent("inspectable")
    
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_bloodstone.xml"

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(TUNING.AIP_BLOODSTONE_USES)
    inst.components.finiteuses:SetUses(0.00001)

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("aip_bloodstone", fn, assets)
