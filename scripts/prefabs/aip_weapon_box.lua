local language = aipGetModConfig("language")

require "prefabutil"

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Iridescent Chest",
		DESC = "A treasure chest linked to magical energy",
        REC_DESC = "A special chest that can summon its items when you need it",
        BIND = "Bind success!",
	},
	chinese = {
		NAME = "虹光宝库",
		DESC = "联结着神奇能量的宝箱",
        REC_DESC = "一个特殊的宝箱，可以在你需要的时候召唤其中的物品",
        BIND = "绑定成功！",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

-- 文字描述
STRINGS.NAMES.AIP_WEAPON_BOX = LANG.NAME
STRINGS.RECIPE_DESC.AIP_WEAPON_BOX = LANG.REC_DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_WEAPON_BOX = LANG.DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_WEAPON_BOX_BIND = LANG.BIND

local assets = {
    Asset("ANIM", "anim/aip_weapon_box.zip"),
    Asset("ANIM", "anim/aip_weapon_box_fx.zip"),
    Asset("ATLAS", "images/inventoryimages/aip_weapon_box.xml"),
}

------------------------------------ 开关 ------------------------------------
local function onopen(inst)
    if not inst:HasTag("burnt") then
        inst.SoundEmitter:PlaySound("dontstarve/wilson/chest_open")
    end
end

local function onclose(inst)
    if not inst:HasTag("burnt") then
        inst.SoundEmitter:PlaySound("dontstarve/wilson/chest_close")
    end
end

------------------------------------ 毁坏 ------------------------------------
local function onhammered(inst, worker)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
        inst.components.burnable:Extinguish()
    end
    inst.components.lootdropper:DropLoot()
    if inst.components.container ~= nil then
        inst.components.container:DropEverything()
    end
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("stone")
    inst:Remove()
end

local function onhit(inst, worker)
    if not inst:HasTag("burnt") then
        if inst.components.container ~= nil then
            inst.components.container:DropEverything()
            inst.components.container:Close()
        end
        inst.AnimState:PlayAnimation("hit")
        inst.AnimState:PushAnimation("idle", false)
    end
end

local function onbuilt(inst)
    inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation("idle", false)
    inst.SoundEmitter:PlaySound("dontstarve/common/chest_craft")
end

------------------------------------ 绑定 ------------------------------------
local function onBindCaller(inst, doer)
    if doer and doer.components.aipc_weapon_caller then
        doer.components.aipc_weapon_caller:Bind(inst)

        if doer.components.talker then
            doer.components.talker:Say(
                STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_WEAPON_BOX_BIND
            )
        end
    end
end

------------------------------------ 存取 ------------------------------------
local function onsave(inst, data)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() or inst:HasTag("burnt") then
        data.burnt = true
    end
end

local function onload(inst, data)
    if data ~= nil and data.burnt and inst.components.burnable ~= nil then
        inst.components.burnable.onburnt(inst)
    end
end

------------------------------------ 实例 ------------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    inst.MiniMapEntity:SetIcon("treasurechest.png")

    inst:AddTag("structure")
    inst:AddTag("chest")

    inst.AnimState:SetBank("aip_weapon_box")
    inst.AnimState:SetBuild("aip_weapon_box")
    inst.AnimState:PlayAnimation("idle")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    -- 烹饪
	inst:AddComponent("aipc_action")
	inst.components.aipc_action.onDoAction = onBindCaller

    inst:AddComponent("inspectable")
    inst:AddComponent("container")
    inst.components.container:WidgetSetup("aip_weapon_box")
    inst.components.container.onopenfn = onopen
    inst.components.container.onclosefn = onclose
    inst.components.container.skipclosesnd = true
    inst.components.container.skipopensnd = true

    inst:AddComponent("lootdropper")
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(2)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)

    MakeSmallBurnable(inst, nil, nil, true)
    MakeMediumPropagator(inst)

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

    inst:ListenForEvent("onbuilt", onbuilt)

    -- Save / load is extended by some prefab variants
    inst.OnSave = onsave
    inst.OnLoad = onload

    return inst
end

------------------------------------ 特效 ------------------------------------
local function fxFn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst:AddTag("NOCLICK")
	inst:AddTag("FX")

    inst.AnimState:SetBank("aip_weapon_box_fx")
    inst.AnimState:SetBuild("aip_weapon_box_fx")
    inst.AnimState:PlayAnimation("start")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:ListenForEvent("animover", inst.Remove)

    return inst
end

return Prefab("aip_weapon_box", fn, assets),
    MakePlacer("aip_weapon_box_placer", "aip_weapon_box", "aip_weapon_box", "idle"),
    Prefab("aip_weapon_box_fx", fxFn, assets)