local assets = {}

local chineseStory = require "aipStory/chinese"

-- 动态加载资源
for _, cat in ipairs(chineseStory) do
	local descList = cat.desc

	for _, descInfo in ipairs(descList) do
		if type(descInfo) == "table" and descInfo.type == "img" then
			local name = descInfo.name
			if name ~= nil then
				local imgPath = "images/aipStory/"..name..".xml"
				if softresolvefilepath(imgPath) ~= nil then
					table.insert(assets, Asset("ATLAS", imgPath))
				end
			end
		end
	end
end

local function fn()
    local inst = CreateEntity()

    return inst
end

return Prefab("aip_0_preload", fn, assets)
