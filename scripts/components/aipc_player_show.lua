local dev_mode = aipGetModConfig("dev_mode") == "enabled"

-- 服务端：围绕玩家开始的演出

local SHOW_RANGE = 20

local function debugEffect(inst)
	if dev_mode then
		aipSpawnPrefab(inst, "aip_shadow_wrapper").DoShow()
	end
end

local function isInOcean(tgtPT, range)
	range = range or 3
	local tgtPT_LT = Vector3(tgtPT.x - range, 0, tgtPT.z - range)
	local tgtPT_LB = Vector3(tgtPT.x - range, 0, tgtPT.z + range)
	local tgtPT_RT = Vector3(tgtPT.x + range, 0, tgtPT.z - range)
	local tgtPT_RB = Vector3(tgtPT.x + range, 0, tgtPT.z + range)

	if
		TheWorld.Map:IsOceanAtPoint(tgtPT.x, tgtPT.y, tgtPT.z) and
		TheWorld.Map:IsOceanAtPoint(tgtPT_LT.x, tgtPT_LT.y, tgtPT_LT.z) and
		TheWorld.Map:IsOceanAtPoint(tgtPT_LB.x, tgtPT_LB.y, tgtPT_LB.z) and
		TheWorld.Map:IsOceanAtPoint(tgtPT_RT.x, tgtPT_RT.y, tgtPT_RT.z) and
		TheWorld.Map:IsOceanAtPoint(tgtPT_RB.x, tgtPT_RB.y, tgtPT_RB.z)
	then
		return true
	end

	return false
end

-- 蝴蝶：被鸟吃
local function butterflyShow(pos)
	local butterfly =  TheSim:FindEntities(
		pos.x, pos.y, pos.z, SHOW_RANGE, { "butterfly" }
	)[1]

	-- 创造一个鸟，吃掉它
	if butterfly ~= nil and butterfly.components.locomotor ~= nil then
		local wings = aipSpawnPrefab(butterfly, "butterflywings")
		wings.AnimState:OverrideMultColour(0,0,0,0)

		local butterflyPt = butterfly:GetPosition()
		local bird = aipSpawnPrefab(butterfly, "robin")
		bird.Physics:Teleport(butterflyPt.x, 6, butterflyPt.z)

		if bird.components.eater ~= nil then
			bird.components.eater:SetDiet({ FOODTYPE.VEGGIE }, { FOODTYPE.VEGGIE })
		end
		bird.bufferedaction = BufferedAction(bird, wings, ACTIONS.EAT)

		-- 停下来准备被吃掉
		butterfly.components.locomotor:Stop()
		butterfly.components.locomotor:SetExternalSpeedMultiplier(
			butterfly, "aip_lock_move", 0
		)

		butterfly:DoTaskInTime(0.5, function()
			wings.AnimState:OverrideMultColour(1,1,1,1)
			aipFlingItem(wings)
			butterfly:Remove()
		end)

		return true
	end
end

-- 草丛：草里窜走的兔子
local function grassShow(pos)
	local grasses = TheSim:FindEntities(
		pos.x, pos.y, pos.z, SHOW_RANGE, { "plant", "renewable" }
	)

	grasses = aipFilterTable(grasses, function(item)
		return (
			item.prefab == "grass" and
			item.components.pickable ~= nil and
			item.components.pickable:CanBePicked()
		)
	end)

	if #grasses >= 2 then
		local grass1 = grasses[1]
		local grass2 = grasses[2]

		local rabbit = aipSpawnPrefab(grass1, "rabbit")

		if rabbit.components.homeseeker == nil then
			rabbit:AddComponent("homeseeker")
		end
		rabbit.components.homeseeker.home = grass2

		if rabbit.components.locomotor ~= nil then
			rabbit.components.locomotor:SetExternalSpeedMultiplier(
				rabbit, "aip_lock_move", 1.5
			)
		end

		rabbit:DoTaskInTime(0.1, function()
			rabbit:PushEvent("gohome")
			rabbit.components.homeseeker:GoHome(true)
		end)

		return true
	end
