local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Lazy Pumpkin",
		DESC = "It will throw things when anger",
	},
	chinese = {
		NAME = "怠惰的南瓜",
		DESC = "惹它生气可会乱丢东西",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_TRICKY_THROWER = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_TRICKY_THROWER = LANG.DESC

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_tricky_thrower.zip"),
    Asset("ATLAS", "images/inventoryimages/aip_tricky_thrower.xml"),
}

------------------------------------ 方法 ------------------------------------
local SEARCH_RANGE = 15

local function markItem(inst, data)
    inst._aipDropItem = data.item
end

local function onHit(inst, attacker)
    local x, y, z = inst.Transform:GetWorldPosition()

    local ents = TheSim:FindEntities(
                    x, y, z, SEARCH_RANGE,
                    nil, { "INLIMBO", "NOCLICK", "ghost" }
                )

    -- 找到最近的需要充能的单位
    local target = nil -- 需要充能的目标
    local fuelItem = nil
    local dist = nil

    for _, ent in ipairs(ents) do
        if
            ent.components.fueled ~= nil and
            ent.components.fueled:GetCurrentSection() < ent.components.fueled.sections
        then
             -- 需要充能
             local allItems = inst.components.container:GetAllItems()

             for _, item in ipairs(allItems) do -- 找可以充能的物品
                if ent.components.fueled:CanAcceptFuelItem(item) then
                    local targetDist = inst:GetDistanceSqToInst(ent)
                    if target == nil or targetDist < dist then
                        target = ent
                        fuelItem = item
                        dist = targetDist

                        break
                    end
                end
             end
        end
    end

    -- 充能吧
    if target ~= nil then
        inst._aipDropItem = nil
        inst.components.container:DropItem(fuelItem)
        local pickOne = inst._aipDropItem

        -- 投掷物理准备
        if pickOne.components.complexprojectile == nil then
            pickOne:AddComponent("complexprojectile")
        end

        if pickOne.Physics == nil then
            pickOne.entity:AddPhysics()
            MakeInventoryPhysics(pickOne)
        end

        -- 干掉物理
        pickOne.Physics:SetMass(1)
        pickOne.Physics:SetCapsule(0.2, 0.2)
        pickOne.Physics:SetFriction(0)
        pickOne.Physics:SetDamping(0)
        pickOne.Physics:SetCollisionGroup(COLLISION.CHARACTERS)
        pickOne.Physics:ClearCollisionMask()
        pickOne.Physics:CollidesWith(COLLISION.GROUND)
        pickOne.Physics:CollidesWith(COLLISION.OBSTACLES)
        pickOne.Physics:CollidesWith(COLLISION.ITEMS)

        -- 设置投掷参数
        pickOne.components.complexprojectile:SetHorizontalSpeed(15)
        pickOne.components.complexprojectile:SetGravity(-35)
        pickOne.components.complexprojectile:SetLaunchOffset(Vector3(0, 2, 0))
        pickOne.components.complexprojectile:SetOnHit(function()
            target.components.fueled:TakeFuelItem(pickOne)
        end)

        -- 扔吧
        pickOne.components.complexprojectile:Launch(target:GetPosition(), inst)
        inst.AnimState:PlayAnimation("throw")
        inst.AnimState:PushAnimation("idle", true)
    end
end

------------------------------------ 实例 ------------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("aip_tricky_thrower")
    inst.AnimState:SetBuild("aip_tricky_thrower")
    inst.AnimState:PlayAnimation("idle", true)

    -- 添加粒子标记，让南瓜可以被攻击到
    inst:AddTag("aip_particles")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("aip_tricky_thrower")

    inst:AddComponent("combat")
    inst.components.combat.onhitfn = onHit

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(100)
    inst.components.health.nofadeout = true
    inst.components.health:StartRegen(1, 10)

    inst:ListenForEvent("dropitem", markItem)

    MakeHauntableLaunch(inst)

    return inst
end

return  Prefab("aip_tricky_thrower", fn, assets),
        MakePlacer("aip_tricky_thrower_placer", "aip_tricky_thrower", "aip_tricky_thrower", "idle")
