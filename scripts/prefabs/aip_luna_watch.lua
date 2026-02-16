local language = aipGetModConfig("language")

local LANG_MAP = {
	english = {
		NAME = "Luna Watch",
		DESC = "A mysterious lucky blessing from the East",
	},
	chinese = {
		NAME = "月相怀表",
		DESC = "来自东方神秘的幸运祝福",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_LUNA_WATCH = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_LUNA_WATCH = LANG.DESC

local assets = {
    Asset("ANIM", "anim/aip_luna_watch.zip"),
	Asset("ATLAS", "images/inventoryimages/aip_luna_watch.xml"),
}

local function GetLuckFn(inst)
	if TheWorld and TheWorld.state.isfullmoon then
		return 6
	else
		return 0
	end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("aip_luna_watch")
    inst.AnimState:SetBuild("aip_luna_watch")
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryFloatable(inst, "med", 0.3, 1)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_luna_watch.xml"

	inst:AddComponent("luckitem")
	inst.components.luckitem:SetLuck(GetLuckFn)

	inst:ListenForEvent("ms_setmoonphase", function()
		inst:PushEvent("updateownerluck")
	end)

	inst:AddComponent("tradable")
	inst.components.tradable.goldvalue = 10

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("aip_luna_watch", fn, assets)
