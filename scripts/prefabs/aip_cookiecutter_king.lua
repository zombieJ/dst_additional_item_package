-- 文字描述
local language = aipGetModConfig("language")

local LANG_MAP = {
	english = {
		NAME = "Cookie Breaker",
		DESC = "How long has it grown?",
		TALK_PLAYER_SECRET = "What do you say?",
		TALK_KING_SECRET = "Bo bo bo...",
		TALK_KING_HUNGER_1 = "(Koalefant Trunk Steak!)",
		TALK_KING_HUNGER_2 = "(Live Rabbit!)",
		TALK_KING_HUNGER_3 = "(Live Mud crab!)",
		TALK_KING_FIND_ME = "(Keep! touch!)",
		TALK_KING_GIVE_TOOL = "(Use this to find me~)",
		TALK_KING_88 = "(Bye!)",
	},
	chinese = {
		NAME = "饼干碎裂机",
		DESC = "到底长了多久？",
		TALK_PLAYER_SECRET = "不知道它在说什么",
		TALK_KING_SECRET = "咕噜咕噜咕噜...",
		TALK_KING_HUNGER_1 = "(烤象鼻排!)",
		TALK_KING_HUNGER_2 = "(活兔子!)",
		TALK_KING_HUNGER_3 = "(活泥蟹!)",
		TALK_KING_FIND_ME = "(保持联系)",
		TALK_KING_GIVE_TOOL = "(来吧，用它们投石问路)",
		TALK_KING_88 = "(再见)",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_COOKIECUTTER_KING = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_COOKIECUTTER_KING = LANG.DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_COOKIECUTTER_KING_TALK_KING_SECRET = LANG.TALK_KING_SECRET
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_COOKIECUTTER_KING_TALK_PLAYER_SECRET = LANG.TALK_PLAYER_SECRET
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_COOKIECUTTER_KING_TALK_KING_FIND_ME = LANG.TALK_KING_FIND_ME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_COOKIECUTTER_KING_TALK_KING_GIVE_TOOL = LANG.TALK_KING_GIVE_TOOL
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_COOKIECUTTER_KING_TALK_KING_88 = LANG.TALK_KING_88

STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_COOKIECUTTER_KING_TALK_KING_HUNGER_1 = LANG.TALK_KING_HUNGER_1
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_COOKIECUTTER_KING_TALK_KING_HUNGER_2 = LANG.TALK_KING_HUNGER_2
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_COOKIECUTTER_KING_TALK_KING_HUNGER_3 = LANG.TALK_KING_HUNGER_3

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
--                                    马甲                                    --
--------------------------------------------------------------------------------
local function vestFn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	inst:AddTag("NOBLOCK")

	inst:AddComponent("talker")
	inst.components.talker.fontsize = 30
	inst.components.talker.font = TALKINGFONT
	inst.components.talker.colour = Vector3(.9, 1, .9)
	inst.components.talker.offset = Vector3(0, -500, 0)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetLoot({})

	inst.persists = false

	return inst
end

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

-------------------------- 存取 --------------------------
local function onSave(inst, data)
	data.aipStatus = inst.aipStatus
end

local function onLoad(inst, data)
	if data ~= nil then
		inst.aipStatus = data.aipStatus
	end
end

-------------------------- 事件 --------------------------
local function refreshIcon(inst)
	inst:DoTaskInTime(0.1, function()
		inst.MiniMapEntity:SetEnabled(inst.aipStatus == "hunger_1")
	end)
end

local function delayTalk(delay, talker, king, speech, knownSpeech, callback)
	talker:DoTaskInTime(delay or 0, function()
		if talker and talker.components.talker ~= nil then
			-- 寻找附近的玩家
			local players = aipFindNearPlayers(king, 30)
			local teaDrinkers = aipFilterTable(players, function(player)
				return player.components.timer ~= nil and player.components.timer:TimerExists("aip_olden_tea")
			end)

			local finalSpeech = #teaDrinkers > 0 and knownSpeech or speech

			if finalSpeech then
				talker.components.talker:Say(finalSpeech)

				if king.aipVest == talker then
					king.AnimState:PlayAnimation("talk")
					king.AnimState:PushAnimation("idle", true)
				end
			end

			if callback ~= nil then
				callback()
			end
		end
	end)
end

local function clearChecker(inst)
	if inst.aipLoopCheckerTask ~= nil then
		inst.aipLoopCheckerTask:Cancel()
		inst.aipLoopCheckerTask = nil
	end
end

local function findCrabs(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	local ents = TheSim:FindEntities(x, 0, z, 4, { "aip_mud_crab" })

	return aipFilterTable(ents, function(ent)
		return ent.components.inventoryitem == nil or ent.components.inventoryitem:GetGrandOwner() == nil
	end)
end

local function onNear(inst, player)
	clearChecker(inst)

	-------------------- 如果没吃过泥蟹就要求吃一些 --------------------
	if inst.aipStatus == "hunger_1" then
		-- 鱼吐泡泡
		delayTalk(2, inst.aipVest, inst,
			STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_COOKIECUTTER_KING_TALK_KING_SECRET,
			STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_COOKIECUTTER_KING_TALK_KING_HUNGER_1
		)

		-- 玩家表示听不懂
		delayTalk(5, player, inst,
			STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_COOKIECUTTER_KING_TALK_PLAYER_SECRET,
			""
		)

		-- 寻找附近泥蟹吃掉
		inst.aipLoopCheckerTask = inst:DoPeriodicTask(1, function()
			local ents = findCrabs(inst)

			if #ents > 0 then
				inst.AnimState:PlayAnimation("eat")
				inst.AnimState:PushAnimation("idle", true)

				inst:DoTaskInTime(.3, function()
					local ents = findCrabs(inst)

					-- 吃完开始游戏
					if #ents > 0 then
						for i, ent in ipairs(ents) do
							aipReplacePrefab(ent, "small_puff")
						end

						clearChecker(inst)
						inst.aipStatus = "disabled"

						-- 鱼很开心，开始游戏
						delayTalk(2, inst.aipVest, inst,
							STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_COOKIECUTTER_KING_TALK_KING_SECRET,
							STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_COOKIECUTTER_KING_TALK_KING_FIND_ME
						)

						-- 给予物品
						delayTalk(4, inst.aipVest, inst,
							STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_COOKIECUTTER_KING_TALK_KING_SECRET,
							STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_COOKIECUTTER_KING_TALK_KING_GIVE_TOOL,
							function()
								inst.aipVest.components.lootdropper:SpawnLootPrefab("aip_shell_stone_blueprint")
								for i = 1, 3 do
									inst.aipVest.components.lootdropper:SpawnLootPrefab("aip_shell_stone")
								end
							end
						)

						-- 创建一个副本，然后删除自己
						inst.persists = false
						local kingPos = inst:GetPosition()
						local nextKing = TheWorld.components.world_common_store:CreateCoookieKing(kingPos)
						nextKing.aipStatus = "hunger_2"

						-- 鱼很开心，开始游戏
						delayTalk(6, inst.aipVest, inst,
							STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_COOKIECUTTER_KING_TALK_KING_SECRET,
							STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_COOKIECUTTER_KING_TALK_KING_88
						)

						inst:DoTaskInTime(7, function()
							inst.AnimState:SetMultColour(0,0,0,0)
							inst.components.hull.boat_lip.AnimState:PlayAnimation("hide", false)
							inst.components.hull.boat_lip:ListenForEvent("animover", function()
								inst:Remove()
							end)
						end)
					end
				end)
			end
		end)

	--------------------- 再次被玩家找到，下一阶段 ---------------------
	elseif inst.aipStatus == "hunger_2" then
		-- 鱼很开心，开始游戏
		delayTalk(2, inst.aipVest, inst,
			STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_COOKIECUTTER_KING_TALK_KING_SECRET,
			STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_COOKIECUTTER_KING_TALK_KING_FIND_ME
		)
	end
end

local function onFar(inst)
	clearChecker(inst)
end

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
	inst.components.waterphysics.restitution = 0.75 -- 推回撞击的船只

	inst.doplatformcamerazoom = net_bool(inst.GUID, "doplatformcamerazoom", "doplatformcamerazoomdirty")

	if not TheNet:IsDedicated() then
		inst:AddComponent("boattrail")
	end

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("playerprox")
	inst.components.playerprox:SetDist(6, 10)
	inst.components.playerprox:SetOnPlayerNear(onNear)
	inst.components.playerprox:SetOnPlayerFar(onFar)

	-- 船体？
	inst:AddComponent("hull")
    inst.components.hull:SetRadius(radius)
    inst.components.hull:SetBoatLip(SpawnPrefab('aip_cookiecutter_king_lip')) -- 让船看起来立体的船沿下半部分
    local playercollision = SpawnPrefab("boat_player_collision") -- 船手碰撞？似乎是让玩家站上面？
	inst.components.hull:AttachEntityToBoat(playercollision, 0, 0)
    playercollision.collisionboat = inst

	-- 船体移动
	-- inst:AddComponent("boatphysics")

	inst.aipVest = inst:SpawnChild("aip_cookiecutter_king_vest")

	inst.aipStatus = "hunger_1"

	refreshIcon(inst)

	inst.Transform:SetRotation(math.random() * 360)

	inst.OnLoad = onLoad
	inst.OnSave = onSave

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

return Prefab("aip_cookiecutter_king_vest", vestFn, {}),
		Prefab("aip_cookiecutter_king_lip", tailFn, assets),
		Prefab("aip_cookiecutter_king", fn, assets, prefabs)