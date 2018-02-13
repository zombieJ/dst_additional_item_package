local foldername = KnownModIndex:GetModActualName(TUNING.ZOMBIEJ_ADDTIONAL_PACKAGE)

local Empty = Class(function()
end)

-- 提示框提升
local tooltip_enhance = aipGetModConfig("tooltip_enhance")
if tooltip_enhance ~= "open" then
	return Empty
end

------------------------------------------------------------------------------------------
local function OnNilValue(inst)
	local component = inst.components.aipc_info_client
	if not component then
		return
	end

	local nilKey = component.netNil:value()
	component.values[nilKey] = nil
	component.valuesInited[nilKey] = true
end

-- 这个组件是用于服务端客户端通讯之使用，可以接受任意信息作为同步通讯
local InfoClient = Class(function(self, inst)
	self.inst = inst

	self.networks = {}
	self.events = {}
	self.values = {}
	self.valuesInited = {} -- 用于标记是否已经获得值，如果没有则初始化一下

	-- Check for nil value
	self.netNil = net_string(inst.GUID, "aipc_info_nil", "aipc_info_nil")
	self.inst:ListenForEvent("aipc_info_nil", OnNilValue)
end)

function InfoClient:InitNetKey(netFunc, key)
	local net = self.networks[key]

	if not net then
		local myKey = "aipc_info."..key
		net = netFunc(self.inst.GUID, myKey, myKey)
		self.networks[key] = net

		-- 事件处理
		self.inst:ListenForEvent(myKey, function(inst)
			self.values[key] = net:value()
			self.valuesInited[key] = true

			if self.events[key] then
				self.events[key](inst, self.values[key])
			end
		end)
	end

	return net
end

function InfoClient:Set(netFunc, key, value, mock)
	local net = self:InitNetKey(netFunc, key)

	if not mock then
		if value ~= nil then
			net:set(value)
		else
			self.netNil:set(key)
		end
	end
end

function InfoClient:ListenForEvent(key, func)
	self.events[key] = func
end

function InfoClient:SetString(key, value, mock)
	self:Set(net_string, key, value, mock)
end

function InfoClient:SetUInt(key, value, mock)
	self:Set(net_uint, key, value, mock)
end

function InfoClient:SetByteArray(key, value, mock)
	self:Set(net_bytearray, key, value, mock)
end

function InfoClient:Get(key)
	if not self.valuesInited[key] then
		local net = self.networks[key]

		if net then
			self.values[key] = net:value()
			self.valuesInited[key] = true
		end
	end

	return self.values[key]
end

return InfoClient