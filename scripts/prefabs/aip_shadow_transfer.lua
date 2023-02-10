local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Transfer",
        REC_DESC = "Move building to other place",
		DESC = "Why it seems so happy?",
	},
	chinese = {
		NAME = "搬运石偶",
        REC_DESC = "将建筑搬运至另一个地方",
		DESC = "它的快乐我不能理解",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_SHADOW_TRANSFER = LANG.NAME
STRINGS.RECIPE_DESC.AIP_SHADOW_TRANSFER = LANG.REC_DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_SHADOW_TRANSFER = LANG.DESC

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_shadow_transfer.zip"),
	Asset("ATLAS", "images/inventoryimages/aip_shadow_transfer.xml"),
    Asset("ATLAS", "images/inventoryimages/aip_shadow_transfer_charged.xml"),
}

------------------------------------ 事件 ------------------------------------
local function ondeploy(inst, pt, deployer)
    if inst.components.aipc_shadow_transfer ~= nil then
        inst.components.aipc_shadow_transfer:MoveTo(pt, deployer)
    end
end

local function onToggle(inst, marked)
    -- 更新贴图
	if marked then
        inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_shadow_transfer_charged.xml"
        inst.components.inventoryitem:ChangeImageName("aip_shadow_transfer_charged")
		inst.AnimState:PlayAnimation("charged", false)

        if inst.components.deployable == nil then
            inst:AddComponent("deployable")
            inst.components.deployable.ondeploy = ondeploy
            inst.components.deployable:SetDeploySpacing(DEPLOYSPACING.LESS)
        end
	else
        inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_shadow_transfer.xml"
        inst.components.inventoryitem:ChangeImageName("aip_shadow_transfer")
		inst.AnimState:PlayAnimation("idle", false)

        if inst.components.deployable ~= nil then
            inst:RemoveComponent("deployable")
        end
	end
end

-- 如果是错误加载，则直接删除
local function cleanUp(inst)
    local pt = inst:GetPosition()
    if pt.x == 0 and pt.y == 0 and pt.z == 0 then
        inst:Remove()
    end
end

------------------------------------ 实例 ------------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("aip_shadow_transfer")
    inst.AnimState:SetBuild("aip_shadow_transfer")
    inst.AnimState:PlayAnimation("idle")

    inst:AddComponent("aipc_shadow_transfer")
    inst.components.aipc_shadow_transfer.onToggle = onToggle

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_shadow_transfer.xml"
    inst.components.inventoryitem.imagename = "aip_shadow_transfer"

    MakeHauntableLaunch(inst)

    inst:DoTaskInTime(1, cleanUp)

    return inst
end

return Prefab("aip_shadow_transfer", fn, assets)
