local questConfig = require("configurations/aip_pig_village_quest")

local Ticket = {}

-- 合并玩家物品栏内所有满足三张一组的体验券碎片。
function Ticket.MergeFragments(owner)
	if owner == nil or not owner:IsValid() or owner.components.inventory == nil then
		return 0
	end

	local _, fragmentCount = owner.components.inventory:Has("aip_train_ticket_fragment", 1)
	local ticketCount = math.floor(fragmentCount / questConfig.TICKET_FRAGMENT_COUNT)
	if ticketCount <= 0 then
		return 0
	end

	owner.components.inventory:ConsumeByName(
		"aip_train_ticket_fragment",
		ticketCount * questConfig.TICKET_FRAGMENT_COUNT
	)
	for _ = 1, ticketCount do
		local ticket = aipSpawnPrefab(owner, "aip_train_ticket")
		if ticket ~= nil then
			owner.components.inventory:GiveItem(ticket, nil, owner:GetPosition())
		end
	end

	if owner.components.talker ~= nil then
		owner.components.talker:Say(questConfig.LANG.TICKET_MERGED)
	end
	return ticketCount
end

-- 安排玩家级合并检查，避免多个碎片回调在同一帧重复消费。
function Ticket.ScheduleMerge(owner)
	if owner == nil or not owner:HasTag("player") or owner._aipTrainTicketMergeTask ~= nil then
		return false
	end

	owner._aipTrainTicketMergeTask = owner:DoTaskInTime(0, function(player)
		player._aipTrainTicketMergeTask = nil
		Ticket.MergeFragments(player)
	end)
	return true
end

return Ticket
