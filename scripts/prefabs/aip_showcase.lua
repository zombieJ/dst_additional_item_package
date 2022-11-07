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
		NAME = "Vest",
		DESC = "Will be repalced",
        STONE_NAME = "Showcase",
		STONE_DESC = "Show item on it but not keep fresh",
        NAIL_NAME = "Nail Showcase",
		NAIL_DESC = "Show item on it, will keep fresh",
        DESCRIBE = "Show your case",
        TALK_WARNING = "Do not put precious items to avoid BUG and loss",
        TALK_DENEY = "Can not show this",
	},
	chinese = {
		NAME = "马甲",
		DESC = "会被替换哦",
        STONE_NAME = "展示柜",
		STONE_DESC = "用于展示一个物品，放入的内容不保鲜",
        NAIL_NAME = "冰图钉展示柜",
		NAIL_DESC = "用于展示一个物品，放入的内容不会腐烂",
        DESCRIBE = "展示你的物品",
        TALK_WARNING = "请勿放入珍贵物品，以免 BUG 而丢失",
        TALK_DENEY = "抱歉，无法展示",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_SHOWCASE = LANG.NAME
STRINGS.RECIPE_DESC.AIP_SHOWCASE = LANG.DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_SHOWCASE = LANG.DESCRIBE

STRINGS.NAMES.AIP_SHOWCASE_STONE = LANG.STONE_NAME
STRINGS.RECIPE_DESC.AIP_SHOWCASE_STONE = LANG.STONE_DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_SHOWCASE_STONE = LANG.DESCRIBE

STRINGS.NAMES.AIP_SHOWCASE_NAIL = LANG.NAIL_NAME
STRINGS.RECIPE_DESC.AIP_SHOWCASE_NAIL = LANG.NAIL_DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_SHOWCASE_NAIL = LANG.DESCRIBE


STRINGS.AIP_SHOWCASE_WARNING = LANG.TALK_WARNING
STRINGS.AIP_SHOWCASE_DENEY = LANG.TALK_DENEY

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_showcase.zip"),
	Asset("ATLAS", "images/inventoryimages/aip_showcase_stone.xml"),
    Asset("ATLAS", "images/inventoryimages/aip_showcase_nail.xml"),
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

-- local function lockItem(item, lock)
--     if item then
--         if lock then
--             -- 让它不能点
--             item:AddTag("INLIMBO")
--             item:AddTag("NOCLICK")
--         else
--             item:RemoveTag("INLIMBO")
--             item:RemoveTag("NOCLICK")
--         end
--     end
-- end

-- local function cleanup(inst)
--     if inst._aipTargetItem ~= nil then
--         inst._aipTargetItem.Follower:StopFollowing()
--         lockItem(inst._aipTargetItem, false)

--         inst._aipTargetItem = nil
--     end
-- end

-- local function dangerShowItem(inst, item)
--     item:ReturnToScene()

--     if item.Follower == nil then
--         item.entity:AddFollower()
--     end
--     item.Follower:FollowSymbol(inst.GUID, "swap_item", 0, 0, 0.1)
--     inst._aipTargetItem = item

--     lockItem(item, true)
-- end

-- -- 刷新物品
-- local function refreshShow(inst)
--     local numslots = inst.components.container:GetNumSlots()
--     for slot = 1, numslots do
--         local item = inst.components.container:GetItemInSlot(slot)

--         -- 复制物品贴图
--         if item ~= nil and item.components.inventoryitem ~= nil then
--             -- if safeShowItem(inst, item) then
--             --     return
--             -- end

--             -- 相同物品则不做处理
--             if item == inst._aipTargetItem then
--                 return
--             end

--             inst.components.talker:Say(STRINGS.AIP_SHOWCASE_WARNING)
--             dangerShowItem(inst, item)
--                 -- inst._aipTargetItem = item
--             return
--         end
--     end

--     cleanup(inst)
-- end

-- local function getItem(inst, data)
--     cleanup(inst)

--     inst:DoTaskInTime(0.1, function()
--         local item = data.item

--         inst.components.container:DropItem(item)
--         dangerShowItem(inst, item)
--     end)
-- end

-- 损毁
local function onhammered(inst, worker)
    -- inst.components.lootdropper:DropLoot()
    -- if inst.components.container ~= nil then
    --     inst.components.container:DropEverything()
    -- end

    -- cleanup(inst)
    aipReplacePrefab(inst, "collapse_small"):SetMaterial("wood")
end

-- 敲击
local function onhit(inst, worker)
    inst.AnimState:PlayAnimation(inst._aipAnim.."_hit")
    inst.AnimState:PushAnimation(inst._aipAnim, false)
end

--------------------------------- 绑定 ---------------------------------
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

--丢弃物品
local function dropItem(inst)
    local item = inst._aipShowcaseItem

    inst:RemoveTag("aip_showcase_active")
    inst._aipShowcaseItem = nil

    if item ~= nil then
        lockItem(item, false)
        item.Follower:StopFollowing()
        aipFlingItem(item, inst:GetPosition())

        return item
    end
end

-- 展示物品
local function showItem(inst, item)
    -- 清理之前的物品
    dropItem(inst)

    -- 取出一个物品，并且重置 Owner 为展示柜
    if item.components.inventoryitem ~= nil then
        inst.components.container:GiveItem(item)
        item = inst.components.container:GetItemInSlot(1)
        inst.components.container:DropItem(item)

        item.components.inventoryitem:SetOwner(inst)
    end

    -- item:ReturnToScene()

    if item.Follower == nil then
        item.entity:AddFollower()
    end
    item.Follower:FollowSymbol(inst.GUID, "swap_item", 0, 0, 0.1)

    lockItem(item, true)

    inst._aipShowcaseItem = item
    inst:AddTag("aip_showcase_active")
end

--------------------------------- 交易 ---------------------------------
local function AbleToAcceptTest(inst, item, giver)
	return true
end

local function AcceptTest(inst, item, giver)
    return true
end

local function OnGetItemFromPlayer(inst, giver, item)
    showItem(inst, item)
end

--------------------------------- 拿取 ---------------------------------
local function canBeTakeOn(inst, doer)
	return doer ~= nil and inst ~= nil and inst:HasTag("aip_showcase_active")
end

local function onDoAction(inst, doer)
	if doer ~= nil and doer.components.inventory ~= nil and doer ~= nil then
		local item = dropItem(inst)

        if item ~= nil then
            doer.components.inventory:GiveItem(item)
        end
	end
end

--------------------------------- 实例 ---------------------------------
local function createInst(name, anim, postFn)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    -- MakeInventoryPhysics(inst)
    MakeObstaclePhysics(inst, .2)

    inst.AnimState:SetBank("aip_showcase")
    inst.AnimState:SetBuild("aip_showcase")
    inst.AnimState:PlayAnimation(anim)

    inst._aipAnim = anim

    inst:AddComponent("talker")
    inst.components.talker.fontsize = 30
    inst.components.talker.font = TALKINGFONT
    inst.components.talker.colour = Vector3(.9, 1, .9)
    inst.components.talker.offset = Vector3(0, -500, 0)

    inst:AddComponent("aipc_action_client")
	inst.components.aipc_action_client.canBeTakeOn = canBeTakeOn

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("aipc_action")
	inst.components.aipc_action.onDoAction = onDoAction

    -- 放置物品
    inst:AddComponent("container")
    inst.components.container:WidgetSetup(name)
    inst.components.container.skipclosesnd = true
    inst.components.container.skipopensnd = true
    inst.components.container.canbeopened = false

    -- 可以接受物品
    inst:AddComponent("trader")
    inst.components.trader:SetAbleToAcceptTest(AbleToAcceptTest)
    inst.components.trader:SetAcceptTest(AcceptTest)
    inst.components.trader.onaccept = OnGetItemFromPlayer
    inst.components.trader.deleteitemonaccept = false
    -- inst.components.trader.onrefuse = OnRefuseItem

    -- 可以砸毁
    inst:AddComponent("lootdropper")
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(3)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)

    MakeHauntableLaunch(inst)

    -- inst:ListenForEvent("dropitem", refreshShow)
    -- inst:ListenForEvent("gotnewitem", refreshShow)
    -- inst:ListenForEvent("itemget", getItem)
    -- inst:ListenForEvent("itemlose", refreshShow)

    -- inst:DoTaskInTime(0.1, refreshShow)

    if postFn ~= nil then
        postFn(inst)
    end

    return inst
