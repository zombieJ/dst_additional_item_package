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
		DESC = "Show item on it but not keep fresh",
        NAIL_NAME = "Nail Showcase",
		NAIL_DESC = "Show item on it, will keep fresh",
        DESCRIBE = "Show your case",
        TALK_WARNING = "Do not put precious items to avoid BUG and loss",
        TALK_DENEY = "Can not show this",
	},
	chinese = {
        NAME = "展示柜",
		DESC = "用于展示一个物品，放入的内容不保鲜",
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

STRINGS.NAMES.AIP_SHOWCASE_NAIL = LANG.NAIL_NAME
STRINGS.RECIPE_DESC.AIP_SHOWCASE_NAIL = LANG.NAIL_DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_SHOWCASE_NAIL = LANG.DESCRIBE

STRINGS.AIP_SHOWCASE_WARNING = LANG.TALK_WARNING
STRINGS.AIP_SHOWCASE_DENEY = LANG.TALK_DENEY

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_showcase.zip"),
	Asset("ATLAS", "images/inventoryimages/aip_showcase.xml"),
    Asset("ATLAS", "images/inventoryimages/aip_showcase_nail.xml"),
}

--------------------------------- 方法 ---------------------------------

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

--------------------------------- 存取 ---------------------------------
local function onSave(inst, data)
    local guidtable = {}

    if inst._aipShowcaseItem ~= nil then
        data.itemGUID = inst._aipShowcaseItem.GUID
        table.insert(guidtable, inst._aipShowcaseItem.GUID)
    end

    return guidtable
end

local function onLoadPostPass(inst, newents, data)
    -- 加载绑定的物品
    if data ~= nil and data.itemGUID ~= nil then
        local item = newents[data.itemGUID]
        if item ~= nil then
            showItem(inst, item.entity)
        end

    -- 如果里面放了东西，说明旧版本的，丢出来绑定
    elseif not inst.components.container:IsEmpty() then
        local item = inst.components.container:GetItemInSlot(1)
        if item ~= nil then
            showItem(inst, item)
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

    -- inst.OnLoad = onLoad
    inst.OnSave = onSave
    inst.OnLoadPostPass = onLoadPostPass

    return inst
end

-- ======================================================================
---------------------------------- 实例 ----------------------------------
-- ======================================================================
local showcaseList = {
    ---------------------------------- 石头 ----------------------------------
    aip_showcase = {
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