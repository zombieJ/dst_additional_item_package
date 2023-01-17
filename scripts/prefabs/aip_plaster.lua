-- 配置
local additional_survival = aipGetModConfig("additional_survival")
if additional_survival ~= "open" then
	return nil
end

local survival_effect = aipGetModConfig("survival_effect")
local language = aipGetModConfig("language")

-- 默认参数
local HEAL_MAP = {
	["less"] = TUNING.HEALING_SMALL,
	["normal"] = TUNING.HEALING_MEDSMALL,
	["large"] = TUNING.HEALING_MED,
}

-- 语言
local LANG_MAP = {
	["english"] = {
		["NAME"] = "Plantash",
		["DESC"] = "Cure burns",
		["DESCRIBE"] = "The exclusive secret recipe of quack doctor",
	},
	["chinese"] = {
		["NAME"] = "草木灰",
		["DESC"] = "治疗烫伤的游方",
		["DESCRIBE"] = "江湖郎中的独家秘方",
	},
	["russian"] = {
		["NAME"] = "Зола растений",
		["DESC"] = "Лечит ожоги",
		["DESCRIBE"] = "Эксклюзивный секретный рецепт шарлатанского доктора",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

-- 资源
local assets =
{
	Asset("ANIM", "anim/aip_plaster.zip"),
	Asset("ATLAS", "images/inventoryimages/aip_plaster.xml"),
	Asset("IMAGE", "images/inventoryimages/aip_plaster.tex"),
}

-- 文字描述
STRINGS.NAMES.AIP_PLASTER = LANG.NAME
STRINGS.RECIPE_DESC.AIP_PLASTER = LANG.DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_PLASTER = LANG.DESCRIBE

-----------------------------------------------------------
local function onHeal(inst, target)
	local limit = TUNING.OVERHEAT_TEMP - 10
	if target.components.temperature ~= nil and target.components.temperature:GetCurrent() > limit then
		target.components.temperature:SetTemperature(limit)
	end
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)

	inst.AnimState:SetBank("aip_plaster")
	inst.AnimState:SetBuild("aip_plaster")
	inst.AnimState:PlayAnimation("idle")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("stackable")
	inst.components.stackable.maxsize = TUNING.STACK_SIZE_TINYITEM

	inst:AddComponent("inspectable")

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_plaster.xml"

	inst:AddComponent("healer")
	inst.components.healer:SetHealthAmount(HEAL_MAP[survival_effect])
	inst.components.healer.onhealfn = onHeal

	MakeHauntableLaunch(inst)

	return inst
end

return Prefab("aip_plaster", fn, assets) --    c_give"campfire"      c_give"aip_plaster"
