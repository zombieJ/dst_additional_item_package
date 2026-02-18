local language = aipGetModConfig("language")

local LANG_MAP = {
	english = {
		NAME = "Doomsday Clock",
		DESC = "Rewind to a previous state",
		USE = "Time rewinds...",
	},
	chinese = {
		NAME = "末日时钟",
		DESC = "让我回到过去的状态",
		USE = "时光倒流...",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_DOOMSDAY_CLOCK = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_DOOMSDAY_CLOCK = LANG.DESC

local assets = {
	Asset("ANIM", "anim/aip_doomsday_clock.zip"),
	Asset("ATLAS", "images/inventoryimages/aip_doomsday_clock.xml"),
	Asset("IMAGE", "images/inventoryimages/aip_doomsday_clock.tex"),
}


--------------------------------- 方法 -----------------------------------
--- TODO: 使用 aipc_timer 来管理记录状态。当玩家捡起该物品时，开始计时器，每秒记录一次血量、理智、饥饿、潮湿度（最多记录 5s）。
--- 当玩家使用该物品时，恢复到 5s 前的状态。如果 5s 内没有记录，则不做任何操作。
--- 每次使用都有 60s 的冷却时间。

local function startRecord()
end

local function stopRecord()
end

--------------------------------- 实例 -----------------------------------
local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)

	inst.AnimState:SetBank("aip_doomsday_clock")
	inst.AnimState:SetBuild("aip_doomsday_clock")
	inst.AnimState:PlayAnimation("idle")

	MakeInventoryFloatable(inst, "med", 0.3, 1)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("inspectable")

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_doomsday_clock.xml"

	inst:AddComponent("aipc_timer")

	inst:AddComponent("usable")
	inst.components.usable.onuse = onUse
	inst.components.usable.quickaction = true

	MakeHauntableLaunch(inst)

	return inst
end

return Prefab("aip_doomsday_clock", fn, assets)
