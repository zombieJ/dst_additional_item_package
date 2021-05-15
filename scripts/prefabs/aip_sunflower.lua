-- 食物
local additional_food = aipGetModConfig("additional_food")
if additional_food ~= "open" then
	return nil
end

-- 开发模式
local dev_mode = aipGetModConfig("dev_mode") == "enabled"

local language = aipGetModConfig("language")

local LANG_MAP = {
	["english"] = {
		["NAME"] = "Sun Tree",
		["DESC"] = "What happened?",
	},
	["chinese"] = {
		["NAME"] = "向日树",
		["DESC"] = "它是怎么长出来的？",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

-- 文字描述
STRINGS.NAMES.AIP_SUNFLOWER = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_SUNFLOWER = LANG.DESC

local assets =
{
    Asset("ANIM", "anim/aip_sunflower.zip"),
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
		local tgt = aipReplacePrefab(inst, "aip_sunflower_"..inst._aip_next)
		tgt.AnimState:PlayAnimation("grow_"..inst._aip_now.."_post", false)
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

    local he_right = true

    if chopper then
        local hispos = chopper:GetPosition()
        he_right = (hispos - pt):Dot(TheCamera:GetRightVec()) > 0
    else
        if math.random() > 0.5 then
            he_right = false
        end
    end

    if he_right then
        inst.AnimState:PlayAnimation("fallleft_"..inst._aip_stage)
        inst.components.lootdropper:DropLoot(pt - TheCamera:GetRightVec())
    else
        inst.AnimState:PlayAnimation("fallright_"..inst._aip_stage)
        inst.components.lootdropper:DropLoot(pt + TheCamera:GetRightVec())
    end

	inst:DoTaskInTime(0.6, chop_down_shake)

	inst:ListenForEvent("animover", inst.Remove)
end

--------------------------------- 鬼树 ---------------------------------
local function chop_ghost(inst, chopper)
    if not (chopper ~= nil and chopper:HasTag("playerghost")) then
		inst.SoundEmitter:PlaySound("dontstarve/creatures/leif/livingtree_hit")
    end

	inst.AnimState:PlayAnimation("chop_"..inst._aip_stage)
	inst.AnimState:PushAnimation("idle_"..inst._aip_stage, true)
end

local function chop_down_ghost(inst, chopper)
	inst.SoundEmitter:PlaySound("dontstarve/creatures/leif/livingtree_die")

	inst.AnimState:PlayAnimation("fall_"..inst._aip_stage)
	inst.components.lootdropper:DropLoot()

	-- 开启公测后创造一个鬼怪出来
	local effect = aipSpawnPrefab(inst, "aip_shadow_wrapper")
	effect.Transform:SetScale(2, 2, 2)
	effect.DoShow()

	aipSpawnPrefab(inst, "aip_dragon")

	inst:ListenForEvent("animover", inst.Remove)
end

------------------------------- 阶段函数 -------------------------------
local function sunflower(stage, info)
	local name = "aip_sunflower_"..stage
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
		inst:AddTag("aip_sunflower")

		if info.tag ~= nil then
			inst:AddTag(info.tag)
		end

		inst.AnimState:SetBuild("aip_sunflower")
		inst.AnimState:SetBank("aip_sunflower")
		inst.AnimState:PlayAnimation("idle_"..stage, true)

		-- 原生的雪景覆盖没有定位信息，我们只能自己实现了
		inst:AddTag("SnowCovered")
		inst.AnimState:Hide("snow")


		inst.entity:SetPristine()

		if not TheWorld.ismastersim then
			return inst
		end

		-- 微调颜色
		local color = .5 + math.random() * .5
		inst.AnimState:SetMultColour(color, color, color, 1)

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

		MakeSnowCovered(inst)

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
		aipReplacePrefab(inst, "aip_sunflower_tall")
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
		loot = {"twigs"},
		grow = {
			next = "tall",
			time = dev_mode and 3 or (TUNING.DAY_TIME_DEFAULT * 3),
		}
	},
	tall = {
		physics = .25,
		tag = "aip_sunflower_tall",
		workable = {
			times = TUNING.EVERGREEN_CHOPS_NORMAL,
			action = ACTIONS.CHOP,
			callback = chop_tree,
			finishCallback = chop_down_tree,
		},
		loot = {"log", "log","aip_veggie_sunflower"}
	},
	ghost = {
		physics = .25,
		workable = {
			times = TUNING.EVERGREEN_CHOPS_NORMAL,
			action = ACTIONS.CHOP,
			callback = chop_ghost,
			finishCallback = chop_down_ghost,
		},
		loot = {"nightmarefuel"}
	},
}
local prefabs = {
	Prefab("aip_sunflower", fn, assets)
}

for stage, info in pairs(PLANTS) do
	table.insert(prefabs, sunflower(stage, info))
end

return unpack(prefabs)

--[[

c_give"aip_veggie_sunflower"
c_give"birdcage"
c_give"robin_winter"


c_give"aip_sunflower_ghost"

c_give"axe"


c_give"aip_sunflower"





TheWorld:PushEvent("snowcoveredchanged", true)



TheWorld:PushEvent("ms_setseason", "spring")



TheWorld:PushEvent("ms_setseason", "autumn")

]]