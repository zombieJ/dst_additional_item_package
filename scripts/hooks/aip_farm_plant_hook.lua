local _G = GLOBAL
local PLANT_DEFS = _G.require("prefabs/farm_plant_defs").PLANT_DEFS

-- 有品质的物品只和同品质合堆，避免吃的时候品质被混掉。
local function patchQualityStackable(inst)
    if inst.components.stackable then
        inst.components.stackable.aipMergeType = function(this, other)
            local thisQ = this.components.aipc_quality ~= nil and this.components.aipc_quality:GetVal() or 1
            local otherQ = other.components.aipc_quality ~= nil and other.components.aipc_quality:GetVal() or 1
            return thisQ == otherQ
        end
    end
end

for plant_name, plant_data in pairs(PLANT_DEFS) do
    if not plant_data.is_randomseed then
        local seed_prefab = plant_data.seed
        local cooked_prefab = plant_name .. "_cooked"
        local oversized_prefab = plant_name .. "_oversized"
        local farm_plant_prefab = "farm_plant_" .. plant_name

        local prefabList = { seed_prefab, plant_name, cooked_prefab, oversized_prefab, farm_plant_prefab }

        for _, prefab in ipairs(prefabList) do
            AddPrefabPostInit(prefab, function(inst)
                inst:AddComponent("aipc_info_client")
                inst:AddComponent("aipc_quality")

                if not _G.TheWorld.ismastersim then
                    return
                end

                patchQualityStackable(inst)
            end)
        end

        -- 植物种植时继承种子品质
        AddPrefabPostInit(farm_plant_prefab, function(inst)
            inst:ListenForEvent("on_planted", function(inst, data)
                if data ~= nil and data.seed ~= nil and data.seed.components.aipc_quality then
                    local seedQ = data.seed.components.aipc_quality:GetVal()
                    inst.components.aipc_quality:SetVal(seedQ)
                end
            end)

            inst:ListenForEvent("loot_prefab_spawned", function(inst, data)
                local loot = data.loot
                if loot ~= nil and loot.components.aipc_quality then
                    local plantQ = inst.components.aipc_quality:GetVal()
                    loot.components.aipc_quality:SetVal(plantQ)
                end
            end)
        end)

        -- 种子合并要添加品质检查
        AddPrefabPostInit(seed_prefab, function(inst)
            inst:ListenForEvent("on_loot_dropped", function(inst, data)
                local dropper = data.dropper
                if dropper ~= nil and dropper.components.aipc_quality then
                    local dropperQ = dropper.components.aipc_quality:GetVal()
                    inst.components.aipc_quality:SetVal(dropperQ)
                end
            end)

        end)

        --  oversized_prefab 生成时，种子的质量 +1
        AddPrefabPostInit(oversized_prefab, function(inst)
            inst:ListenForEvent("loot_prefab_spawned", function(inst, data)
                local loot = data.loot
                if loot ~= nil and loot.prefab == plant_data.seed and loot.components.aipc_quality then
                    loot.components.aipc_quality:DoDelta(1)
                end
            end)
        end)
    end
end
