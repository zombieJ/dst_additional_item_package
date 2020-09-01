------------------------------------ 配置 ------------------------------------
-- 矿车关闭
local additional_orbit = aipGetModConfig("additional_orbit")
if additional_orbit ~= "open" then
	return nil
end

local language = aipGetModConfig("language")

local LANG_MAP = {
	english = {
		NAME = "Minecart",
		REC_DESC = "Can drive on orbit with usage limit",
		DESC = "Where will we go?",
		leaveTips = "press 'X' to leave minecart",
	},
	chinese = {
		NAME = "矿车",
		REC_DESC = "有限次数的轨道矿车",
		DESC = "登船靠岸停稳！~",
		leaveTips = "按'X'键离开矿车",
	},
	russian = {
		NAME = "Вагонетка",
		REC_DESC = "Персональный мини-вагончик",
		DESC = "Куда мы поедем?",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english
local LANG_ENG = LANG_MAP.english

-- 资源
local assets =
{
	Asset("ATLAS", "images/inventoryimages/aip_mine_car.xml"),
	Asset("IMAGE", "images/inventoryimages/aip_mine_car.tex"),
	Asset("ANIM", "anim/aip_mine_car.zip"),
}

local prefabs =
{
}

-- 开发模式
local dev_mode = aipGetModConfig("dev_mode") == "enabled"

-- 文字描述
STRINGS.NAMES.AIP_MINE_CAR = LANG.NAME
STRINGS.RECIPE_DESC.AIP_MINE_CAR = LANG.REC_DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_MINE_CAR = LANG.DESC
STRINGS.AIP.AIP_MINECART_LEAVE = LANG.leaveTips or LANG_ENG.leaveTips

-- 使用次数
TUNING.AIP_MINE_CAR_USAGE = dev_mode and 3 or 8
local speedMulti = dev_mode and 0.1 or 2

-- 配方
local aip_mine_car = Recipe("aip_mine_car", {Ingredient("boards", 5)}, RECIPETABS.SURVIVAL, TECH.SCIENCE_ONE)
aip_mine_car.atlas = "images/inventoryimages/aip_mine_car.xml"

-------------------------------------- 实体 --------------------------------------
-- 锤子
local function onhammered(inst, worker)
	inst.components.lootdropper:DropLoot()
	local x, y, z = inst.Transform:GetWorldPosition()
	local fx = SpawnPrefab("collapse_small")
	fx.Transform:SetPosition(x, y, z)
	fx:SetMaterial("wood")
	inst:Remove()
end

local function onhit(inst, worker)
	inst.AnimState:PlayAnimation("hit")
	inst.AnimState:PushAnimation("idle")
end

-- 矿车重置高度
local function resetCarPosition(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	inst.Transform:SetPosition(x, 0.9, z)
end

-- 保存
local function onsave(inst, data)
	if inst.components.inventoryitem and not inst.components.inventoryitem.canbepickedup then
		data.status = "placed"
	end
end

-- 载入
local function onload(inst, data)
	if data ~= nil and data.status == "placed" and inst.components.inventoryitem then
		inst.components.inventoryitem.canbepickedup = false

		resetCarPosition(inst)
	end
end

-- 初始化
local function onInit(inst)
	if inst.components.inventoryitem and inst.components.inventoryitem.canbepickedup == false then
		resetCarPosition(inst)
	end
end

local function onPlaced(inst)
	inst.AnimState:PlayAnimation("place")
	inst.AnimState:PushAnimation("idle", false)
	inst.SoundEmitter:PlaySound("dontstarve/common/place_structure_wood")
end

local function onUsageFinished(inst)
	inst.AnimState:PlayAnimation("destroy")
	inst:ListenForEvent("animover", inst.Remove)

	local x, y, z = inst.Transform:GetWorldPosition()
	local fx = SpawnPrefab("collapse_small")
	fx.Transform:SetPosition(x, y, z)
	fx:SetMaterial("wood")
end

local function OnStartDrive(inst)
	inst.AnimState:PlayAnimation("running", true)
	inst._drived = true
end

local function OnStopDrive(inst)
	if inst.persists then
		inst.AnimState:PlayAnimation("idle", false)
	end
end

local function OnAddDriver(inst, driver)
	inst._drived = false

	if driver and driver.components.talker then
		driver.components.talker:Say(STRINGS.AIP.AIP_MINECART_LEAVE)
	end
end

local function OnRemoveDriver(inst)
	if inst.components.finiteuses ~= nil and inst._drived then
		inst.components.finiteuses:Use()

		if inst.components.finiteuses:GetUses() <= 0 then
			inst.persists = false
			onUsageFinished(inst)
		end
	end
end

-- 注：
-- 默认的乘坐逻辑需要装上鞍，装备完毕后的移动动画是骑牛的动画（并且会显示鞍）。
-- 感觉在之上改造太过麻烦，干脆直接自己模拟好了。
function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()
	
	MakeGhostPhysics(inst, 0, 0.3)
	inst.Transform:SetScale(1.3, 1.3, 1.3)
	
	inst.AnimState:SetBank("aip_mine_car")
	inst.AnimState:SetBuild("aip_mine_car")
	inst.AnimState:PlayAnimation("idle")

	inst:AddTag("aip_minecar")

	inst.entity:SetPristine()

	-- 矿车客户端组件
	inst:AddComponent("aipc_minecar_client")

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_mine_car.xml"
	inst.components.inventoryitem.nobounce = true

	inst:AddComponent("inspectable")

	-- 矿车组件
	inst:AddComponent("aipc_minecar")
	inst.components.aipc_minecar.onPlaced = onPlaced
	inst.components.aipc_minecar.onStartDrive = OnStartDrive
	inst.components.aipc_minecar.onStopDrive = OnStopDrive
	inst.components.aipc_minecar.onAddDriver = OnAddDriver
	inst.components.aipc_minecar.onRemoveDriver = OnRemoveDriver

	-- 移动者
	inst:AddComponent("locomotor")
	inst.components.locomotor:SetTriggersCreep(false)
	inst.components.locomotor.walkspeed = TUNING.WILSON_WALK_SPEED * speedMulti
	inst.components.locomotor.runspeed = TUNING.WILSON_RUN_SPEED * speedMulti

	-- 掉东西
	inst:AddComponent("lootdropper")

	-- 被锤子
	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
	inst.components.workable:SetWorkLeft(3)
	inst.components.workable:SetOnFinishCallback(onhammered)
	inst.components.workable:SetOnWorkCallback(onhit)

	-- 使用次数
	inst:AddComponent("finiteuses")
	inst.components.finiteuses:SetMaxUses(TUNING.AIP_MINE_CAR_USAGE)
	inst.components.finiteuses:SetUses(TUNING.AIP_MINE_CAR_USAGE)

	-- 禁止碰撞
	inst.Physics:SetCollides(false)

	inst:DoTaskInTime(0, onInit)

	inst.OnLoad = onload
	inst.OnSave = onsave

	return inst
end

return Prefab( "aip_mine_car", fn, assets, prefabs) 
