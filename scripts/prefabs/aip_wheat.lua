-- 开发模式
local dev_mode = aipGetModConfig("dev_mode") == "enabled"

local assets =
{
    Asset("ANIM", "anim/aip_wheat.zip"),
    Asset("SOUND", "sound/common.fsb"),
}

----------------------------- Function -----------------------------
-- 生长
local function onregenfn(inst)
    inst.AnimState:PlayAnimation("grow")
    inst.AnimState:PushAnimation("idle", true)
end

-- 捡起
local function onpickedfn(inst, picker)
    inst.SoundEmitter:PlaySound("dontstarve/wilson/pickup_reeds")
    inst.AnimState:PlayAnimation("picking")

    inst.AnimState:PushAnimation("picked", false)
end

-- 初始化置空
local function makeemptyfn(inst)
    inst.AnimState:PlayAnimation("picked")
end

-- 挖起
local function dig_up(inst, worker)
    if inst.components.pickable ~= nil and inst.components.lootdropper ~= nil then
        if inst.components.pickable:CanBePicked() then
            inst.components.lootdropper:SpawnLootPrefab(inst.components.pickable.product)
        end

        -- 掉落干草
        inst.components.lootdropper:SpawnLootPrefab("cutgrass")
    end
    inst:Remove()
end

------------------------------- Main -------------------------------
local function wheatFn()
	local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    -- inst.Transform:SetScale(1.2, 1.2, 1.2)

    inst.MiniMapEntity:SetIcon("grass.png")

    inst.AnimState:SetBank("aip_wheat")
    inst.AnimState:SetBuild("aip_wheat")
    inst.AnimState:PlayAnimation("idle", true)

    inst:AddTag("plant")
    -- inst:AddTag("renewable") 不可以再生
    inst:AddTag("silviculture") -- for silviculture book

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
        return inst
    end

    -- 没想到草居然还会随机上色……
    inst.AnimState:SetTime(math.random() * 2)
    local color = 0.75 + math.random() * 0.25
    inst.AnimState:SetMultColour(color, color, color, 1)

    inst:AddComponent("pickable")
    inst.components.pickable.picksound = "dontstarve/wilson/pickup_reeds"

    inst.components.pickable:SetUp("cutgrass", dev_mode and 1 or TUNING.GRASS_REGROW_TIME)
    inst.components.pickable.onregenfn = onregenfn
    inst.components.pickable.onpickedfn = onpickedfn
    inst.components.pickable.makeemptyfn = makeemptyfn
    -- 永不贫瘠
    -- inst.components.pickable.makebarrenfn = makebarrenfn
    -- inst.components.pickable.max_cycles = 20
    -- inst.components.pickable.cycles_left = 20
    -- inst.components.pickable.ontransplantfn = ontransplantfn

    inst:AddComponent("lootdropper")
    inst:AddComponent("inspectable")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.DIG)
    inst.components.workable:SetOnFinishCallback(dig_up)
    inst.components.workable:SetWorkLeft(1)

    MakeMediumBurnable(inst)
    MakeSmallPropagator(inst)
    MakeNoGrowInWinter(inst)
    MakeHauntableIgnite(inst)

	return inst
end

return Prefab("aip_wheat", wheatFn, assets)
