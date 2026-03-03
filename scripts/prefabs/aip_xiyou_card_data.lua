local charactersList = {
	"monkey_king",
	"neza",
	"white_bone",
	"pigsy",
	"yangjian",
	"myth_yutu",
	"yama_commissioners",
}

-- 抽奖概率
local charactersChance = {}
for i, name in ipairs(charactersList) do
	charactersChance["aip_xiyou_card_"..name] = 1
end
charactersChance.aip_xiyou_card_neza = 0.4
charactersChance.aip_xiyou_card_yangjian = 0.4

return {
	charactersList = charactersList,
	characterCount = #charactersList,
	charactersChance = charactersChance,
}