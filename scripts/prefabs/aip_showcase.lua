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
        NAIL_NAME = "冰展示柜",
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

STRINGS.NAMES.AIP_SHOWCASE_ICE = LANG.NAIL_NAME
STRINGS.RECIPE_DESC.AIP_SHOWCASE_ICE = LANG.NAIL_DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_SHOWCASE_ICE = LANG.DESCRIBE

STRINGS.AIP_SHOWCASE_WARNING = LANG.TALK_WARNING
STRINGS.AIP_SHOWCASE_DENEY = LANG.TALK_DENEY

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_showcase.zip"),
	Asset("ATLAS", "images/inventoryimages/aip_showcase.xml"),
    Asset("ATLAS", "images/inventoryimages/aip_showcase_ice.xml"),
}

--------------------------------- 皮肤类型 ---------------------------------
local skinList = {"circle","broken","button","mix"}

--------------------------------- 绑定 ---------------------------------
local function lockItem(item, lock)
    if item then
        if lock then
            -- 让它不能点
            item:AddTag("INLIMBO")
            item:AddTag("NOCLICK")
            item:StopBrain()

            if item.Physics then
                item.Physics:SetActive(false)
            end
        else
            item:RemoveTag("INLIMBO")
            item:RemoveTag("NOCLICK")
            item:RestartBrain()

            if item.Physics then
                item.Physics:SetActive(true)
            end
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
        -- 移除 Owner
        item = item.components.inventoryitem:RemoveFromOwner(false)

        -- 重置 Owner
        inst.components.container:GiveItem(item)
        item = inst.components.container:GetItemInSlot(1)
        inst.components.container:DropItem(item)

        item.components.inventoryitem:SetOwner(inst)
    end

    if item.Follower == nil then
        item.entity:AddFollower()
    end
    item.Follower:FollowSymbol(inst.GUID, "swap_item", 0, 0, 0.1)

    lockItem(item, true)

    inst._aipShowcaseItem = item
    inst:AddTag("aip_showcase_active")
end

--------------------------------- 方法 ---------------------------------
local MINE_LEFT = 8
local MINE_CHANGE = MINE_LEFT - 4

-- 损毁
local function onhammered(inst)
    inst.components.lootdropper:DropLoot()

    dropItem(inst)

    -- 兜底掉落，其实没啥用
    if inst.components.container ~= nil then
        inst.components.container:DropEverything()
    end

    aipReplacePrefab(inst, "collapse_small"):SetMaterial("wood")
end

-- 敲击
local function onhit(inst, worker)
    inst.AnimState:PlayAnimation(inst._aipAnim.."_hit")
    inst.AnimState:PushAnimation(inst._aipAnim, false)
end

-- 凿击
local function mineFn(inst)
    inst._aipMineLeft = (inst._aipMineLeft or MINE_LEFT) - 1

    -- 挖坏啦
    if inst._aipMineLeft <= 0 then
        onhammered(inst)
        return
    end

    -- 挖变啦
    if inst._aipMineLeft == MINE_CHANGE then
        local animName = aipRandomEnt(skinList)
        inst._aipAnim = inst._aipMaterial.."_"..animName
    end

    -- 摇晃
    inst.AnimState:PlayAnimation(inst._aipAnim.."_hit")
    inst.AnimState:PushAnimation(inst._aipAnim, false)
end

--------------------------------- 拿取 ---------------------------------
-- 给予
local function canBeGiveOn(inst, doer, item)
    -- aipPrint("Check Give!", inst, doer, item)
    return true
end

local function onDoGiveAction(inst, doer, item)
    -- aipPrint("Give!", inst, doer, item)
    showItem(inst, item)
end

-- 拿取
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

    data._aipMineLeft = inst._aipMineLeft

    if inst._aipShowcaseItem ~= nil then
        data.itemGUID = inst._aipShowcaseItem.GUID
        table.insert(guidtable, inst._aipShowcaseItem.GUID)
    end

    return guidtable
end

local function onLoad(inst, data)
    if data ~= nil then
        inst._aipMineLeft = data._aipMineLeft or MINE_LEFT
    end
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

    inst:AddTag("aip_showcase")
    inst:AddTag(ACTIONS.MINE.id.."_workable") -- 强制可挖掘

    MakeObstaclePhysics(inst, .2)

    inst.AnimState:SetBank("aip_showcase")
    inst.AnimState:SetBuild("aip_showcase")
    inst.AnimState:PlayAnimation(anim)

    inst._aipAnim = anim
    inst._aipMaterial = anim -- 物料这里偷懒了，和动画名一样

    inst:AddComponent("talker")
    inst.components.talker.fontsize = 30
    inst.components.talker.font = TALKINGFONT
    inst.components.talker.colour = Vector3(.9, 1, .9)
    inst.components.talker.offset = Vector3(0, -500, 0)

    inst:AddComponent("aipc_action_client")
	inst.components.aipc_action_client.canBeTakeOn = canBeTakeOn
    inst.components.aipc_action_client.canBeGiveOn = canBeGiveOn

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    -- 放置物品
    inst:AddComponent("container")
    inst.components.container:WidgetSetup(name)
    inst.components.container.skipclosesnd = true
    inst.components.container.skipopensnd = true
    inst.components.container.canbeopened = false

    -- 可以接受物品
    inst:AddComponent("aipc_action")
    inst.components.aipc_action.onDoGiveAction = onDoGiveAction
    inst.components.aipc_action.onDoAction = onDoAction

    -- 可以砸毁
    inst:AddComponent("lootdropper")
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(3)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)

    MakeHauntableLaunch(inst)

    inst._aipMineFn = mineFn -- 通过 componentsHooker 注入的额外挖掘技能
    inst._aipMineLeft = MINE_LEFT
    
    if postFn ~= nil then
        postFn(inst)
    end

    inst.OnSave = onSave
    inst.OnLoad = onLoad
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
    aip_showcase_ice = {
        anim = "ice",
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