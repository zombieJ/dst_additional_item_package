local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Animal Box",
        REC_DESC = "Toggle show or hide small animals, if no small animals then not effective",
		DESC = "Who likes to hide in the box?",
        EMPTY = "I don't have any small animals yet!",
	},
	chinese = {
		NAME = "小动物纸箱",
        REC_DESC = "切换展示小动物，如果没有小动物则不生效",
		DESC = "谁最喜欢躲在盒子里？",
        EMPTY = "我还没有小动物呢！",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_PET_TRIGGER = LANG.NAME
STRINGS.RECIPE_DESC.AIP_PET_TRIGGER = LANG.REC_DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_PET_TRIGGER = LANG.DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_PET_TRIGGER_EMPTY = LANG.EMPTY

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_pet_trigger.zip"),
	Asset("ATLAS", "images/inventoryimages/aip_pet_trigger.xml"),
}

-------------------------------- 方法 --------------------------------
local function canBeActOn(inst, doer)
	return true
end

-- 触发宠物展示或隐藏
local function onDoAction(inst, doer)
    if doer.components.aipc_pet_owner ~= nil then
        if not doer.components.aipc_pet_owner:IsEmpty() then
            -- 没有则展示，有则隐藏
            if doer.components.aipc_pet_owner.showPet then
                doer.components.aipc_pet_owner:HidePet()
            else
                doer.components.aipc_pet_owner:ShowPet()
            end
        elseif doer.components.talker ~= nil then
            doer.components.talker:Say(
                STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_PET_TRIGGER_EMPTY
            )
        end
    end
end

-------------------------------- 实例 --------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("aip_pet_trigger")
    inst.AnimState:SetBuild("aip_pet_trigger")
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryFloatable(inst, "med", 0.3, 1)

    inst.entity:SetPristine()

    inst:AddComponent("aipc_action_client")
	inst.components.aipc_action_client.canBeActOn = canBeActOn

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("aipc_action")
	inst.components.aipc_action.onDoAction = onDoAction

    inst:AddComponent("inspectable")
    
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_pet_trigger.xml"

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("aip_pet_trigger", fn, assets)