end

-- ======================================================================
---------------------------------- 实例 ----------------------------------
-- ======================================================================
local showcaseList = {
    ---------------------------------- 兼容 ----------------------------------
    -- 原本的方法废弃了，这里做一个替换能力
    aip_showcase = {
        anim = "stone",
        postFn = function(inst)
            -- 丢弃物品后替换成新的展示柜
            inst:ListenForEvent("dropitem", function(inst, data)
                local showcase = aipReplacePrefab(inst, "aip_showcase_stone")
                showItem(showcase, data.item)
            end)

            -- 延迟丢弃
            inst:DoTaskInTime(0.1, function()
                inst.components.container:DropEverything()
                
            end)
        end,
    },
    ---------------------------------- 石头 ----------------------------------
    aip_showcase_stone = {
        anim = "stone",
    },

    ---------------------------------- 冰冻 ----------------------------------
    aip_showcase_nail = {
        anim = "nail",
        postFn = function(inst)
            inst:AddComponent("preserver")
            inst.components.preserver:SetPerishRateMultiplier(0)
        end,
    },
}

local prefabs = {}
for name, data in pairs(showcaseList) do
    local function fn()
        return createInst(name, data.anim, data.postFn)
    end

    table.insert(prefabs, Prefab(name, fn, assets))
    table.insert(prefabs, MakePlacer(name.."_placer", "aip_showcase", "aip_showcase", data.anim))
end

return unpack(prefabs)