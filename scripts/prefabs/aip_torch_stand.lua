------------------------------------ 配置 ------------------------------------
-- 开发模式
local dev_mode = aipGetModConfig("dev_mode") == "enabled"

-- 建筑关闭
local additional_building = aipGetModConfig("additional_building")
if additional_building ~= "open" then return nil end

local language = aipGetModConfig("language")

local LANG_MAP = {
    english = {
        NAME = "Moonlight Torch",
        DESC = "It longs to be illuminated by the warm and cold firelight"
    },
    chinese = {
        NAME = "月光火柱",
        DESC = "它渴望被即温暖又寒冷的火光照亮"
    }
}

local LANG = LANG_MAP[language] or LANG_MAP.english

-- 文字描述
STRINGS.NAMES.AIP_TORCH_STAND = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_TORCH_STAND = LANG.DESC

local assets = {
    Asset("ANIM", "anim/aip_torch_stand.zip"),
}

local prefabs = {"collapse_small"}

------------------------------------ 方法 ------------------------------------
local function onhammered(inst, worker)
    inst.components.lootdropper:DropLoot()
    local x, y, z = inst.Transform:GetWorldPosition()
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(x, y, z)
    fx:SetMaterial("stone")
    inst:Remove()
end

local function onhit(inst, worker)
    inst.AnimState:PlayAnimation("hit")
    inst.AnimState:PushAnimation("idle")
end

-- 让火可以点燃不同类型的火焰
local function postTypeFire(inst, fx, type)
    if type == "mix" then
        fx.AnimState:OverrideMultColour(1, 0, 1, 1)
    end

    if fx.components.firefx then
        fx.components.firefx:SetLevel(4)
    end

    fx:AddTag("aip_rubik_fire")
    fx:AddTag("aip_rubik_fire_"..type)
end

------------------------------------ 实例 ------------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    -- 碰撞体积
    MakeObstaclePhysics(inst, .3)

    -- 动画
    inst.AnimState:SetBank("aip_torch_stand")
    inst.AnimState:SetBuild("aip_torch_stand")
    inst.AnimState:PlayAnimation("idle", false)

    -- 标签
    inst:AddTag("structure")
    inst:AddTag("aip_torch_stand")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then return inst end

    -- 掉东西
    inst:AddComponent("lootdropper")

    -- 被锤子
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)

	-- 添加类型火焰特效
    inst:AddComponent("aipc_type_fire")
    inst.components.aipc_type_fire.hotPrefab = "campfirefire"
	inst.components.aipc_type_fire.coldPrefab = "coldfirefire"
    inst.components.aipc_type_fire.mixPrefab = "coldfirefire"
	inst.components.aipc_type_fire.followSymbol = "firefx"
	inst.components.aipc_type_fire.followOffset = Vector3(0, 0, 0)
    inst.components.aipc_type_fire.postFireFn = postTypeFire

    -- 可检查
    inst:AddComponent("inspectable")

    return inst
end

return Prefab("aip_torch_stand", fn, assets, prefabs)
