-- 配置
local additional_weapon = aipGetModConfig("additional_weapon")
if additional_weapon ~= "open" then
	return nil
end

local assets = {
    Asset("ANIM", "anim/aip_dou_scepter_projectile.zip"),
}

local prefabs = {}

--------------------------------- 配方 ---------------------------------


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
    -- inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

    --projectile (from projectile component) added to pristine state for optimization
    inst:AddTag("projectile")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("aipc_projectile")

    return inst
end

return Prefab("aip_dou_scepter_projectile", fn, assets, prefabs)
