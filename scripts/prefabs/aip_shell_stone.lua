local language = aipGetModConfig("language")
local dev_mode = aipGetModConfig("dev_mode") == "enabled"

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
		SHOW = "Show me the way!",
		DESC_BROKEN = "It shows the direction",
		DISABLED = "Seems he is gone",
	},
	chinese = {
		NAME = "饼干碎石",
		REC_DESC = "用它来寻找大饼干",
		DESC = "投石问路！",
		SHOW = "帮我指明方向吧",
		DESC_BROKEN = "朝着它的方向找去",
		DISABLED = "看起来它已经离开了",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_SHELL_STONE = LANG.NAME
STRINGS.RECIPE_DESC.AIP_SHELL_STONE = LANG.REC_DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_SHELL_STONE = LANG.DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_SHELL_STONE_SHOW = LANG.SHOW
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_SHELL_STONE_DISABLED = LANG.DISABLED
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_SHELL_STONE_BROKEN = LANG.DESC_BROKEN

----------------------------------- 方法 -----------------------------------
-- 获取描述
local function getDesc(inst, viewer)
	if inst.persists == false then
		return STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_SHELL_STONE_BROKEN
	end
end

local function canBeActOn()
	return true
end

local function onHit(inst)
	inst.persists = false
	inst.AnimState:PlayAnimation("broken")
	inst.SoundEmitter:PlaySound("dontstarve/common/together/catapult/rock_hit")
	inst:RemoveComponent("inventoryitem")
	inst:DoTaskInTime(dev_mode and 10 or 120, inst.Remove)
end

local function onDoAction(inst, doer)
	local king = TheSim:FindFirstEntityWithTag("aip_cookiecutter_king")
	if king == nil then
		if doer.components.talker ~= nil then
			doer.components.talker:Say(
				STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_SHELL_STONE_DISABLED
			)
		end
		return
	end

	local current = inst
	if doer.components.inventory ~= nil then
		current = doer.components.inventory:DropItem(inst, false)
	end

	current:AddComponent("complexprojectile")
	current.components.complexprojectile:SetHorizontalSpeed(15)
	current.components.complexprojectile:SetGravity(-25)
	current.components.complexprojectile:SetLaunchOffset(Vector3(.25, 1, 0))
	current.components.complexprojectile:SetOnHit(onHit)

	current.Physics:Stop()

	local doerPos = doer:GetPosition()
	local angle = aipGetAngle(doerPos, king:GetPosition())
	local targetPos = aipAngleDist(doerPos, angle, 5)
	current.components.complexprojectile:Launch(targetPos, doer)

	if doer.components.talker ~= nil then
		doer.components.talker:Say(
			STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_SHELL_STONE_SHOW
		)
	end
end

----------------------------------- 实体 -----------------------------------
local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
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
	inst.components.inspectable.getspecialdescription = getDesc

	inst:AddComponent("stackable")
	inst.components.stackable.maxsize = TUNING.STACK_SIZE_MEDITEM

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_shell_stone.xml"

	return inst
end

return Prefab("aip_shell_stone", fn, assets)

