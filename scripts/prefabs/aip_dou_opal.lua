------------------------------------ 配置 ------------------------------------
-- 雕塑关闭
local additional_chesspieces = aipGetModConfig("additional_chesspieces")
if additional_chesspieces ~= "open" then
	return nil
end

local language = aipGetModConfig("language")

local LANG_MAP = {
	["english"] = {
		["NAME"] = "Mysterious Opal",
		["REC_DESC"] = "Alien from the sky",
		["DESC"] = "Decorate your Walking Cane",
	},
	["chinese"] = {
		["NAME"] = "神秘猫眼石",
		["REC_DESC"] = "天外来物",
		["DESC"] = "它似乎可以嵌入步行手杖",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

-- 资源
local assets =
{
	Asset("ATLAS", "images/inventoryimages/aip_fish_sword.xml"),
	Asset("ANIM", "anim/aip_fish_sword.zip"),
	Asset("ANIM", "anim/aip_fish_sword_swap.zip"),
}

local prefabs =
{
	"houndfire",
}

-- 文字描述
STRINGS.NAMES.AIP_DOU_OPAL = LANG.NAME
STRINGS.RECIPE_DESC.AIP_DOU_OPAL = LANG.REC_DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_DOU_OPAL = LANG.DESC

-----------------------------------------------------------
local function onLightning(inst)
	-- 掉落火焰
	for i = 1, 3 do
		inst.components.lootdropper:SpawnLootPrefab('houndfire')
	end
end

function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()
	
	MakeInventoryPhysics(inst)

	inst:AddTag("lightningrod")
	
	inst.AnimState:SetBank("aip_fish_sword")
	inst.AnimState:SetBuild("aip_fish_sword")
	inst.AnimState:PlayAnimation("idle")

	MakeInventoryFloatable(inst, "med", 0.1, 0.75)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	-- 如果被雷击
	inst:ListenForEvent("lightningstrike", onLightning)

	inst:AddComponent("inspectable")

	inst:AddComponent("lootdropper")

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_fish_sword.xml"

	MakeSmallBurnable(inst, TUNING.LARGE_BURNTIME)
	MakeSmallPropagator(inst)

	MakeHauntableLaunchAndIgnite(inst)

	return inst
end

return Prefab( "aip_dou_opal", fn, assets) 
