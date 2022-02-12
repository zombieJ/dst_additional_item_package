local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Strange Bulb",
		DESC = "This thing is kinda creepy",
	},
	chinese = {
		NAME = "怪异的球茎",
		DESC = "这东西多少有点渗人",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_OLDONE_PLANT = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_PLANT = LANG.DESC

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_oldone_plant.zip"),
}

------------------------------------ 事件 ------------------------------------
-- 捡起，释放毒圈
local function onpickedfn(inst, picker)
    aipSpawnPrefab(inst, "aip_aura_poison")
end

local function CanShaveTest(inst, shaver)
    return true
end

------------------------------------ 实例 ------------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("aip_oldone_plant")
    inst.AnimState:SetBuild("aip_oldone_plant")
    inst.AnimState:PlayAnimation("small", true)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    -- 可以直接捡起，但是会中毒
    inst:AddComponent("pickable")
    inst.components.pickable.picksound = "dontstarve/wilson/harvest_berries"
    inst.components.pickable:SetUp("aip_oldone_plant_broken", 10)
    inst.components.pickable.onpickedfn = onpickedfn
	inst.components.pickable.remove_when_picked = true
    inst.components.pickable.quickpick = true

    -- 可以用剃刀
    inst:AddComponent("beard")
    inst.components.beard.bits = 1
    inst.components.beard.canshavetest = CanShaveTest
    inst.components.beard.prize = "aip_oldone_plant_full"
    inst:ListenForEvent("shaved", inst.Remove)

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("aip_oldone_plant", fn, assets)
