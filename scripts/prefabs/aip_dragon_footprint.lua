local dev_mode = aipGetModConfig("dev_mode") == "enabled"

local assets = {
	Asset("ANIM", "anim/aip_dragon_footprint.zip"),
}

local prefabs = {
	"nightmarefuel",
	"aip_projectile",
	"aip_shadow_wrapper"
}

local createGroudVest = require("utils/aip_vest_util").createGroudVest

local brain = require "brains/aip_dragon_footprint_brain"

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
		inst._footStep = math.mod((inst._footStep or 0) + 1, 2)

		local rot = aipGetAngle(inst._pos, curPos)
		local deg = inst._footStep == 1 and (rot - 90) or (rot + 90)
		deg = deg / 180 * PI

		local vest = createGroudVest("aip_dragon_footprint", "aip_dragon_footprint", "disappear")
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

			aipTypePrint("Exist:", aipBufferExist(player, "seeFootPrint"))
			-- 如果有帽子光环就可以直接看到
			if aipBufferExist(player, "seeFootPrint") then
				ptg = 0
			end

			local mulPtg = 1 - ptg * 0.8

			vest.AnimState:OverrideMultColour(mulPtg, mulPtg, mulPtg, mulPtg)
		end

		-- 每次打印脚印后就更新一下记录
		inst._pos = curPos
	end
end

-- 一定时间后消除对象
local function RemoveIt(inst)
	local effect = aipSpawnPrefab(inst, "aip_shadow_wrapper")
	effect.DoShow()

	aipReplacePrefab(inst, "nightmarefuel")
end

local function RemoveOnTime(inst)
	if inst._aipRM ~= nil then
		inst._aipRM:Cancel()
		inst._aipRM = nil
	end

	inst._aipRM = inst:DoTaskInTime(dev_mode and 5 or 30, RemoveIt)
end

-- 找向日葵撞
local function GoToTarget(inst, target)
	if target:IsValid() then
		local prefab = aipSpawnPrefab(target, "aip_shadow_wrapper")
		prefab.DoShow()

		aipReplacePrefab(target, "aip_sunflower_ghost")
	end
end

local function FindSunflower(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	local ents = TheSim:FindEntities(x, y, z, 10, { "aip_sunflower_tall" })

	for i, v in ipairs(ents) do
		if v.entity:IsVisible() then
			return v
		end
	end

	return nil
end

local function SeekSunflower(inst)
	local sunflower = FindSunflower(inst)
	if sunflower ~= nil then
		local proj = aipReplacePrefab(inst, "aip_projectile", nil, 1)
		proj.components.aipc_info_client:SetByteArray( -- 调整颜色
			"aip_projectile_color", { 0, 0, 0, 5 }
		)
		proj.components.aipc_projectile.speed = 10
		proj.components.aipc_projectile:GoToTarget(sunflower, GoToTarget)
	end
end

-- ----------------------------------------------------------------------
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

	-- 过一段时间自杀
	RemoveOnTime(inst)

	-- 如果发现有人追就重新设置自杀时间
	inst:ListenForEvent("locomote", function(inst)
		local run = inst.components.locomotor:WantsToRun()
		if run then
			RemoveOnTime(inst)
		end
	end)

	-- 检测附近是否有向日葵树，有就飞过去
	inst:DoPeriodicTask(0.5, SeekSunflower)

	return inst
end

return Prefab("aip_dragon_footprint", fn, assets, prefabs)

--[[



c_give"aip_sunflower"



c_give"aip_dragon_footprint"


]]