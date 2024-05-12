-- 废弃了，用 aip_space_hook

local _G = GLOBAL

local dev_mode = _G.aipGetModConfig("dev_mode") == "enabled"

if not dev_mode then
	return
end

-- IMPASSABLE = 1                   不可过边界（深水）
-- GRASS = 6,                       草地
-- FOREST = 7,                      森林
-- OCEAN_COASTAL = 201              海洋
-- OCEAN_COASTAL_SHORE = 202        海岸线
-- INVALID = 255                    无效（黑色的空间）


-- local aipHouses = {}

local RANGE = 1900

-- 是否在特殊空间里
local function inPlace(x, z, offset)
    offset = offset or 50
    return x >= RANGE - offset and x <= RANGE + offset and
            z >= RANGE - offset and z <= RANGE + offset
end

AddPrefabPostInit("world", function(inst)
    local map = _G.getmetatable(inst.Map).__index
    if map then
        local old_IsAboveGroundAtPoint = map.IsAboveGroundAtPoint
        map.IsAboveGroundAtPoint = function(self, x, y, z, ...)
            if inPlace(x, z) then
                -- for k, v in pairs(aipHouses) do
                --     if v[3] ~= nil then
                --         if z >= v[2] - 6.5 and z <= v[2] + 6.5 and x >= v[1] -
                --             5.5 and x <= v[1] + 5 then
                --             return true
                --         end
                --     else
                --         if v and z >= v[2] - 12 and z <= v[2] + 12 and x >= v[1] -
                --             8 and x <= v[1] + 8 then
                --             if TheSim:WorldPointInPoly(x, z, {
                --                 {v[1] - 6.2, v[2] + 10},
                --                 {v[1] - 6.2, v[2] - 10.6},
                --                 {v[1] + 7.8, v[2] - 12}, {v[1] + 7.8, v[2] + 12}
                --             }) then return true end
                --         end
                --     end
                -- end
                return true
            end
            return old_IsAboveGroundAtPoint(self, x, y, z, ...)
        end

        local old_IsVisualGroundAtPoint = map.IsVisualGroundAtPoint
        map.IsVisualGroundAtPoint = function(self, x, y, z, ...)
            if inPlace(x, z) then
                -- for k, v in pairs(aipHouses) do
                --     if v[3] ~= nil then
                --         if z >= v[2] - 6.5 and z <= v[2] + 6.5 and x >= v[1] -
                --             5.5 and x <= v[1] + 5 then
                --             return true
                --         end
                --     else
                --         if v and z >= v[2] - 12 and z <= v[2] + 12 and x >= v[1] -
                --             8 and x <= v[1] + 8 then
                --             if TheSim:WorldPointInPoly(x, z, {
                --                 {v[1] - 6.2, v[2] + 10},
                --                 {v[1] - 6.2, v[2] - 10.6},
                --                 {v[1] + 7.8, v[2] - 12}, {v[1] + 7.8, v[2] + 12}
                --             }) then return true end
                --         end
                --     end
                -- end
                return true
            end
            return old_IsVisualGroundAtPoint(self, x, y, z, ...)
        end

        local old_GetTileCenterPoint = map.GetTileCenterPoint
        map.GetTileCenterPoint = function(self, x, y, z)
            if inPlace(x, z, 0) then
                return math.floor(x / 4) * 4 + 2, 0, math.floor(z / 4) * 4 + 2
            end
            if z then
                return old_GetTileCenterPoint(self, x, y, z)
            else
                return old_GetTileCenterPoint(self, x, y)
            end
        end
    end
end)
