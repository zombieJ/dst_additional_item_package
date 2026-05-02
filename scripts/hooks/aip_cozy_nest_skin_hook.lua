local _G = GLOBAL

local cozyNestConfig = _G.require("configurations/aip_cozy_nest")
cozyNestConfig.RegisterPrefabSkins()
cozyNestConfig.RegisterInventoryAtlases()
cozyNestConfig.RegisterStrings(_G.aipGetModConfig("language"))

local function containsSkin(skinsList, skinName)
	for _, skin in ipairs(skinsList) do
		if skin.item == skinName then
			return true
		end
	end

	return false
end

local function appendCozyNestSkins(self, skinsList)
	if self.recipe == nil or self.recipe.product ~= cozyNestConfig.PREFAB then
		return skinsList
	end

	for _, skinName in ipairs(cozyNestConfig.BUILD_SKINS) do
		if not containsSkin(skinsList, skinName) then
			table.insert(skinsList, {
				type = "item",
				item = skinName,
				timestamp = 0,
			})
		end
	end

	return skinsList
end

local function patchSkinList(packageName)
	local class = _G.require(packageName)
	if class._aip_cozy_nest_skin_list_patched then
		return
	end

	local oldGetSkinsList = class.GetSkinsList
	class.GetSkinsList = function(self, ...)
		return appendCozyNestSkins(self, oldGetSkinsList(self, ...))
	end

	class._aip_cozy_nest_skin_list_patched = true
end

if not _G.TheNet:IsDedicated() then
	patchSkinList("widgets/recipepopup")
	patchSkinList("widgets/redux/craftingmenu_skinselector")
end
