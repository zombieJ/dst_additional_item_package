-- 文字描述
local language = aipGetModConfig("language")

local LANG_MAP = {
	english = {
		NAME = "Cookie Breaker",
		DESC = "How long has it grown?",
		TOTEM_NAME = "Exchanger",
	},
	chinese = {
		NAME = "饼干碎裂机",
		DESC = "到底长了多久？",
		TOTEM_NAME = "交易切割",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_COOKIECUTTER_KING = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_COOKIECUTTER_KING = LANG.DESC

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_cookiecutter_king.zip"),
	Asset("ATLAS", "minimap/aip_cookiecutter_king.xml"),
	Asset("IMAGE", "minimap/aip_cookiecutter_king.tex"),
}

local prefabs = {
    "boat_item_collision",
	"boat_player_collision",
	"aip_cookiecutter_king_lip",
}

--------------------------------------------------------------------------------
--                                    主体                                    --
--------------------------------------------------------------------------------

-------------------------- 物理 --------------------------
local function RemoveConstrainedPhysicsObj(physics_obj)
	if physics_obj:IsValid() then
		physics_obj.Physics:ConstrainTo(nil)
		physics_obj:Remove()
	end
end

local function AddConstrainedPhysicsObj(boat, physics_obj)
	physics_obj:ListenForEvent("onremove", function() RemoveConstrainedPhysicsObj(physics_obj) end, boat)

	physics_obj:DoTaskInTime(0, function()
		if boat:IsValid() then
			physics_obj.Transform:SetPosition(boat.Transform:GetWorldPosition())
			physics_obj.Physics:ConstrainTo(boat.entity)
		end
	end)
end

-------------------------- 事件 --------------------------

-------------------------- 实体 --------------------------
local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddMiniMapEntity()
	inst.MiniMapEntity:SetIcon("aip_cookiecutter_king.tex")
	inst.MiniMapEntity:SetPriority(10)
	inst.entity:AddNetwork()

	inst:AddTag("ignorewalkableplatforms")
	inst:AddTag("antlion_sinkhole_blocker")
	inst:AddTag("aip_cookiecutter_king")
	inst:AddTag("boat")

	local radius = 4
	local phys = inst.entity:AddPhysics()
	phys:SetMass(TUNING.BOAT.MASS)
	phys:SetFriction(0)
	phys:SetDamping(5)
	phys:SetCollisionGroup(COLLISION.OBSTACLES)
	phys:ClearCollisionMask()
	phys:CollidesWith(COLLISION.WORLD)
	phys:CollidesWith(COLLISION.OBSTACLES)
	phys:SetCylinder(radius, 3)
	phys:SetDontRemoveOnSleep(true)

	inst.AnimState:SetBank("aip_cookiecutter_king")
	inst.AnimState:SetBuild("aip_cookiecutter_king")
	inst.AnimState:PlayAnimation("idle", true)
	inst.AnimState:SetSortOrder(ANIM_SORT_ORDER.OCEAN_BOAT)
	inst.AnimState:SetFinalOffset(1)
	inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
	inst.AnimState:SetLayer(LAYER_BACKGROUND)

	inst:AddComponent("walkableplatform")
    inst.components.walkableplatform.radius = radius
	
	-- 添加受限物理对象：好像是用来推开水里东西用的
	AddConstrainedPhysicsObj(inst, SpawnPrefab("boat_item_collision"))

	-- 水之物理？看起来是缓慢减少速度用的
	inst:AddComponent("waterphysics")
	inst.components.waterphysics.restitution = 0.75

	inst.doplatformcamerazoom = net_bool(inst.GUID, "doplatformcamerazoom", "doplatformcamerazoomdirty")

	if not TheNet:IsDedicated() then
		inst:AddComponent("boattrail")
	end

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	-- 船体？
	inst:AddComponent("hull")
    inst.components.hull:SetRadius(radius)
    inst.components.hull:SetBoatLip(SpawnPrefab('aip_cookiecutter_king_lip')) -- 让船看起来立体的船沿下半部分
    local playercollision = SpawnPrefab("boat_player_collision") -- 船手碰撞？似乎是让玩家站上面？
	inst.components.hull:AttachEntityToBoat(playercollision, 0, 0)
    playercollision.collisionboat = inst

	-- 船体移动的物理组件？
	inst:AddComponent("boatphysics")

	return inst
end

--------------------------------------------------------------------------------
--                                    尾巴                                    --
--------------------------------------------------------------------------------
local function tailFn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst:AddTag("NOBLOCK")
    inst:AddTag("DECOR")

    inst.AnimState:SetBank("aip_cookiecutter_king")
    inst.AnimState:SetBuild("aip_cookiecutter_king")
    inst.AnimState:PlayAnimation("lip", true)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGroundFixed)
    inst.AnimState:SetLayer(LAYER_BELOW_GROUND)
    inst.AnimState:SetSortOrder(ANIM_SORT_ORDER_BELOW_GROUND.UNDERWATER)
    inst.AnimState:SetFinalOffset(0)
    inst.AnimState:SetOceanBlendParams(TUNING.OCEAN_SHADER.EFFECT_TINT_AMOUNT)
    inst.AnimState:SetInheritsSortKey(false)

    inst.Transform:SetRotation(90)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    return inst
end

return Prefab("aip_cookiecutter_king_lip", tailFn, assets),
		Prefab("aip_cookiecutter_king", fn, assets, prefabs)