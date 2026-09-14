if aipGetModConfig("dev_mode") ~= "enabled" then return end

STRINGS.NAMES.AIP_PIG_KING_TRAIN_TEST_TICKET = "测试实验券"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_PIG_KING_TRAIN_TEST_TICKET = "使用后自动测试观光列车，结束时暂停并分批报告。"
local assets = {
	Asset("ANIM", "anim/aip_train_ticket.zip"),
	Asset("ATLAS", "images/inventoryimages/aip_train_ticket.xml"),
}

-- 开发券在物品栏中右键使用，实际检查均由服务端执行。
local function CanUse(inst, doer)
	return doer ~= nil and not doer:HasTag("playerghost")
end

-- 每张券可反复使用；再次触发会先清理旧会话，再从第一项重新开始。
local function OnUse(inst, doer)
	if doer == nil or not doer:IsValid() or not CanUse(inst, doer) then return end
	local owner = inst.components.inventoryitem:GetGrandOwner()
	if owner ~= doer then return end
	require("dev/aip_pig_king_train_tests").Start(doer)
end

-- 复用正式券素材，不创建编译资源，退出开发模式后不留下测试物品。
local function Fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()
	MakeInventoryPhysics(inst)
	inst.AnimState:SetBank("aip_train_ticket")
	inst.AnimState:SetBuild("aip_train_ticket")
	inst.AnimState:PlayAnimation("idle")
	inst:AddComponent("aipc_action_client")
	inst.components.aipc_action_client.canBeActOn = CanUse
	inst.persists = false
	inst.entity:SetPristine()
	if not TheWorld.ismastersim then return inst end
	inst:AddComponent("inspectable")
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.imagename = "aip_train_ticket"
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_train_ticket.xml"
	inst:AddComponent("aipc_action")
	inst.components.aipc_action.onDoAction = OnUse
	return inst
end

return Prefab("aip_pig_king_train_test_ticket", Fn, assets)
