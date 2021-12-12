-- 武器关闭
local additional_weapon = aipGetModConfig("additional_weapon")

local weapon_damage = aipGetModConfig("weapon_damage")
local language = aipGetModConfig("language")

-- 默认参数
local USES_MAP = {
	less = 50,
	normal = 100,
	much = 150,
}
local DAMAGE_MAP = {
	less = TUNING.CANE_DAMAGE * 0.8,
	normal = TUNING.CANE_DAMAGE,
	large = TUNING.CANE_DAMAGE * 1.5,
}

local LANG_MAP = {
	english = {
		NAME = "Weak Holder",
		REC_DESC = "Create a shadow track",
		DESC = "Mixed with moon and shadow",
	},
	chinese = {
		NAME = "幻影之握",
		REC_DESC = "制作一条暗影轨道",
		DESC = "暗影与月光的奇艺融合",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

TUNING.AIP_TRACK_TOOLE_DAMAGE =  DAMAGE_MAP[weapon_damage]

-- 资源
local assets = {
	Asset("ATLAS", "images/inventoryimages/aip_track_tool.xml"),
	Asset("ANIM", "anim/aip_track_tool.zip"),
	Asset("ANIM", "anim/aip_track_tool_swap.zip"),
	Asset("ANIM", "anim/aip_glass_orbit_point.zip"),
}

local prefabs = {}

-- 文字描述
STRINGS.NAMES.AIP_TRACK_TOOL = LANG.NAME
STRINGS.RECIPE_DESC.AIP_TRACK_TOOL = LANG.REC_DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_TRACK_TOOL = LANG.DESC

--------------------------------- 装备 ---------------------------------
local function onequip(inst, owner)
	owner.AnimState:OverrideSymbol("swap_object", "aip_track_tool_swap", "aip_track_tool_swap")
	owner.SoundEmitter:PlaySound("dontstarve/wilson/equip_item_gold")
	owner.AnimState:Show("ARM_carry")
	owner.AnimState:Hide("ARM_normal")
end

local function onunequip(inst, owner)
	owner.AnimState:ClearOverrideSymbol("swap_object")
	owner.AnimState:Hide("ARM_carry")
	owner.AnimState:Show("ARM_normal")
end

--------------------------------- 部署 ---------------------------------
local function onDeploy(inst, pt, deployer)
    inst.components.aipc_track_creator:LineTo(pt, deployer)
end

--------------------------------- 实例 ---------------------------------

function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()
	
	MakeInventoryPhysics(inst)
	
	inst.AnimState:SetBank("aip_track_tool")
	inst.AnimState:SetBuild("aip_track_tool")
	inst.AnimState:PlayAnimation("idle")

	inst:AddTag("show_spoilage")
	inst:AddTag("icebox_valid")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("aipc_track_creator")

	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(TUNING.AIP_TRACK_TOOLE_DAMAGE)

	inst:AddComponent("inspectable")

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_track_tool.xml"

	MakeHauntableLaunch(inst)

	inst:AddComponent("equippable")
	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)

	return inst
end

return	Prefab("aip_track_tool", fn, assets)