
-- 配置
local additional_weapon = aipGetModConfig("additional_weapon")
if additional_weapon ~= "open" then
	return nil
end

-- 资源
local assets =
{
	Asset("ANIM", "anim/aip_heal_fx.zip"),
}

-----------------------------------------------------------

function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()
	inst.entity:AddSoundEmitter()

	inst:AddTag("NOCLICK")
	inst:AddTag("FX")
	
	MakeInventoryPhysics(inst)
	
	inst.AnimState:SetBank("aip_heal_fx")
	inst.AnimState:SetBuild("aip_heal_fx")
	inst.AnimState:PlayAnimation("idle")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst.persists = false
	inst.entity:SetCanSleep(false)

	inst:DoTaskInTime(0, function(inst)
		inst.SoundEmitter:PlaySound("dontstarve/characters/wortox/soul/heal")
	end)

	inst:DoTaskInTime(3, inst.Remove)

	return inst
end

return Prefab( "aip_heal_fx", fn, assets) 
