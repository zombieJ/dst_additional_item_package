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

	self.pointStr = net_string(inst.GUID, "aipc_orbit_link.pointStr", "aipc_orbit_link.pointStr_dirty")

	if not TheNet:IsDedicated() then
        inst:ListenForEvent("aipc_orbit_link.pointStr_dirty", onLinkRefresh)
    end
end)

function Linker:Link(startP, endP)
	self.startP = startP
	self.endP = endP

	local str = aipCommonStr(false, "|", startP.x, startP.z, endP.x, endP.z)
	self.pointStr:set(str)
end

function Linker:SyncPath()
	local list = aipSplit(self.pointStr:value(), "|")
	local startPt = Vector3(tonumber(list[1]), 0, tonumber(list[2]))
	local endPt = Vector3(tonumber(list[3]), 0, tonumber(list[4]))

	aipTypePrint("aipc_orbit_link", "startPt:", startPt, "endPt:", endPt)
end

return Linker