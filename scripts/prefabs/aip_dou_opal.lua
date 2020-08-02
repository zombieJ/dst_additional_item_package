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
	Asset("ATLAS", "images/inventoryimages/aip_dou_opal.xml"),
	Asset("ANIM", "anim/aip_dou_opal.zip"),
}

local prefabs =
{
	"livinglog",
}

-- 文字描述
STRINGS.NAMES.AIP_DOU_OPAL = LANG.NAME
STRINGS.RECIPE_DESC.AIP_DOU_OPAL = LANG.REC_DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_DOU_OPAL = LANG.DESC

-----------------------------------------------------------
local function onLightning(inst)
	-- 点燃掉落物
	for i = 1, 3 do
		local item = inst.components.lootdropper:SpawnLootPrefab('livinglog')
		if item.components.burnable ~= nil then
			item.components.burnable:Ignite()
		end
	end
end

local function canActOn(inst, target, doer)
	return target.prefab == "cane"
end

function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()
	
	MakeInventoryPhysics(inst)

	inst:AddTag("lightningrod")
	
	inst.AnimState:SetBank("aip_dou_opal")
	inst.AnimState:SetBuild("aip_dou_opal")
	inst.AnimState:PlayAnimation("idle", true)

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
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_dou_opal.xml"

	inst:AddComponent("aipc_action")
	inst.components.aipc_action.canActOn = canActOn

	MakeSmallBurnable(inst, TUNING.LARGE_BURNTIME)
	MakeSmallPropagator(inst)

	MakeHauntableLaunchAndIgnite(inst)

	return inst
end

return Prefab("aip_dou_opal", fn, assets)
