-- 寻找附近的标记点
local function findNearByPoint(pt)
  local ents = TheSim:FindEntities(pt.x, 0, pt.z, 1, { "aip_glass_orbit_point" })
  return ents[1]
end

-- 轨道制造者
local Creator = Class(function(self, inst)
    self.inst = inst
end)

function Creator:LineTo(targetPos, creator)
  local startPos = creator:GetPosition()

  -- 起始点：如果附近有点就不创建
  local startP = findNearByPoint(startPos)
  if startP == nil then
    startP = aipSpawnPrefab(creator, "aip_glass_orbit_point")
  end

  -- 目的地：如果附近有点就不创建
  local endP = findNearByPoint(targetPos)
  if endP == nil then
    endP = aipSpawnPrefab(creator, "aip_glass_orbit_point")
  end
end

return Creator
