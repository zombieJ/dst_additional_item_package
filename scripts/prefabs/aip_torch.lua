-- 武器 标准 模板，武器模板
local dev_mode = aipGetModConfig("dev_mode") == "enabled"

-- 配置
local additional_weapon = aipGetModConfig("additional_weapon")
if additional_weapon ~= "open" then
	return nil
end

local weapon_uses = aipGetModConfig("weapon_uses")
local weapon_damage = aipGetModConfig("weapon_damage")
local language = aipGetModConfig("language")

-- 默认参数
local DAMAGE_MAP = {
	less = TUNING.NIGHTSWORD_DAMAGE / 68 * 100,
	normal = TUNING.NIGHTSWORD_DAMAGE / 68 * 500,
	large = TUNING.NIGHTSWORD_DAMAGE / 68 * 1000,
}

local LANG_MAP = {
	english = {
		NAME = "Radish Match",
		REC_DESC = "Take away the flame of the bonfire",
		DESC = "Take away the flame of the bonfire",
	},
	chinese = {
		NAME = "大根火柴",
		REC_DESC = "可以带走篝火的火焰",
		DESC = "带走篝火的火焰",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

TUNING.AIP_TORCH_DAMAGE = DAMAGE_MAP[weapon_damage]

-- 资源
local assets = {
	Asset("ATLAS", "images/inventoryimages/aip_torch.xml"),
	Asset("ANIM", "anim/aip_torch.zip"),
	Asset("ANIM", "anim/aip_torch_swap.zip"),
}

local prefabs = {}

-- 文字描述
STRINGS.NAMES.AIP_TORCH = LANG.NAME
STRINGS.RECIPE_DESC.AIP_TORCH = LANG.REC_DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_TORCH = LANG.DESC

---------------------------- 监听 ----------------------------
-- 找到最近营火在燃烧的火焰
local function getFire(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	local ents = TheSim:FindEntities(x, y, z, 2, { "fire" })

	-- 找到火焰
	for _, ent in pairs(ents) do
		if
			ent.components.burnable and
			ent.components.burnable:IsBurning() and
			ent.components.burnable.fxchildren
		then
			for _, fx in pairs(ent.components.burnable.fxchildren) do
				if fx and fx:IsValid() and fx.components.heater then
					return fx
				end
			end
		end
	end
end

-- 停火
local function stopFire(inst)
	if inst._aipFireFX then
		inst._aipFireFX:Remove()
	end

	inst._aipFirePrefab = nil
	inst._aipFireFX = nil
end

-- 点火，根据火焰的热量选择对应的火焰
local function flareFire(inst, owner, firePrefab)
	if inst._aipFirePrefab == firePrefab then
		return
	end

	stopFire(inst)

	local fx = SpawnPrefab(firePrefab)
	fx.entity:SetParent(owner.entity)
	fx.entity:AddFollower()
	fx.Follower:FollowSymbol(owner.GUID, "swap_object", 0, -140, 0)

	inst._aipFirePrefab = firePrefab
	inst._aipFireFX = fx
end



local function syncFire(inst, owner)
	local fireFX = getFire(inst)

	if fireFX then
		local heat = fireFX.components.heater:GetHeat(owner)

		local firePrefab = heat > 0 and "aip_hot_torchfire" or "aip_cold_torchfire"
		flareFire(inst, owner, firePrefab)
	end
end

---------------------------- 装备 ----------------------------
local function onequip(inst, owner)
	owner.AnimState:OverrideSymbol("swap_object", "aip_torch_swap", "aip_torch_swap")
	owner.SoundEmitter:PlaySound("dontstarve/wilson/equip_item_gold")
	owner.AnimState:Show("ARM_carry")
	owner.AnimState:Hide("ARM_normal")

	owner.components.aipc_timer:NamedInterval("syncFire", 0.4, function()
		syncFire(inst, owner)
	end)

	stopFire(inst)
end

local function onunequip(inst, owner)
	owner.AnimState:ClearOverrideSymbol("swap_object")
	owner.AnimState:Hide("ARM_carry")
	owner.AnimState:Show("ARM_normal")

	owner.components.aipc_timer:KillName("syncFire")

	stopFire(inst)
end

---------------------------- 实例 ----------------------------
local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()
	
	MakeInventoryPhysics(inst)
	
	inst.AnimState:SetBank("aip_torch")
	inst.AnimState:SetBuild("aip_torch")
	inst.AnimState:PlayAnimation("idle")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("finiteuses")
	inst.components.finiteuses:SetMaxUses(1)
	inst.components.finiteuses:SetUses(1)
	inst.components.finiteuses:SetOnFinished(inst.Remove)

	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(TUNING.AIP_TORCH_DAMAGE)

	inst:AddComponent("inspectable")

	inst:AddComponent("aipc_timer")

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_torch.xml"

	MakeHauntable(inst)

	inst:AddComponent("equippable")
	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)

	inst._aipFirePrefab = nil
	inst._aipFireFX = nil

	return inst
end

return Prefab("aip_torch", fn, assets)
