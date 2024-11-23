------------------------------------ 配置 ------------------------------------
-- 开发模式
local dev_mode = aipGetModConfig("dev_mode") == "enabled"

-- 建筑关闭
local additional_building = aipGetModConfig("additional_building")
if additional_building ~= "open" then return nil end

local language = aipGetModConfig("language")

local LANG_MAP = {
    english = {
        NAME = "Final Monument",
        REC_DESC = "Empower your weapon",
        DESC = "This is the proof of my ability",
    },
    chinese = {
        NAME = "永恒纪念碑",
        REC_DESC = "让你的武器获得强化",
        DESC = "这是我能力的证明",
    }
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_TORCH_STAND_FINAL = LANG.NAME
STRINGS.RECIPE_DESC.AIP_TORCH_STAND_FINAL = LANG.REC_DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_TORCH_STAND_FINAL = LANG.DESC

local assets = {
    Asset("ANIM", "anim/aip_torch_stand.zip"),
}


------------------------------------ 方法 ------------------------------------
local function onhammered(inst, worker)
    inst.components.lootdropper:DropLoot()
    local x, y, z = inst.Transform:GetWorldPosition()
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(x, y, z)
    fx:SetMaterial("stone")
    inst:Remove()
end

-- 让火可以点燃不同类型的火焰
local function postTypeFire(inst, fx, type)
    if fx.components.firefx then
        fx.components.firefx:SetLevel(2)
    end

    fx:AddTag("aip_rubik_fire")
    fx:AddTag("aip_rubik_fire_"..type)
end

------------------------------------ 升级 ------------------------------------
CONSTRUCTION_PLANS["aip_torch_stand_final"] = {
    Ingredient("milkywhites", 1),
    Ingredient("glommerfuel", 1),
}

local function OnConstructed(inst, doer)
    local concluded = true
    for i, v in ipairs(CONSTRUCTION_PLANS[inst.prefab] or {}) do
        if inst.components.constructionsite:GetMaterialCount(v.type) < v.amount then
            concluded = false
            break
        end
    end

    if concluded then -- 满足建造条件
        aipFlingItem(
            aipSpawnPrefab(inst, "aip_snakeoil")
        )
    end
end

------------------------------------ 实例 ------------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, .1)

    -- 动画
    inst.AnimState:SetBank("aip_torch_stand")
    inst.AnimState:SetBuild("aip_torch_stand")
    inst.AnimState:PlayAnimation("final", true)

    -- 标签
    inst:AddTag("structure")
    inst:AddTag("aip_can_lighten") -- 让 aipc_lighter 可以点燃它

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then return inst end

    -- 掉东西
    inst:AddComponent("lootdropper")

    -- 被锤子
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(onhammered)

	-- 添加类型火焰特效
    inst:AddComponent("aipc_type_fire")
    -- inst.components.aipc_type_fire.forever = true
    inst.components.aipc_type_fire.hotPrefab = "aip_hot_fire"
	inst.components.aipc_type_fire.coldPrefab = "coldfirefire"
    inst.components.aipc_type_fire.mixPrefab = "aip_mix_fire"
	inst.components.aipc_type_fire.followSymbol = "firefx"
	inst.components.aipc_type_fire.followOffset = Vector3(0, 0, 0)
    inst.components.aipc_type_fire.postFireFn = postTypeFire

    inst:AddComponent("constructionsite")
    inst.components.constructionsite:SetConstructionPrefab("construction_container")
    inst.components.constructionsite:SetOnConstructedFn(OnConstructed)

    -- 可检查
    inst:AddComponent("inspectable")

    return inst
end

return Prefab("aip_torch_stand_final", fn, assets, prefabs),
	MakePlacer("aip_torch_stand_final_placer", "aip_torch_stand", "aip_torch_stand", "final")