local _G = GLOBAL
local PLANT_DEFS = _G.require("prefabs/farm_plant_defs").PLANT_DEFS

for plant_name, plant_data in pairs(PLANT_DEFS) do
    if not plant_data.is_randomseed then
        local seed_prefab = plant_data.seed
        local oversized_prefab = plant_name .. "_oversized"

        local prefabList = { seed_prefab, plant_name, oversized_prefab }

        for _, prefab in ipairs(prefabList) do
            AddPrefabPostInit(prefab, function(inst)
                inst:AddComponent("aipc_info_client")
                inst:AddComponent("aipc_quality")

                if not _G.TheWorld.ismastersim then
                    return
                end
            end)
        end

        -- AddPrefabPostInit(oversized_prefab, function(inst)
        --     inst:ListenForEvent("loot_prefab_spawned", function(inst, data)
        --         local loot = data.loot
        --         if loot ~= nil and loot.prefab == plant_data.seed then

        --         end
        --     end)
        -- end)
    end
end
