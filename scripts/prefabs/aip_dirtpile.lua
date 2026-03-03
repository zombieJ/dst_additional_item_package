local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Normal Dirt Pile",
		DESC = "Completely unremarkable",
	},
	chinese = {
		NAME = "浅埋的土堆",
		DESC = "完全不可疑",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_DIRTPILE = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_DIRTPILE = LANG.DESC

local assets = {
    Asset("ANIM", "anim/koalefant_tracks.zip"),
    Asset("ANIM", "anim/smoke_puff_small.zip"),
}

local prefabs = {
    "small_puff"
}

local function GetVerb()
    return "INVESTIGATE"
end

local function OnInvestigated(inst, doer)
    aipSpawnPrefab(inst, "small_puff")

    local loot = {
        aip_22_fish = 1,
        aip_oldone_meat = 5,
        aip_oldone_plant_broken = 75,
        aip_oldone_plant_full = 20,
    }
    local lootName = aipRandomLoot(loot)

    inst:DoTaskInTime(.3, function()
        aipReplacePrefab(inst, lootName)
    end)
end

local function OnHaunted(inst, haunter)
    inst:OnInvestigated(haunter)
    return true
end

local function create()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst:AddTag("dirtpile")

    inst.AnimState:SetBank("track")
    inst.AnimState:SetBuild("koalefant_tracks")
    inst.AnimState:SetRayTestOnBB(true)
    inst.AnimState:PlayAnimation("idle_pile")

    inst.GetActivateVerb = GetVerb

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.OnInvestigated = OnInvestigated

    inst:AddComponent("inspectable")

    local activatable = inst:AddComponent("activatable")
    activatable.OnActivate = inst.OnInvestigated
    activatable.inactive = true

    local hauntable = inst:AddComponent("hauntable")
    hauntable:SetHauntValue(TUNING.HAUNT_SMALL)
    hauntable:SetOnHauntFn(OnHaunted)

    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(TUNING.TOTAL_DAY_TIME)
    inst.components.perishable:StartPerishing()

    inst.persists = false
    return inst
end

return Prefab("aip_dirtpile", create, assets, prefabs)