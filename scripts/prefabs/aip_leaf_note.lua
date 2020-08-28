-- 公测开启
local open_beta = aipGetModConfig("open_beta")
if open_beta ~= "open" then
	return nil
end

------------------------------------ 配置 ------------------------------------
-- 雕塑关闭
local additional_chesspieces = aipGetModConfig("additional_chesspieces")
if additional_chesspieces ~= "open" then
	return nil
end

local language = aipGetModConfig("language")

local LANG_MAP = {
	english = {
    NAME = "Leaf Note",
    NOTES = {
      "...moon...doujiang chesspiece...",
      "customize...magic with opal...",
      "fire...firestaff...",
      "water...ball...water",
      "...nightstick...elec...",
      "...luxury Fan bring the wind...",
      "fertilizer...on..earth",
      "...board is made by plant",
    },
	},
	chinese = {
    NAME = "树叶笔记",
    NOTES = {
      "月亮碎片的某个雕塑...",
      "...豆酱雕塑有特殊形态...",
      "...权杖可以...自定义魔法...",
      "...雕塑...召唤猫眼石...",
      "火...魔杖",
      "水球全都是水",
      "辰星...是带电的",
      "麋鹿鹅...风好大",
      "便便桶居然代表土?",
      "木板...朴实无华",
    },
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

-- 资源
local assets = {
  Asset("ANIM", "anim/aip_leaf_note.zip"),
  Asset("ATLAS", "images/inventoryimages/aip_leaf_note.xml"),
}

local prefabs = {}

-- 文字描述
STRINGS.NAMES.AIP_LEAF_NOTE = LANG.NAME

-----------------------------------------------------------
local function setNote(inst, idx)
  local mergedIdx = idx
  if mergedIdx == nil or mergedIdx < 0 then
    mergedIdx = math.floor(math.random() * #LANG.NOTES)
  end
  if mergedIdx >= #LANG.NOTES then
    mergedIdx = 0
  end

  inst.components.inspectable:SetDescription(LANG.NOTES[mergedIdx + 1])
  inst._noteIdx = mergedIdx
end

local function onsave(inst, data)
	data.noteIdx = inst._noteIdx
end

local function onload(inst, data)
	if data ~= nil then
    inst._noteIdx = data.noteIdx
  end

  setNote(inst, inst._noteIdx)
end

function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()
	
  MakeInventoryPhysics(inst)

  -- Show spoiled age
  inst:AddTag("show_spoilage")
  inst:AddTag("icebox_valid")

	inst.AnimState:SetBank("aip_leaf_note")
	inst.AnimState:SetBuild("aip_leaf_note")
	inst.AnimState:PlayAnimation("idle")

	MakeInventoryFloatable(inst, "small", 0.15, 0.9)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
  end

  inst:AddComponent("fuel")
  inst.components.fuel.fuelvalue = TUNING.TINY_FUEL

  inst:AddComponent("perishable")
  inst.components.perishable:SetPerishTime(TUNING.PERISH_FAST)
  inst.components.perishable:StartPerishing()
  inst.components.perishable.onperishreplacement = "ash"

  inst:AddComponent("inspectable")

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_leaf_note.xml"

	MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
	MakeSmallPropagator(inst)

  MakeHauntableLaunchAndIgnite(inst)

  inst.OnLoad = onload
  inst.OnSave = onsave

  inst:DoTaskInTime(0.5, function()
    setNote(inst, inst._noteIdx)
  end)

	return inst
end

return Prefab("aip_leaf_note", fn, assets, prefabs)
