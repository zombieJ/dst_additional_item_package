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

local function getIndex(pt)
	local x = pt.x + 1
	local y = pt.y + 1
	local z = pt.z + 1
	return y * 9 + x * 3 + z + 1
end

local function getSameCount(x1, y1, z1, x2, y2, z2)
	local sameX = x1 == x2
	local sameY = y1 == y2
	local sameZ = z1 == z2
	local sameCnt = (sameX and 1 or 0) + (sameY and 1 or 0) + (sameZ and 1 or 0)
	return sameCnt
end

local function isCorner(x, y, z)
	return math.abs(x) == 1 and math.abs(y) == 1 and math.abs(z) == 1
end

-- 获取两点相同的轴
local function getSameAxis(p1, p2)
	local axises = {}
	local xyz = {'x','y','z'}
	for i, axis in ipairs(xyz) do
		if p1[axis] == p2[axis] then
			table.insert(axises, axis)
		end
	end
	return axises
end

-- 是一条边的中间
local function isEdgeCenter(x, y, z)
	return math.abs(x) + math.abs(y) + math.abs(z) == 2
end

-- 是一个面的中间
local function isFaceCenter(x, y, z)
	return math.abs(x) + math.abs(y) + math.abs(z) == 1
end

-- 按照一个轴反转角度
local function revertPT(axis, x, y, z)
	if type(x) == "table" then
		z = x.z
		y = x.y
		x = x.x
	end

	local pt = Vector3(x, y, z)
	pt[axis] = -pt[axis]
	return pt
end

-- 设置得到一个新的
local function setPT(axis, pt, val)
	local clone = Vector3(pt.x, pt.y, pt.z)
	clone[axis] = val
	return clone
end

-- 偏移得到一个新的
local function offsetPT(axis, pt, offset)
	local val = pt[axis] + offset
	return setPT(axis, pt, val)
end

local function 

-- 给与两个坐标轴，开始转一圈
local function tryWalkPT(startPT, endPT, restAxises, reverse)
	local currentPT = startPT

	local finalRestAxises = aipTableSlice(restAxises)

	-- 我们会从一个轴开始转圈，一个转完了转另一个，然后往复到目标点为止
	local walkingAxisIdx = 1
	local walkingAxisOffsets = {}

	local startWalkingAxisOffset = nil

	-- !!! 开始时需要决定初始转圈的方向 !!!
	if math.abs(startPT[restAxises[1]]) == 1 and math.abs(startPT[restAxises[2]]) == 1 and reverse then
		-- 如果是角落，互换一下坐标顺序即可
		finalRestAxises = { restAxises[2], restAxises[1] }
	end

	for step = 1, 20 do
		-- 获取当前需要走步数的坐标
		local walkingAxis = finalRestAxises[walkingAxisIdx]

		-- 如果还没有位移数据，则根据点随便搞一个
		if not walkingAxisOffsets[walkingAxisIdx] then
			walkingAxisOffsets[walkingAxisIdx] = currentPT[walkingAxis] == 1 and -1 or 1

			-- 如果是设置了 reverse，就取反一下方向
			if currentPT[walkingAxis] == 0 and reverse then
				walkingAxisOffsets[walkingAxisIdx] = -walkingAxisOffsets[walkingAxisIdx]
			end

			-- 记录一下起始状态的 offset
			if startWalkingAxisOffset == nil then
				startWalkingAxisOffset = walkingAxisOffsets[walkingAxisIdx]
			end
		end

		-- 获取位移数据
		local walkingAxisOffset = walkingAxisOffsets[walkingAxisIdx]

		-- 走一步
		local nextWalkingAxisPos = currentPT[walkingAxis] + walkingAxisOffset
		local nextPT = Vector3(currentPT.x, currentPT.y, currentPT.z)
		nextPT[walkingAxis] = nextWalkingAxisPos

		-- aipTypePrint("Walking:", step, currentPT, ">>>", nextPT)

		-- 如果发现到了边界，则走下一个边
		if math.abs(nextWalkingAxisPos) == 1 then
			walkingAxisOffsets[walkingAxisIdx] = -walkingAxisOffsets[walkingAxisIdx]
			walkingAxisIdx = walkingAxisIdx == 1 and 2 or 1
		end

		-- 如果到了目标点，我们结束
		if nextPT.x == endPT.x and nextPT.y == endPT.y and nextPT.z == endPT.z then
			return {
				step = step,
				restAxises = finalRestAxises,
				walkingAxisOffset = startWalkingAxisOffset,
			}
		end

		currentPT = nextPT
	end
