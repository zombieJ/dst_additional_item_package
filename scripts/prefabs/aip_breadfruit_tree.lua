-- 食物
local additional_food = aipGetModConfig("additional_food")
if additional_food ~= "open" then
	return nil
end

-- 开发模式
local dev_mode = aipGetModConfig("dev_mode") == "enabled"

local language = aipGetModConfig("language")

local LANG_MAP = {
	english = {
		NAME = "Breadfruit Tree",
		DESC = "Full of fruit aroma",
	},
	chinese = {
		NAME = "面包树",
		DESC = "充满了水果香气",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

-- 文字描述
STRINGS.NAMES.AIP_BREADFRUIT_TREE = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_BREADFRUIT_TREE = LANG.DESC

local assets = {
    Asset("ANIM", "anim/aip_breadfruit_tree.zip"),
}

------------------------------- 幼苗阶段 -------------------------------
local function dig_tree(inst, digger)
	inst.components.lootdropper:DropLoot(inst:GetPosition())
	inst:Remove()
end

local function growNext(inst)
	inst.AnimState:PlayAnimation("grow_"..inst._aip_now.."_pre")
	inst.SoundEmitter:PlaySound("dontstarve/forest/treeGrow")

	inst:ListenForEvent("animover", function()
		local tgt = aipReplacePrefab(inst, "aip_breadfruit_tree_"..inst._aip_next)
		tgt.AnimState:PlayAnimation("grow_"..inst._aip_now.."_pst", false)
		tgt.AnimState:PushAnimation("idle_"..inst._aip_next, true)
	end)
end

------------------------------- 成熟阶段 -------------------------------
local function chop_tree(inst, chopper)
    if not (chopper ~= nil and chopper:HasTag("playerghost")) then
        inst.SoundEmitter:PlaySound(
            chopper ~= nil and chopper:HasTag("beaver") and
            "dontstarve/characters/woodie/beaver_chop_tree" or
            "dontstarve/wilson/use_axe_tree"
        )
    end

	inst.AnimState:PlayAnimation("chop_"..inst._aip_stage)
	inst.AnimState:PushAnimation("idle_"..inst._aip_stage, true)
end

-- 晃动镜头
local function chop_down_shake(inst)
    ShakeAllCameras(CAMERASHAKE.FULL, .25, .025, .14, inst, 6)
end

-- 按照角度砍倒树木
local function chop_down_tree(inst, chopper)
	inst.SoundEmitter:PlaySound("dontstarve/forest/treefall")
	local pt = inst:GetPosition()

	inst.AnimState:PlayAnimation("fall_"..inst._aip_stage)
	inst.components.lootdropper:DropLoot(pt - TheCamera:GetRightVec())

	inst:DoTaskInTime(0.6, chop_down_shake)

	inst:ListenForEvent("animover", inst.Remove)
end

------------------------------- 可以收获 -------------------------------
local function refreshFruit(inst)
	aipPrint("Refresh:", inst.components.pickable:CanBePicked())
	if inst.components.pickable:CanBePicked() then
		inst.AnimState:Show("bread")
	else
		inst.AnimState:Hide("bread")
	end
end

local function getRegenTime(inst)
	aipPrint("Get Regren Time:", inst.components.pickable)
	if inst.components.pickable == nil then
		return TUNING.BERRY_REGROW_TIME
	end

	local time = dev_mode and 3 or TUNING.BERRY_REGROW_TIME + TUNING.BERRY_REGROW_VARIANCE * math.random()
	aipPrint("Regren Time:", time)

	return time
end

local function onpickedfn(inst, picker)
	aipPrint("Pick")
	refreshFruit(inst)
end

local function makeemptyfn(inst)
	aipPrint("Empty")
	refreshFruit(inst)
end

local function makefullfn(inst)
	aipPrint("Full")
	refreshFruit(inst)
end

------------------------------- 阶段函数 -------------------------------
local function refreshScale(inst)
	inst.aipScale = inst.aipScale or (1 + math.random() * .3)
	inst.Transform:SetScale(inst.aipScale, inst.aipScale, inst.aipScale)
end

-- 存取
local function onSave(inst, data)
	data.aipScale = inst.aipScale
end

local function onLoad(inst, data)
	if data ~= nil then
		inst.aipScale = data.aipScale
		refreshScale(inst)
	end
end

local function genTree(stage, info)
	local name = "aip_breadfruit_tree_"..stage
	local uname = string.upper(name)

	STRINGS.NAMES[uname] = LANG.NAME
	STRINGS.CHARACTERS.GENERIC.DESCRIBE[uname] = LANG.DESC

	local function fn()
		local inst = CreateEntity()

		inst._aip_stage = stage

		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddSoundEmitter()
		inst.entity:AddMiniMapEntity()
		inst.entity:AddNetwork()

		if info.physics ~= nil then
			MakeObstaclePhysics(inst, info.physics)
		end

		inst.MiniMapEntity:SetIcon("twiggy.png")

		inst.MiniMapEntity:SetPriority(-1)

		inst:AddTag("plant")
		inst:AddTag("tree")
		inst:AddTag("aip_breadfruit_tree")

		if info.tag ~= nil then
			inst:AddTag(info.tag)
		end

		inst.AnimState:SetBuild("aip_breadfruit_tree")
		inst.AnimState:SetBank("aip_breadfruit_tree")
		inst.AnimState:PlayAnimation("idle_"..stage, true)

		-- 原生的雪景覆盖没有定位信息，我们只能自己实现了
		inst:AddTag("SnowCovered")
		inst.AnimState:Hide("snow")

		inst.entity:SetPristine()

		if not TheWorld.ismastersim then
			return inst
		end

		-- 微调颜色
		local c1 = .7 + math.random() * .3
		local c2 = .7 + math.random() * .3
		local c3 = .7 + math.random() * .3
		inst.AnimState:SetMultColour(c1, c2, c3, 1)

		-- 燃烧
		MakeLargeBurnable(inst, TUNING.TREE_BURN_TIME)
		MakeMediumPropagator(inst)

		-- 可检查
		inst:AddComponent("inspectable")

		-- 工作狂
		inst:AddComponent("workable")
		inst.components.workable:SetWorkLeft(info.workable.times)
		inst.components.workable:SetWorkAction(info.workable.action)
		inst.components.workable:SetOnWorkCallback(info.workable.callback)
		inst.components.workable:SetOnFinishCallback(info.workable.finishCallback)

		-- 掉东西
		inst:AddComponent("lootdropper")
		inst.components.lootdropper:SetLoot(info.loot)

		-- 可成长
		if info.grow then
			inst:AddComponent("aipc_weak_timer")
			inst._aip_now = stage
			inst._aip_next = info.grow.next
			inst.components.aipc_weak_timer:Start(info.grow.time, growNext)
		end

		if info.pickable then
			inst:AddComponent("pickable")
			inst.components.pickable.picksound = "dontstarve/wilson/harvest_berries"

			inst.components.pickable:SetUp(info.pickable.prefab, 5)
			inst.components.pickable.getregentimefn = getRegenTime
			-- inst.components.pickable.max_cycles = TUNING.BERRYBUSH_CYCLES + math.random(2)
			-- inst.components.pickable.cycles_left = inst.components.pickable.max_cycles 无限采收

			inst.components.pickable.onpickedfn = onpickedfn
			inst.components.pickable.makeemptyfn = makeemptyfn
			-- inst.components.pickable.makebarrenfn = makebarrenfn
			inst.components.pickable.makefullfn = makefullfn
			-- inst.components.pickable.ontransplantfn = ontransplantfn
			refreshFruit(inst)
		end

		refreshScale(inst)

		MakeSnowCovered(inst)

		inst.OnLoad = onLoad
		inst.OnSave = onSave

		return inst
	end

	return Prefab(name, fn, assets)
end

---------------------------------- 树 ----------------------------------
local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddMiniMapEntity()
	inst.entity:AddNetwork()

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:DoTaskInTime(0, function()
		aipReplacePrefab(inst, "aip_breadfruit_tree_tall")
	end)

	return inst
end

--------------------------------- 遍历 ---------------------------------

local PLANTS = {
	short = {
		workable = {
			times = 1,
			action = ACTIONS.DIG,
			finishCallback = dig_tree,
		},
		loot = {"spoiled_food"},
		grow = {
			next = "mid",
			time = dev_mode and 3 or (TUNING.DAY_TIME_DEFAULT * 2),
		}
	},
	mid = {
		physics = .2,
		workable = {
			times = TUNING.EVERGREEN_CHOPS_NORMAL,
			action = ACTIONS.CHOP,
			callback = chop_tree,
			finishCallback = chop_down_tree,
		},
		loot = {"log"},
		grow = {
			next = "tall",
			time = dev_mode and 3 or (TUNING.DAY_TIME_DEFAULT * 3),
		}
	},
	tall = {
		physics = .25,
		-- tag = "aip_sunflower_tall",
		workable = {
			times = TUNING.EVERGREEN_CHOPS_TALL,
			action = ACTIONS.CHOP,
			callback = chop_tree,
			finishCallback = chop_down_tree,
		},
		pickable = {
			prefab = "ash",
		},
		loot = {"log", "log", "log"}
	},
}
local prefabs = {
	Prefab("aip_breadfruit_tree", fn, assets)
}

for stage, info in pairs(PLANTS) do
	table.insert(prefabs, genTree(stage, info))
end

return unpack(prefabs)

--[[

c_give"aip_breadfruit_tree"
c_give"axe"

TheWorld:PushEvent("snowcoveredchanged", true)

c_give"aip_breadfruit_tree_short"

]]
