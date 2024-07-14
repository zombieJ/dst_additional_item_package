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

	-- 如果是设置了特殊 tag，我们认为这个火焰可以直接使用
	local rubikFireEnts = TheSim:FindEntities(x, y, z, 3, { "aip_rubik_fire" })

	-- 如果有多个，我们看看是不是存在两种火焰。有的话则直接上混合火焰
	if #rubikFireEnts > 0 then
		local hotPrefab = nil
		local coldPrefab = nil
		local mixPrefab = nil

		for _, ent in pairs(rubikFireEnts) do
			if ent:HasTag("aip_rubik_fire_hot") then
				hotPrefab = ent
			elseif ent:HasTag("aip_rubik_fire_cold") then
				coldPrefab = ent
			elseif ent:HasTag("aip_rubik_fire_mix") then
				mixPrefab = ent
			end
		end

		if mixPrefab then
			return true
		end

		return hotPrefab or coldPrefab
	end

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

local function syncFire(inst, owner)
	-- 查看附近有没有火焰
	local fireFX = getFire(inst)

	-- 神圣之火
	if fireFX == true then
		inst.components.aipc_type_fire:StartFire("mix", owner)

	-- 普通火焰，如果已经是 神圣之火 了，就不能覆盖它
	elseif fireFX and inst.components.aipc_type_fire:GetType() ~= "mix" then
		local heat = fireFX.components.heater:GetHeat(owner)

		inst.components.aipc_type_fire:StartFire(heat > 0 and "hot" or "cold", owner)
	end
end

local function onToggleFire(inst, fireType)
	if inst.components.aipc_lighter then
		inst.components.aipc_lighter:Enabled(fireType)
	end
end

---------------------------- 熄火 ----------------------------
-- 如果玩家跑得太远了，我们就直接熄火掉
local function checkFireExtinguish(inst, owner)
	local post = owner:GetPosition()

	if inst._aipLastPos then
		local dist = inst._aipLastPos:Dist(post)
		if dist > 8 then
			inst.components.aipc_type_fire:StopFire()
		end
	end

	inst._aipLastPos = post
end

---------------------------- 装备 ----------------------------
local function onequip(inst, owner)
	owner.AnimState:OverrideSymbol("swap_object", "aip_torch_swap", "aip_torch_swap")
	owner.SoundEmitter:PlaySound("dontstarve/wilson/equip_item_gold")
	owner.AnimState:Show("ARM_carry")
	owner.AnimState:Hide("ARM_normal")

	owner.components.aipc_timer:NamedInterval("syncFire", 0.8, function()
		syncFire(inst, owner)
		checkFireExtinguish(inst, owner)
	end)

	-- stopFire(inst)
	inst.components.aipc_type_fire:StopFire()
end

local function onunequip(inst, owner)
	owner.AnimState:ClearOverrideSymbol("swap_object")
	owner.AnimState:Hide("ARM_carry")
	owner.AnimState:Show("ARM_normal")

	owner.components.aipc_timer:KillName("syncFire")

	inst.components.aipc_type_fire:StopFire()
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

	MakeInventoryFloatable(inst, "small", 0.15, 0.9)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("aipc_lighter")

	inst:AddComponent("finiteuses")
	inst.components.finiteuses:SetMaxUses(1)
	inst.components.finiteuses:SetUses(1)
	inst.components.finiteuses:SetOnFinished(inst.Remove)

	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(TUNING.AIP_TORCH_DAMAGE)

	inst:AddComponent("inspectable")

	inst:AddComponent("aipc_timer")

	-- 火焰类型
	inst:AddComponent("aipc_type_fire")
	inst.components.aipc_type_fire.hotPrefab = "aip_hot_torchfire"
	inst.components.aipc_type_fire.coldPrefab = "aip_cold_torchfire"
	inst.components.aipc_type_fire.mixPrefab = "aip_mix_torchfire"
	inst.components.aipc_type_fire.followSymbol = "swap_object"
	inst.components.aipc_type_fire.followOffset = Vector3(0, -140, 0)
	inst.components.aipc_type_fire.onToggle = onToggleFire

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_torch.xml"

	MakeHauntable(inst)

	inst:AddComponent("equippable")
	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)

	inst._aipFirePrefab = nil
	inst._aipFireFX = nil
	inst._aipLastPos = nil

	return inst
end

return Prefab("aip_torch", fn, assets)
