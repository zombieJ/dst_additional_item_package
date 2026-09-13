local Indicator = {}
local QUEST_MARKER_DATA = { image = "poi_question.tex", atlas = "images/avatars.xml" }

-- 为猪村任务标记补充原版问号头像，其他目标和显式配置保持不变。
function Indicator.Resolve(target, data)
	if data ~= nil or target == nil or target.prefab ~= "aip_pig_village_quest_marker" then
		return data
	end
	return QUEST_MARKER_DATA
end

return Indicator