end

-- 兔子：躲秃鹫
local function rabbitShow(pos)
	local rabbit = TheSim:FindEntities(
		pos.x, pos.y, pos.z, SHOW_RANGE, { "rabbit" }
	)[1]

	if rabbit ~= nil and rabbit.prefab == "rabbit" then
		debugEffect(rabbit)

		local buzzard = aipSpawnPrefab(rabbit, "buzzard", nil, 30)
		buzzard.sg:GoToState("glide")

		buzzard:DoTaskInTime(3, function()
			buzzard.components.locomotor:Stop()
			debugEffect(rabbit)
			buzzard.sg:GoToState("flyaway")
		end)

		return true
	end
end

-- 海洋：荧光水母
local function jellyfishShow(pos)
	local chance = dev_mode and 1 or 0.05

	if
		-- 不是晚上就算了
		not TheWorld.state.isnight or
		-- 当前位置是否在海里
		not TheWorld.Map:IsOceanAtPoint(pos.x, pos.y, pos.z, true) or
		-- 几率不对
		math.random() > chance
	then
		return
	end

	-- 在附近找另一个海点
	local randomAngle = math.random() * 2 * PI
	local dist = 15

	local tgtPT = pos + Vector3(math.cos(randomAngle) * dist, 0, math.sin(randomAngle) * dist)
	local tgtPT_LT = Vector3(tgtPT.x - 3, 0, tgtPT.z - 3)
	local tgtPT_LB = Vector3(tgtPT.x - 3, 0, tgtPT.z + 3)
	local tgtPT_RT = Vector3(tgtPT.x + 3, 0, tgtPT.z - 3)
	local tgtPT_RB = Vector3(tgtPT.x + 3, 0, tgtPT.z + 3)

	if isInOcean(tgtPT, 5) then
		local jellyfishGrp = aipSpawnPrefab(nil, "aip_ocean_jellyfish_group", tgtPT.x, 0, tgtPT.z)

		debugEffect(jellyfishGrp)
		return true
	end
end

-- 夜晚的靡靡之花
local function blinkFlowerShow(pos)
	local chance = dev_mode and 1 or 0.05

	if
		-- 不是晚上就算了
		not TheWorld.state.isnight or
		-- 当前位置是否在海里
		not TheWorld.Map:IsLandTileAtPoint(pos.x, pos.y, pos.z) or
		-- 几率不对
		math.random() > chance
	then
		return
	end

	-- 随机位置
	local randomAngle = math.random() * 2 * PI
	local dist = 15

	local tgtPT = pos + Vector3(math.cos(randomAngle) * dist, 0, math.sin(randomAngle) * dist)

	-- 创建靡靡之花
	if TheWorld.Map:IsLandTileAtPoint(tgtPT.x, tgtPT.y, tgtPT.z) then
		local flowerGrp = aipSpawnPrefab(nil, "aip_blink_flower_group", tgtPT.x, 0, tgtPT.z)

		debugEffect(flowerGrp)
		return true
	end
end

-- 海中旋涡
local function vortexShow(pos)
	local chance = dev_mode and 1 or 0.05

	if
		-- 晚上就算了
		TheWorld.state.isnight or
		-- 当前位置是否在海里
		not TheWorld.Map:IsOceanAtPoint(pos.x, pos.y, pos.z, true) or
		-- 几率不对
		math.random() > chance
	then
		return
	end

	-- 在附近找另一个海点
	local randomAngle = math.random() * 2 * PI
	local dist = 15

	local tgtPT = pos + Vector3(math.cos(randomAngle) * dist, 0, math.sin(randomAngle) * dist)
	
	if isInOcean(tgtPT, 10) then
		local vortex = aipSpawnPrefab(nil, "aip_ocean_vortex", tgtPT.x, 0, tgtPT.z)

		debugEffect(vortex)
		return true
	end
end

