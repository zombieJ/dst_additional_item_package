local _G = GLOBAL

local skinUtil = _G.require("utils/aip_skin_util")

local SKIN_CONFIGS = {
	_G.require("configurations/skin/aip_endless_lotus"),
	_G.require("configurations/skin/aip_cozy_nest"),
	_G.require("configurations/skin/aip_grandfather_clock"),
	_G.require("configurations/skin/aip_lantern"),
	_G.require("configurations/skin/aip_lantern_stand"),
	_G.require("configurations/skin/aip_crayon_wall"),
}

for _, config in ipairs(SKIN_CONFIGS) do
	skinUtil.RegisterBuildSkinConfig(config, _G.aipGetModConfig("language"))
end

local SKIN_CONFIG_BY_PREFAB = {}
for _, config in ipairs(SKIN_CONFIGS) do
	SKIN_CONFIG_BY_PREFAB[config.PREFAB] = config
	for _, alias in ipairs(config.ALIASES or {}) do
		SKIN_CONFIG_BY_PREFAB[alias] = config
	end
end

-- 判断指定皮肤是否属于本模组登记的建造皮肤。
local function isAipBuildSkin(prefab, skin)
	local config = prefab ~= nil and SKIN_CONFIG_BY_PREFAB[prefab] or nil

	return skin ~= nil and config ~= nil and config.SKIN_INDEX[skin] ~= nil
end

-- 记录菜单制作时选择的模组皮肤，避免原版库存校验把自定义皮肤丢掉。
local function setPendingBuildSkin(builder, recipe, skin)
	if recipe == nil then
		return
	end

	builder._aipPendingBuildSkins = builder._aipPendingBuildSkins or {}

	if isAipBuildSkin(recipe.product, skin) then
		builder._aipPendingBuildSkins[recipe.name] = skin
	else
		builder._aipPendingBuildSkins[recipe.name] = nil
	end
end

-- 读取当前构建动作里缓存的模组皮肤。
local function getCurrentBuildSkin(builder)
	local builderComponent = builder.components ~= nil and builder.components.builder or nil

	return builderComponent ~= nil and builderComponent._aipCurrentBuildSkin or nil
end

-- 读取菜单制作时缓存的模组皮肤，处理原版校验异步清掉 skin 的情况。
local function getPendingBuildSkin(builder, recipe)
	local builderComponent = builder.components ~= nil and builder.components.builder or nil

	return builderComponent ~= nil and
		builderComponent._aipPendingBuildSkins ~= nil and
		recipe ~= nil and
		builderComponent._aipPendingBuildSkins[recipe.name] or nil
end

-- 成品生成后清理已消费的菜单皮肤缓存。
local function clearPendingBuildSkin(builder, recipe)
	local builderComponent = builder.components ~= nil and builder.components.builder or nil

	if builderComponent ~= nil and builderComponent._aipPendingBuildSkins ~= nil and recipe ~= nil then
		builderComponent._aipPendingBuildSkins[recipe.name] = nil
	end
end

-- 建造完成后把配方里选择的皮肤应用到成品。
local function onBuildProduct(builder, data)
	local skin = data ~= nil and data.skin or nil
	local recipe = data ~= nil and data.recipe or nil

	if skin == nil then
		skin = getCurrentBuildSkin(builder)
	end
	if skin == nil then
		skin = getPendingBuildSkin(builder, recipe)
	end

	if skin ~= nil then
		skinUtil.ApplyBuiltSkin({
			item = data ~= nil and data.item or nil,
			skin = skin,
		})
	else
		skinUtil.ApplyBuiltSkin(data)
	end

	clearPendingBuildSkin(builder, recipe)
end

-- 劫持 builder 制作流程，为 builditem 补上原版校验丢掉的模组皮肤。
local function patchBuilderBuildSkin()
	local builderClass = _G.require("components/builder")

	if builderClass._aip_build_skin_patched then
		return
	end

	local oldMakeRecipeFromMenu = builderClass.MakeRecipeFromMenu
	-- 菜单发起制作时保存用户选择的模组皮肤。
	builderClass.MakeRecipeFromMenu = function(self, recipe, skin, ...)
		setPendingBuildSkin(self, recipe, skin)
		return oldMakeRecipeFromMenu(self, recipe, skin, ...)
	end

	local oldDoBuild = builderClass.DoBuild
	-- 执行 BUILD 动作时把缓存皮肤暴露给 builditem 事件。
	builderClass.DoBuild = function(self, recname, pt, rotation, skin, ...)
		local recipe = _G.GetValidRecipe(recname)
		local pendingSkin = self._aipPendingBuildSkins ~= nil and
			self._aipPendingBuildSkins[recname] or nil
		local currentSkin = isAipBuildSkin(recipe ~= nil and recipe.product or nil, skin) and
			skin or pendingSkin

		self._aipCurrentBuildSkin = currentSkin

		local success, reason = oldDoBuild(self, recname, pt, rotation, skin, ...)

		self._aipCurrentBuildSkin = nil
		if success and self._aipPendingBuildSkins ~= nil then
			self._aipPendingBuildSkins[recname] = nil
		end

		return success, reason
	end

	builderClass._aip_build_skin_patched = true
end

patchBuilderBuildSkin()

AddComponentPostInit("builder", function(self)
	if _G.TheWorld == nil or not _G.TheWorld.ismastersim then
		return
	end

	-- 灯笼这类物品走 builditem，建筑类皮肤走 buildstructure。
	self.inst:ListenForEvent("builditem", onBuildProduct)
	self.inst:ListenForEvent("buildstructure", onBuildProduct)
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
