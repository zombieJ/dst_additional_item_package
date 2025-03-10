local language = aipGetModConfig("language")

local characterData = require("prefabs/aip_xiyou_card_data")
local charactersList = characterData.charactersList
local characterCount = characterData.characterCount

-- 资源
local assets = {
	Asset("ATLAS", "images/inventoryimages/aip_xiyou_card_single.xml"),
	Asset("ATLAS", "images/inventoryimages/aip_xiyou_card_multiple.xml"),
	Asset("ANIM", "anim/aip_xiyou_card.zip"),
}

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Character card",
		DESC = "Popluar in another world.",
		LEFT = "Still miss %d cards",
		
		WICKERBOTTOM = "WickerBottom", -- 测试用
		MONKEY_KING = "Monkey",
		NEZA = "Neza",
		WHITE_BONE = "Bone",
		PIGSY = "Pigsy",
		YANGJIAN = "Jian",
		MYTH_YUTU = "Yu Tu",
		YAMA_COMMISSIONERS = "Impermanence",
	},
	chinese = {
		NAME = "西游人物卡",
		DESC = "在另一个世界很流行的卡片,",
		LEFT = "还差 %d 张集齐",

		WICKERBOTTOM = "薇克", -- 测试用
		MONKEY_KING = "悟空",
		NEZA = "哪吒",
		WHITE_BONE = "白骨",
		PIGSY = "八戒",
		YANGJIAN = "杨戬",
		MYTH_YUTU = "玉兔",
		YAMA_COMMISSIONERS = "无常",

		DESC_WICKERBOTTOM = "骗孩子的玩意儿~", -- 测试用
		DESC_MONKEY_KING = "呔，俺老孙甚是喜欢!",
		DESC_NEZA = "把我画的倒是精巧~",
		DESC_WHITE_BONE = "把哀家给画丑了!",
		DESC_PIGSY = "这不是俺老猪么!",
		DESC_YANGJIAN = "凡夫俗子的东西!",
		DESC_MYTH_YUTU = "我的卡片嫦娥姐姐会有吗?",
		DESC_YAMA_COMMISSIONERS = "引路六道，舍我其谁？",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_XIYOU_CARD = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_XIYOU_CARD = LANG.DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_XIYOU_CARD_LEFT = LANG.LEFT

----------------------------------- 方法 -----------------------------------
-- 获取总数
local function getTotal(inst)
	local total = 0
	for name, cnt in pairs(inst.aipCats or {}) do
		if cnt ~= nil and cnt > 0 then
			total = total + 1
		end
	end

	return total
end

-- 获取描述
local function getDesc(inst, viewer)
	local desc = STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_XIYOU_CARD

	if inst.aipCats[viewer.prefab] ~= nil and inst.aipCats[viewer.prefab] > 0 then
		desc = LANG["DESC_"..string.upper(viewer.prefab)]
	end
	return desc..string.format(
		STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_XIYOU_CARD_LEFT,
		characterCount - getTotal(inst)
	)
end

-- 更新状态
local function refreshStatus(inst)
	local total = getTotal(inst)

	-- 替换卡片
	if total >= characterCount then
		aipReplacePrefab(inst, "aip_xiyou_cards")
		return
	end

	-- 更新名称
	local first = true
	local str = ""

	for name, cnt in pairs(inst.aipCats or {}) do
		if cnt ~= nil and cnt > 0 then
			if first ~= true then
				str = str..","
			end
			first = false

			str = str..LANG[string.upper(name)]
		end
	end

	inst.components.named:SetName(
		STRINGS.NAMES.AIP_XIYOU_CARD.."("..str..")"
	)

	-- 更新贴图
	if total > 1 then
		inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_xiyou_card_multiple.xml"
		inst.components.inventoryitem:ChangeImageName("aip_xiyou_card_multiple")
		inst.AnimState:PlayAnimation("multiple")
	else
		inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_xiyou_card_single.xml"
		inst.components.inventoryitem:ChangeImageName("aip_xiyou_card_single")
		inst.AnimState:PlayAnimation("single")
	end
end

-- 是否可以合并
local function canActOn(inst, doer, target)
	return target:HasTag("aip_xiyou_card")
end

-- 合并数据
local function mergeCats(target, catData)
	for name, cnt in pairs(catData or {}) do
		local tgtCnt = target.aipCats[name] or 0
		target.aipCats[name] = cnt + tgtCnt
	end

	refreshStatus(target)
end

local function onDoTargetAction(inst, doer, target)
	if not TheWorld.ismastersim then
		return inst
	end

	local data1 = inst.aipCats
	local data2 = target.aipCats

	local replacement = aipReplacePrefab(target, "aip_xiyou_card")
	mergeCats(replacement, data1)
	mergeCats(replacement, data2)
	inst:Remove()

	refreshStatus(replacement)
end


-- 加载
local function onSave(inst, data)
	data.aipCats = inst.aipCats
end

local function onLoad(inst, data)
	if data ~= nil then
		inst.aipCats = data.aipCats
	end
end

----------------------------------- 实体 -----------------------------------
local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()
	
	MakeInventoryPhysics(inst)
	MakeInventoryFloatable(inst, "med", nil, 0.75)
	
	inst.AnimState:SetBank("aip_xiyou_card")
	inst.AnimState:SetBuild("aip_xiyou_card")
	inst.AnimState:PlayAnimation("single")

	inst.entity:SetPristine()

	-- 游戏里这么做，不知道为什么
	inst:AddTag("_named")

	inst:AddTag("aip_xiyou_card")

	inst:AddComponent("aipc_action_client")
	inst.components.aipc_action_client.canActOn = canActOn

	if not TheWorld.ismastersim then
		return inst
	end

	-- 游戏里这么做，不知道为什么
	inst:RemoveTag("_named")

	inst:AddComponent("fuel")
	inst.components.fuel.fuelvalue = TUNING.TINY_FUEL

	inst:AddComponent("aipc_action")
	inst.components.aipc_action.onDoTargetAction = onDoTargetAction

	inst:AddComponent("named")

	inst:AddComponent("inspectable")
	inst.components.inspectable.getspecialdescription = getDesc

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_xiyou_card_single.xml"
	inst.components.inventoryitem.imagename = "aip_xiyou_card_single"

	MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
	MakeSmallPropagator(inst)

	-- 卡片名称对应的数量
	inst.aipCats = {}

	inst.OnLoad = onLoad
	inst.OnSave = onSave

	inst:DoTaskInTime(0.3, function()
		refreshStatus(inst)
	end)

	return inst
end

--------------------------------- 角色卡片 ---------------------------------
local function makeCardFn(name)
	local function tmpFn()
		local inst = fn()

		if not TheWorld.ismastersim then
			return inst
		end

		inst:AddComponent("stackable")
		inst.components.stackable.maxsize = TUNING.STACK_SIZE_TINYITEM

		inst.aipCats[name] = 1

		return inst
	end

	return tmpFn
end

----------------------------------- 组装 -----------------------------------
local prefabs = {
	Prefab("aip_xiyou_card", fn, assets),
}

for i, name in ipairs(charactersList) do
	table.insert(prefabs, Prefab("aip_xiyou_card_"..name, makeCardFn(name), assets))
end

return unpack(prefabs)