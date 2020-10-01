--[[ INSTRUCTIONS:
I. Common stuff:
1) Copy custom_tech_tree.lua to your mod directory.
2) Add a line to your modmain:
	modimport "custom_tech_tree.lua"
3) After that add one of these lines to modmain:
	AddNewTechTree("YOUR_TREE_NAME")
	AddNewTechTree("ANOTHER_TREE_NAME",3) --makes 3 levels, e.g. ANOTHER_TREE_NAME_ONE, also _TWO and _THREE
	etc. The number means number of levels.
II. Structure prefab:
1) Add "prototyper" tag to crafting structure in pristine state (before SetPristine).
	inst:AddTag("prototyper")
2) Also you may add "giftmachine" tag if you want.
3) Add prototyper:
	inst:AddComponent("prototyper")
	inst.components.prototyper.trees = TUNING.PROTOTYPER_TREES.YOUR_TREE_NAME_ONE
III. Add a recipe:
	AddRecipe("your_item_prefab", { Ingredient("cutgrass", 1), },
	RECIPETABS.TOOLS, TECH.YOUR_TREE_NAME_ONE,
	nil, nil, nil, nil, nil,
	"images/your_altas_name.xml")
IV. Add text constants (you can support a few languages if you like):
	STRINGS.UI.CRAFTING.YOUR_TREE_NAME_ONE = "You need a <custom structure name> to make it."
--]]
_G=GLOBAL

if _G.rawget(_G,"aipAddNewTechTree") then --Make compatible with other mods.
	AddNewTechTree = _G.aipAddNewTechTree --adding to the env of the mod.
	return
end

--Prepare variables. Save existing environment.

local db = {} -- db.MAGIC == 0
local db_new_techs = {} -- Only new trees, e.g. db_new_techs.NEWTREE == 0
local db_new_classified = {} --e.g.  db_new_classified.NEWTREE == "custom_NEWTREE_level"
local db_new_builder_name = {} -- e.g. db_new_builder_name.NEWTREE == "builder.accessible_tech_trees.NEWTREE"

for k,v in pairs(_G.TECH.NONE) do --initialize (copy)
	db[k] = 0
end
if TUNING.PROTOTYPER_TREES then --just for sure
	for k,v in pairs(TUNING.PROTOTYPER_TREES.SCIENCEMACHINE) do
		db[k] = 0
	end
end

local function UpdateDB(newtree_name) --add new element to our table, create common stuff
	db[newtree_name] = 0
	db_new_techs[newtree_name] = 0
	db_new_classified[newtree_name] = "custom_" .. newtree_name .. "_level"
	db_new_builder_name[newtree_name] = "builder.accessible_tech_trees." .. newtree_name
end

--Custom little hack instrument.
local getupvalue, setupvalue, getinfo = _G.debug.getupvalue, _G.debug.setupvalue, _G.debug.getinfo
local function inject_local(fn, local_fn_name)
	print("INJECT... Trying to find",local_fn_name)
	local info = getinfo(fn, "u")
	local nups = info and info.nups
	for i = 1, nups do
		local name, val = getupvalue(fn, i)
		if (name == local_fn_name) then
			return val, i
		end
	end
	print("CRITICAL ERROR: Can't find variable "..tostring(upvalue_name).."!")
end



--Thanks rezecib for the all places in the code:
--http://forums.kleientertainment.com/topic/69813-how-to-make-custom-tech-tree/
--1) constants, TECH.NONE.NEWTREE = 0, also TECH.NEWTREE_ONE, etc (these are optional, but get used in the recipes a lot)

local function AddNewTechConstants(newtree_name)
	_G.TECH.NONE[newtree_name] = 0
	_G.TECH.LOST[newtree_name] = 10
	if TUNING.PROTOTYPER_TREES then
		for k,tbl in pairs(TUNING.PROTOTYPER_TREES) do
			tbl[newtree_name] = 0
		end
	end
end

