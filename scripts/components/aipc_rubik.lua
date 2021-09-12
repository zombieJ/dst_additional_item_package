------------------------------- 方法 -------------------------------
local FX_OFFSET = 2
local FX_HEIGHT = 7

local function getPos(idx)
	local mathIdx = idx - 1
	local y = math.floor(mathIdx / 9)
	local x = math.floor(math.mod(mathIdx, 9) / 3)
	local z = math.mod(mathIdx, 3)

	return x - 1, y - 1, z - 1
end

------------------------------- 组件 -------------------------------
local Rubik = Class(function(self, inst)
	self.inst = inst

	self.start = false
	self.fxs = {}

	self.matrix = {}
	local colors = {"red","green","blue"}
	for y = 0, 2 do
		local color = colors[y + 1]

		for x = 0, 2 do
			for z = 0, 2 do
				local idx = 1 + z + x * 3 + y * 9
				self.matrix[idx] = color
			end
		end
	end
end)

function Rubik:SyncPos()
	for i, fx in ipairs(self.fxs) do
		local ox, oy, oz = getPos(i)

		local scaleOffset = 1 + (oy - 1) / 6
		
		fx.Transform:SetPosition(
			ox * FX_OFFSET * scaleOffset,
			oy * FX_OFFSET + FX_HEIGHT,
			oz * FX_OFFSET * scaleOffset
		)
	end
end

function Rubik:Start()
	self.start = true

	if #self.fxs == 0 then
		for i, color in ipairs(self.matrix) do
			local fx = SpawnPrefab("aip_rubik_fire_"..color)
			self.inst:AddChild(fx)
			self.fxs[i] = fx
		end
	end

	self:SyncPos()
end

function Rubik:Stop()
	self.start = false

	for i, fx in ipairs(self.fxs) do
		fx:Remove()
	end

	self.fxs = {}
end

return Rubik