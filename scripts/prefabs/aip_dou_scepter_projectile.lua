-- 公测开启
local open_beta = aipGetModConfig("open_beta")
if open_beta ~= "open" then
	return nil
end

-- 配置
local additional_weapon = aipGetModConfig("additional_weapon")
if additional_weapon ~= "open" then
	return nil
end

local createEffectVest = require("utils/aip_vest_util").createEffectVest

local assets = {
    Asset("ANIM", "anim/aip_dou_scepter_projectile.zip"),
}

local prefabs = {}

--------------------------------- 实体 ---------------------------------
local function CreateTail(inst)
    local tail = createEffectVest("aip_dou_scepter_projectile", "aip_dou_scepter_projectile", "disappear")

    local x, y, z = inst.Transform:GetWorldPosition()
    local speed = 15

    local rot = inst.Transform:GetRotation()
    tail.Transform:SetRotation(rot)
    rot = rot * DEGREES
    local offsangle = math.random() * 2 * PI
    local offsradius = math.random() * .2 + .2
    local hoffset = math.cos(offsangle) * offsradius
    local voffset = math.sin(offsangle) * offsradius
    tail.Transform:SetPosition(x + math.sin(rot) * hoffset, y + voffset, z + math.cos(rot) * hoffset)
    tail.Physics:SetMotorVel(speed * (.2 + math.random() * .3), 0, 0)
end

local function OnUpdateProjectileTail(inst)
    -- 
    if inst.entity:IsVisible() then
        local tail = CreateTail(inst)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    RemovePhysicsColliders(inst)

    inst.AnimState:SetBank("aip_dou_scepter_projectile")
    inst.AnimState:SetBuild("aip_dou_scepter_projectile")
    inst.AnimState:PlayAnimation("idle", true)
    inst.AnimState:OverrideMultColour(1, 0.8, 0, 1)
    -- inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

    --projectile (from projectile component) added to pristine state for optimization
    inst:AddTag("projectile")
    inst:AddTag("flying")
    inst:AddTag("ignorewalkableplatformdrowning")

    -- 客户端的特效
    if not TheNet:IsDedicated() then
        inst:DoPeriodicTask(0, OnUpdateProjectileTail, nil)
    end

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(1)

    inst:AddComponent("aipc_projectile")

    return inst
end

return Prefab("aip_dou_scepter_projectile", fn, assets, prefabs)
