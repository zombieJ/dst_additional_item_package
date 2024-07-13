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
        DESC = "It longs to be illuminated by the warm and cold firelight",
        NAME_MAIN = "Guarded Moonlight Torch",
        NAME_PILLAR = "Shaded Moonlight Torch",
        NAME_CRAB = "Clawed Moonlight Torch",
        NAME_PORTAL = "Jungle Moonlight Torch",
        NAME_CRITTER = "Hidden Moonlight Torch",
    },
    chinese = {
        NAME = "月光火柱",
        DESC = "它渴望被即温暖又寒冷的火光照亮",
        NAME_MAIN = "受看管的月光柱",
        NAME_PILLAR = "荫蔽的月光柱",               -- 大树干 watertree_pillar
        NAME_CRAB = "巨钳的月光柱",                 -- 帝王蟹 crabking
        NAME_PORTAL = "丛林的月光柱",               -- 猴岛传送门 monkeyisland_portal
        NAME_CRITTER = "躲藏的月光柱",              -- 小动物巢穴 critterlab
    }
}

local LANG = LANG_MAP[language] or LANG_MAP.english

local assets = {
    Asset("ANIM", "anim/aip_torch_stand.zip"),
}

local list = {
    {
        name = "main",
        postFn = function(inst)
            -- 火焰永不熄灭
            inst.components.aipc_type_fire.forever = true

            -- 起始图腾可以召唤熊峰
            inst:DoTaskInTime(1, function()
                local bee = aipSpawnPrefab(inst, "aip_nectar_bee")
                bee.aipHome = inst:GetPosition()
            end)
        end,
    },
    {
        name = "pillar",
        target = "watertree_pillar",
    },
    {
        name = "crab",
        target = "crabking",
    },
    {
        name = "portal",
        target = "monkeyisland_portal",
    },
    {
        name = "critter",
        target = "critterlab",
    },
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

local function onhit(inst, worker)
    inst.AnimState:PlayAnimation("hit")
    inst.AnimState:PushAnimation("idle")
end

-- 让火可以点燃不同类型的火焰
local function postTypeFire(inst, fx, type)
    fx:RemoveTag("aip_rubik_fire")

    if type == "mix" then
        fx.AnimState:OverrideMultColour(1, 0, 1, 1)
    end

    if fx.components.firefx then
        fx.components.firefx:SetLevel(2)
    end

    fx:AddTag("aip_rubik_fire")
    fx:AddTag("aip_rubik_fire_"..type)

    -- 冰火 会比 火 高一点，我们特调一下
    if type == "hot" then
        inst.AnimState:PlayAnimation("idle_hot", false)
    else
        inst.AnimState:PlayAnimation("idle", false)
    end
end

------------------------------------ 启迪 ------------------------------------
-- 启迪一个下一个地点
local function toggleActive(inst, doer)
    inst.components.activatable.inactive = true

    if doer.player_classified ~= nil then
        doer.player_classified.revealmapspot_worldx:set(x)
        doer.player_classified.revealmapspot_worldz:set(z)
        doer.player_classified.revealmapspotevent:push()

		doer:DoStaticTaskInTime(4*FRAMES, function()
			doer.player_classified.MapExplorer:RevealArea(x, y, z, true, true)
		end)
	end
end

------------------------------------ 存取 ------------------------------------
local function onSave(inst, data)
	
end

local function onLoad(inst, data)
	if data ~= nil then
		
	end
end

------------------------------------ 实例 ------------------------------------
local function commonFn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    -- 碰撞体积
    MakeObstaclePhysics(inst, .1)

    -- 动画
    inst.AnimState:SetBank("aip_torch_stand")
    inst.AnimState:SetBuild("aip_torch_stand")
    inst.AnimState:PlayAnimation("idle", false)

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
    inst.components.workable:SetOnWorkCallback(onhit)

    -- 可以激活
    inst:AddComponent("activatable")
	inst.components.activatable.OnActivate = toggleActive
    inst.components.activatable.quickaction = true

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

    inst.OnSave = onSave
    inst.OnLoad = onLoad

    return inst
end

-- 遍历生成
local prefabList = {}
for i, info in ipairs(list) do
    local name = "aip_torch_stand_"..info.name
    local upName = string.upper(name)

    -- 文字描述
    STRINGS.NAMES[upName] = LANG["NAME_"..string.upper(info.name)]
    STRINGS.CHARACTERS.GENERIC.DESCRIBE[upName] = LANG.DESC

    local fn = function()
        local inst = commonFn()
        inst:AddTag(name)

        if not TheWorld.ismastersim then return inst end

        if info.postFn then
            info.postFn(inst)
        end

        return inst
    end

    table.insert(prefabList, Prefab(name, fn, assets))
end

return unpack(prefabList)