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

------------------------------- 不同阶段 -------------------------------
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

local function chop_down_tree(inst, chopper)
	inst.SoundEmitter:PlaySound("dontstarve/forest/treefall")
end

local function sunflower(stage)
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

		MakeObstaclePhysics(inst, .25)

		inst.MiniMapEntity:SetIcon("twiggy.png")

		inst.MiniMapEntity:SetPriority(-1)

		inst:AddTag("plant")
		inst:AddTag("tree")

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
		inst.components.workable:SetWorkAction(ACTIONS.CHOP)
		inst.components.workable:SetOnWorkCallback(chop_tree)
		inst.components.workable:SetOnFinishCallback(chop_down_tree)

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

local PLANTS = { "tall" }
local prefabs = {
	Prefab("aip_sunflower", fn, assets)
}

for i, stage in ipairs(PLANTS) do
	table.insert(prefabs, sunflower(stage))
end

return unpack(prefabs)

--[[




c_give"aip_sunflower"




TheWorld:PushEvent("snowcoveredchanged", true)






TheWorld:PushEvent("ms_setseason", "winter")




TheWorld:PushEvent("snowcoveredchanged", true)


]]