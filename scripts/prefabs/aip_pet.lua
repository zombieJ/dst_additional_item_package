local language = aipGetModConfig("language")

local brain = require("brains/aip_pet_brain")
local petConfig = require("configurations/aip_pet")

----------------------------------- 说明 -----------------------------------
-- 名字带上品质
local function syncPetInfo(inst)
    if inst.components.aipc_petable and inst.components.aipc_info_client then
        local quality = inst.components.aipc_petable:GetQuality()
		inst.components.aipc_info_client:SetString("aip_info", aipStr(petConfig.QUALITY_LANG[quality]))
		inst.components.aipc_info_client:SetByteArray("aip_info_color", petConfig.QUALITY_COLORS[quality])
	end
end

-- 检查时弹出窗口
local function onSelect(inst, viewer)
    if
        viewer ~= nil and inst ~= nil and
        inst.components.aipc_petable ~= nil and
        viewer.components.aipc_pet_owner ~= nil
    then
        -- 获取宠物信息
        local petInfo = inst.components.aipc_petable:GetInfo()
        local msgData = {
            current = 1,
            petInfos = { petInfo },
        }
        

        -- 如果是同一个主人，其他的宠物也能看到
        if inst.components.aipc_petable.owner == viewer then
            msgData.owner = true
            msgData.petInfos = viewer.components.aipc_pet_owner:GetInfos()
            msgData.current = aipTableIndex(msgData.petInfos, function(v)
                return v.id == petInfo.id
            end)
            aipPrint("Current pet index: "..msgData.current)
        end

        -- 加一个切割前缀强制服务器触发
        local dataStr = json.encode(msgData)
        viewer.player_classified.aip_pet_info:set(tostring(os.time()).."|"..dataStr)
    end
end

local function OnNamedByWriteable(inst, new_name, writer)
    if inst.components.named ~= nil then
        inst.components.named:SetName(new_name, writer ~= nil and writer.userid or nil)
    end
end

----------------------------------- 实例 -----------------------------------
local function createPet(name, info)
    local upperCase = string.upper(name)
    local upperOrigin = string.upper(info.origin)

    STRINGS.NAMES[upperCase] = STRINGS.NAMES[upperOrigin]
    STRINGS.CHARACTERS.GENERIC.DESCRIBE[upperCase] = STRINGS.CHARACTERS.GENERIC.DESCRIBE[upperOrigin]

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddDynamicShadow()
        inst.entity:AddNetwork()

        MakeFlyingCharacterPhysics(inst, 1, .5)

        inst.DynamicShadow:SetSize(1, .75)
        inst.Transform:SetFourFaced()

        inst.AnimState:SetBank(info.bank)
        inst.AnimState:SetBuild(info.build)
        inst.AnimState:PlayAnimation(info.anim)

        inst:AddComponent("aipc_petable")
        inst:AddComponent("aipc_info_client")

        inst:AddTag("_named")
        -- inst:AddTag("_writeable")

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:RemoveTag("_named")
        -- inst:RemoveTag("_writeable")

        inst:AddComponent("named")
        inst:AddComponent("inspectable")
        inst.components.inspectable.descriptionfn = onSelect

        -- inst:AddComponent("writeable")
        -- inst.components.writeable:SetOnWrittenFn(OnNamedByWriteable)

        inst.sounds = info.sounds

        inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
        inst.components.locomotor.runspeed = TUNING.WILSON_RUN_SPEED
        inst.components.locomotor.walkspeed = TUNING.WILSON_WALK_SPEED

        inst:SetStateGraph(info.sg)
        inst:SetBrain(brain)

        inst.persists = false

        inst:DoTaskInTime(.1, syncPetInfo)

        return inst
    end

    return fn
end

----------------------------------- 列表 -----------------------------------
local data = {
    rabbit = {
        bank = "rabbit",
        build = "rabbit_build",
        anim = "idle",
        sg = "SGrabbit",
        sounds = {
            scream = "dontstarve/rabbit/scream",
            hurt = "dontstarve/rabbit/scream_short",
        },
        origin = "rabbit",
    },
    rabbit_winter = {
        bank = "rabbit",
        build = "rabbit_winter_build",
        anim = "idle",
        sg = "SGrabbit",
        sounds = {
            scream = "dontstarve/rabbit/winterscream",
            hurt = "dontstarve/rabbit/winterscream_short",
        },
        origin = "rabbit",
    },
    rabbit_crazy = {
        bank = "rabbit",
        build = "beard_monster",
        anim = "idle",
        sg = "SGrabbit",
        sounds = {
            scream = "dontstarve/rabbit/scream",
            hurt = "dontstarve/rabbit/scream_short",
        },
        origin = "rabbit",
    },
}
local prefabs = {}

for name, info in pairs(data) do
    local prefabName = "aip_pet_"..name
    local prefab = Prefab(prefabName, createPet(prefabName, info), {})
    table.insert(prefabs, prefab)
end

return unpack(prefabs)
