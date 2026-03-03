local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Rice Ballx",
		DESC = "Let's fill with rice ball",
	},
	chinese = {
		NAME = "饭团盒",
		DESC = "它能装多少个饭团呢？",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_OLDONE_RICE = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDONE_RICE = LANG.DESC

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_oldone_rice.zip"),
}

------------------------------ 事件 ------------------------------
local function onopen(inst)
    inst.SoundEmitter:PlaySound("dontstarve/wilson/chest_open")
end

local function onclose(inst)
    inst.SoundEmitter:PlaySound("dontstarve/wilson/chest_close")
end

local function onItemGet(inst)
    if inst.components.container ~= nil and inst.components.container:IsFull() then
        local players = aipFindNearPlayers(inst, 8)
        for i, player in ipairs(players) do
            if player ~= nil and player.components.aipc_oldone ~= nil then
                player.components.aipc_oldone:DoDelta()
            end
        end

        aipReplacePrefab(inst, "aip_shadow_wrapper").DoShow()
    end
end

------------------------------ 实例 ------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 0.2, 0.5)

    inst.AnimState:SetBank("aip_oldone_rice")
    inst.AnimState:SetBuild("aip_oldone_rice")
    inst.AnimState:PlayAnimation("idle")

    local scale = 0.5
    inst.Transform:SetScale(scale, scale, scale)

    inst:AddTag("aip_olden_flower")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("aip_oldone_rice")
    inst.components.container.onopenfn = onopen
    inst.components.container.onclosefn = onclose
    inst.components.container.skipclosesnd = true
    inst.components.container.skipopensnd = true

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

    inst.persists = false

    inst:ListenForEvent("itemget", onItemGet)

    return inst
end

return Prefab("aip_oldone_rice", fn, assets)
