local disable_weapon = aipGetModConfig("additional_weapon") ~= "open"

-- 文字描述
local language = aipGetModConfig("language")

local LANG_MAP = {
	english = {
		NAME = "Cookie Breaker",
		DESC = "How long has it grown?",
		TALK_PLAYER_SECRET = "What do you say?",
		TALK_KING_SECRET = "Bo bo bo...",

		TALK_KING_HUNGER_TRUNK_COOKED = "(Koalefant Trunk Steak!)",
		TALK_KING_HUNGER_RABBIT = "(Live Rabbit!)",
		TALK_KING_HUNGER_KILLERBEE = "(Live Killer Bee!)",
		TALK_KING_HUNGER_BUTTERFLY = "(Live Butterfly!)",
		TALK_KING_HUNGER_MOLE = "(Live Mole!)",
		TALK_KING_HUNGER_AIP_MUD_CRAB = "(Live Mud crab!)",

		TALK_KING_FIND_ME = "(Keep in touch!)",
		TALK_KING_FINISH = "(Nice food. Next challenge is in dev)",
		TALK_KING_88 = "(Bye!)",
	},
	chinese = {
		NAME = "饼干碎裂机",
		DESC = "到底长了多久？",
		TALK_PLAYER_SECRET = "不知道它在说什么",
		TALK_KING_SECRET = "咕噜咕噜咕噜...",

		TALK_KING_HUNGER_TRUNK_COOKED = "(烤象鼻排!)",
		TALK_KING_HUNGER_RABBIT = "(活兔子!)",
		TALK_KING_HUNGER_KILLERBEE = "(活杀人蜂!)",
		TALK_KING_HUNGER_BUTTERFLY = "(活蝴蝶!)",
		TALK_KING_HUNGER_MOLE = "(活鼹鼠!)",
		TALK_KING_HUNGER_AIP_MUD_CRAB = "(活泥蟹!)",

		TALK_KING_FIND_ME = "(保持联系，投石问路)",
		TALK_KING_FINISH = "(多谢招待，下一个挑战还在开发中)",
		TALK_KING_88 = "(再见)",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_COOKIECUTTER_KING = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_COOKIECUTTER_KING = LANG.DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_COOKIECUTTER_KING_TALK_KING_SECRET = LANG.TALK_KING_SECRET
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_COOKIECUTTER_KING_TALK_PLAYER_SECRET = LANG.TALK_PLAYER_SECRET
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_COOKIECUTTER_KING_TALK_KING_FIND_ME = LANG.TALK_KING_FIND_ME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_COOKIECUTTER_KING_TALK_KING_FINISH = LANG.TALK_KING_FINISH
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_COOKIECUTTER_KING_TALK_KING_88 = LANG.TALK_KING_88

STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_COOKIECUTTER_KING_TALK_KING_HUNGER_TRUNK_COOKED = LANG.TALK_KING_HUNGER_TRUNK_COOKED
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_COOKIECUTTER_KING_TALK_KING_HUNGER_RABBIT = LANG.TALK_KING_HUNGER_RABBIT
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_COOKIECUTTER_KING_TALK_KING_HUNGER_KILLERBEE = LANG.TALK_KING_HUNGER_KILLERBEE
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_COOKIECUTTER_KING_TALK_KING_HUNGER_BUTTERFLY = LANG.TALK_KING_HUNGER_BUTTERFLY
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_COOKIECUTTER_KING_TALK_KING_HUNGER_MOLE = LANG.TALK_KING_HUNGER_MOLE
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_COOKIECUTTER_KING_TALK_KING_HUNGER_AIP_MUD_CRAB = LANG.TALK_KING_HUNGER_AIP_MUD_CRAB

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
	data.aipFood = inst.aipFood
end

local function onLoad(inst, data)
	if data ~= nil then
		inst.aipStatus = data.aipStatus
		inst.aipFood = data.aipFood
	end
end

-------------------------- 辅助 --------------------------
-- 更新图标
local function refreshIcon(inst)
	inst:DoTaskInTime(0.1, function()
		inst.MiniMapEntity:SetEnabled(inst.aipStatus == "hunger_1")
	end)
end

-- 延迟说话
local function delayTalk(delay, talker, king, speech, knownSpeech, callback)
	talker:DoTaskInTime(delay or 0, function()
		if talker and talker.components.talker ~= nil then
			-- 寻找附近的玩家
			local players = aipFindNearPlayers(king, 30)
			local teaDrinkers = aipFilterTable(players, function(player)
				return player.components.timer ~= nil and player.components.timer:TimerExists("aip_olden_tea")
			end)

			local finalSpeech = #teaDrinkers > 0 and knownSpeech or speech

			if finalSpeech and finalSpeech ~= "" then
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

-------------------------- 吃货 --------------------------
local foods = {
	hunger_1 = { "trunk_cooked" },
	hunger_2 = { "rabbit", "killerbee", "butterfly", "mole" },
	hunger_3 = { "aip_mud_crab" },
}

local nextStatus = {
	hunger_1 = "hunger_2",
	hunger_2 = "hunger_3",
}

-- 随机一个食物种类
local function pickFood(inst)
	local foodList = foods[inst.aipStatus]

	if foodList and not aipInTable(foodList, inst.aipFood) then
		inst.aipFood = foodList[math.random(#foodList)]
	end
end

-- 停止监听吃货
local function stopEater(inst)
	if inst.aipLoopCheckerTask ~= nil then
		inst.aipLoopCheckerTask:Cancel()
		inst.aipLoopCheckerTask = nil
	end
end

-- 寻找匹配物
local function findFoods(inst, prefab)
	local ents = aipFindNearEnts(inst, { prefab }, 4)

	return aipFilterTable(ents, function(ent)
		return ent.components.inventoryitem == nil or ent.components.inventoryitem:GetGrandOwner() == nil
	end)
end

-- 开始监听吃货
local function startEater(inst)
	stopEater(inst)

	inst.aipLoopCheckerTask = inst:DoPeriodicTask(1, function()
		local food = inst.aipFood

		-- 没有匹配食物就不吃了
		if food == nil then
			return
		end

		local ents = findFoods(inst, food)

		if #ents > 0 then
			inst.AnimState:PlayAnimation("eat")
			inst.AnimState:PushAnimation("idle", true)

			-- 张嘴动画结束后再检测一次吃掉食物
			inst:DoTaskInTime(.3, function()
				local ents = findFoods(inst, food)

				if #ents > 0 then
					for i, ent in ipairs(ents) do
						aipReplacePrefab(ent, "small_puff")
					end

					-- 如果有下一个状态就创建一个新的副本
					local nextKingStatus = nextStatus[inst.aipStatus]
					if nextKingStatus ~= nil then
						local kingPos = inst:GetPosition()
						local nextKing = TheWorld.components.world_common_store:CreateCoookieKing(kingPos)
						nextKing.aipStatus = nextKingStatus

						-- 感谢 并给予 油纸包
						delayTalk(2, inst.aipVest, inst,
							STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_COOKIECUTTER_KING_TALK_KING_SECRET,
							STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_COOKIECUTTER_KING_TALK_KING_FIND_ME,
							function()
								for i = 1, 5 do
									inst.aipVest.components.lootdropper:SpawnLootPrefab("aip_map")
								end
							end
						)

					-- 没下一个状态了，给予子卿
					else
						delayTalk(2, inst.aipVest, inst,
							STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_COOKIECUTTER_KING_TALK_KING_SECRET,
							STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_COOKIECUTTER_KING_TALK_KING_FINISH,
							function()
								if disable_weapon then
									-- 禁用武器，给予小树枝
									inst.aipVest.components.lootdropper:SpawnLootPrefab("twigs")
								else
									-- 给予子卿
									inst.aipVest.components.lootdropper:SpawnLootPrefab("aip_suwu")
								end
							end
						)
					end

					-- 本身已经没用了
					stopEater(inst)
					inst.aipStatus = "disabled"
					refreshIcon(inst)
					inst.persists = false

					-- 鱼很开心，开始游戏
					delayTalk(4, inst.aipVest, inst,
						STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_COOKIECUTTER_KING_TALK_KING_SECRET,
						STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_COOKIECUTTER_KING_TALK_KING_88
					)

					inst:DoTaskInTime(4.1, function()
						inst.AnimState:OverrideMultColour(0,0,0,0)
						inst.components.hull.boat_lip.AnimState:PlayAnimation("hide", false)
						inst.components.hull.boat_lip:ListenForEvent("animover", function()
							inst:Remove()
						end)
					end)
				end
			end)
		end
	end)
end

-------------------------- 事件 --------------------------
local function onNear(inst, player)
	startEater(inst)

	---------------------- 需求食物 ----------------------
	local food = foods[inst.aipStatus]
	if food ~= nil then
		-- 选择一下食物
		pickFood(inst)

		local upperCase = string.upper(inst.aipFood)
		local foodSpeak = STRINGS.CHARACTERS.GENERIC.DESCRIBE["AIP_COOKIECUTTER_KING_TALK_KING_HUNGER_"..upperCase]

		-- 鱼吐泡泡
		delayTalk(2, inst.aipVest, inst,
			STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_COOKIECUTTER_KING_TALK_KING_SECRET,
			foodSpeak
		)

		-- 玩家表示听不懂
		delayTalk(5, player, inst,
			STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_COOKIECUTTER_KING_TALK_PLAYER_SECRET,
			""
		)
	end
end

local function onFar(inst)
	stopEater(inst)
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

	-- 船体移动：移除就会掉水里
	inst:AddComponent("boatphysics")

	inst.aipVest = inst:SpawnChild("aip_cookiecutter_king_vest")

	inst.aipStatus = "hunger_1"
	inst.aipFood = nil

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