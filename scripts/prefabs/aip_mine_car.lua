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
-- 矿车重置高度
local function resetHeight(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	inst.Transform:SetPosition(x, 0.9, z)
end

-- 位移到最近的轨道上
local function moveToOrbit(inst, distance)
	local x, y, z = inst.Transform:GetWorldPosition()
	local instPoint = Point(inst.Transform:GetWorldPosition())
	local orbits = TheSim:FindEntities(x, y, z, distance or 2, { "orbit" })

	-- Find closest one
	local closestDist = 100
	local closest = nil
	for i, target in ipairs(orbits) do
		local targetPoint = Point(target.Transform:GetWorldPosition())
		local dsq = distsq(instPoint, targetPoint)

		if closestDist > dsq then
			closestDist = dsq
			closest = target
		end
	end

	if closest ~= nil then
		local tx, ty, tz = closest.Transform:GetWorldPosition()
		inst.Transform:SetPosition(tx, ty, tz)
	end

	return #orbits
end

-- 丢弃矿车
local function OnDropped(inst)
	local hasOrbit = moveToOrbit(inst, 2) > 0

	if hasOrbit then
		inst.components.inventoryitem.canbepickedup = false
	end
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

		resetHeight(inst)
	end
end

-- 初始化
local function onInit(inst)
	if inst.components.inventoryitem and inst.components.inventoryitem.canbepickedup == false then
		resetHeight(inst)
	end
end

function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()
	
	-- MakeInventoryPhysics(inst)
	MakeGhostPhysics(inst, 0, 0.3)
	inst.Transform:SetScale(1.3, 1.3, 1.3)
	
	inst.AnimState:SetBank("aip_mine_car")
	inst.AnimState:SetBuild("aip_mine_car")
	inst.AnimState:PlayAnimation("idle")

	inst:AddTag("aip_minecar")
	inst:AddTag("saddleable")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_mine_car.xml"
	inst.components.inventoryitem.nobounce = true

	inst:AddComponent("inspectable")

	-- 矿车组件
	inst:AddComponent("aipc_minecar")

	-- 移动者
	inst:AddComponent("locomotor")
	inst.components.locomotor:SetTriggersCreep(false)
	inst.components.locomotor.walkspeed = TUNING.WILSON_WALK_SPEED * speedMulti
	inst.components.locomotor.runspeed = TUNING.WILSON_RUN_SPEED * speedMulti

	--[[ 乘坐
	注： 默认的乘坐逻辑需要装上鞍，装备完毕后的移动动画是骑牛的动画（并且会显示鞍）。
		感觉在之上改造太过麻烦，干脆直接自己模拟好了。
	inst:AddComponent("locomotor")
	--inst:AddComponent("saddler")
	--inst.components.saddler:SetBonusDamage(data.bonusdamage)
	--inst.components.saddler:SetBonusSpeedMult(data.speedmult)
	--inst.components.saddler:SetSwaps(name, "swap_saddle")
	--inst.components.saddler:SetDiscardedCallback(ondiscarded)
	inst:AddComponent("rideable")
	inst.components.rideable:SetSaddleable(true)
	--inst.components.rideable:SetRequiredObedience(TUNING.BEEFALO_MIN_BUCK_OBEDIENCE)
	--inst:ListenForEvent("saddlechanged", OnSaddleChanged)
	--inst:ListenForEvent("refusedrider", OnRefuseRider)]]

	inst.OnLoad = onload
	inst.OnSave = onsave

	inst:DoTaskInTime(0, onInit)

	return inst
end

return Prefab( "aip_mine_car", fn, assets, prefabs) 