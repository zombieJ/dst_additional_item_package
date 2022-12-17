-- 配置
local additional_weapon = aipGetModConfig("additional_weapon")
if additional_weapon ~= "open" then
	return nil
end

local weapon_uses = aipGetModConfig("weapon_uses")
local weapon_damage = aipGetModConfig("weapon_damage")
local language = aipGetModConfig("language")

-- 默认参数
local USE_MAP = {
	less = 0.5,
	normal = 1,
	much = 2,
}
local DAMAGE_MAP = {
	less = 0.5,
	normal = 1,
	large = 2,
}

local LANG_MAP = {
	english = {
		NAME = "Rice Amulet",
		REC_DESC = "Like boomerang but will jump between enemies",
		DESC = "Sticky rice boomerang?",
	},
	chinese = {
		NAME = "弹跳符",
		REC_DESC = "像回旋镖一样，但是会弹跳",
		DESC = "糯米回旋镖？",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

TUNING.AIP_JUMP_PAPER_USES = TUNING.BOOMERANG_USES * USE_MAP[weapon_uses]
TUNING.AIP_JUMP_PAPER_DAMAGE = TUNING.BOOMERANG_DAMAGE * DAMAGE_MAP[weapon_damage]

-- 资源
local assets = {
	Asset("ATLAS", "images/inventoryimages/aip_jump_paper.xml"),
	Asset("ANIM", "anim/aip_jump_paper.zip"),
	Asset("ANIM", "anim/aip_jump_paper_swap.zip"),
}

local prefabs = {}

-- 文字描述
STRINGS.NAMES.AIP_JUMP_PAPER = LANG.NAME
STRINGS.RECIPE_DESC.AIP_JUMP_PAPER = LANG.REC_DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_JUMP_PAPER = LANG.DESC

-----------------------------------------------------------

local function OnFinished(inst)
	aipReplacePrefab(inst, "aip_shadow_wrapper").DoShow()
end

local function OnEquip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "aip_jump_paper_swap", "aip_jump_paper_swap")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")

	inst._aipEnemies = {}
end

local function OnDropped(inst)
    inst.AnimState:PlayAnimation("idle")
    inst.components.inventoryitem.pushlandedevents = true
    inst:PushEvent("on_landed")

	inst._aipEnemies = nil
end

local function OnUnequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
end

local function OnThrown(inst, owner, target)
    if target ~= owner then
        owner.SoundEmitter:PlaySound("dontstarve/wilson/boomerang_throw")
    end
    inst.AnimState:PlayAnimation("spin_loop", true)
    inst.components.inventoryitem.pushlandedevents = false
end

local function OnCaught(inst, catcher)
    if catcher ~= nil and catcher.components.inventory ~= nil and catcher.components.inventory.isopen then
        if inst.components.equippable ~= nil and not catcher.components.inventory:GetEquippedItem(inst.components.equippable.equipslot) then
            catcher.components.inventory:Equip(inst)
        else
            catcher.components.inventory:GiveItem(inst)
        end
        catcher:PushEvent("catch")
    end
end

local function ReturnToOwner(inst, owner)
    if owner ~= nil and not (inst.components.finiteuses ~= nil and inst.components.finiteuses:GetUses() < 1) then
        owner.SoundEmitter:PlaySound("dontstarve/wilson/boomerang_return")
        inst.components.projectile:Throw(owner, owner)
    end
end

local function OnHit(inst, owner, target)
	inst._aipEnemies = inst._aipEnemies or {}
	table.insert(inst._aipEnemies, target)

    if owner == target or owner:HasTag("playerghost") then
        OnDropped(inst)
    else
		------------------- 找敌人 开始 -------------------
		local RETARGET_MUST_TAGS = { "_combat", "_health" }
		local RETARGET_CANT_TAGS = { "INLIMBO", "player", "engineering" }

		local x, y, z = inst.Transform:GetWorldPosition()
		local ents = TheSim:FindEntities(
			x, y, z,
			TUNING.BOOMERANG_DISTANCE, RETARGET_MUST_TAGS, RETARGET_CANT_TAGS
		)

		-- 过滤 敌对 和 想攻击你 的
		ents = aipFilterTable(ents, function(ent)
			return ent:HasTag("hostile") or (
				ent.components.combat ~= nil and
				ent.components.combat.target == owner
			)
		end)

		-- 过滤已经在列表里的单位
		ents = aipFilterTable(ents, function(ent)
			return not aipInTable(inst._aipEnemies, ent)
		end)

		------------------- 找敌人 结束 -------------------

		local first = ents[1]
		if first ~= nil then
			inst.components.projectile:Throw(owner, first)
		else
			ReturnToOwner(inst, owner)
		end
    end

	-- 攻击特效
    if target ~= nil and target:IsValid() and target.components.combat then
        local impactfx = SpawnPrefab("impact")
        if impactfx ~= nil then
            local follower = impactfx.entity:AddFollower()
            follower:FollowSymbol(target.GUID, target.components.combat.hiteffectsymbol, 0, 0, 0)
            impactfx:FacePoint(inst.Transform:GetWorldPosition())
        end
    end
end

local function OnMiss(inst, owner, target)
    if owner == target then
        OnDropped(inst)
    else
        ReturnToOwner(inst, owner)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    RemovePhysicsColliders(inst)

    inst.AnimState:SetBank("aip_jump_paper")
    inst.AnimState:SetBuild("aip_jump_paper")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetRayTestOnBB(true)

    inst:AddTag("thrown")

    --weapon (from weapon component) added to pristine state for optimization
    inst:AddTag("weapon")

    --projectile (from projectile component) added to pristine state for optimization
    inst:AddTag("projectile")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(TUNING.AIP_JUMP_PAPER_DAMAGE)
    inst.components.weapon:SetRange(TUNING.BOOMERANG_DISTANCE, TUNING.BOOMERANG_DISTANCE+2)
    -------

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(TUNING.AIP_JUMP_PAPER_USES)
    inst.components.finiteuses:SetUses(TUNING.AIP_JUMP_PAPER_USES)

    inst.components.finiteuses:SetOnFinished(OnFinished)

    inst:AddComponent("inspectable")

    inst:AddComponent("projectile")
    inst.components.projectile:SetSpeed(10)
    inst.components.projectile:SetCanCatch(true)
    inst.components.projectile:SetOnThrownFn(OnThrown)
    inst.components.projectile:SetOnHitFn(OnHit)
    inst.components.projectile:SetOnMissFn(OnMiss)
    inst.components.projectile:SetOnCaughtFn(OnCaught)

    inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_jump_paper.xml"
    inst.components.inventoryitem:SetOnDroppedFn(OnDropped)

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(OnEquip)
    inst.components.equippable:SetOnUnequip(OnUnequip)

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("aip_jump_paper", fn, assets)
