local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Animal Dessert",
        REC_DESC = "Catch small animals. The higher the quality of the small animals, the harder to catch.",
		DESC = "Catch small animals",
        SUCCESS = "It works!",
        ESCAPE = "Not work as expected",
        FULL = "I have too many pets",
	},
	chinese = {
		NAME = "小动物甜品",
        REC_DESC = "用于捕捉小动物，品质越高的小动物越难捕捉",
		DESC = "用于捕捉小动物",
        SUCCESS = "成功啦！",
        ESCAPE = "没有吸引到它",
        FULL = "我已经有太多宠物了",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_PET_CATCHER = LANG.NAME
STRINGS.RECIPE_DESC.AIP_PET_CATCHER = LANG.REC_DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_PET_CATCHER = LANG.DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_PET_CATCHER_SUCCESS = LANG.SUCCESS
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_PET_CATCHER_ESCAPE = LANG.ESCAPE
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_PET_CATCHER_FULL = LANG.FULL

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_pet_catcher.zip"),
	Asset("ATLAS", "images/inventoryimages/aip_pet_catcher.xml"),
}

local petConfig = require("configurations/aip_pet")
local QUALITY_COLORS = petConfig.QUALITY_COLORS

----------------------------------- 方法 -----------------------------------
local function canActOn()
    return true, true
end

local function onDoTargetAction(inst, doer, target)
    if target ~= nil then
        aipRemove(inst)

        local clone = aipSpawnPrefab(doer, "aip_pet_catcher")
        clone.components.complexprojectile:Launch(target:GetPosition(), doer)
    end
end

local function onLaunch(inst)
    inst.AnimState:PlayAnimation("loop", true)
end

-- 捕捉
local function onHit(inst, attacker, target)
    local aura = aipReplacePrefab(inst, "aip_fx_splode").DoShow(nil, 0.5)

    if not attacker or not attacker.components.aipc_pet_owner then
        return
    elseif attacker.components.aipc_pet_owner:IsFull() then
        if attacker.components.talker ~= nil then
            attacker.components.talker:Say(
                STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_PET_CATCHER_FULL
            )
        end

        return
    end

    local pt = inst:GetPosition()

    -- 寻找野生的
    local ents = TheSim:FindEntities(
        pt.x, pt.y, pt.z, 3,
        {"aip_petable"}, { "FX", "NOCLICK", "DECOR", "INLIMBO" }
    )
    ents = aipFilterTable(ents, function (ent)
        return ent.components.aipc_petable ~= nil and ent.components.aipc_petable.owner == nil
    end)

    local ent = ents[1]
    if ent ~= nil then
        local chance = ent.components.aipc_petable:GetQualityChance()

        -- 如果有 游说 技能宠物，则提升捕捉概率
        local skillInfo, skillLv = attacker.components.aipc_pet_owner:GetSkillInfo("eloquence")
        if skillInfo ~= nil then
            chance = chance + skillInfo.multi * skillLv
        end

        if aipChance(chance, attacker) then
            aipRemove(ent)

            -- 伯乐 宠物有概率提升品质
            local enhanceQuality = 0
            local skillInfo, skillLv = attacker.components.aipc_pet_owner:GetSkillInfo("insight")
            if skillInfo ~= nil then
                local enhanceQualityChance = skillInfo.multi * skillLv

                -- 如果是唯一的宠物，则 100%
                if attacker.components.aipc_pet_owner:Count() <= 1 then
                    enhanceQualityChance = 1
                end

                enhanceQuality = math.random() <= enhanceQualityChance and 1 or 0
            end

            local quality = ent.components.aipc_petable:GetQuality()

            -- 重置小动物数据
            ent.components.aipc_petable:ResetInfo()

            -- 记录宠物
            local pet = attacker.components.aipc_pet_owner:AddPet(ent, enhanceQuality)
            quality = pet.components.aipc_petable:GetQuality()

            -- 说话
            if attacker.components.talker ~= nil then
                attacker.components.talker:Say(
                    STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_PET_CATCHER_SUCCESS
                )
            end
        else
            -- 临时展示一下光环
            ent.components.aipc_petable:ShowClientAura()

            -- 说话
            if attacker.components.talker ~= nil then
                attacker.components.talker:Say(
                    STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_PET_CATCHER_ESCAPE
                )
            end
        end
    end
end

----------------------------------- 实例 -----------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("aip_pet_catcher")
    inst.AnimState:SetBuild("aip_pet_catcher")
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryFloatable(inst, "med", 0.3, 1)

    inst:AddComponent("aipc_action_client")
	inst.components.aipc_action_client.canActOn = canActOn

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("aipc_action")
	inst.components.aipc_action.onDoTargetAction = onDoTargetAction

    inst:AddComponent("stackable")
	inst.components.stackable.maxsize = TUNING.STACK_SIZE_MEDITEM

    inst:AddComponent("complexprojectile")
    inst.components.complexprojectile:SetHorizontalSpeed(15)
    inst.components.complexprojectile:SetGravity(-25)
    inst.components.complexprojectile:SetLaunchOffset(Vector3(0, 2.5, 0))
    inst.components.complexprojectile:SetOnLaunch(onLaunch)
    inst.components.complexprojectile:SetOnHit(onHit)

    inst:AddComponent("inspectable")
    
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_pet_catcher.xml"

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("aip_pet_catcher", fn, assets)
