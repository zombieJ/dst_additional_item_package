-- 武器关闭
local additional_weapon = aipGetModConfig("additional_weapon")

local weapon_damage = aipGetModConfig("weapon_damage")
local language = aipGetModConfig("language")

-- 默认参数
local USE_TIMES = 20

local DAMAGE_MAP = {
	less = TUNING.CANE_DAMAGE * 0.8,
	normal = TUNING.CANE_DAMAGE,
	large = TUNING.CANE_DAMAGE * 1.5,
}

local LANG_MAP = {
	english = {
		NAME = "Track Measurer",
		NAME_HIGH = "Track Measurer (Hight)",
		NAME_LOW = "Track Measurer (Low)",
		REC_DESC = "Create a moon track. Can be upgrade by blue or red gem.",
		DESC = "Mixed with moon and shadow",
	},
	chinese = {
		NAME = "月轨测量仪",
		NAME_HIGH = "月轨测量仪(升轨)",
		NAME_LOW = "月轨测量仪(降轨)",
		REC_DESC = "制作一条月亮轨道，工具可用 蓝、红 宝石升级",
		DESC = "暗影与月光的奇艺融合",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

TUNING.AIP_TRACK_TOOLE_DAMAGE =  DAMAGE_MAP[weapon_damage]

-- 资源
local assets = {
	Asset("ATLAS", "images/inventoryimages/aip_track_tool.xml"),
	Asset("ATLAS", "images/inventoryimages/aip_track_tool_high.xml"),
	Asset("ATLAS", "images/inventoryimages/aip_track_tool_low.xml"),
	Asset("ANIM", "anim/aip_track_tool.zip"),
	Asset("ANIM", "anim/aip_track_tool_swap.zip"),
	Asset("ANIM", "anim/aip_glass_orbit_point.zip"),
}

local prefabs = {}

-- 文字描述
STRINGS.NAMES.AIP_TRACK_TOOL = LANG.NAME
STRINGS.NAMES.AIP_TRACK_TOOL_HIGH = LANG.NAME_HIGH
STRINGS.NAMES.AIP_TRACK_TOOL_LOW = LANG.NAME_LOW
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

--------------------------------- 装备 ---------------------------------
local function onFueled(inst, item, doer)
	if inst.components.finiteuses ~= nil then
		inst.components.finiteuses:Use(-USE_TIMES / 4)
	end
end

--------------------------------- 部署 ---------------------------------
local function canActOnPoint(inst)
	return true
end

local function canActOn(inst, doer, target)
	return target ~= nil and target.prefab == "aip_glass_orbit_point"
end

-- 寻找附近的标记点
local MAX_HEIGHT = 10
local NEAR_DIST = 2

-- 在点制造轨道
local function onDoPointAction(inst, creator, targetPos)
    local startPos = creator:GetPosition()

	if inst.components.finiteuses:GetUses() == 0 then
		return
	end

	-- 消耗一次次数
	inst.components.finiteuses:Use()

	-- 起始点：如果附近有点就不创建
	local startP = aipFindOrbitPoint(startPos)
	if startP == nil then
		startP = aipSpawnPrefab(creator, "aip_glass_orbit_point")
		aipSpawnPrefab(startP, "aip_shadow_wrapper").DoShow()
	end

	local startPT = startP:GetPosition()

	-- 目的地：如果附近有点就不创建
	local endP = aipFindOrbitPoint(targetPos)
	if endP == nil then
		local y = startPT.y + (inst._aip_offset or 0)
		y = math.max(y, 0)
		y = math.min(y, MAX_HEIGHT)
		endP = aipSpawnPrefab(nil, "aip_glass_orbit_point", targetPos.x, y, targetPos.z)
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

local function CanCastFn(doer, target, pos)
    return true
end

local function CreateRail(inst, target, pos)
	local owner = inst.components.inventoryitem:GetGrandOwner()
	if owner == nil then
		return
	end

	onDoPointAction(inst, owner, pos)
end

--------------------------------- 变化 ---------------------------------
-- 只允许 蓝宝石 和 红宝石
local function canBeGiveOn(inst, doer, item)
    return aipInTable({"redgem", "bluegem"}, item.prefab)
end

-- 给予宝石变化物品
local function onDoGiveAction(inst, doer, item)
	local uses = inst.components.finiteuses:GetUses()
	local tool = nil

	if item.prefab == "redgem" then
		tool = aipReplacePrefab(inst, "aip_track_tool_high")
	elseif item.prefab == "bluegem" then
		tool = aipReplacePrefab(inst, "aip_track_tool_low")
	end

	if tool ~= nil then
		tool.components.finiteuses:SetUses(uses)
    	aipRemove(item)
	end
end

--------------------------------- 实例 ---------------------------------
local function commonFn(postFn)
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()
	
	MakeInventoryPhysics(inst)
	
	inst.AnimState:SetBank("aip_track_tool")
	inst.AnimState:SetBuild("aip_track_tool")
	inst.AnimState:PlayAnimation("idle")

	inst:AddTag("allow_action_on_impassable")

	inst:AddComponent("aipc_action_client")
	inst.components.aipc_action_client.canActOnPoint = canActOnPoint
	inst.components.aipc_action_client.canActOn = canActOn
	inst.components.aipc_action_client.canBeGiveOn = canBeGiveOn

	-- 双端通用的匹配
	inst:AddComponent("aipc_fueled")
	inst.components.aipc_fueled.prefab = "moonglass"
	inst.components.aipc_fueled.onFueled = onFueled

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(TUNING.AIP_TRACK_TOOLE_DAMAGE)

	inst:AddComponent("finiteuses")
	inst.components.finiteuses:SetMaxUses(USE_TIMES)
    inst.components.finiteuses:SetUses(0)

	inst:AddComponent("inspectable")

	inst:AddComponent("inventoryitem")

	-- -- 施法
    inst:AddComponent("aipc_action")
    inst.components.aipc_action.onDoPointAction = onDoPointAction
	inst.components.aipc_action.onDoTargetAction = onDoTargetAction
	inst.components.aipc_action.onDoGiveAction = onDoGiveAction

	MakeHauntableLaunch(inst)

	inst:AddComponent("equippable")
	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)

	postFn(inst)

	return inst
end

--------------------------------- 高低 ---------------------------------
local function fn()
	return commonFn(function(inst)
		inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_track_tool.xml"
	end)
end

local function highFn()
	return commonFn(function(inst)
		inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_track_tool_high.xml"
		inst._aip_offset = 2
	end)
end

local function lowFn()
	return commonFn(function(inst)
		inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_track_tool_low.xml"
		inst._aip_offset = -2
	end)
end

return	Prefab("aip_track_tool", fn, assets),
	Prefab("aip_track_tool_high", highFn, assets),
	Prefab("aip_track_tool_low", lowFn, assets)