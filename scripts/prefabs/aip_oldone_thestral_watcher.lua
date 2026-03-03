local dev_mode = aipGetModConfig("dev_mode") == "enabled"
local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Wool Mat",
		DESC = "It can help me see 'it'",
	},
	chinese = {
		NAME = "绒线地垫",
		DESC = "它可以让我见到“它”",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_OLDONE_THESTRAL_WATCHER = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_THESTRAL_WATCHER = LANG.DESC
STRINGS.NAMES.AIP_OLDONE_THESTRAL_WATCHER_ITEM = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_THESTRAL_WATCHER_ITEM = LANG.DESC

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_oldone_thestral_watcher.zip"),
    Asset("ATLAS", "images/inventoryimages/aip_oldone_thestral_watcher.xml"),
}

---------------------------------- 事件 ----------------------------------
local BOSS_POS = 20
local BOSS_POS_DEV = 20

-- 点击激活点
local function toggleActive(inst, doer)
    if not inst.components.activatable.inactive then
        inst.AnimState:PlayAnimation("turn")
        inst.AnimState:PushAnimation("active", true)
        inst:AddTag("aip_oldone_smile_active")

        -- 持续检测附近玩家
        inst.components.aipc_timer:NamedInterval("PlayerNear", 1, function()
            local players = aipFindNearPlayers(inst, 2)

            if #players == 0 then
                inst.components.activatable.inactive = true
                inst.AnimState:PlayAnimation("idle", true)
                inst:RemoveTag("aip_oldone_smile_active")

                return false
            end
        end)

        -- 召唤一个笑脸
        if aipCommonStore().smileLeftDays <= 0 then
            aipCommonStore().smileLeftDays = 3

            local smile = TheSim:FindFirstEntityWithTag("aip_oldone_smile")
            if smile == nil then
                local pt = aipGetSpawnPoint(inst:GetPosition(), dev_mode and BOSS_POS_DEV or BOSS_POS)
                aipSpawnPrefab(inst, "aip_oldone_smile", pt.x, pt.y, pt.z)
            end
        end
    end
end

local function onhammered(inst, worker)
    aipSpawnPrefab(inst, "aip_slime_mold")
    aipReplacePrefab(inst, "collapse_small"):SetMaterial("wood")
end

---------------------------------- 实例 ----------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("aip_oldone_thestral_watcher")
    inst.AnimState:SetBuild("aip_oldone_thestral_watcher")
    inst.AnimState:PlayAnimation("idle", true)

    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_WORLD_BACKGROUND)
    inst.AnimState:SetSortOrder(0)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("aipc_timer")

    inst:AddComponent("activatable")
	inst.components.activatable.OnActivate = toggleActive

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(3)
    inst.components.workable:SetOnFinishCallback(onhammered)

    return inst
end

---------------------------------- 物体 ----------------------------------
local function alwaysCanBuild()
    return true, false
end

-- 资源
local itemAssets = {
    Asset("ANIM", "anim/aip_oldone_thestral_watcher.zip"),
    Asset("ATLAS", "images/inventoryimages/aip_oldone_thestral_watcher.xml"),
}

local function onDeploy(inst, pt)
    aipSpawnPrefab(inst, "aip_oldone_thestral_watcher", pt.x, pt.y, pt.z)
    aipRemove(inst)
end

local function itemFn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("aip_oldone_thestral_watcher")
    inst.AnimState:SetBuild("aip_oldone_thestral_watcher")
    inst.AnimState:PlayAnimation("item")

    MakeInventoryFloatable(inst, "med", 0.2, 0.70)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    
    inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_oldone_thestral_watcher.xml"
    inst.components.inventoryitem.imagename = "aip_oldone_thestral_watcher"

    inst:AddComponent("deployable")
    inst.components.deployable.ondeploy = onDeploy
    inst.components.deployable:SetDeploySpacing(DEPLOYSPACING.NONE)

    inst:AddComponent("stackable")
	inst.components.stackable.maxsize = TUNING.STACK_SIZE_LARGEITEM

    MakeSmallBurnable(inst)
    MakeSmallPropagator(inst)

    return inst
end

return Prefab("aip_oldone_thestral_watcher", fn, assets),
        Prefab("aip_oldone_thestral_watcher_item", itemFn, itemAssets),
        MakePlacer(
            "aip_oldone_thestral_watcher_item_placer", "aip_oldone_thestral_watcher", "aip_oldone_thestral_watcher", "idle", true
        )