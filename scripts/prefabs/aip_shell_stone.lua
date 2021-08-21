local language = aipGetModConfig("language")

-- 资源
local assets = {
	Asset("ATLAS", "images/inventoryimages/aip_shell_stone.xml"),
	Asset("ANIM", "anim/aip_shell_stone.zip"),
}

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Cutter Strone",
		REC_DESC = "Find the cookie king!",
		DESC = "Ask the way by throw",
	},
	chinese = {
		NAME = "饼干碎石",
		REC_DESC = "用它来寻找大饼干",
		DESC = "投石问路！",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_SHELL_STONE = LANG.NAME
STRINGS.RECIPE_DESC.AIP_SHELL_STONE = LANG.REC_DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_SHELL_STONE = LANG.DESC

----------------------------------- 方法 -----------------------------------
local function canBeActOn()
	return true
end

local function onDoAction(inst, doer)
	local king = TheSim:FindFirstEntityWithTag("aip_cookiecutter_king")
	if king == nil then
		return
	end

	if doer.components.inventory ~= nil then
		doer.components.inventory:DropItem(inst, false)
	end

	inst:AddComponent("complexprojectile")
	inst.components.complexprojectile:SetHorizontalSpeed(15)
	inst.components.complexprojectile:SetGravity(-25)
	inst.components.complexprojectile:SetLaunchOffset(Vector3(.25, 1, 0))
	-- inst.components.complexprojectile:SetOnHit(OnHitSnow)

	local doerPos = doer:GetPosition()
	local angle = aipGetAngle(doerPos, king:GetPosition())
	local targetPos = aipAngleDist(doerPos, angle, 5)
	inst.components.complexprojectile:Launch(targetPos, doer)
end

----------------------------------- 实体 -----------------------------------
local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()
	
	MakeInventoryPhysics(inst)
	MakeInventoryFloatable(inst, "med", nil, 0.75)
	
	inst.AnimState:SetBank("aip_shell_stone")
	inst.AnimState:SetBuild("aip_shell_stone")
	inst.AnimState:PlayAnimation("idle")

	inst.entity:SetPristine()

	inst:AddTag("molebait")
	inst:AddTag("projectile")

	inst:AddComponent("aipc_action_client")
	inst.components.aipc_action_client.canBeCastOn = canBeActOn

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("locomotor")

	inst:AddComponent("aipc_action")
	inst.components.aipc_action.onDoAction = onDoAction

	inst:AddComponent("inspectable")

	inst:AddComponent("stackable")
	inst.components.stackable.maxsize = TUNING.STACK_SIZE_MEDITEM

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_shell_stone.xml"

	return inst
end

return Prefab("aip_shell_stone", fn, assets)

