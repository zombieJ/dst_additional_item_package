local foldername = KnownModIndex:GetModActualName(TUNING.ZOMBIEJ_ADDTIONAL_PACKAGE)

-- 配置
local dress_uses = aipGetModConfig("dress_uses")
local language = aipGetModConfig("language")

-- 默认参数
local PERISH_MAP = {
	["less"] = 0.5,
	["normal"] = 1,
	["much"] = 2,
}

local LANG_MAP = {
	["english"] = {
		["NAME"] = "Horse Head",
		["REC_DESC"] = "It makes you faster",
		["DESC"] = "I have 4 legs",
	},
	["russian"] = {
		["NAME"] = "Голова Лошади",
		["REC_DESC"] = "Это сделает тебя быстрее",
		["DESC"] = "Теперь у меня 4 ноги.",
	},
	["chinese"] = {
		["NAME"] = "马头",
		["REC_DESC"] = "让你跑的更快",
		["DESC"] = "我感觉长了4条腿",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

TUNING.AIP_HORSE_HEAD_FUEL = TUNING.YELLOWAMULET_FUEL * PERISH_MAP[dress_uses]

-- 文字描述
STRINGS.NAMES.AIP_HORSE_HEAD = LANG.NAME
STRINGS.RECIPE_DESC.AIP_HORSE_HEAD = LANG.REC_DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_HORSE_HEAD = LANG.DESC

local tempalte = require("prefabs/aip_dress_template")
return tempalte("aip_horse_head", {
	hideHead = true,
	walkspeedmult = TUNING.CANE_SPEED_MULT,
	fueled = {
		level = TUNING.AIP_HORSE_HEAD_FUEL,
	},
	waterproofer = true,
})

-----------------------------------------------------------
--[[local function onequip(inst, owner)
	owner.AnimState:OverrideSymbol("swap_hat", "aip_horse_head", "swap_hat")
	owner.AnimState:Show("HAT")
	owner.AnimState:Show("HAIR_HAT")
	owner.AnimState:Hide("HAIR_NOHAT")
	owner.AnimState:Hide("HAIR")

	if owner:HasTag("player") then
		owner.AnimState:Hide("HEAD")
		-- owner.AnimState:Show("HEAD_HAT")
	end

	if inst.components.fueled ~= nil then
		inst.components.fueled:StartConsuming()
	end
end

local function onunequip(inst, owner)
	owner.AnimState:ClearOverrideSymbol("swap_hat")
	owner.AnimState:Hide("HAT")
	owner.AnimState:Hide("HAIR_HAT")
	owner.AnimState:Show("HAIR_NOHAT")
	owner.AnimState:Show("HAIR")

	if owner:HasTag("player") then
		owner.AnimState:Show("HEAD")
		-- owner.AnimState:Hide("HEAD_HAT")
	end

	if inst.components.fueled ~= nil then
		inst.components.fueled:StopConsuming()
	end
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)

	inst.AnimState:SetBank("aip_horse_head")
	inst.AnimState:SetBuild("aip_horse_head")
	inst.AnimState:PlayAnimation("anim")

	inst:AddTag("hat")
	inst:AddTag("waterproofer")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_horse_head.xml"

	inst:AddComponent("inspectable")

	inst:AddComponent("tradable")

	inst:AddComponent("equippable")
	inst.components.equippable.equipslot = EQUIPSLOTS.HEAD
	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)
	inst.components.equippable.walkspeedmult = TUNING.CANE_SPEED_MULT

	inst:AddComponent("fueled")
	inst.components.fueled.fueltype = FUELTYPE.USAGE
	inst.components.fueled:InitializeFuelLevel(TUNING.AIP_HORSE_HEAD_FUEL)
	inst.components.fueled:SetDepletedFn(inst.Remove)

	MakeHauntableLaunch(inst)

	inst:AddComponent("waterproofer")
	inst.components.waterproofer:SetEffectiveness(TUNING.WATERPROOFNESS_SMALL)

	return inst
end

return Prefab("aip_horse_head", fn, assets, prefabs)]]