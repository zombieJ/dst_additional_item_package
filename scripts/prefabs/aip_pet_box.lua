local language = aipGetModConfig("language")

local petConfig = require("configurations/aip_pet")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Animal Box",
        REC_DESC = "Put animal into box, can be given to others",
		DESC = "Who doesn't like a box?",
        EMPTY = "There is no animal around me!",
	},
	chinese = {
		NAME = "动物纸箱",
        REC_DESC = "将你的宠物收容到纸箱中，可用于赠与他人",
		DESC = "谁不喜欢纸箱子呢？",
        EMPTY = "还没有小动物在身边呢！",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_PET_BOX = LANG.NAME
STRINGS.RECIPE_DESC.AIP_PET_BOX = LANG.REC_DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_PET_BOX = LANG.DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_PET_BOX_EMPTY = LANG.EMPTY

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_pet_box.zip"),
	Asset("ATLAS", "images/inventoryimages/aip_pet_box.xml"),
    Asset("ATLAS", "images/inventoryimages/aip_pet_box_in.xml"),
}

-------------------------------- 方法 --------------------------------
local function canBeActOn(inst, doer)
	return true
end

-- 更新充能状态
local function refreshStatus(inst)
	-- 更新贴图
	if inst._aipPetData == nil then
		inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_pet_box.xml"
		inst.components.inventoryitem:ChangeImageName("aip_pet_box")
        inst.AnimState:PlayAnimation("idle")
	else
		inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_pet_box_in.xml"
		inst.components.inventoryitem:ChangeImageName("aip_pet_box_in")
        inst.AnimState:PlayAnimation("in", true)

        -- 更新描述信息
        local upperCase = string.upper(inst._aipPetData.prefab)
        local name = (STRINGS.NAMES[upperCase] or "UNKNOWN")

        local quality = inst._aipPetData.quality
        inst.components.aipc_info_client:SetString("aip_info", aipStr(petConfig.QUALITY_LANG[quality])..name)
        inst.components.aipc_info_client:SetByteArray("aip_info_color", petConfig.QUALITY_COLORS[quality])
	end
end

-- 触发宠物展示或隐藏
local function onDoAction(inst, doer)
    if doer.components.aipc_pet_owner == nil then
        return
    end

    -- >>>>>> 放入宠物
    if inst._aipPetData == nil then
        local pet = doer.components.aipc_pet_owner.showPet

        if pet and pet.components.aipc_petable ~= nil then
            -- 装进盒子里
            inst._aipPetData = pet.components.aipc_petable:GetInfo()

            -- 移除宠物
            if inst._aipPetData ~= nil then
                doer.components.aipc_pet_owner:RemovePet(inst._aipPetData.id)
                refreshStatus(inst)
                return
            end
        end

        -- 说没有宠物
        if doer.components.talker ~= nil then
            doer.components.talker:Say(
                STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_PET_BOX_EMPTY
            )
        end

    else -- >>>>>>> 取出宠物
        local pet = doer.components.aipc_pet_owner:AddPetByInfo(inst._aipPetData)
        if pet ~= nil then
            aipRemove(inst)
        end
    end
end

local function onDesc(inst, viewer)
    if
        viewer ~= nil and inst ~= nil and
        inst._aipPetData ~= nil and
        viewer.components.aipc_pet_owner ~= nil
    then
        -- 获取宠物信息
        local msgData = {
            current = 1,
            petInfos = { inst._aipPetData },
        }

        -- 加一个切割前缀强制服务器触发
        local dataStr = json.encode(msgData)
        viewer.player_classified.aip_pet_info:set(tostring(os.time()).."|"..dataStr)
    end
end

-------------------------------- 存取 --------------------------------
local function onSave(inst, data)
	data._aipPetData = inst._aipPetData
end

local function onLoad(inst, data)
	if data ~= nil then
		inst._aipPetData = data._aipPetData
		refreshStatus(inst)
	end
end

-------------------------------- 实例 --------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("aip_pet_box")
    inst.AnimState:SetBuild("aip_pet_box")
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryFloatable(inst, "med", 0.3, 1)

    inst.entity:SetPristine()

    inst:AddComponent("aipc_action_client")
	inst.components.aipc_action_client.canBeActOn = canBeActOn

    inst:AddComponent("aipc_info_client")
    inst:AddTag("_named")

    if not TheWorld.ismastersim then
        return inst
    end

    inst:RemoveTag("_named")

    inst:AddComponent("aipc_action")
	inst.components.aipc_action.onDoAction = onDoAction

    inst:AddComponent("inspectable")
    inst.components.inspectable.descriptionfn = onDesc

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_pet_box.xml"

    MakeHauntableLaunch(inst)

    -- 小动物信息
    inst._aipPetData = nil

    refreshStatus(inst)

    inst.OnLoad = onLoad
    inst.OnSave = onSave

    return inst
end

return Prefab("aip_pet_box", fn, assets)
