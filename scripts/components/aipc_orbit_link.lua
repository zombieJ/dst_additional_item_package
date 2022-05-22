-- 创建路径列表
local function onLinkRefresh(inst)
	if inst.components.aipc_orbit_link ~= nil then
		inst.components.aipc_orbit_link:SyncPath()
	end
end

-- 双端通用组件
local Linker = Class(function(self, inst)
	self.inst = inst
	self.startP = nil
	self.endP = nil

	-- 轨道贴图列表
	self.orbits = {}

	self.pointStr = net_string(inst.GUID, "aipc_orbit_link.pointStr", "aipc_orbit_link.pointStr_dirty")

	if not TheWorld.ismastersim then
        inst:ListenForEvent("aipc_orbit_link.pointStr_dirty", onLinkRefresh)
    end
end)

function Linker:Link(startP, endP)
	self.startP = startP
	self.endP = endP

	local startPt = startP:GetPosition()
	local endPt = endP:GetPosition()

	local str = aipCommonStr(false, "|", startPt.x, startPt.z, endPt.x, endPt.z)
	self.pointStr:set(str)

	if TheWorld.ismastersim then
		onLinkRefresh(self.inst)
	end
end

-- 清除轨道
function Linker:Unlink()
	for i, v in ipairs(self.orbits) do
		if v:IsValid() then
			v:Remove()
		end
	end

	self.orbits = {}
end

-- 创造路径贴图
function Linker:SyncPath()
	if TheNet:IsDedicated() then  -- 专服不需要轨道贴图
		return
	end

	-- 先清除
	self:Unlink()

	-- 根据网络记录复原轨道所需信息
	local list = aipSplit(self.pointStr:value(), "|")
	local startPt = Vector3(tonumber(list[1]), 0, tonumber(list[2]))
	local endPt = Vector3(tonumber(list[3]), 0, tonumber(list[4]))

	local ORBIT_DIST = 0.6
	local dist = aipDist(startPt, endPt)
	local count = math.ceil(dist / ORBIT_DIST)


	-- 绘制轨道
	for i = 1, count - 1 do
		local x = startPt.x + (endPt.x - startPt.x) * i / count
		local z = startPt.z + (endPt.z - startPt.z) * i / count

		local orbit = aipSpawnPrefab(nil, "aip_glass_orbit", x, 0, z)
		orbit:ForceFacePoint(endPt)

		table.insert(self.orbits, orbit)
	end
end

function Linker:Includes(target)
	return self.startP == target or self.endP == target
end

-- 获取另一个端点，如果都没有，则随便返回一个
function Linker:GetAnother(target)
	return self.startP == target and self.endP or self.startP
end

function Linker:OnRemoveEntity()
	self:Unlink()
end

function Linker:OnEntitySleep()
	self:Unlink()
end

function Linker:OnEntityWake()
	self:SyncPath()
end

Linker.OnRemoveFromEntity = Linker.OnRemoveEntity

-------------------------------------------------------------
function Linker:OnSave()
	if self.startP and self.endP then
		local startPt = self.startP:GetPosition()
		local endPt = self.endP:GetPosition()

		return {
			startX = startPt.x,
			startZ = startPt.z,
			endX = endPt.x,
			endZ = endPt.z,
		}
	elseif -- 兜底
		self._startX ~= nil and self._startZ ~= nil and
		self._endX ~= nil and self._endZ ~= nil
	then
		return {
			startX = self._startX,
			startZ = self._startZ,
			endX = self._endX,
			endZ = self._endZ,
		}
	end
end

function Linker:OnLoad(data)
	if data then
		local startX = data.startX
		local startZ = data.startZ
		local endX = data.endX
		local endZ = data.endZ

		self._startX = startX
		self._startZ = startZ
		self._endX = endX
		self._endZ = endZ

		-- 等物体载入完成后，再链接起来
		self.inst:DoTaskInTime(1, function()
			local startP = TheSim:FindEntities(startX, 0, startZ, 0.1, {"aip_glass_orbit_point"})[1]
			local endP = TheSim:FindEntities(endX, 0, endZ, 0.1, {"aip_glass_orbit_point"})[1]
	
			if startP and endP then
				self:Link(startP, endP)
			else
				self.inst:Remove()
			end
		end)
	end
end

return Linker