local TECH_LEVELS = {'_ONE','_TWO','_THREE','_FOUR','_FIVE'} -- e.g. NEWTREE_ONE
local saved_tech_names = {} --for text hint in GetHintTextForRecipe
local function AddTechLevel(newtree_name, level) 
	level = level or 1
	local level_name
	if TECH_LEVELS[level] then 
		level_name = newtree_name .. TECH_LEVELS[level]
	else
		level_name = newtree_name .. "_" .. tostring(level)
	end
	--Save new name
	if not saved_tech_names[newtree_name] then
		saved_tech_names[newtree_name] = {}
	end
	saved_tech_names[newtree_name][level] = level_name
	_G.TECH[level_name] = {[newtree_name] = level} --for using in recipes
	--for using in new crafting structures:
	if TUNING.PROTOTYPER_TREES then
		local new_tree = {} --make new instance
		for k,v in pairs(db) do --copy old data to new instance
			new_tree[k] = v
		end
		new_tree[newtree_name] = level --> make structure useful
		TUNING.PROTOTYPER_TREES[level_name] = new_tree
	end
end



--2) components/builder:EvaluateTechTrees makes specific mention to each of the trees in order to bring in self.bonus. Looks like it might involve a messy override in order to add intrinsic character bonuses to a tree, because it does both the check and the result without any functions in between to hook into... You could maybe do it by replacing self.accessible_tech_trees with a proxy table that has a metatable so you can intercept the assignment? That's pretty gross, though.

--NB: No bonuses for custom tech trees! //star

--But we still to check if player goes away (over time).
local prototyper = _G.require "components/prototyper"
local old_TurnOn = prototyper.TurnOn
function prototyper:TurnOn(doer, ...)
	if doer.task_custom_tech then
		doer.task_custom_tech:Cancel()
	end
	doer.task_custom_tech = doer:DoTaskInTime(1.5,function(player)
		local trees_changed = false
		local tech_tree = player.components.builder.accessible_tech_trees
		for tech_name, _ in pairs(db_new_techs) do
			if tech_tree ~= nil and tech_tree[tech_name] ~= nil and tech_tree[tech_name] > 0 then
				trees_changed = true
				tech_tree[tech_name] = 0
			end
		end
		if trees_changed then
			player:PushEvent("techtreechange", {level = tech_tree})
			player.replica.builder:SetTechTrees(tech_tree)
		end
		player.task_custom_tech = nil
	end)
	return old_TurnOn(self,doer, ...)
end



--3) components/builder_replica has Setters and Getters for each tree's intrinsic bonuses, these are called later in recipepopup

local replica = _G.require "components/builder_replica"
local old_SetTechTrees = replica.SetTechTrees
function replica:SetTechTrees(techlevels,...)
	if self.classified ~= nil then
		for tech_name,v in pairs(db_new_techs) do
			self.classified[db_new_classified[tech_name] ]:set(techlevels[tech_name] or 0)
		end
	end
	return old_SetTechTrees(self,techlevels,...)
end



--4) KnowsRecipe explicitly checks each tree in both builder and builder_replica

--No custom bonus.
--So we should just restrict custom tech trees as bonus.

local AllRecipes = _G.AllRecipes

local builder = _G.require "components/builder"
local old_KnowsRecipe = builder.KnowsRecipe
function builder:KnowsRecipe(recname)
	local result = old_KnowsRecipe(self, recname)
	if result then
		if self.freebuildmode or table.contains(self.recipes, recname) then
			return true
		end
		local recipe = AllRecipes[recname]
		for tech_name,v in pairs(db_new_techs) do
			if recipe.level[tech_name] > 0 then
				return false --no custom bonus
			end
		end
	end
	return result
end

local old_KnowsRecipe_replica = replica.KnowsRecipe
function replica:KnowsRecipe(recname)
    if self.inst.components.builder ~= nil then
        return self.inst.components.builder:KnowsRecipe(recname)
	end
	local result = old_KnowsRecipe_replica(self, recname)
	if result then
		if self.classified.isfreebuildmode:value() or 
			self.classified.recipes[recname] ~= nil and self.classified.recipes[recname]:value()
		then
			return true
		end
		local recipe = AllRecipes[recname]
		for tech_name,v in pairs(db_new_techs) do
			if recipe.level[tech_name] > 0 then
				return false --no custom bonus
			end
		end
	end
	return result
end



--5) components/prototyper constructor, self.trees.NEWTREE = 0, and have any prototyper prefabs you make increase that

AddClassPostConstruct("components/prototyper", function(this) --increase table used by :GetTechTrees function.
	this.trees = {}
	for k,v in pairs(db) do --db is already prepared for copying.
		this.trees[k] = v
	end
end)



--6) prefabs/player_classified OnTechTreesDirty checks each of them explicitly. You could add a listener for "techtreesdirty" and make your check there. Also inst.newtreelevel would need to be added.

