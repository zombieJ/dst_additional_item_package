local foldername = KnownModIndex:GetModActualName(TUNING.ZOMBIEJ_ADDTIONAL_PACKAGE)

------------------------------------ 配置 ------------------------------------
-- 建筑关闭
local additional_building = aipGetModConfig("additional_building")
if additional_building ~= "open" then
	return nil
end

-- 食物关闭
local additional_food = aipGetModConfig("additional_food")
if additional_food ~= "open" then
	return nil
end

local language = aipGetModConfig("language")

local LANG_MAP = {
	["english"] = {
		["NAME"] = "Greedy Observer",
		["DESC"] = "Show the boss position",
		["DESCRIBE"] = "No 'PAY' no gain",
	},
	["spanish"] = {
		["NAME"] = "El Observador Avariento",
		["DESC"] = "Muestra la posición de los enemigos tipo jefe",
		["DESCRIBE"] = "El que algo queire, algo le CUESTA",
	},
	["russian"] = {
		["NAME"] = "Жадный Наблюдатель",
		["DESC"] = "Показывает местоположение босса",
		["DESCRIBE"] = "Нет платы - нет помощи.",
	},
	["portuguese"] = {
		["NAME"] = "Observador ganancioso",
		["DESC"] = "Mostra a posição do chefão",
		["DESCRIBE"] = "Sem comprar sem ganhar",
	},
	["korean"] = {
		["NAME"] = "탐욕스런 관찰자",
		["DESC"] = "보스 몬스터의 위치를 보여줘",
		["DESCRIBE"] = "’대가’없이 얻을 수 있는 건 없는 법이지",
	},
	["chinese"] = {
		["NAME"] = "贪婪观察者",
		["DESC"] = "显示Boss的坐标",
		["DESCRIBE"] = "没有付出就没有提示",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

-- 文字描述
STRINGS.NAMES.DARK_OBSERVER = LANG.NAME
STRINGS.RECIPE_DESC.DARK_OBSERVER = LANG.DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.DARK_OBSERVER = LANG.DESCRIBE

-----------------------------------------------------------
require "prefabutil"

local assets =
{
	Asset("ANIM", "anim/dark_observer.zip"),
	Asset("ATLAS", "images/inventoryimages/dark_observer.xml"),
	Asset("IMAGE", "images/inventoryimages/dark_observer.tex"),
}

local prefabs =
{
	"collapse_small",
	"dark_observer_vest",
}

-- 观察者
local function StopWatching(inst)
	if inst and inst:HasTag("observerWatching") then
		TheWorld.components.world_common_store.shadow_follower_count = TheWorld.components.world_common_store.shadow_follower_count - 1

		inst:RemoveTag("observerWatching")
		inst.AnimState:PlayAnimation("spell_end")
		inst.AnimState:PushAnimation("idle", false)
	end
end

-- 交易者
local function AcceptTest(inst, item)
	local is_event_item = IsSpecialEventActive(SPECIAL_EVENTS.HALLOWED_NIGHTS) and item.components.tradable.halloweencandyvalue and item.components.tradable.halloweencandyvalue > 0
	return item.components.tradable.goldvalue > 0 or is_event_item or item.prefab == "goldnugget"
end

local function OnGetItemFromPlayer(inst, giver, item)
	inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/bearger/groundpound")

	-- 更新状态
	if not inst:HasTag("observerWatching") then
		inst.AnimState:PlayAnimation("spell_start")
		inst.AnimState:PushAnimation("spell_ing", true)
		TheWorld.components.world_common_store.shadow_follower_count = TheWorld.components.world_common_store.shadow_follower_count + 1
	end
	inst:AddTag("observerWatching")
	inst.__inner_id = inst.__inner_id + 1
	local my_id = inst.__inner_id

	inst:DoTaskInTime(60, function()
		-- 如果已经被接管，则跳过
		if inst.__inner_id ~= my_id then
			return
		end

		-- 取消关注
		StopWatching(inst)
	end)
end

local function OnRefuseItem(inst, giver, item)
	inst.SoundEmitter:PlaySound("dontstarve/pig/PigKingReject")

	if not inst:HasTag("observerWatching") then
		inst.AnimState:PlayAnimation("unimpressed")
		inst.AnimState:PushAnimation("idle", false)
	end
end

-- 工作狂
local function onhammered(inst, worker)
	if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
		inst.components.burnable:Extinguish()
	end
	inst.components.lootdropper:DropLoot()
	local fx = SpawnPrefab("collapse_small")
	fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
	fx:SetMaterial("wood")
	inst:Remove()
end

local function onhit(inst, worker)
	if not inst:HasTag("burnt") then
		if inst:HasTag("observerWatching") then
			-- 取消关注
			StopWatching(inst)
		else
			inst.AnimState:PlayAnimation("hit")
			inst.AnimState:PushAnimation("idle", false)
		end
	end
end

-- 建筑
local function onbuilt(inst)
	inst.AnimState:PlayAnimation("place")
	inst.AnimState:PushAnimation("idle", false)
	inst.SoundEmitter:PlaySound("dontstarve/common/sign_craft")
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
	MakeObstaclePhysics(inst, .2)

	-- 动画
	inst.AnimState:SetBank("dark_observer")
	inst.AnimState:SetBuild("dark_observer")
	inst.AnimState:PlayAnimation("idle", false)

	-- 标签
	inst:AddTag("structure")

	MakeSnowCoveredPristine(inst)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	-- 可燃烧
	MakeMediumBurnable(inst)

	-- 可交易
	inst:AddComponent("trader")
	inst.components.trader:SetAcceptTest(AcceptTest)
	inst.components.trader.onaccept = OnGetItemFromPlayer
	inst.components.trader.onrefuse = OnRefuseItem
	inst.__inner_id = 0

	-- 掉东西
	inst:AddComponent("lootdropper")

	-- 被锤子
	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
	inst.components.workable:SetWorkLeft(4)
	inst.components.workable:SetOnFinishCallback(onhammered)
	inst.components.workable:SetOnWorkCallback(onhit)

	-- 可伤害
	MakeHauntableWork(inst)
	inst.components.hauntable:SetOnHauntFn(function(inst, haunter)
		StopWatching(inst)
		return false
	end)

	-- 可检查
	inst:AddComponent("inspectable")

	inst:ListenForEvent("onbuilt", onbuilt)
	inst:ListenForEvent("onremove", function()
		StopWatching(inst)
	end)
	inst:DoTaskInTime(0, OnInit)

	return inst
end

return Prefab("dark_observer", fn, assets, prefabs),
	MakePlacer("dark_observer_placer", "dark_observer", "dark_observer", "idle")