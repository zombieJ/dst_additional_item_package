local dev_mode = aipGetModConfig("dev_mode") == "enabled"
local language = aipGetModConfig("language")

local LANG_MAP = {
	english = {
		NAME = "Hand Of Glory",
		DESC = "Lighten everyone",
	},
	chinese = {
		NAME = "光荣之手",
		DESC = "照亮所有人",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

-- 文字描述
STRINGS.NAMES.AIP_GLORY_HAND = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_GLORY_HAND = LANG.DESC

local assets = {
    Asset("ANIM", "anim/aip_glory_hand.zip"),
    Asset("ANIM", "anim/aip_glory_hand_swap.zip"),
    Asset("SOUND", "sound/common.fsb"),
    Asset("ATLAS", "images/inventoryimages/aip_glory_hand.xml"),
}

local prefabs = { "torchfire_shadow" }

------------------------------------ 方法 ------------------------------------
local FX = "torchfire_shadow"

local function darkenAllPlayer(inst)
    if inst._aipFireList ~= nil then
        for k, v in pairs(inst._aipFireList) do
            if v ~= nil and v:IsValid() then
                v:Remove()
            end
        end
    end

    inst._aipFireList = nil
end

local function lightenAllPlayer(inst)
    darkenAllPlayer(inst)

    -- 烧完了就不给与光亮了
    if inst.components.fueled ~= nil and inst.components.fueled:IsEmpty() then
        return
    end

    inst._aipFireList = {}

    for i, player in pairs(AllPlayers) do
		local fx = aipSpawnPrefab(player, FX, nil, 15)
        MakeProjectilePhysics(fx)

        fx:AddComponent("aipc_float")
        fx.components.aipc_float.offset = Vector3(0, 4, 0)
        fx.components.aipc_float.speed = 5
        fx.components.aipc_float.ySpeed = 3
        fx.components.aipc_float:MoveToInst(player)

        table.insert(inst._aipFireList, fx)
	end
end

local function onTakeFuel(inst)
    if inst._aipFireList == nil then
        lightenAllPlayer(inst)
    end
end

------------------------------------ 原生 ------------------------------------
local function onequip(inst, owner)
    

    owner.AnimState:OverrideSymbol("swap_object", "aip_glory_hand_swap", "aip_glory_hand_swap")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")

    owner.SoundEmitter:PlaySound("dontstarve/wilson/torch_swing")

    -- 空的不会有火焰效果
    if inst.components.fueled ~= nil and inst.components.fueled:IsEmpty() then
        return
    end

    inst.components.burnable:Ignite()

    if inst.fires == nil then
        inst.fires = {}

        -- local fx = SpawnPrefab(FX)
        -- fx.entity:SetParent(owner.entity)
        -- fx.entity:AddFollower()
        -- fx.Follower:FollowSymbol(owner.GUID, "swap_object", 0, -150, 0)
        -- fx:AttachLightTo(owner)

        -- table.insert(inst.fires, fx)
    end

    lightenAllPlayer(inst)
end

local function onunequip(inst, owner)
    if inst.fires ~= nil then
        for i, fx in ipairs(inst.fires) do
            fx:Remove()
        end
        inst.fires = nil
        owner.SoundEmitter:PlaySound("dontstarve/common/fireOut")
    end

    inst.components.burnable:Extinguish()
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")

    darkenAllPlayer(inst)
end

local function onpocket(inst, owner)
    inst.components.burnable:Extinguish()
end

local function onattack(weapon, attacker, target)
    --target may be killed or removed in combat damage phase
    if target ~= nil and target:IsValid() and target.components.burnable ~= nil and math.random() < TUNING.TORCH_ATTACK_IGNITE_PERCENT * target.components.burnable.flammability then
        target.components.burnable:Ignite(nil, attacker)
    end
end

local function onupdatefueledraining(inst)
    local owner = inst.components.inventoryitem ~= nil and inst.components.inventoryitem.owner or nil
    inst.components.fueled.rate =
        owner ~= nil and
        owner.components.sheltered ~= nil and
        owner.components.sheltered.sheltered and
        (inst._fuelratemult or 1) or
        (1 + TUNING.TORCH_RAIN_RATE * TheWorld.state.precipitationrate) * (inst._fuelratemult or 1)
end

local function onisraining(inst, israining)
    if inst.components.fueled ~= nil then
        if israining then
            inst.components.fueled:SetUpdateFn(onupdatefueledraining)
            onupdatefueledraining(inst)
        else
            inst.components.fueled:SetUpdateFn()
            inst.components.fueled.rate = inst._fuelratemult or 1
        end
    end
end

local function onfuelchange(newsection, oldsection, inst)
    if newsection <= 0 then
        --when we burn out
        if inst.components.burnable ~= nil then
            inst.components.burnable:Extinguish()
        end
        -- local equippable = inst.components.equippable
        -- if equippable ~= nil and equippable:IsEquipped() then
        --     local owner = inst.components.inventoryitem ~= nil and inst.components.inventoryitem.owner or nil
        --     if owner ~= nil then
        --         local data = {
        --             prefab = inst.prefab,
        --             equipslot = equippable.equipslot,
        --             announce = "ANNOUNCE_TORCH_OUT",
        --         }
        --         inst:Remove()
        --         owner:PushEvent("itemranout", data)
        --         return
        --     end
        -- end
        -- inst:Remove()
    end
end

local function SetFuelRateMult(inst, mult)
    mult = mult ~= 1 and mult or nil
    if inst._fuelratemult ~= mult then
        inst._fuelratemult = mult
        onisraining(inst, TheWorld.state.israining)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("aip_glory_hand")
    inst.AnimState:SetBuild("aip_glory_hand")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("wildfireprotected")

    --lighter (from lighter component) added to pristine state for optimization
    inst:AddTag("lighter")

    --waterproofer (from waterproofer component) added to pristine state for optimization
    inst:AddTag("waterproofer")

    --weapon (from weapon component) added to pristine state for optimization
    inst:AddTag("weapon")

	MakeInventoryFloatable(inst, "med", nil, 0.68)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(TUNING.TORCH_DAMAGE)
    inst.components.weapon:SetOnAttack(onattack)

    -----------------------------------
    inst:AddComponent("lighter")
    -----------------------------------

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_glory_hand.xml"
    -----------------------------------

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnPocket(onpocket)
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    -----------------------------------

    inst:AddComponent("waterproofer")
    inst.components.waterproofer:SetEffectiveness(TUNING.WATERPROOFNESS_SMALL)

    -----------------------------------

    inst:AddComponent("inspectable")

    -----------------------------------

    inst:AddComponent("burnable")
    inst.components.burnable.canlight = false
    inst.components.burnable.fxprefab = nil

    -----------------------------------

    inst:AddComponent("fueled")
    inst.components.fueled.accepting = true
    inst.components.fueled.fueltype = FUELTYPE.NIGHTMARE
    inst.components.fueled:SetSectionCallback(onfuelchange)
    inst.components.fueled:InitializeFuelLevel(TUNING.TORCH_FUEL)
    inst.components.fueled:SetDepletedFn(darkenAllPlayer)
    inst.components.fueled:SetFirstPeriod(TUNING.TURNON_FUELED_CONSUMPTION, TUNING.TURNON_FULL_FUELED_CONSUMPTION)
    inst.components.fueled:SetTakeFuelFn(onTakeFuel)

    -- 测试模式燃料少一点
    if dev_mode then
        inst.components.fueled:SetPercent(0.1)
    end

    inst:WatchWorldState("israining", onisraining)
    onisraining(inst, TheWorld.state.israining)

    inst._fuelratemult = nil
    inst.SetFuelRateMult = SetFuelRateMult

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("aip_glory_hand", fn, assets, prefabs)