--Need to inject in local function OnTechTreesDirty and replace it.
--Pricey hack, so should be done only once per game session.
local function PlayerClassifiedHack()
	local RegisterNetListeners_fn = inject_local(_G.Prefabs.player_classified.fn, "RegisterNetListeners")
	local OnTechTreesDirty_fn_old, var_num = inject_local(RegisterNetListeners_fn, "OnTechTreesDirty")
	local OnTechTreesDirty_fn_new = function(inst)
		for tech_name,v in pairs(db_new_techs) do
			if inst[db_new_classified[tech_name] ] == nil then
				print("error: inst."..db_new_classified[tech_name].." == nil")
			else
				inst.techtrees[tech_name] = inst[db_new_classified[tech_name] ]:value()
			end
		end
		return OnTechTreesDirty_fn_old(inst)
	end
	setupvalue(RegisterNetListeners_fn, var_num, OnTechTreesDirty_fn_new)
end
local player_classified_hacked = false
AddPrefabPostInit("world",function(w)
	if not player_classified_hacked then
		player_classified_hacked = true
		PlayerClassifiedHack()
	end
end)

--Create network variables. 
local net_tinybyte = _G.net_tinybyte
AddPrefabPostInit("player_classified",function(inst) --print("ADDPREFABPOSTINIT player_classified")
	for tech_name,v in pairs(db_new_techs) do
		inst[db_new_classified[tech_name] ] = net_tinybyte(inst.GUID, db_new_builder_name[tech_name], "techtreesdirty")
	end
end)



--7) recipe, self.level.NEWTREE = self.level.NEWTREE or 0 needs to be added, could be done by overriding Recipe._ctor, or doing an AddClassPostConstruct (maybe? the recipe.lua file doesn't return the class though, so maybe not)

AddPrefabPostInit("world",function(w) --Fixing all recipes. Just for sure.
	for rec_name, recipe in pairs(_G.AllRecipes) do
		for tree_name,_ in pairs(db_new_techs) do
			recipe.level[tree_name] = recipe.level[tree_name] or 0
		end
	end
end)



--8) tuning, PROTOTYPER_TREES needs to have each of its entries modified (although I think if you don't they should default to zero from the other changes)

-- (+) Done in AddTechLevel().

--9) widgets/recipepopup GetHintTextForRecipe takes into account player intrinsic bonuses to trees for the help text. This looks like it might need to be overridden

local save_hint_recipe

--We need just a link to recipe.
do
	local recipepopup = _G.require "widgets/recipepopup"
	local RecipePopup_Refresh_fn = recipepopup.Refresh
	local old_GetHintTextForRecipe, num_var = inject_local(RecipePopup_Refresh_fn,"GetHintTextForRecipe")
	if old_GetHintTextForRecipe then
		setupvalue(RecipePopup_Refresh_fn, num_var, function(player, recipe)
			save_hint_recipe = recipe
			return old_GetHintTextForRecipe(player, recipe)
		end)
	end
end

--Here we can use the link. 
local CRAFTING = _G.STRINGS.UI.CRAFTING --See STRINGS.UI.CRAFTING.NEEDSCIENCEMACHINE
AddClassPostConstruct("widgets/recipepopup",function(self)
	local old_SetString = self.teaser.SetString
	function self.teaser:SetString(str)
		--print("Show text",str,tostring(save_hint_recipe))
		if str == "Text not found." and save_hint_recipe ~= nil  then --Probably custom recipe
			local custom_tech, custom_level
			for tech_name, _ in pairs(db_new_techs) do --Check if it's really custom.
				custom_level = save_hint_recipe.level[tech_name]
				if custom_level > 0 then
					custom_tech = tech_name
					break
				end
			end
			if custom_tech then
				str = CRAFTING[saved_tech_names[custom_tech][custom_level] ] or str
			end
		end
		return old_SetString(self,str)
	end
end)



--Main function of the lib.
function AddNewTechTree(newtree_name, num_levels)
	UpdateDB(newtree_name) --update local tables
	AddNewTechConstants(newtree_name) --_G.TECH.NEWTREE
	num_levels = num_levels or 1
	for i = 1, num_levels do --_G.TECH.NEWTREE_ONE and TUNING.PROTOTYPER_TREES.NEWTREE_ONE, two, three etc.
		AddTechLevel(newtree_name, i)
	end
end

--Global define
_G.aipAddNewTechTree = AddNewTechTree