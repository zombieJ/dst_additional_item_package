local dev_mode = aipGetModConfig("dev_mode") == "enabled"

-- 文字描述
local language = aipGetModConfig("language")

local LANG_MAP = {
	english = {
		NAME = "Permafrost Ice",
		DESC = "What inside?",
	},
	chinese = {
		NAME = "永冻岩",
		DESC = "里面藏着什么东西？",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_SUWU_MOUND = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_SUWU_MOUND = LANG.DESC

local assets = {
	Asset("ANIM", "anim/aip_suwu_mound.zip"),
}

local times = TUNING.ICE_MINE * 2
local WORK_CNT = dev_mode and times or times * 5

---------------------------------- 事件 ----------------------------------
-- 每天恢复全部耐久
local function dayEnd(inst)
    if inst.components.workable ~= nil then
        inst.components.workable:SetWorkLeft(WORK_CNT)
    end
end

-- 一定次数掉落冰
local function onWork(inst, worker, workleft, numWorks)
	inst.aipWorkCnt = inst.aipWorkCnt + numWorks
	local cnt = math.floor(inst.aipWorkCnt / times)
	inst.aipWorkCnt = inst.aipWorkCnt - cnt * times

	for i = 1, cnt do
		inst.components.lootdropper:SpawnLootPrefab("ice")
	end
end

-- 撞击掉冰
local function onCollide(inst, data)
	local boat_physics = data.other.components.boatphysics
	if boat_physics ~= nil then
		local hit_velocity = math.floor(math.abs(boat_physics:GetVelocity() * data.hit_dot_velocity) * DAMAGE_SCALE / boat_physics.max_velocity + 0.5)
		inst.components.workable:WorkedBy(data.other, hit_velocity * TUNING.SEASTACK_MINE)
	end
end

---------------------------------- 实体 ----------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    inst.MiniMapEntity:SetIcon("seastack.png")

    inst:SetPhysicsRadiusOverride(2.6)

    MakeWaterObstaclePhysics(inst, 2.6, 2, 0.75)

    inst:AddTag("ignorewalkableplatforms")
    inst:AddTag("aip_suwu_mound")

    inst.AnimState:SetBank("aip_suwu_mound")
    inst.AnimState:SetBuild("aip_suwu_mound")
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryFloatable(inst, "large", 0.1, {2.5, 1, 2.5})
	inst.components.floater.bob_percent = 0

    local land_time = (POPULATING and math.random()*5*FRAMES) or 0
    inst:DoTaskInTime(land_time, function(inst)
        inst.components.floater:OnLandedServer()
    end)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetChanceLootTable({})

	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.MINE)
	inst.components.workable:SetMaxWork(WORK_CNT)
	inst.components.workable:SetWorkLeft(WORK_CNT)
	inst.components.workable:SetOnWorkCallback(onWork)
	inst.components.workable.savestate = true
	inst.aipWorkCnt = 0

	inst:AddComponent("inspectable")

	MakeHauntableWork(inst)

	inst:ListenForEvent("on_collide", onCollide)

	inst:WatchWorldState("cycles", dayEnd)

	return inst
end

return Prefab("aip_suwu_mound", fn, assets)