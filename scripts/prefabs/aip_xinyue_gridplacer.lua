local assets =
{
    Asset("ANIM", "anim/aip_xinyue_gridplacer.zip"),
}

local function OnCanBuild(inst, mouse_blocked)
    inst.AnimState:SetMultColour(1, 1, 1, 1)
    inst:Show()
end

local function OnCannotBuild(inst, mouse_blocked)
    inst.AnimState:SetMultColour(.75, .25, .25, 1)
    inst:Show()
end

local function fn()
    local inst = CreateEntity()

    inst:AddTag("CLASSIFIED")
    inst:AddTag("NOCLICK")
    inst:AddTag("placer")
    --[[Non-networked entity]]
    inst.persists = false

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    inst.AnimState:SetBank("aip_xinyue_gridplacer")
    inst.AnimState:SetBuild("aip_xinyue_gridplacer")
    inst.AnimState:PlayAnimation("anim", true)
    inst.AnimState:SetLightOverride(1)
	inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)

    inst:AddComponent("placer")
	inst.components.placer.hide_inv_icon = false
    inst.components.placer.snap_to_tile = true
    inst.components.placer.oncanbuild = OnCanBuild
    inst.components.placer.oncannotbuild = OnCannotBuild

    return inst
end

return Prefab("aip_xinyue_gridplacer", fn, assets)
