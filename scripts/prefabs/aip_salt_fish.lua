local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Salt Fish",
		DESC = "It's smelly",
	},
	chinese = {
		NAME = "盐渍鱼",
		DESC = "有股奇怪的味道",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_SALT_FISH = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_SALT_FISH = LANG.DESC

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_salt_fish.zip"),
	Asset("ATLAS", "images/inventoryimages/aip_salt_fish.xml"),
}

-- 吃下提供一点谜团因子
local function oneaten(inst, eater)
	if eater ~= nil and eater.components.aipc_oldone ~= nil then
		eater.components.aipc_oldone:DoDelta()
	end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("aip_salt_fish")
    inst.AnimState:SetBuild("aip_salt_fish")
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryFloatable(inst, "med", 0.3, 1)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_salt_fish.xml"

	-- 食物
	inst:AddComponent("edible")
	inst.components.edible.foodtype = FOODTYPE.MEAT
	inst.components.edible.healthvalue = 25
	inst.components.edible.hungervalue = 25
	inst.components.edible.sanityvalue = -5
	inst.components.edible:SetOnEatenFn(oneaten)

	inst:AddComponent("stackable")
	inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM
	
	inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(TUNING.PERISH_ONE_DAY)
    inst.components.perishable:StartPerishing()
	inst.components.perishable.onperishreplacement = "spoiled_fish_small"

	inst:AddComponent("tradable")
	inst.components.tradable.goldvalue = 1

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("aip_salt_fish", fn, assets)
