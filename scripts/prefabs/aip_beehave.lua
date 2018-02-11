local foldername = KnownModIndex:GetModActualName(TUNING.ZOMBIEJ_ADDTIONAL_PACKAGE)

------------------------------------ 配置 ------------------------------------
-- 武器关闭
local additional_weapon = GetModConfigData("additional_weapon", foldername)
if additional_weapon ~= "open" then
	return nil
end

local weapon_uses = GetModConfigData("weapon_uses", foldername)
local weapon_damage = GetModConfigData("weapon_damage", foldername)
local language = GetModConfigData("language", foldername)

-- 默认参数
local USES_MAP = {
	["less"] = 50,
	["normal"] = 100,
	["much"] = 150,
}
local DAMAGE_MAP = {
	["less"] = TUNING.SPIKE_DAMAGE * 0.8,
	["normal"] = TUNING.SPIKE_DAMAGE,
	["large"] = TUNING.SPIKE_DAMAGE * 1.5,
}

local LANG_MAP = {
	["english"] = {
		["NAME"] = "Beehave",
		["REC_DESC"] = "Realy Have Bee!",
		["DESC"] = "I can hear the noise",
	},
	["russian"] = {
		["NAME"] = "Улей",
		["REC_DESC"] = "Они на вашей стороне.",
		["DESC"] = "Я слышу этот звук.",
	},
	["korean"] = {
		["NAME"] = "벌주는 방망이",
		["REC_DESC"] = "정말 벌이 있어!",
		["DESC"] = "벌소리가 들려",
	},
	["chinese"] = {
		["NAME"] = "蜂语",
		["REC_DESC"] = "真的有蜜蜂！",
		["DESC"] = "我听到了嗡嗡声",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

TUNING.AIP_BEEHAVE_USES = USES_MAP[weapon_uses]
TUNING.AIP_BEEHAVE_DAMAGE =  DAMAGE_MAP[weapon_damage]

-- 资源
local assets =
{
	Asset("ATLAS", "images/inventoryimages/aip_beehave.xml"),
	Asset("ANIM", "anim/aip_beehave.zip"),
	Asset("ANIM", "anim/aip_beehave_swap.zip"),
}

local prefabs =
{
}

-- 文字描述
STRINGS.NAMES.AIP_BEEHAVE = LANG.NAME
STRINGS.RECIPE_DESC.AIP_BEEHAVE = LANG.REC_DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_BEEHAVE = LANG.DESC

-- 配方
local aip_beehave = Recipe("aip_beehave", {Ingredient("tentaclespike", 1),Ingredient("stinger", 10),Ingredient("nightmarefuel", 2)}, RECIPETABS.MAGIC, TECH.MAGIC_TWO)
aip_beehave.atlas = "images/inventoryimages/aip_beehave.xml"

-----------------------------------------------------------

local function onAttack(inst, owner, target)
	if inst.components.finiteuses:GetUses() % 5 == 0 then
		local x, y, z = owner.Transform:GetWorldPosition()
		local bee = SpawnPrefab("bee")
		bee.Transform:SetPosition(x, y, z)

		bee.AnimState:SetMultColour(0, 0, 0, 0.8)
		if bee.components.lootdropper then
			-- bee:RemoveComponent("lootdropper")
			bee.components.lootdropper.randomloot = nil
			bee.components.lootdropper.totalrandomweight = nil
		end
		if bee.components.combat then
			bee.components.combat:SetDefaultDamage(TUNING.BEE_DAMAGE * 0.5)
			bee.components.combat:SetTarget(target)
		end
		if bee.components.health then
			bee.components.health:SetMaxHealth(1)
		end

		bee:DoTaskInTime(10, function()
			if bee and not bee.components.health:IsDead() then
				bee.components.health:Kill()
			end
		end)
	end
end

local function onequip(inst, owner)
	owner.AnimState:OverrideSymbol("swap_object", "aip_beehave_swap", "aip_beehave_swap")
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
	
	inst.AnimState:SetBank("aip_beehave")
	inst.AnimState:SetBuild("aip_beehave")
	inst.AnimState:PlayAnimation("idle")

	inst:AddTag("show_spoilage")
	inst:AddTag("icebox_valid")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("finiteuses")
	inst.components.finiteuses:SetMaxUses(TUNING.AIP_BEEHAVE_USES)
	inst.components.finiteuses:SetUses(TUNING.AIP_BEEHAVE_USES)
	inst.components.finiteuses:SetOnFinished(inst.Remove)

	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(TUNING.AIP_BEEHAVE_DAMAGE)
	inst.components.weapon:SetOnAttack(onAttack)

	inst:AddComponent("inspectable")

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_beehave.xml"

	MakeHauntableLaunch(inst)

	inst:AddComponent("equippable")
	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)

	return inst
end

return Prefab( "aip_beehave", fn, assets) 
