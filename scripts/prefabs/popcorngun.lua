local assets =
{
	Asset("ANIM", "anim/popcorn_gun.zip"),
	Asset("ANIM", "anim/swap_popcorn_gun.zip"),
}

local prefabs =
{
	"impact",
}

local function onequip(inst, owner)
	owner.AnimState:OverrideSymbol("swap_object", "swap_popcorn_gun", "swap_popcorn_gun")
	owner.SoundEmitter:PlaySound("dontstarve/wilson/equip_item_gold")
	owner.AnimState:Show("ARM_carry")
	owner.AnimState:Hide("ARM_normal")
end

local function onunequip(inst, owner)
	owner.AnimState:ClearOverrideSymbol("swap_object")
	owner.AnimState:Hide("ARM_carry")
	owner.AnimState:Show("ARM_normal")
end

function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()
	
	MakeInventoryPhysics(inst)
	
	inst.AnimState:SetBank("popcorn_gun")
	inst.AnimState:SetBuild("popcorn_gun")
	inst.AnimState:PlayAnimation("idle")

	inst:AddTag("popcorngun")
	inst:AddTag("sharp")
	inst:AddTag("projectile")
	
	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	-- 武器
	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(TUNING.POPCORNGUN_DAMAGE)
	inst.components.weapon:SetRange(8, 10)
	inst.components.weapon:SetProjectile("fire_projectile")

	-- 可检查
	inst:AddComponent("inspectable")
	
	-- 物品栏
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/popcorngun.xml"
	
	-- 使用次数
	inst:AddComponent("finiteuses")
	inst.components.finiteuses:SetMaxUses(TUNING.POPCORNGUN_USES)
	inst.components.finiteuses:SetUses(TUNING.POPCORNGUN_USES)
	
	inst.components.finiteuses:SetOnFinished(inst.Remove)
	
	-- 装备
	inst:AddComponent("equippable")
	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)
	
	-- 可以造成伤害
	MakeHauntableLaunch(inst)

	return inst
end

return Prefab( "popcorngun", fn, assets) 