-- 变形蘑菇
local function turnMushroomShow(pos)
	local chance = dev_mode and 1 or 0.05

	if
		-- 晚上就算了
		TheWorld.state.isnight or
		-- 当前位置是否在海里
		not TheWorld.Map:IsOceanAtPoint(pos.x, pos.y, pos.z, true) or
		-- 几率不对
		math.random() > chance
	then
		return
	end

	-- 在附近找一个地面添加花环
	local newPT = aipGetSpawnPoint(pos, 20)
end

------------------------------ 方法 ------------------------------
local function createIfPossible(inst, prefab, tag)
	local oldoneHand = TheSim:FindFirstEntityWithTag(tag)

	-- 对于存在 tag 但是 prefab 不同的情况，说明是已经被合成了的高级武器。那就不能提供
	if oldoneHand ~= nil and oldoneHand.prefab ~= prefab then
		return
	end

	local target = nil
	local newItem = false

	if oldoneHand == nil then
		target = aipSpawnPrefab(inst, prefab)
		newItem = true
	elseif oldoneHand.components.inventoryitem:GetGrandOwner() == nil then
		target = oldoneHand

		aipSpawnPrefab(oldoneHand, "aip_shadow_wrapper").DoShow()

		-- 恢复少量耐久
		local ptg = target.components.finiteuses:GetPercent() + .25
		target.components.finiteuses:SetPercent(
			math.min(1, ptg)
		)
	end

	if target ~= nil then
		aipFlingItem(target, inst:GetPosition())
	end

	return target, newItem
end

------------------------------ 事件 ------------------------------
-- 查理攻击
local function OnGrueAttacked(inst)
	-- 憎恨之刃：在黑暗中被查理攻击，或者在黑暗中吃下 噩梦之灵
	local chance = dev_mode and 1 or 0.05

	if TheWorld:HasTag("forest") and math.random() <= chance then
		inst.components.aipc_player_show:CreateOldoneHand()
	end
end

-- 完成工作
local function OnFinishedWork(inst, data)
	local chance = dev_mode and 1 or 0.05

	if data ~= nil and data.target ~= nil then
		if data.target.prefab == "moonglass_rock" and math.random() <= chance then
			inst.components.aipc_player_show:CreateLivingFriendship()
		end
	end
end

------------------------------ 实例 ------------------------------
local PlayerShow = Class(function(self, inst)
	self.inst = inst

	self.showTask = nil

	self.inst:ListenForEvent("attackedbygrue", OnGrueAttacked)

	self.inst:ListenForEvent("finishedwork", OnFinishedWork)

	self.inst:WatchWorldState("isnight", function(_, isnight)
		local chance = dev_mode and 1 or 0.1

		if isnight and math.random() < chance then
			self:StartShow()
		end
	end)

	if dev_mode then
		self.inst:DoTaskInTime(5, function()
			self:StartShow()
		end)
	end
end)

------------------------------ 表演 ------------------------------
-- 表演检测器
function PlayerShow:StopShow()
	if self.showTask then
		self.showTask:Cancel()
		self.showTask = nil
	end
end

function PlayerShow:StartShow()
	self:StopShow()

	self.showTask = self.inst:DoPeriodicTask(1, function()
		local pos = self.inst:GetPosition()

		local funcList = {
			grassShow,
			butterflyShow,
			rabbitShow,
			jellyfishShow,
			blinkFlowerShow,
			vortexShow,
			turnMushroomShow,
		}

		local randomFunc = dev_mode and turnMushroomShow or aipRandomEnt(funcList)
		
		-- 开发模式下，指定项目
		if randomFunc(pos) then
			self:StopShow()
		end
	end)
end

------------------------------ 掉落 ------------------------------
-- 创建 憎恨之刃
function PlayerShow:CreateOldoneHand()
	self:StopShow()
	local item, newItem = createIfPossible(self.inst, "aip_oldone_hand", "aip_DivineRapier_bad")

	if item and newItem and aipUnique() then
		item._aipKillerCount = aipUnique():OldoneKillCount()
	end
end

-- 创建 羁绊之刃
function PlayerShow:CreateLivingFriendship()
	self:StopShow()
	createIfPossible(self.inst, "aip_living_friendship", "aip_DivineRapier_good")
end

return PlayerShow