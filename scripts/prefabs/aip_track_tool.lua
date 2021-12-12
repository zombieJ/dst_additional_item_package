-- 武器关闭
local additional_weapon = aipGetModConfig("additional_weapon")

local weapon_damage = aipGetModConfig("weapon_damage")
local language = aipGetModConfig("language")

-- 默认参数
local USES_MAP = {
	less = 50,
	normal = 100,
	much = 150,
}
local DAMAGE_MAP = {
	less = TUNING.CANE_DAMAGE * 0.8,
	normal = TUNING.CANE_DAMAGE,
	large = TUNING.CANE_DAMAGE * 1.5,
}

local LANG_MAP = {
	english = {
		NAME = "Weak Holder",
		REC_DESC = "Create a shadow track",
		DESC = "Mixed with moon and shadow",
	},
	chinese = {
		NAME = "幻影之握",
		REC_DESC = "制作一条暗影轨道",
		DESC = "暗影与月光的奇艺融合",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

TUNING.AIP_TRACK_TOOLE_DAMAGE =  DAMAGE_MAP[weapon_damage]

-- 资源
local assets = {
	Asset("ATLAS", "images/inventoryimages/aip_track_tool.xml"),
	Asset("ANIM", "anim/aip_track_tool.zip"),
	Asset("ANIM", "anim/aip_track_tool_swap.zip"),
	Asset("ANIM", "anim/aip_glass_orbit_point.zip"),
}

local prefabs = {}

-- 文字描述
STRINGS.NAMES.AIP_TRACK_TOOL = LANG.NAME
STRINGS.RECIPE_DESC.AIP_TRACK_TOOL = LANG.REC_DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_TRACK_TOOL = LANG.DESC

--------------------------------- 装备 ---------------------------------
local function onequip(inst, owner)
	owner.AnimState:OverrideSymbol("swap_object", "aip_track_tool_swap", "aip_track_tool_swap")
	owner.SoundEmitter:PlaySound("dontstarve/wilson/equip_item_gold")
	owner.AnimState:Show("ARM_carry")
	owner.AnimState:Hide("ARM_normal")
end

local function onunequip(inst, owner)
	owner.AnimState:ClearOverrideSymbol("swap_object")
	owner.AnimState:Hide("ARM_carry")
	owner.AnimState:Show("ARM_normal")
end

--------------------------------- 部署 ---------------------------------
local function canActOnPoint()
	return true
end

local function canActOn(inst, doer, target)
	return target ~= nil and target.prefab == "aip_glass_orbit_point"
end

-- 寻找附近的标记点
local function findNearByPoint(pt)
	local ents = TheSim:FindEntities(pt.x, 0, pt.z, 2, { "aip_glass_orbit_point" })
	return ents[1]
end

-- 在点制造轨道
local function onDoPointAction(inst, creator, targetPos)
    local startPos = creator:GetPosition()

	-- 起始点：如果附近有点就不创建
	local startP = findNearByPoint(startPos)
	if startP == nil then
		startP = aipSpawnPrefab(creator, "aip_glass_orbit_point")
		aipSpawnPrefab(startP, "aip_shadow_wrapper").DoShow()
	end

	-- 目的地：如果附近有点就不创建
	local endP = findNearByPoint(targetPos)
	if endP == nil then
		endP = aipSpawnPrefab(nil, "aip_glass_orbit_point", targetPos.x, 0, targetPos.z)
		aipSpawnPrefab(endP, "aip_shadow_wrapper").DoShow()
	end

	-- 不是同一个节点的时候链接起来
	if startP ~= nil and endP ~= nil and startP ~= endP then
		-- startP.components.aipc_orbit_link:Add(endP)
		-- endP.components.aipc_orbit_link:Add(startP)
		local endPos = endP:GetPosition()
		local centerPt = Vector3(
			(startPos.x + endPos.x) / 2,
			0,
			(startPos.z + endPos.z) / 2
		)

		local link = aipSpawnPrefab(nil, "aip_glass_orbit_link", centerPt.x, centerPt.y, centerPt.z)
		link.components.aipc_orbit_link:Link(startP, endP)
	end
end

-- 拆出轨道点
local function onDoTargetAction(inst, doer, target)
	if target == nil then
		return
	end

	local linkList = aipFindEnts("aip_glass_orbit_link")
	for i, v in ipairs(linkList) do
		if v.components.aipc_orbit_link:Includes(target) then
			v:Remove()
		end
	end

	target:Remove()
end

--------------------------------- 实例 ---------------------------------
function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()
	
	MakeInventoryPhysics(inst)
	
	inst.AnimState:SetBank("aip_track_tool")
	inst.AnimState:SetBuild("aip_track_tool")
	inst.AnimState:PlayAnimation("idle")

	inst:AddTag("show_spoilage")
	inst:AddTag("icebox_valid")

	inst:AddComponent("aipc_action_client")
	inst.components.aipc_action_client.canActOnPoint = canActOnPoint
	inst.components.aipc_action_client.canActOn = canActOn

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(TUNING.AIP_TRACK_TOOLE_DAMAGE)

	inst:AddComponent("inspectable")

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_track_tool.xml"

	-- 施法
    inst:AddComponent("aipc_action")
    inst.components.aipc_action.onDoPointAction = onDoPointAction
	inst.components.aipc_action.onDoTargetAction = onDoTargetAction

	MakeHauntableLaunch(inst)

	inst:AddComponent("equippable")
	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)

	return inst
end

return	Prefab("aip_track_tool", fn, assets)