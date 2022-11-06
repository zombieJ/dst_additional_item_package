local language = aipGetModConfig("language")

--[[
元宝显示的是金子
武器穿模
换皮肤
猪年的金腰带
]]

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Showcase",
		DESC = "Show your case",
        TALK_WARNING = "Do not put precious items to avoid BUG and loss",
        TALK_DENEY = "Can not show this",
	},
	chinese = {
		NAME = "展示柜",
		DESC = "展示你的物品",
        TALK_WARNING = "请勿放入珍贵物品，以免 BUG 而丢失",
        TALK_DENEY = "抱歉，无法展示",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_SHOWCASE = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_SHOWCASE = LANG.DESC
STRINGS.AIP_SHOWCASE_WARNING = LANG.TALK_WARNING
STRINGS.AIP_SHOWCASE_DENEY = LANG.TALK_DENEY

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_showcase.zip"),
	Asset("ATLAS", "images/inventoryimages/aip_showcase.xml"),
}

--------------------------------- 方法 ---------------------------------
-- local function safeShowItem(inst, item)
--     if inst._aipItemVest == nil then
--         inst._aipItemVest = SpawnPrefab("aip_vest")
--         inst._aipItemVest.entity:SetParent(inst.entity)
--         inst._aipItemVest.entity:AddFollower()
--         inst._aipItemVest.Follower:FollowSymbol(inst.GUID, "swap_item", 0, 0, 0)
--     end

--     -- 设置动画效果
--     local vest = inst._aipItemVest
--     local bank = item.AnimState:GetCurrentBankName()
--     local build = item.AnimState:GetBuild()
--     local anim = aipGetAnimation(item)



--     if bank ~= nil and build ~= nil and anim ~= nil then
--         vest.AnimState:SetBank(bank)
--         vest.AnimState:SetBuild(build)
--         vest.AnimState:PlayAnimation(anim, false)
--         return true
--     else
--         inst.components.container:DropItem(item)
--         inst.components.talker:Say(STRINGS.AIP_SHOWCASE_DENEY)
--     end
-- end

local function lockItem(item, lock)
    if item then
        if lock then
            -- 让它不能点
            item:AddTag("INLIMBO")
            item:AddTag("NOCLICK")
        else
            item:RemoveTag("INLIMBO")
            item:RemoveTag("NOCLICK")
        end
    end
end

local function cleanup(inst)
    if inst._aipTargetItem ~= nil then
        -- inst._aipTargetItem._aipTask:Cancel()

        inst._aipTargetItem.Follower:StopFollowing()
        lockItem(inst._aipTargetItem, false)

        inst._aipTargetItem = nil
    end
end

local function dangerShowItem(inst, item)
    item:ReturnToScene()

    if item.Follower == nil then
        item.entity:AddFollower()
    end
    item.Follower:FollowSymbol(inst.GUID, "swap_item", 0, 0, 0.1)
    inst._aipTargetItem = item

    -- item._aipTask = item:DoPeriodicTask(1, function()
    --     -- local x, y, z = inst.Transform:GetWorldPosition()
    --     -- item.Transform:SetPosition(0, 1, 0)
    --     aipTypePrint("POS:", item:GetPosition(), inst:GetPosition())
    -- end)

    -- item:DoTaskInTime(3, function()
    --     aipPrint("Go!")
    --     item.Follower:StopFollowing()

    --     local pt = inst:GetPosition()
    --     local it = item:GetPosition()

    --     -- item.Transform:SetPosition(it.x - pt.x, it.y - pt.y, it.z - pt.z)
    --     item.Transform:SetPosition(0, it.y - pt.y, 0)
    -- end)

    lockItem(item, true)

    -- return true
end

-- 刷新物品
local function refreshShow(inst)
    local numslots = inst.components.container:GetNumSlots()
    for slot = 1, numslots do
        local item = inst.components.container:GetItemInSlot(slot)

        -- 复制物品贴图
        if item ~= nil and item.components.inventoryitem ~= nil then
            -- if safeShowItem(inst, item) then
            --     return
            -- end

            -- 相同物品则不做处理
            if item == inst._aipTargetItem then
                return
            end

            inst.components.talker:Say(STRINGS.AIP_SHOWCASE_WARNING)
            dangerShowItem(inst, item)
                -- inst._aipTargetItem = item
            return
        end
    end

    -- if inst._aipItemVest ~= nil then
    --     aipRemove(inst._aipItemVest)
    --     inst._aipItemVest = nil
    -- end

    cleanup(inst)

    -- clearDangerItem(inst)
end

-- 损毁
local function onhammered(inst, worker)
    inst.components.lootdropper:DropLoot()
    if inst.components.container ~= nil then
        inst.components.container:DropEverything()
    end

    cleanup(inst)
    aipReplacePrefab(inst, "collapse_small"):SetMaterial("wood")
end

-- 敲击
local function onhit(inst, worker)
    inst.AnimState:PlayAnimation("stone_hit")
    inst.AnimState:PushAnimation("stone", false)
end

--------------------------------- 实例 ---------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    -- MakeInventoryPhysics(inst)
    MakeObstaclePhysics(inst, .2)

    inst.AnimState:SetBank("aip_showcase")
    inst.AnimState:SetBuild("aip_showcase")
    inst.AnimState:PlayAnimation("stone")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("talker")
    inst.components.talker.fontsize = 30
    inst.components.talker.font = TALKINGFONT
    inst.components.talker.colour = Vector3(.9, 1, .9)
    inst.components.talker.offset = Vector3(0, -500, 0)

    inst:AddComponent("container")
	inst.components.container:WidgetSetup("aip_showcase")
	-- inst.components.container.onopenfn = onopen
	-- inst.components.container.onclosefn = onclose
	inst.components.container.skipclosesnd = true
	inst.components.container.skipopensnd = true
	inst.components.container.canbeopened = true

    -- 可以砸毁
    inst:AddComponent("lootdropper")
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(3)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)

    -- inst.AnimState:OverrideSymbol("swap_item", "aip_armor_gambler", "swap_body")

    MakeHauntableLaunch(inst)

    inst:ListenForEvent("dropitem", refreshShow)
    inst:ListenForEvent("gotnewitem", refreshShow)
    inst:ListenForEvent("itemget", refreshShow)
    inst:ListenForEvent("itemlose", refreshShow)

    inst:DoTaskInTime(0.1, refreshShow)

    return inst
end

return  Prefab("aip_showcase", fn, assets),
        MakePlacer("aip_showcase_placer", "aip_showcase", "aip_showcase", "stone")
