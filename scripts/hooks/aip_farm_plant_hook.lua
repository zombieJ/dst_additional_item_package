local _G = GLOBAL
local PLANT_DEFS = _G.require("prefabs/farm_plant_defs").PLANT_DEFS

for plant_name, plant_data in pairs(PLANT_DEFS) do
    if not plant_data.is_randomseed then
        local oversized_prefab = plant_name.."_oversized"

        AddPrefabPostInit(oversized_prefab, function(inst)
            if not _G.TheWorld.ismastersim then
                return
            end

            inst:ListenForEvent("loot_prefab_spawned", function(inst, data)
                local loot = data.loot
                if loot ~= nil and loot.prefab == plant_data.seed then
                    
                end
            end)
        end)
    end
end
