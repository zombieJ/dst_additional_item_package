local dev_mode = aipGetModConfig("dev_mode") == "enabled"

local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
        DESC_SUCCESS = "Collected, no more",

		NAME_GRASS = "Grass Liver",
		DESC_GRASS = "Pointless collection challenges and no prizes",
        NAME_LOG = "Log Liver",
		DESC_LOG = "Pointless collection challenges and no prizes",
        NAME_STONE = "Stone Liver",
		DESC_STONE = "Pointless collection challenges and no prizes",
        NAME_GOLD = "Gold Liver",
		DESC_GOLD = "Pointless collection challenges and no prizes",
        NAME_GEM = "Gem Liver",
		DESC_GEM = "Pointless collection challenges and no prizes",
        NAME_OPALPRECIOUS = "Opalprecious Liver",
		DESC_OPALPRECIOUS = "Seems like Opalprecious but not is",
	},
	chinese = {
        DESC_SUCCESS = "集齐了，没然后了",

		NAME_GRASS = "草肝",
		DESC_GRASS = "即便采集干草，也不会有任何奖品",
        NAME_LOG = "木肝",
		DESC_LOG = "砍树会掉耐久，但是也没啥用",
        NAME_STONE = "石肝",
		DESC_STONE = "镐没什么好玩的，更没什么奖励",
        NAME_GOLD = "金肝",
		DESC_GOLD = "金子制品很不错，但是它本身不过毫无用处",
        NAME_GEM = "宝石肝",
		DESC_GEM = "制作的宝石很有用，但是这个没用",
        NAME_OPALPRECIOUS = "虹光肝",
		DESC_OPALPRECIOUS = "长得像虹光宝石，不过也仅仅是长得像而已",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_LIVER_SUCCESS = LANG.DESC_SUCCESS

----------------------------------- 数据 -----------------------------------
TUNING.AIP_LIVER_USES = dev_mode and 2 or 100

local function useOne(inst)
    if inst.components.finiteuses ~= nil and inst.components.finiteuses:GetPercent() > 0 then
        inst.components.finiteuses:Use(1)
    end
end

local data = {}

local function getRndLiver()
    local names = aipTableKeys(data)
    local name = aipRandomEnt(names)

    return "aip_liver_"..name
end

data = {
    grass = {
        onEquip = function(inst, owner)
            inst._aip_work_fn = function(owner, data)
                if
                    data ~= nil and data.loot ~= nil and
                    aipInTable({ "cutgrass", "aip_veggie_wheat" }, data.loot.prefab)
                then
                    useOne(inst)
                end
            end

            owner:ListenForEvent("picksomething", inst._aip_work_fn)
        end,
        onUnequip = function(inst, owner)
            owner:RemoveEventCallback("picksomething", inst._aip_work_fn)
        end,
    },
    log = {
        onEquip = function(inst, owner)
            inst._aip_work_fn = function(owner, data)
                if data ~= nil and data.action == ACTIONS.CHOP then
                    useOne(inst)
                end
            end

            owner:ListenForEvent("finishedwork", inst._aip_work_fn)
        end,
        onUnequip = function(inst, owner)
            owner:RemoveEventCallback("finishedwork", inst._aip_work_fn)
        end,
    },
    stone = {
        onEquip = function(inst, owner)
            inst._aip_work_fn = function(owner, data)
                if data ~= nil and data.action == ACTIONS.MINE then
                    useOne(inst)
                end
            end

            owner:ListenForEvent("finishedwork", inst._aip_work_fn)
        end,
        onUnequip = function(inst, owner)
            owner:RemoveEventCallback("finishedwork", inst._aip_work_fn)
        end,
    },
    gold = {
        onEquip = function(inst, owner)
            inst._aip_work_fn = function(owner, data)
                if data ~= nil and data.recipe ~= nil and data.recipe.ingredients ~= nil then
                    -- 看看里面有没有金子
                    local hasGold = false
                    for i, ingredient in ipairs(data.recipe.ingredients) do
                        if ingredient.type == "goldnugget" then
                            hasGold = true
                        end
                    end

                    if hasGold then
                        useOne(inst)
                    end
                end
            end

            owner:ListenForEvent("makerecipe", inst._aip_work_fn)
        end,
        onUnequip = function(inst, owner)
            owner:RemoveEventCallback("makerecipe", inst._aip_work_fn)
        end,
    },
    gem = {
        onEquip = function(inst, owner)
            inst._aip_work_fn = function(owner, data)
                if
                    data ~= nil and data.recipe ~= nil and
                    aipInTable({ "redgem", "bluegem", "yellowgem", "orangegem", "purplegem", "greengem", "opalpreciousgem" }, data.recipe.name)
                then
                    useOne(inst)
                end
            end

            owner:ListenForEvent("makerecipe", inst._aip_work_fn)
        end,
        onUnequip = function(inst, owner)
            owner:RemoveEventCallback("makerecipe", inst._aip_work_fn)
        end,
    },
    opalprecious = {
        finiteuses = false,

        postFn = function(inst)
            inst:AddComponent("edible")
            inst.components.edible.healthvalue = 999
            inst.components.edible.hungervalue = 999
            inst.components.edible.sanityvalue = 999

            inst.components.edible:SetOnEatenFn(function(inst, eater)
                aipFlingItem(
                    aipSpawnPrefab(eater, getRndLiver())
                )
            end)
        end
    },
}

----------------------------------- 方法 -----------------------------------
local function getDesc(inst)
    if inst.components.finiteuses ~= nil and inst.components.finiteuses:GetPercent() == 0 then
        return STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_LIVER_SUCCESS
    end
end

----------------------------------- 实例 -----------------------------------
local function commonFn(name, key, info)
    return function()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)

        inst.AnimState:SetBank("aip_liver")
        inst.AnimState:SetBuild("aip_liver")
        inst.AnimState:PlayAnimation(key)

        MakeInventoryFloatable(inst, "med", 0.3, 1)

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("inspectable")
        inst.components.inspectable.descriptionfn = getDesc

        if info.onEquip ~= nil or info.onUnequip ~= nil then
            inst:AddComponent("equippable")
            inst.components.equippable.equipslot = EQUIPSLOTS.BODY
            inst.components.equippable:SetOnEquip(info.onEquip)
            inst.components.equippable:SetOnUnequip(info.onUnequip)
        end

        if info.postFn ~= nil then
            info.postFn(inst)
        end

        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.atlasname = "images/inventoryimages/"..name..".xml"

        inst:AddComponent("tradable")
        inst.components.tradable.goldvalue = 1

        MakeHauntableLaunch(inst)

        if info.finiteuses ~= false then
            inst:AddComponent("finiteuses")
            inst.components.finiteuses:SetMaxUses(TUNING.AIP_LIVER_USES)
            inst.components.finiteuses:SetUses(TUNING.AIP_LIVER_USES)
        end

        return inst
    end
end

----------------------------------- 替换 -----------------------------------
local function liverFn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:DoTaskInTime(0.01, function()
        aipReplacePrefab(inst, getRndLiver())
    end)

    return inst
end

----------------------------------- 遍历 -----------------------------------
local prefabs = {
    Prefab("aip_liver", liverFn, {})
}

for key, info in pairs(data) do
    local name = "aip_liver_"..key

    -- 语言
    local upName = string.upper(name)
    STRINGS.NAMES[upName] = LANG["NAME_"..string.upper(key)]
    STRINGS.CHARACTERS.GENERIC.DESCRIBE[upName] = LANG["DESC_"..string.upper(key)]

    local assets = {
        Asset("ANIM", "anim/aip_liver.zip"),
        Asset("ATLAS", "images/inventoryimages/"..name..".xml"),
    }

    local fn = commonFn(name, key, info)

    table.insert(prefabs, Prefab(name, fn, assets))
end

return unpack(prefabs)
