local dev_mode = aipGetModConfig("dev_mode") == "enabled"

local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Dream Stone",
		DESC = "Lets have a dream together",
	},
	chinese = {
		NAME = "缘梦",
		DESC = "让我们一起入眠吧",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_DREAM_STONE = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_DREAM_STONE = LANG.DESC

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_dream_stone.zip"),
	Asset("ATLAS", "images/inventoryimages/aip_dream_stone.xml"),
}

-------------------------------- 使用 --------------------------------
local CD = dev_mode and 2 or (TUNING.TOTAL_DAY_TIME * 3)

local function canBeActOn(inst, doer)
	return inst ~= nil and inst:HasTag("aip_charged")
end

local function onDoAction(inst, doer)
    if not inst.components.rechargeable:IsCharged() then
		return
	end

    inst.components.rechargeable:Discharge(CD)

    aipSpawnPrefab(doer, "sleepbomb_burst")

    local SLEEPTARGETS_CANT_TAGS = { "playerghost", "FX", "DECOR", "INLIMBO" }
    local SLEEPTARGETS_ONEOF_TAGS = { "sleeper", "player" }
    local time = TUNING.MANDRAKE_SLEEP_TIME

    local x, y, z = doer.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(
        x, y, z, TUNING.MANDRAKE_SLEEP_RANGE_COOKED, nil,
        SLEEPTARGETS_CANT_TAGS, SLEEPTARGETS_ONEOF_TAGS
    )

    for i, v in ipairs(ents) do
        if
            not (v.components.freezable ~= nil and v.components.freezable:IsFrozen()) and
            not (v.components.pinnable ~= nil and v.components.pinnable:IsStuck()) and
            not (v.components.fossilizable ~= nil and v.components.fossilizable:IsFossilized())
        then
            local mount = v.components.rider ~= nil and v.components.rider:GetMount() or nil
            if mount ~= nil then
                mount:PushEvent("ridersleep", { sleepiness = 7, sleeptime = time + math.random() })
            end

            local sleeptime = time + math.random()

            -- 玩家会睡的更少时间
            if v:HasTag("player") then
                sleeptime = sleeptime / 2
            end

            if v.components.sleeper ~= nil then
                v.components.sleeper:AddSleepiness(7, sleeptime)
            elseif v.components.grogginess ~= nil then
                v.components.grogginess:AddGrogginess(4, sleeptime)
            else
                v:PushEvent("knockedout")
            end
        end
    end
end


-------------------------------- 充能 --------------------------------
local function onDischarged(inst)
	inst:RemoveTag("aip_charged")
end

local function onCharged(inst)
	inst:AddTag("aip_charged")
end

-------------------------------- 实例 --------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("aip_dream_stone")
    inst.AnimState:SetBuild("aip_dream_stone")
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryFloatable(inst, "med", 0.3, 1)

    inst:AddComponent("aipc_action_client")
	inst.components.aipc_action_client.canBeActOn = canBeActOn

    inst:AddTag("aip_charged")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("rechargeable")
	inst.components.rechargeable:SetOnDischargedFn(onDischarged)
	inst.components.rechargeable:SetOnChargedFn(onCharged)

    inst:AddComponent("aipc_action")
	inst.components.aipc_action.onDoAction = onDoAction

    inst:AddComponent("inspectable")
    
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_dream_stone.xml"

	inst:AddComponent("tradable")
	inst.components.tradable.goldvalue = 1

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("aip_dream_stone", fn, assets)
