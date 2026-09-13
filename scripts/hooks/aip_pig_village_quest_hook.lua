local _G = GLOBAL
if _G.TheNet:IsDedicated() then return end

local indicator = _G.require("aip_pig_village_indicator")

-- 包装每个玩家 HUD 的目标指示入口，为猪村任务标记传入有效头像资源。
AddClassPostConstruct("screens/playerhud", function(hud)
	if hud._aipPigVillageIndicatorHook then return end
	local originalAddTargetIndicator = hud.AddTargetIndicator
	hud.AddTargetIndicator = function(self, target, data)
		return originalAddTargetIndicator(self, target, indicator.Resolve(target, data))
	end
	hud._aipPigVillageIndicatorHook = true
end)
