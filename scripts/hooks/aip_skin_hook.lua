local _G = GLOBAL

local skinUtil = _G.require("utils/aip_skin_util")

local SKIN_CONFIGS = {
	_G.require("configurations/skin/aip_cozy_nest"),
	_G.require("configurations/skin/aip_grandfather_clock"),
	_G.require("configurations/skin/aip_lantern"),
	_G.require("configurations/skin/aip_lantern_stand"),
}

for _, config in ipairs(SKIN_CONFIGS) do
	skinUtil.RegisterBuildSkinConfig(config, _G.aipGetModConfig("language"))
end

local function onBuildStructure(builder, data)
	skinUtil.ApplyBuiltSkin(data)
end

AddComponentPostInit("builder", function(self)
	if _G.TheWorld == nil or not _G.TheWorld.ismastersim then
		return
	end

	self.inst:ListenForEvent("buildstructure", onBuildStructure)
end)

local function patchSkinList(packageName)
	local class = _G.require(packageName)
	if class._aip_skin_list_patched then
		return
	end

	local oldGetSkinsList = class.GetSkinsList
	if type(oldGetSkinsList) ~= "function" then
		return
	end

	class.GetSkinsList = function(self, ...)
		return skinUtil.AppendBuildSkins(self.recipe, oldGetSkinsList(self, ...))
	end

	class._aip_skin_list_patched = true
end

if not _G.TheNet:IsDedicated() then
	patchSkinList("widgets/recipepopup")
	patchSkinList("widgets/redux/craftingmenu_skinselector")
end
