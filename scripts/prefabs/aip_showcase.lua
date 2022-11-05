local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Showcase",
		DESC = "Show your case",
	},
	chinese = {
		NAME = "展示柜",
		DESC = "展示你的物品",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_SHOWCASE = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_SHOWCASE = LANG.DESC

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_showcase.zip"),
	-- Asset("ATLAS", "images/inventoryimages/aip_22_fish.xml"),
}

--------------------------------- 方法 ---------------------------------
-- 刷新速度
local function refreshShow(inst)
    local numslots = inst.components.container:GetNumSlots()
    for slot = 1, numslots do
        local item = inst.components.container:GetItemInSlot(slot)

        -- 复制物品贴图
        if item ~= nil and item.components.inventoryitem ~= nil then
            -- inst.components.container:DropItem(item)
            -- item.entity:SetParent(inst.entity)
            -- item.entity:AddFollower()
            -- item.Follower:FollowSymbol(inst.GUID, "swap_item", 0, 0, 0)
            
            local imagename = item.components.inventoryitem.imagename or item.prefab
            local texname = imagename..".tex"

            inst.AnimState:OverrideSymbol(
                "swap_item",
                GetInventoryItemAtlas(texname), texname
            )
            return
        end
    end

    inst.AnimState:ClearOverrideSymbol("swap_item")
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

    inst:AddComponent("container")
	inst.components.container:WidgetSetup("aip_showcase")
	-- inst.components.container.onopenfn = onopen
	-- inst.components.container.onclosefn = onclose
	inst.components.container.skipclosesnd = true
	inst.components.container.skipopensnd = true
	inst.components.container.canbeopened = true

    -- inst.AnimState:OverrideSymbol("swap_item", "aip_armor_gambler", "swap_body")

    MakeHauntableLaunch(inst)

    inst:ListenForEvent("dropitem", refreshShow)
    inst:ListenForEvent("gotnewitem", refreshShow)
    inst:ListenForEvent("itemget", refreshShow)
    inst:ListenForEvent("itemlose", refreshShow)

    return inst
end

return Prefab("aip_showcase", fn, assets)
