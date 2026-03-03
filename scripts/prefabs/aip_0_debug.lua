local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Debug",
		DESC = "Not good",
	},
	chinese = {
		NAME = "测试",
		DESC = "不好吃",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_0_DEBUG = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_0_DEBUG = LANG.DESC

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_salt_fish.zip"),
	Asset("ATLAS", "images/inventoryimages/aip_salt_fish.xml"),
}

-- 把玩家移动走
local function oneaten(inst, eater)
	if eater ~= nil and eater.components.locomotor ~= nil then
		eater.Physics:Teleport(1900, 0, 1900)
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
	inst.components.inventoryitem.imagename = "aip_salt_fish"

	-- 食物
	inst:AddComponent("edible")
	inst.components.edible.foodtype = FOODTYPE.MEAT
	inst.components.edible:SetOnEatenFn(oneaten)

    return inst
end

return Prefab("aip_0_debug", fn, assets)
