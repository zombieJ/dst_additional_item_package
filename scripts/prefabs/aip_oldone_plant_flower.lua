local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Spring Puzzle",
		DESC = "Let's plant flower!",
	},
	chinese = {
		NAME = "春日谜团",
		DESC = "种上鲜花吧",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_OLDONE_PLANT_FLOWER = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_PLANT_FLOWER = LANG.DESC

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_oldone_plant_flower.zip"),
}

------------------------------- 事件 --------------------------------
local function onNear(inst, player)
    inst.components.aipc_timer:NamedInterval("PlayerNear", 0.4, function()
        local flowers = aipFindNearEnts(inst, { "flower" }, 0.6)

        if #flowers > 0 then
            aipRemove(flowers[1])

            for i = 1, #flowers do
                aipFlingItem(flowers[i])
            end

            -- 播放一个闪现特效
            inst:DoTaskInTime(0.5, function()
                aipSpawnPrefab(inst, "aip_shadow_wrapper").DoShow(0.6)
            end)
            inst:RemoveComponent("aipc_timer")

            -- 增加模因因子
            local players = aipFindNearPlayers(inst, 3)
            for i, player in ipairs(players) do
                if player ~= nil and player.components.aipc_oldone ~= nil then
                    player.components.aipc_oldone:DoDelta()
                end
            end

            -- 消失吧
            inst:DoTaskInTime(1, function()
                aipReplacePrefab(inst, "aip_shadow_wrapper").DoShow()
            end)
        end
    end)
end

local function onFar(inst)
    inst.components.aipc_timer:KillName("PlayerNear")
end

local function initMatrix(inst)
    local angle = 360 * math.random()
    inst.Transform:SetRotation(angle)
end

local function onWorldState(inst, season)
    if season ~= "spring" then
        aipReplacePrefab(inst, "aip_shadow_wrapper").DoShow()
    end
end

------------------------------- 实例 --------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    local scale = 0.9
    inst.Transform:SetScale(scale, scale, scale)

    inst.AnimState:SetBank("aip_oldone_plant_flower")
    inst.AnimState:SetBuild("aip_oldone_plant_flower")
    inst.AnimState:PlayAnimation("idle")

    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_WORLD_BACKGROUND)
    inst.AnimState:SetSortOrder(0)

    inst:AddTag("NOCLICK")
    inst:AddTag("FX")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("playerprox")
    inst.components.playerprox:SetDist(8, 8)
    inst.components.playerprox:SetOnPlayerNear(onNear)
    inst.components.playerprox:SetOnPlayerFar(onFar)

    inst:AddComponent("aipc_timer")

    inst:WatchWorldState("season", onWorldState)

    inst:DoTaskInTime(0.001, initMatrix)

    return inst
end

return Prefab("aip_oldone_plant_flower", fn, assets)
