-- 配置
local additional_building = aipGetModConfig("additional_building")
if additional_building ~= "open" then
	return nil
end

local language = aipGetModConfig("language")

--[[
	TODO:!!!!
可以存储 30 格木头，不会被烧毁，有一个祭祀按钮。随机消耗 5 ~ 20 根木头，产生特殊的事件：
5~10格：
	恢复生命值/饥饿值/理智值中的一项50点
	掉落8~15花/4~7蘑菇/3~5种子/3~8树种
	什么都不发生
11~16格：
	掉落1~2活木/黄金/石头
	召唤一个低级树人
17~20格：
	恢复3值各50点
	掉落1齿轮/1蓝or红宝石
	树木精华（每秒恢复15点生命/理智并发光持续30s），会腐坏
	树木糟粕（每3s脚下生成1朵恶魔花并减少20点理智持续30s），不会坏
]]

local LANG_MAP = {
	["english"] = {
		["NAME"] = "Log Temple",
		["DESC"] = "Burn everything into ash!",
		["DESCRIBE"] = "Why we do not just burn the home to make ash?",
		["ACTIONFAIL"] = {
			["GENERIC"] = "Hmmm, finally find something can't burn",
			["WAXWELL"] = "Hmmm, finally find something can't burn",
			["WOLFGANG"] = "Hmmm, finally find something can't burn",
			["WX78"] = "Hmmm, finally find something can't burn",
			["WILLOW"] = "Hmmm, finally find something can't burn",
			["WENDY"] = "Hmmm, finally find something can't burn",
			["WOODIE"] = "Hmmm, finally find something can't burn",
			["WICKERBOTTOM"] = "Hmmm, finally find something can't burn",
			["WATHGRITHR"] = "Hmmm, finally find something can't burn",
			["WEBBER"] = "Hmmm, finally find something can't burn",
		},
	},
	["chinese"] = {
		["NAME"] = "木之祭祀",
		["DESC"] = "把一切都烧成灰！",
		["DESCRIBE"] = "想要灰为什么不直接烧家？",
		["ACTIONFAIL"] = {
			["GENERIC"] = "这东西看来烧不掉",
			["WAXWELL"] = "终于有烧不掉的东西了",
			["WOLFGANG"] = "它吃不下它！",
			["WX78"] = "错误的参数",
			["WILLOW"] = "不能燃烧的东西有什么意义！",
			["WENDY"] = "火焰也不能带走它的美丽",
			["WOODIE"] = "看来烧不掉",
			["WICKERBOTTOM"] = "烧不掉就赞美它",
			["WATHGRITHR"] = "它无法变成离子态",
			["WEBBER"] = "无法燃烧的恐惧",
			["WINONA"] = "总有事情无法挑战",
		},
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

-- 文字描述
STRINGS.NAMES.INCINERATOR = LANG.NAME
STRINGS.RECIPE_DESC.INCINERATOR = LANG.DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.INCINERATOR = LANG.DESCRIBE

STRINGS.CHARACTERS.GENERIC.ACTIONFAIL.GIVE.INCINERATOR_NOT_BURN = LANG.ACTIONFAIL.GENERIC
STRINGS.CHARACTERS.WAXWELL.ACTIONFAIL.GIVE.INCINERATOR_NOT_BURN = LANG.ACTIONFAIL.WAXWELL or LANG.ACTIONFAIL.GENERIC
STRINGS.CHARACTERS.WOLFGANG.ACTIONFAIL.GIVE.INCINERATOR_NOT_BURN = LANG.ACTIONFAIL.WOLFGANG or LANG.ACTIONFAIL.GENERIC
STRINGS.CHARACTERS.WX78.ACTIONFAIL.GIVE.INCINERATOR_NOT_BURN = LANG.ACTIONFAIL.WX78 or LANG.ACTIONFAIL.GENERIC
STRINGS.CHARACTERS.WILLOW.ACTIONFAIL.GIVE.INCINERATOR_NOT_BURN = LANG.ACTIONFAIL.WILLOW or LANG.ACTIONFAIL.GENERIC
STRINGS.CHARACTERS.WENDY.ACTIONFAIL.GIVE.INCINERATOR_NOT_BURN = LANG.ACTIONFAIL.WENDY or LANG.ACTIONFAIL.GENERIC
STRINGS.CHARACTERS.WOODIE.ACTIONFAIL.GIVE.INCINERATOR_NOT_BURN = LANG.ACTIONFAIL.WOODIE or LANG.ACTIONFAIL.GENERIC
STRINGS.CHARACTERS.WICKERBOTTOM.ACTIONFAIL.GIVE.INCINERATOR_NOT_BURN = LANG.ACTIONFAIL.WICKERBOTTOM or LANG.ACTIONFAIL.GENERIC
STRINGS.CHARACTERS.WATHGRITHR.ACTIONFAIL.GIVE.INCINERATOR_NOT_BURN = LANG.ACTIONFAIL.WATHGRITHR or LANG.ACTIONFAIL.GENERIC
STRINGS.CHARACTERS.WEBBER.ACTIONFAIL.GIVE.INCINERATOR_NOT_BURN = LANG.ACTIONFAIL.WEBBER or LANG.ACTIONFAIL.GENERIC
STRINGS.CHARACTERS.WINONA.ACTIONFAIL.GIVE.INCINERATOR_NOT_BURN = LANG.ACTIONFAIL.WINONA or LANG.ACTIONFAIL.GENERIC

-- 配方
local incinerator = Recipe("incinerator", {Ingredient("rocks", 5), Ingredient("twigs", 2), Ingredient("ash", 1)}, RECIPETABS.LIGHT, TECH.SCIENCE_ONE, "incinerator_placer")
incinerator.atlas = "images/inventoryimages/incinerator.xml"

-----------------------------------------------------------------------
require "prefabutil"

local assets =
{
	Asset("ANIM", "anim/incinerator.zip"),
	Asset("ATLAS", "images/inventoryimages/incinerator.xml"),
	Asset("IMAGE", "images/inventoryimages/incinerator.tex"),
}

local prefabs =
{
	"campfirefire",
	"collapse_small",
	"ash",
}

local function onBurnItems(inst)
	local hasItems = false
	local returnItems = {}

	-- 计算生产的物料
	if inst.components.aipc_action and inst.components.container then
		local ings = {}
		for k, item in pairs(inst.components.container.slots) do
			local stackSize = item.components.stackable and item.components.stackable:StackSize() or 1
			local lootItem = "ash"

			-- 根据马头剩余耐久度概率提供谜之声帽
			if item.prefab == "aip_horse_head" and item.components.fueled then
				local ptg = item.components.fueled:GetPercent()
				ptg = ptg * ptg * 0.9
				if ptg >= math.random() then
					lootItem = "aip_som"
				end
			end

			returnItems[lootItem] = (returnItems[lootItem] or 0) + stackSize
			hasItems = true
		end
	end

	-- 掉东西咯
	if hasItems then
		inst.AnimState:PlayAnimation("consume")
		inst.AnimState:PushAnimation("idle", false)
		inst.SoundEmitter:PlaySound("dontstarve/common/fireAddFuel")

		for prefab, prefabCount in pairs(returnItems) do
			local currentCount = prefabCount
			local loot = inst.components.lootdropper:SpawnLootPrefab(prefab)
			local lootMaxSize = 1

			if loot.components.stackable then
				lootMaxSize = loot.components.stackable.maxsize
			end
			loot:Remove()

			-- 批量掉落
			while(currentCount > 0)
			do
				local dropCount = math.min(currentCount, lootMaxSize)
				local dropLootItem = inst.components.lootdropper:SpawnLootPrefab(prefab)
				if dropLootItem.components.stackable then
					dropLootItem.components.stackable:SetStackSize(dropCount)
				end

				currentCount = currentCount - dropCount
			end
		end

		inst.components.container:Close()
		inst.components.container:DestroyContents()

		inst.components.burnable:Extinguish()
		inst:DoTaskInTime(0, function ()
			inst.components.burnable:Ignite()
			inst.components.burnable:SetFXLevel(1)
		end)
	end
end

-- 火焰者
local function onextinguish(inst)
end

-- 建筑
local function onhammered(inst, worker)
	inst.components.lootdropper:DropLoot()
	local x, y, z = inst.Transform:GetWorldPosition()
	SpawnPrefab("ash").Transform:SetPosition(x, y, z)
	local fx = SpawnPrefab("collapse_small")
	fx.Transform:SetPosition(x, y, z)
	fx:SetMaterial("stone")
	inst:Remove()
end

local function onhit(inst, worker)
	inst.AnimState:PlayAnimation("hit")
	inst.AnimState:PushAnimation("idle")
end

local function onbuilt(inst)
	inst.AnimState:PlayAnimation("place")
	inst.AnimState:PushAnimation("idle", false)
	inst.SoundEmitter:PlaySound("dontstarve/common/fireAddFuel")
end

local function OnInit(inst)
	if inst.components.burnable ~= nil then
		inst.components.burnable:FixFX()
	end
end

local function fn()
	local inst = CreateEntity()
	
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	-- 碰撞体积
	MakeObstaclePhysics(inst, .3)

	-- 动画
	inst.AnimState:SetBank("incinerator")
	inst.AnimState:SetBuild("incinerator")
	inst.AnimState:PlayAnimation("idle", false)

	-- 标签
	inst:AddTag("structure")

	MakeSnowCoveredPristine(inst)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	-- 可燃烧
	inst:AddComponent("burnable")
	inst.components.burnable:AddBurnFX("fire", Vector3(0, 0.3, 0) )
	inst.components.burnable:SetBurnTime(10)
	inst:ListenForEvent("onextinguish", onextinguish)

	-- 容器
	inst:AddComponent("container")
	inst.components.container:WidgetSetup("incinerator")

	-- 烹饪
	inst:AddComponent("aipc_action")
	inst.components.aipc_action.onDoAction = onBurnItems


	-- 掉东西
	inst:AddComponent("lootdropper")

	-- 被锤子
	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
	inst.components.workable:SetWorkLeft(4)
	inst.components.workable:SetOnFinishCallback(onhammered)
	inst.components.workable:SetOnWorkCallback(onhit)

	-- 可伤害
	inst:AddComponent("hauntable")
	inst.components.hauntable.cooldown = TUNING.HAUNT_COOLDOWN_HUGE

	-- 可检查
	inst:AddComponent("inspectable")

	inst:ListenForEvent("onbuilt", onbuilt)
	inst:DoTaskInTime(0, OnInit)

	return inst
end

return Prefab("incinerator", fn, assets, prefabs),
	MakePlacer("incinerator_placer", "incinerator", "incinerator", "idle")