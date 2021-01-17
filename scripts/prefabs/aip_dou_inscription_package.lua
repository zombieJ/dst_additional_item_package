------------------------------------ 配置 ------------------------------------
-- 雕塑关闭
local additional_chesspieces = aipGetModConfig("additional_chesspieces")
if additional_chesspieces ~= "open" then
	return nil
end

require "prefabutil"

local language = aipGetModConfig("language")

local LANG_MAP = {
	["english"] = {
		["NAME"] = "Inscription Package",
		["REC_DESC"] = "Hold your inscriptions!",
		["DESC"] = "Inscriptions' home",
	},
	["chinese"] = {
		["NAME"] = "符文袋",
		["REC_DESC"] = "装下你的符文！",
		["DESC"] = "符文的好去处",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

-- 文字描述
STRINGS.NAMES.AIP_DOU_INSCRIPTION_PACKAGE = LANG.NAME
STRINGS.RECIPE_DESC.AIP_DOU_INSCRIPTION_PACKAGE = LANG.REC_DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_DOU_INSCRIPTION_PACKAGE = LANG.DESC

------------------------------------ 代码 ------------------------------------
local assets =
{
	Asset("ATLAS", "images/inventoryimages/aip_dou_inscription_package.xml"),
	Asset("ANIM", "anim/aip_dou_inscription_package.zip"),
}

-- 配方
local aip_dou_inscription_package = Recipe(
	"aip_dou_inscription_package",
	{Ingredient("aip_shadow_package", 1, "images/inventoryimages/aip_shadow_package.xml"), Ingredient("lightbulb", 2)},
	RECIPETABS.MAGIC, TECH.MAGIC_TWO
)
aip_dou_inscription_package.atlas = "images/inventoryimages/aip_dou_inscription_package.xml"

local function onDrop(inst)
    if inst.components.container ~= nil then
        inst.components.container:Close()
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("aip_dou_inscription_package")
    inst.AnimState:SetBuild("aip_dou_inscription_package")
    inst.AnimState:PlayAnimation("idle")

    inst.MiniMapEntity:SetIcon("krampus_sack.png")

    MakeInventoryFloatable(inst, "small", 0.1, 0.85)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_dou_inscription_package.xml"
    inst.components.inventoryitem:SetOnDroppedFn(onDrop)

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("aip_dou_inscription_package")

    MakeHauntableLaunchAndDropFirstItem(inst)

    inst.OnRemoveEntity = onDrop

    return inst
end

return Prefab("aip_dou_inscription_package", fn, assets)

--[[



							c_give"aip_dou_inscription_package"



]]