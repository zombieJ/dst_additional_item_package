local PigKingTrain = Class(function(self, inst)
	self.inst = inst

	-- Listen for `trade` event
	self.inst:ListenForEvent("trade", function(inst, data)
		if data.giver and data.item and data.item.prefab == "aip_train_ticket" then
			self:StartTrain(data.giver)
		end
	end)
end)

-- 开始乘车，我们会先创造一个列车实体，然后让玩家进入
function PigKingTrain:StartTrain(doer)
end

return PigKingTrain

--[[
景点：
* 狼王发现你了，赶紧跑！
* 海上的鲨鱼从头顶飞过
* 蚁狮从地上冲出来
* 秃鹫在吃尸体啊！
* 一群蝙蝠从头顶飞过
* 杀人蜂冲了过来
* 牛群在慢悠悠的吃草
* 从山洞里开过去
* 姜饼屋中开过
* 大熊在撞树
* 雷区蹦迪
]]