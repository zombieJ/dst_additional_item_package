-- 开发模式
local dev_mode = aipGetModConfig("dev_mode") == "enabled"

local BaseHealth = dev_mode and 100 or TUNING.LEIF_HEALTH

local assets = {
	Asset("ANIM", "anim/aip_rubik_heart.zip"),
}

local language = aipGetModConfig("language")

local LANG_MAP = {
	english = {
		NAME = "Skits Heart",
		DESC = "A beating heart",
	},
	chinese = {
		NAME = "诙谐之心",
		DESC = "一颗跳动的心脏",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

-- 文字描述
STRINGS.NAMES.AIP_RUBIK_HEART = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_RUBIK_HEART = LANG.DESC

------------------------------- 掉落 -------------------------------
local loot = {
    "aip_fake_fly_totem_blueprint",
}

------------------------------- 事件 -------------------------------
local function onHit(inst)
	inst.SoundEmitter:PlaySound("dontstarve/creatures/leif/livingtree_hit")
	inst.AnimState:PlayAnimation("hit")
	inst.AnimState:PushAnimation("idle", true)

	if
		inst.components.health ~= nil and
		inst.components.timer ~= nil and
		inst.components.health:GetPercent() < 0.5 and
		not inst.components.timer:TimerExists("aip_eat_snity")
	then
		inst.components.timer:StartTimer("aip_eat_snity", 5)
		local players = aipFindNearPlayers(inst, 10)

		for i, player in ipairs(players) do
			if player.components.sanity ~= nil and player.components.sanity:GetPercent() > 0 then
				player.components.sanity:DoDelta(-30)

				local proj = aipSpawnPrefab(player, "aip_projectile")
				proj.components.aipc_info_client:SetByteArray( -- 调整颜色
					"aip_projectile_color", { 0, 0, 0, 5 }
				)
				proj.components.aipc_projectile:GoToTarget(inst, function()
					if not inst.components.health:IsDead() then
						inst.components.health:DoDelta(50)
					end
				end)
			end
		end
	end
end

local function OnDead(inst)
	if inst.aipGhosts then
		-- 不用再通知其他鬼魂了
		local tmpGhosts = inst.aipGhosts
		inst.aipGhosts = {}

		for i, ghost in ipairs(tmpGhosts) do
			ghost.aipHeartDead = true
			if ghost.components.health and not ghost.components.health:IsDead() then
				ghost.components.health:Kill()
			end
		end
	end

	inst:DoTaskInTime(0.1, function()
		inst.AnimState:PlayAnimation("dead")
		inst:ListenForEvent("animover", function()
			aipSpawnPrefab(inst, "aip_shadow_wrapper", nil, 4).DoShow()
			local pt = inst:GetPosition()
			pt.y = 4
			inst.components.lootdropper:DropLoot(pt)
			inst:Remove()
		end)
	end)
end

------------------------------- 实体 -------------------------------
local function fn()
	local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
	inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

	inst.DynamicShadow:SetSize(.8, .5)

    MakeFlyingCharacterPhysics(inst, 0, 0)

    inst:AddTag("aip_shadowcreature") -- 标记的暗影生物，因为默认的不允许攻击
	inst:AddTag("gestaltnoloot")
	inst:AddTag("monster")
	inst:AddTag("hostile")
	inst:AddTag("shadow")
	inst:AddTag("notraptrigger")

    inst.AnimState:SetBank("aip_rubik_heart")
    inst.AnimState:SetBuild("aip_rubik_heart")
	inst.AnimState:PlayAnimation("idle", true)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

	inst:AddComponent("inspectable")

	inst:AddComponent("timer")

    inst:AddComponent("health")
	inst.components.health:SetMaxHealth(BaseHealth)
	inst.components.health.nofadeout = true

	inst:AddComponent("combat")
	inst.components.combat:SetOnHit(onHit)

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot(loot)

	inst:ListenForEvent("death", OnDead)

	inst.persists = false

	return inst
end

return Prefab("aip_rubik_heart", fn, assets)
