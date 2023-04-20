local language = aipGetModConfig("language")

local brain = require("brains/aip_pet_brain")
local petConfig = require("configurations/aip_pet")
local petPrefabs = require("configurations/aip_pet_prefabs")

-- 文字描述
local LANG_MAP = {
	english = {
        REMOVE = "It's gone!",
	},
	chinese = {
		REMOVE = "它被气走了！",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_PET_REMOVE = LANG.REMOVE

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

-- 可接受食物
local function ShouldAcceptItem(inst, item)
    return item and item.components.edible ~= nil
end

-- 从玩家获取物品
local function OnGetItemFromPlayer(inst, giver, item)
    if item and item.components.edible ~= nil then
        -- 吃掉物品
        aipRemove(item)

        if giver and giver.components.aipc_pet_owner then
            local petId = inst.components.aipc_petable:GetInfo().id

            -- 榴莲糖会赶走小动物
            if item.prefab == "durian_sugar" then
                local ret = giver.components.aipc_pet_owner:RemovePet(petId)

                if ret and giver.components.talker then
                    giver.components.talker:Say(
                        STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_PET_REMOVE
                    )
                end
            
            -- 提升小动物技能等级
            else
                local aipc_pet_owner = aipGet(inst, "components|aipc_petable|owner|components|aipc_pet_owner")
                aipPrint("aipc_pet_owner:", aipc_pet_owner)
                aipc_pet_owner:UpgradePet(petId)
            end
        end
    end
end

----------------------------------- 实例 -----------------------------------
local function createPet(name, info)
    local upperCase = string.upper(name)
    local upperOrigin = string.upper(info.origin)

    STRINGS.NAMES[upperCase] = STRINGS.NAMES[upperOrigin]
    STRINGS.CHARACTERS.GENERIC.DESCRIBE[upperCase] = STRINGS.CHARACTERS.GENERIC.DESCRIBE[upperOrigin]

    local scale = info.scale or 0.75

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddDynamicShadow()
        inst.entity:AddNetwork()

        MakeFlyingCharacterPhysics(inst, 1, .5)

        inst.DynamicShadow:SetSize(1, .75)

        if info.face == 2 then
            inst.Transform:SetTwoFaced()
        elseif info.face == 6 then
            inst.Transform:SetSixFaced()
        else
            inst.Transform:SetFourFaced()
        end

        if info.bb then
            inst.AnimState:SetRayTestOnBB(true)
        end

        inst.Transform:SetScale(scale, scale, scale)

        inst.AnimState:SetBank(info.bank)
        inst.AnimState:SetBuild(info.build)
        inst.AnimState:PlayAnimation(info.anim)

        inst:AddComponent("aipc_petable")
        inst:AddComponent("aipc_info_client")

        inst:AddTag("_named")
        -- inst:AddTag("_writeable")

        if info.tags ~= nil then
            for _, tag in ipairs(info.tags) do
                inst:AddTag(tag)
            end
        end

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
        -- inst.components.locomotor.runspeed = TUNING.HOUND_SPEED -- TUNING.WILSON_RUN_SPEED
        -- inst.components.locomotor.walkspeed = TUNING.HOUND_SPEED -- TUNING.WILSON_WALK_SPEED
        inst.components.locomotor.pathcaps = { ignorecreep = true, allowocean = true }

        -- 小动物可以靠吃东西提升等级
        inst:AddComponent("trader")
        inst.components.trader:SetAcceptTest(ShouldAcceptItem)
        inst.components.trader.onaccept = OnGetItemFromPlayer
        inst.components.trader.deleteitemonaccept = false

        if info.postInit ~= nil then
            info.postInit(inst)
        end

        inst:SetStateGraph(info.sg)
        inst:SetBrain(brain)

        inst.persists = false

        inst:DoTaskInTime(.1, syncPetInfo)

        return inst
    end

    return fn
end

----------------------------------- 列表 -----------------------------------

local prefabs = {}

for name, info in pairs(petPrefabs.PREFABS) do
    local prefabName = "aip_pet_"..name
    local prefab = Prefab(prefabName, createPet(prefabName, info), {})
    table.insert(prefabs, prefab)
end

return unpack(prefabs)
