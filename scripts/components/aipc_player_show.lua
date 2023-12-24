local dev_mode = aipGetModConfig("dev_mode") == "enabled"

-- 服务端：围绕玩家开始的演出

------------------------------ 方法 ------------------------------
local function createIfPossible(inst, prefab, tag)
	local oldoneHand = TheSim:FindFirstEntityWithTag(tag)

	-- 对于存在 tag 但是 prefab 不同的情况，说明是已经被合成了的高级武器。那就不能提供
	if oldoneHand ~= nil and oldoneHand.prefab ~= prefab then
		return
	end

	local target = nil

	if oldoneHand == nil then
		target = aipSpawnPrefab(inst, prefab)
	elseif oldoneHand.components.inventoryitem:GetGrandOwner() == nil then
		target = oldoneHand

		aipSpawnPrefab(oldoneHand, "aip_shadow_wrapper").DoShow()

		-- 恢复 44% 耐久
		local ptg = target.components.finiteuses:GetPercent() + .44
		target.components.finiteuses:SetPercent(
			math.min(1, ptg)
		)
	end

	if target ~= nil then
		aipFlingItem(target, inst:GetPosition())
	end
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

	self.inst:ListenForEvent("attackedbygrue", OnGrueAttacked)

	self.inst:ListenForEvent("finishedwork", OnFinishedWork)
end)

-- 创建 憎恨之刃
function PlayerShow:CreateOldoneHand()
	createIfPossible(self.inst, "aip_oldone_hand", "aip_DivineRapier_bad")
end

-- 创建 羁绊之刃
function PlayerShow:CreateLivingFriendship()
	createIfPossible(self.inst, "aip_living_friendship", "aip_DivineRapier_good")
end

return PlayerShow