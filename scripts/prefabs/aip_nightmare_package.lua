local RECHARGE_USES = 10

local language = aipGetModConfig("language")

local assets = {
    Asset("ANIM", "anim/aip_nightmare_package.zip"),
	Asset("ATLAS", "images/inventoryimages/aip_nightmare_package.xml"),
}

-- 文字描述
local LANG_MAP = {
    english = {
        NAME = "Nightmare Soul",
        DESC = "Looks 'non-toxic'",
    },
   chinese = {
        NAME = "噩梦之灵",
        DESC = "看起来是“无毒的”",
    },
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_NIGHTMARE_PACKAGE = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_NIGHTMARE_PACKAGE = LANG.DESC

--------------------------------------- 事件 ---------------------------------------
local function onEaten(inst, eater)
	-- 吃下后会丢失全部理智，并变成噩梦燃料掉落
	if eater ~= nil and eater.components.sanity ~= nil then
		local sanity = eater.components.sanity.current
		local cnt = math.ceil(sanity / 15)

		for i = 1, cnt do
			inst.components.lootdropper:SpawnLootPrefab("nightmarefuel")
		end

		eater.components.sanity:DoDelta(-sanity)
	end
end

local function recharge(inst)
    if inst.components.finiteuses ~= nil then
        inst.components.finiteuses:Use(-1)

        -- 不能过载
        if inst.components.finiteuses:GetPercent() > 1 then
            inst.components.finiteuses:SetPercent(1)
        end
    end
end

--------------------------------------- 实例 ---------------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("aip_nightmare_package")
    inst.AnimState:SetBuild("aip_nightmare_package")
    inst.AnimState:PlayAnimation("idle", true)
    inst.AnimState:SetMultColour(1, 1, 1, 0.5)
    inst.AnimState:UsePointFiltering(true)

    MakeInventoryFloatable(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

	-- 相当于 10 个噩梦燃料的量
    inst:AddComponent("fuel")
    inst.components.fuel.fueltype = FUELTYPE.NIGHTMARE
    inst.components.fuel.fuelvalue = TUNING.LARGE_FUEL * 10

	-- 有限的使用次数
	inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(RECHARGE_USES)
    inst.components.finiteuses:SetUses(RECHARGE_USES)
    inst.components.finiteuses:SetOnFinished(inst.Remove)

	-- 减少理智
	inst:AddComponent("sanityaura")
	inst.components.sanityaura.aura = -TUNING.SANITYAURA_SMALL
	inst.components.sanityaura.max_distsq = 0.1 -- 只有拿着的人会受到效果

	-- 可以吃下去
	inst:AddComponent("edible")
    inst.components.edible.hungervalue = 0
    inst.components.edible.healthvalue = 0
    inst.components.edible.foodtype = FOODTYPE.GOODIES
	inst.components.edible:SetOnEatenFn(onEaten)

	-- 掉落物
	inst:AddComponent("lootdropper")

    inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_nightmare_package.xml"

	MakeHauntableLaunch(inst)

    inst:WatchWorldState("isnight", recharge)

    return inst
end

return Prefab("aip_nightmare_package", fn, assets)