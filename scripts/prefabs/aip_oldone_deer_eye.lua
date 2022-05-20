local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "lantern berry",
		DESC = "It's depends on the rock",
        DESC_FRUIT = "Terror but eatable",
	},
	chinese = {
		NAME = "菇茑",
		DESC = "它的生命力都来自于这个奇怪的石头",
        DESC_FRUIT = "吃下去一定不是什么好主意",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_OLDONE_DEER_EYE = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_DEER_EYE = LANG.DESC
STRINGS.NAMES.AIP_OLDONE_DEER_EYE_FRUIT = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_DEER_EYE_FRUIT = LANG.DESC_FRUIT

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_oldone_deer_eye.zip"),
	Asset("ATLAS", "images/inventoryimages/aip_oldone_deer_eye.xml"),
}

------------------------------------ 事件 ------------------------------------
local function onPick(inst, picker) -- 捡起掉理智
    if picker ~= nil and picker.components.sanity ~= nil then
		picker.components.sanity:DoDelta(-6)
	end
end

------------------------------------ 种植 ------------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst:AddTag("aip_oldone_deer_eye")

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("aip_oldone_deer_eye")
    inst.AnimState:SetBuild("aip_oldone_deer_eye")
    inst.AnimState:PlayAnimation("spawn")
    inst.AnimState:PushAnimation("idle", true)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.SoundEmitter:PlaySound("dontstarve/creatures/eyeplant/eye_emerge")

    inst:AddComponent("inspectable")

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot({"aip_oldone_deer_eye_fruit"})

    inst:AddComponent("pickable")
    inst.components.pickable.picksound = "dontstarve/wilson/pickup_plants"
    inst.components.pickable.onpickedfn = onPick
	inst.components.pickable.remove_when_picked = true
    inst.components.pickable.canbepicked = true
    inst.components.pickable.use_lootdropper_for_product = true

    MakeHauntableLaunch(inst)

    return inst
end

------------------------------------ 物品 ------------------------------------
local function onEaten(inst, eater) -- 吃下鹿眼可以短暂获得真实效果
    aipBufferPatch(inst, eater, "aip_see_eyes", 7)
end

local function foodFn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("aip_oldone_deer_eye")
    inst.AnimState:SetBuild("aip_oldone_deer_eye")
    inst.AnimState:PlayAnimation("item")

    MakeInventoryFloatable(inst, "med", 0.3, 1)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_oldone_deer_eye.xml"
    inst.components.inventoryitem.imagename = "aip_oldone_deer_eye"

	inst:AddComponent("edible")
    inst.components.edible.hungervalue = 5
    inst.components.edible.healthvalue = 1
    inst.components.edible.sanityvalue = -1
    inst.components.edible.foodtype = FOODTYPE.GOODIES
	inst.components.edible:SetOnEatenFn(onEaten)

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_MEDITEM

    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(TUNING.PERISH_FAST)
    inst.components.perishable:StartPerishing()
    inst.components.perishable.onperishreplacement = "spoiled_food"

    MakeHauntableLaunch(inst)

    return inst
end

return  Prefab("aip_oldone_deer_eye", fn, assets),
        Prefab("aip_oldone_deer_eye_fruit", foodFn, assets)
