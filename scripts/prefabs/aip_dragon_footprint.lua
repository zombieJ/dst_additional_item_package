local assets = {
	Asset("ANIM", "anim/aip_dragon_footprint.zip"),
}

local prefabs = {
	"nightmarefuel",
	"aip_projectile",
	"aip_shadow_wrapper"
}

local createGroupVest = require("utils/aip_vest_util").createGroupVest

local brain = require "brains/aip_dragon_footprint_brain"

local function FindSunflower(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	local ents = TheSim:FindEntities(x, y, z, 100, { "aip_sunflower" })

	for i, v in ipairs(ents) do
		if v.entity:IsVisible() then
			return v
		end
	end

	return nil
end

-- 移动时打印脚印
local FP_DIST = 0.6
local FP_OFFSET = 0.4

local function PrintFootPrint(inst)
	local curPos = inst:GetPosition()

	-- 初始化一下
	if inst._pos == nil then
		inst._pos = curPos
		return
	end

	local needPrint = inst._pos == nil or aipDist(curPos, inst._pos) > FP_DIST

	if needPrint then
		-- 脚印左右走
		inst._footStep = math.mod(inst._footStep + 1, 2)

		local rot = aipGetAngle(inst._pos, curPos)
		local deg = inst._footStep == 1 and (rot - 90) or (rot + 90)
		deg = deg / 180 * PI

		local vest = createGroupVest("aip_dragon_footprint", "aip_dragon_footprint", "disappear")
		vest.Transform:SetPosition(
			curPos.x + FP_OFFSET * math.cos(deg),
			0,
			curPos.z + FP_OFFSET * math.sin(deg)
		)
		vest.Transform:SetRotation(inst.Transform:GetRotation())

		-- 根据玩家理智值显示透明度
		local player = ThePlayer
		if player ~= nil and player.replica.sanity ~= nil then
			local ptg = player.replica.sanity:GetPercent()
			vest.AnimState:OverrideMultColour(1, 1, 1, 1 - ptg * 0.8)
		end

		-- 每次打印脚印后就更新一下记录
		inst._pos = curPos
	end
end

-- 一定时间后消除对象
local function RemoveIt(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	local prefab = SpawnPrefab("aip_shadow_wrapper")
	prefab.Transform:SetPosition(x, y, z)
	prefab.DoShow()

	aipReplacePrefab(inst, "nightmarefuel")
end

local function RemoveOnTime(inst)
	if inst._aipRM ~= nil then
		inst._aipRM:cancel()
		inst._aipRM = nil
	end

	inst._aipRM = inst:DoTaskInTime(10, RemoveIt)
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	inst:AddTag("NOCLICK")
	inst:AddTag("FX")

	inst.AnimState:SetBank("aip_dragon_footprint")
	inst.AnimState:SetBuild("aip_dragon_footprint")
	inst.AnimState:PlayAnimation("idle", false)

	MakeCharacterPhysics(inst, 1, .5)
	RemovePhysicsColliders(inst)
	inst.Physics:CollidesWith(COLLISION.WORLD)

	inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
	inst.AnimState:SetLayer(LAYER_WORLD_BACKGROUND)
	inst.AnimState:SetSortOrder(2)

	-- 客户端的特效
	if not TheNet:IsDedicated() then
		inst._footStep = 0
		inst._pos = nil
		inst.tailPeriodTask = inst:DoPeriodicTask(0.02, PrintFootPrint)
	end

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	-- 不可见之物
	inst.AnimState:SetMultColour(0, 0, 0, 0)

	-- 模拟火鸡的行为，它基本和火鸡很相似
	inst:AddComponent("locomotor")
	inst.components.locomotor.runspeed = TUNING.PERD_RUN_SPEED
	inst.components.locomotor.walkspeed = TUNING.PERD_WALK_SPEED

	inst:SetStateGraph("SGaip_dragon_footprint")
	inst:SetBrain(brain)

	inst.persists = false

	RemoveOnTime(inst)

	--[[inst:DoTaskInTime(0, function()

		 TODO: 驱赶术

		local sunflower = FindSunflower(inst)
		local x, y, z = inst.Transform:GetWorldPosition()

		-- 如果地图上有向日葵就动起来
		if sunflower ~= nil then
			-- local proj = SpawnPrefab("aip_projectile")
			-- proj.components.aipc_info_client:SetByteArray( -- 调整颜色
			-- 	"aip_projectile_color", { 0, 0, 0, 5 }
			-- )
			-- proj.Transform:SetPosition(x, 1, z)
			-- proj.components.aipc_projectile.speed = 10
			-- proj.components.aipc_projectile:GoToTarget(sunflower, GoToTarget)
		else
			local prefab = SpawnPrefab("aip_shadow_wrapper")
			prefab.Transform:SetPosition(x, y, z)
			prefab.DoShow()

			inst:Remove()
		end
		
	end)]]

	return inst
end

return Prefab("aip_dragon_footprint", fn, assets, prefabs)

--[[



c_give"aip_sunflower"



c_give"aip_dragon_footprint"


]]