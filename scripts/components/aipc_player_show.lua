local dev_mode = aipGetModConfig("dev_mode") == "enabled"

-- 服务端：围绕玩家开始的演出

local SHOW_RANGE = 20

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

		local funcList = { grassShow, butterflyShow }
		
		if dev_mode and grassShow(pos) then
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