end

-- 播放动画
local function playAnimation(fx, motion)
	if fx then
		fx.AnimState:PlayAnimation(motion, true)

		if motion == "optional" then
			fx.rotate = true
		end
	end
end

-- 根据一个轴的名字，获取剩余两个轴的名字
local function getAxisRest(axis)
	local tbl = {
		x = { 'y', 'z' },
		y = { 'x', 'z' },
		z = { 'x', 'y' },
	}
	return tbl[axis]
end

-- 根据值获得轴的名字
local function getAxisByVal(pt, val)
	if pt.x == val then
		return 'x'
	elseif pt.y == val then
		return 'y'
	elseif pt.z == val then
		return 'z'
	end
end

-- 检查两个点是否在轴上（如果在轴上就不用旋转了）
local function isOnAxis(axis, pt)
	if axis == 'x' then
		return pt.y == 0 and pt.z == 0
	elseif axis == 'y' then
		return pt.x == 0 and pt.z == 0
	elseif axis == 'z' then
		return pt.x == 0 and pt.y == 0
	end
end

------------------------------- 组件 -------------------------------
local Rubik = Class(function(self, inst)
	self.inst = inst

	self.start = false
	self.selectIndex = nil
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

------------------------------- 位置 -------------------------------
function Rubik:SyncPos()
	-- 我们总是延迟一丢丢
	self.inst:DoTaskInTime(0.1, function()
		local x, y, z = self.inst.Transform:GetWorldPosition()

		for i, fx in ipairs(self.fxs) do
			local ox, oy, oz = getPos(i)

			local scaleOffset = 1 + (oy - 1) / 6

			local tgtX = x + ox * FX_OFFSET * scaleOffset
			local tgtY = y + oy * FX_OFFSET + FX_HEIGHT
			local tgtZ = z + oz * FX_OFFSET * scaleOffset
			
			fx.Physics:Teleport(tgtX, tgtY, tgtZ)
		end
	end)
end

function Rubik:SyncHighlight()
	for i, fx in ipairs(self.fxs) do
		local ox, oy, oz = getPos(i)

		playAnimation(fx, "idle")
		fx.rotate = false

		if ox == 0 and oy == 0 and oz == 0 then
			fx:AddTag("FX")
		else
			fx:RemoveTag("FX")
		end
	end

	if self.selectIndex then
		-- 选中动画
		local selected = self.fxs[self.selectIndex]
		playAnimation(selected, "selected")

		-- 可选动画
		local sx, sy, sz = getPos(self.selectIndex)


		------------ 角落点击 ------------
		if isCorner(sx, sy, sz) then
			local ptXY = revertPT('x', revertPT('y', sx, sy, sz))
			ptXY.lock = 'z'
			local ptYZ = revertPT('y', revertPT('z', sx, sy, sz))
			ptYZ.lock = 'x'
			local ptXZ = revertPT('z', revertPT('x', sx, sy, sz))
			ptXZ.lock = 'y'

			local ptList = { ptXY, ptYZ, ptXZ }
			for i, pt in ipairs(ptList) do
				local restAxises = getAxisRest(pt.lock)

				for i, restAxis in ipairs(restAxises) do
					local finalPT = setPT(restAxis, pt, 0)
					local idx = getIndex(finalPT)
					playAnimation(self.fxs[idx], "optional")
				end
			end
		end

		------------ 边缘中间 ------------
		if isEdgeCenter(sx, sy, sz) then
			-- 找到数值为 0 的轴
			local pt = Vector3(sx, sy, sz)
			local fixAxis = getAxisByVal(pt, 0)
			local restAxises = getAxisRest(fixAxis)

			-- 同轴对面
			for i, restAxis in ipairs(restAxises) do
				local finalPT = setPT(restAxis, pt, 0)
				local idx = getIndex(finalPT)
				playAnimation(self.fxs[idx], "optional")
			end

			-- 同面旋转
			local pt1 = setPT(fixAxis, pt, -1) -- 先找到角落
			local pt2 = setPT(fixAxis, pt, 1)
			local ptList = { pt1, pt2 }
			for i, pt in ipairs(ptList) do
				for i, restAxis in ipairs(restAxises) do
					local finalPT = setPT(restAxis, pt, 0)
					local idx = getIndex(finalPT)
					playAnimation(self.fxs[idx], "optional")
				end
			end
		end

		------------ 中心点击 ------------
		if isFaceCenter(sx, sy, sz) then
			local pt = Vector3(sx, sy, sz)
			local fixAxis = getAxisByVal(pt, 1) or getAxisByVal(pt, -1)
			local restAxises = getAxisRest(fixAxis)

			for i, restAxis in ipairs(restAxises) do
				local pt1 = setPT(restAxis, pt, -1)
				local pt2 = setPT(restAxis, pt, 1)
				local ptList = { pt1, pt2 }
				for i, finalPT in ipairs(ptList) do
					local idx = getIndex(finalPT)
					playAnimation(self.fxs[idx], "optional")
				end
			end
		end
	end
end

------------------------------- 开关 -------------------------------
function Rubik:Start()
	self.start = true

	if #self.fxs == 0 then
		for i, color in ipairs(self.matrix) do
			local fx = SpawnPrefab("aip_rubik_fire_"..color)
			fx.aipRubik = self.inst
			self.fxs[i] = fx
		end
	end

	self:SyncPos()
	self:SyncHighlight()
end

function Rubik:Stop()
	self.start = false

	for i, fx in ipairs(self.fxs) do
		fx:Remove()
	end

	self.fxs = {}
end

------------------------------- 选择 -------------------------------
function Rubik:Select(fire)
	local prevIndex = self.selectIndex

	self.selectIndex = aipTableIndex(self.fxs, fire)

	-- 如果是中间那个 或者 相同元素，就不能选中
	if self.selectIndex == 14 or prevIndex == self.selectIndex then
		self.selectIndex = nil
	end

	----------------------- 旋转判断 -----------------------
	if prevIndex and self.selectIndex and fire.rotate then
		local px, py, pz = getPos(prevIndex)
		local cx, cy, cz = getPos(self.selectIndex)
		
		local pStart = Vector3(px, py, pz)
		local pEnd = Vector3(cx, cy, cz)

		aipPrint("旋转吧：", px, py, pz, '>>>', cx, cy, cz)

		-- 遍历每个轴，找到可以旋转的那个
		local axises = getSameAxis(pStart, pEnd)
		for i, axis in ipairs(axises) do
			aipPrint("检测轴：", axis, not isOnAxis(axis, pStart), not isOnAxis(axis, pEnd))
			if not isOnAxis(axis, pStart) and not isOnAxis(axis, pEnd) then
				local fixedAxisPos = pEnd[axis] -- 固定轴上的固定点
				local restAxises = getAxisRest(axis)

				-- 从起点开始转圈，找到最快的转圈方向
				local walkInfo = walkPT(pStart, pEnd, restAxises)
				local reserveWalkInfo = walkPT(pStart, pEnd, restAxises, true)

				-- 开始旋转颜色
				if walkInfo.step < reserveWalkInfo.step then
					aipPrint("GGG")
				else
					aipPrint("AAA")
				end

				-- 转过了，不用选中了
				self.selectIndex = nil
			end
		end
	end

	--------------------- 更新点击状态 ---------------------
	self:SyncHighlight()
end

return Rubik