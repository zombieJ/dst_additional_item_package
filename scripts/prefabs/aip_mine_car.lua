local foldername = KnownModIndex:GetModActualName(TUNING.ZOMBIEJ_ADDTIONAL_PACKAGE)

------------------------------------ 配置 ------------------------------------
-- 矿车关闭
local additional_orbit = GetModConfigData("additional_orbit", foldername)
if additional_orbit ~= "open" then
	return nil
end

local speedMulti = 1

local language = GetModConfigData("language", foldername)

local LANG_MAP = {
	["english"] = {
		["NAME"] = "Mine Car",
		["REC_DESC"] = "Let's drive it!",
		["DESC"] = "Where will we go?",
	},
	["chinese"] = {
		["NAME"] = "矿车",
		["REC_DESC"] = "让我们兜风吧！",
		["DESC"] = "登船靠岸停稳！~",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

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

-- 文字描述
STRINGS.NAMES.AIP_MINE_CAR = LANG.NAME
STRINGS.RECIPE_DESC.AIP_MINE_CAR = LANG.REC_DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_MINE_CAR = LANG.DESC

-- 配方
local aip_mine_car = Recipe("aip_mine_car", {Ingredient("boards", 5)}, RECIPETABS.TOWN, TECH.SCIENCE_ONE)
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

local function OnStartDrive(inst)
	inst.AnimState:PlayAnimation("running", true)
end

local function OnStopDrive(inst)
	inst.AnimState:PlayAnimation("idle", false)
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
	inst.components.workable:SetWorkLeft(4)
	inst.components.workable:SetOnFinishCallback(onhammered)
	inst.components.workable:SetOnWorkCallback(onhit)

	-- 禁止碰撞
	inst.Physics:SetCollides(false)

	inst:DoTaskInTime(0, onInit)

	inst.OnLoad = onload
	inst.OnSave = onsave

	return inst
end

return Prefab( "aip_mine_car", fn, assets, prefabs) 