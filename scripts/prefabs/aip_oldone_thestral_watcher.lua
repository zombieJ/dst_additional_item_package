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

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_oldone_thestral_watcher.zip"),
}

---------------------------------- 事件 ----------------------------------
-- 点击激活点
local function toggleActive(inst, doer)
    if not inst.components.activatable.inactive then
        inst.AnimState:PlayAnimation("turn")
        inst.AnimState:PushAnimation("active", true)

        -- 持续检测附近玩家
        inst.components.aipc_timer:NamedInterval("PlayerNear", 1, function()
            local players = aipFindNearPlayers(inst, 2)

            if #players == 0 then
                inst.components.activatable.inactive = true
                inst.AnimState:PlayAnimation("idle", true)

                return false
            end
        end)
    end
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

    return inst
end

return Prefab("aip_oldone_thestral_watcher", fn, assets)
