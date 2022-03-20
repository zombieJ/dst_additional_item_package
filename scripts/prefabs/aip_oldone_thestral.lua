-- 开发模式
local dev_mode = aipGetModConfig("dev_mode") == "enabled"

local brain = require("brains/aip_oldone_thestral_brain")

local assets = {
    Asset("ANIM", "anim/aip_oldone_thestral.zip"),
	Asset("ANIM", "anim/aip_oldone_thestral_full.zip"),
}


local language = aipGetModConfig("language")

local LANG_MAP = {
	english = {
		NAME = "Sock Snake",
		DESC = "Hmmm, strange...",
		SNAKE = "Si si si...",
		ROCK_HEAD = "'Bring the marble skull to me'",
	},
	chinese = {
		NAME = "袜子蛇",
		DESC = "千人千面！",
		SNAKE = "嘶嘶嘶...",
		ROCK_HEAD = "“把大理石头骨带给我”",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

-- 文字描述
STRINGS.NAMES.AIP_OLDONE_THESTRAL = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_THESTRAL = LANG.DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_THESTRAL_SNAKE = LANG.SNAKE
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_THESTRAL_ROCK_HEAD = LANG.ROCK_HEAD

local sounds = {
	attack = "dontstarve/sanity/creature2/attack",
	attack_grunt = "dontstarve/sanity/creature2/attack_grunt",
	death = "dontstarve/sanity/creature2/die",
	idle = "dontstarve/sanity/creature2/idle",
	taunt = "dontstarve/sanity/creature2/taunt",
	appear = "dontstarve/sanity/creature2/appear",
	disappear = "dontstarve/sanity/creature2/dissappear",
}

-------------------------------- 事件 --------------------------------
local DIST_NEAR = 10
local DIST_FAR = 20
local TALK_DIFF = dev_mode and 8 or 15

-- 玩家靠近
local function onNear(inst, player)
	aipPrint("Near!")

	inst.aip_player_time = inst.components.aipc_timer:Interval(1, function()
		local now = GetTime()

		if now - inst.aip_talk_time >= TALK_DIFF then
			inst.aip_talk_time = now

			local players = aipFilterTable(
				aipFindNearPlayers(inst, DIST_NEAR),
				function(player)
					return aipHasBuffer(player, "aip_see_eyes")
				end
			)

			-- 玩家说话
			for i, player in ipairs(players) do
				if player.components.talker ~= nil then
					player.components.talker:Say(
						STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_THESTRAL_ROCK_HEAD
					)
				end
			end

			-- 蛇蛇说话
			inst.components.talker:Say(
				STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_THESTRAL_SNAKE
			)
		end
	end)
end

-- 玩家远离
local function onFar(inst)
	inst.components.aipc_timer:Kill(inst.aip_player_time)
end
-------------------------------- 实例 --------------------------------
local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	MakeCharacterPhysics(inst, 10, 1.5)
	RemovePhysicsColliders(inst)
	inst.Physics:SetCollisionGroup(COLLISION.SANITY)
	inst.Physics:CollidesWith(COLLISION.SANITY)

	inst.Transform:SetTwoFaced()
	inst.Transform:SetScale(0.8, 0.8, 0.8)

	-- inst:AddTag("monster")

	inst.AnimState:SetBank("aip_oldone_thestral")
	inst.AnimState:SetBuild("aip_oldone_thestral")
	inst.AnimState:PlayAnimation("idle_loop", true)

	inst.AnimState:SetClientsideBuildOverride(
		"aip_see_eyes", -- 客户端替换贴图，有疯狂的 aip_see_eyes buff 的人才能看到
		"aip_oldone_thestral",
		"aip_oldone_thestral_full"
	)

	inst.entity:SetPristine()

	inst:AddComponent("talker")
	inst.components.talker.fontsize = 30
	inst.components.talker.font = TALKINGFONT
	inst.components.talker.colour = Vector3(1, .1, .1)
	inst.components.talker.offset = Vector3(0, -300, 0)

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("inspectable")

	inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
	inst.components.locomotor.walkspeed = TUNING.CRAWLINGHORROR_SPEED

	inst.sounds = sounds

	inst:SetStateGraph("SGaip_oldone_thestral")
	inst:SetBrain(brain)

	inst:AddComponent("aipc_timer")

	-- 玩家靠近，判断一下是否有疯狂的 buff 来说话
    inst:AddComponent("playerprox")
    inst.components.playerprox:SetDist(DIST_NEAR, DIST_FAR)
    inst.components.playerprox:SetOnPlayerNear(onNear)
	inst.components.playerprox:SetOnPlayerFar(onFar)

	inst:AddComponent("sanityaura")

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(dev_mode and 6 or 66)

	inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "body"

	inst:AddComponent("lootdropper")
	inst.components.lootdropper:AddChanceLoot("aip_dou_tooth", 1)

	inst.aip_talk_time = -999

	return inst
end

return Prefab("aip_oldone_thestral", fn, assets)

--[[



c_give"aip_armor_gambler"
c_give"aip_oldone_thestral"




]]