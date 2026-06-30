local _G = GLOBAL
local PLANT_DEFS = _G.require("prefabs/farm_plant_defs").PLANT_DEFS

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

        -- 掉落种子时继承来源品质
        AddPrefabPostInit(seed_prefab, function(inst)
            inst:ListenForEvent("on_loot_dropped", function(inst, data)
                local dropper = data.dropper
                if dropper ~= nil and dropper.components.aipc_quality then
                    local dropperQ = dropper.components.aipc_quality:GetVal()
                    inst.components.aipc_quality:SetVal(dropperQ)
                end
            end)

        end)

        -- Oversized crops keep produce quality, while seeds improve by one level.
        AddPrefabPostInit(oversized_prefab, function(inst)
            inst:ListenForEvent("loot_prefab_spawned", function(inst, data)
                local loot = data.loot
                if loot ~= nil and loot.components.aipc_quality then
                    local dropperQ = inst.components.aipc_quality:GetVal()
                    if loot.prefab == plant_data.seed then
                        loot.components.aipc_quality:SetVal(dropperQ + 1)
                    elseif loot.prefab == plant_name then
                        loot.components.aipc_quality:SetVal(dropperQ)
                    end
                end
            end)
        end)
    end
end
