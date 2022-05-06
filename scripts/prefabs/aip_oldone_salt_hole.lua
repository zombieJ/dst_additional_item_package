local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Small Salt Cave",
		DESC = "Seaside often use it to pickle salted fish",
	},
	chinese = {
		NAME = "小型盐洞",
		DESC = "海边的人常拿它腌制咸鱼",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_OLDONE_SALT_HOLE = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_SALT_HOLE = LANG.DESC

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_oldone_salt_hole.zip"),
}

------------------------------ 事件 ------------------------------
local function validteFood(food)
    return food ~= nil and (
        food:HasTag("fish")
    )
end

local function ShouldAcceptItem(inst, item)
    return validteFood(item)
end

local function OnGetItemFromPlayer(inst, giver, item)
    if validteFood(item) then
        aipRemove(item)
        inst:RemoveComponent("trader")

        inst.AnimState:PlayAnimation("warming", true)
        inst:DoTaskInTime(10, function()
            aipFlingItem(aipSpawnPrefab(inst, "aip_salt_fish"))
            aipReplacePrefab(inst, "aip_shadow_wrapper").DoShow()
        end)
    end
end

------------------------------ 实例 ------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 1)

    inst.AnimState:SetBank("aip_oldone_salt_hole")
    inst.AnimState:SetBuild("aip_oldone_salt_hole")
    inst.AnimState:PlayAnimation("idle")

    local scale = 1
    inst.Transform:SetScale(scale, scale, scale)

    inst:AddTag("aip_olden_flower")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("trader")
    inst.components.trader:SetAcceptTest(ShouldAcceptItem)
    inst.components.trader.onaccept = OnGetItemFromPlayer
    inst.components.trader.deleteitemonaccept = false

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

    inst.persists = false

    return inst
end

return Prefab("aip_oldone_salt_hole", fn, assets)
