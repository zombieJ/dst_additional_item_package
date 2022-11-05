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
        TALK_DENEY = "Can not show this",
	},
	chinese = {
		NAME = "展示柜",
		DESC = "展示你的物品",
        TALK_DENEY = "抱歉，无法展示",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_SHOWCASE = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_SHOWCASE = LANG.DESC
STRINGS.AIP_SHOWCASE_DENEY = LANG.TALK_DENEY

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_showcase.zip"),
	Asset("ATLAS", "images/inventoryimages/aip_showcase.xml"),
}

--------------------------------- 方法 ---------------------------------
-- 刷新物品
local function refreshShow(inst)
    local numslots = inst.components.container:GetNumSlots()
    for slot = 1, numslots do
        local item = inst.components.container:GetItemInSlot(slot)

        -- 复制物品贴图
        if item ~= nil and item.components.inventoryitem ~= nil then
            if inst._aipItemVest == nil then
                local record = item:GetSaveRecord()
                local newItem = SpawnSaveRecord(record)
                newItem.persists = false

                -- for k, v in pairs(newItem.components) do
                --     newItem:RemoveComponent(k)
                -- end

                newItem.entity:SetParent(inst.entity)
                newItem.entity:AddFollower()
                newItem.Follower:FollowSymbol(inst.GUID, "swap_item", 0, 0, 0)

                inst._aipItemVest = newItem


                -- inst._aipItemVest = SpawnPrefab("aip_vest")
                -- inst._aipItemVest.entity:SetParent(inst.entity)
                -- inst._aipItemVest.entity:AddFollower()
                -- inst._aipItemVest.Follower:FollowSymbol(inst.GUID, "swap_item", 0, 0, 0)
            end

            -- -- 设置动画效果
            -- local vest = inst._aipItemVest
            -- local bank = item.AnimState:GetCurrentBankName()
            -- local build = item.AnimState:GetBuild()
            -- local anim = aipGetAnimation(item)



            -- if bank ~= nil and build ~= nil and anim ~= nil then
            --     vest.AnimState:SetBank(bank)
            --     vest.AnimState:SetBuild(build)
            --     vest.AnimState:PlayAnimation(anim, true)
            -- else
            --     inst.components.container:DropItem(item)
            --     inst.components.talker:Say(STRINGS.AIP_SHOWCASE_DENEY)
            -- end

            return
        end
    end

    if inst._aipItemVest ~= nil then
        aipRemove(inst._aipItemVest)
        inst._aipItemVest = nil
    end
end

-- 损毁
local function onhammered(inst, worker)
    inst.components.lootdropper:DropLoot()
    if inst.components.container ~= nil then
        inst.components.container:DropEverything()
    end

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
