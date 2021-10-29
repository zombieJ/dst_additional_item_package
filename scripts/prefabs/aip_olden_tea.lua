local dev_mode = aipGetModConfig("dev_mode") == "enabled"

local additional_food = aipGetModConfig("additional_food")
if additional_food ~= "open" then
	return nil
end

-- 默认参数
local survival_effect = aipGetModConfig("survival_effect")
local HEAL_MAP = {
	["less"] = TUNING.HEALING_TINY,
	["normal"] = TUNING.HEALING_SMALL,
	["large"] = TUNING.HEALING_MED,
}

-- 语言
local language = aipGetModConfig("language")
local LANG_MAP = {
	english = {
		NAME = "Olden Seapot",
		REC_DESC = "As if hearing the sound of the ocean",
		DESC = "Exclusive secret recipe",
		START = "\"Fragrant\" tea",
		END = "The tea smell is gone",
	},
	chinese = {
		NAME = "古早沙滩壶",
		REC_DESC = "仿佛听懂了海洋的声音",
		DESC = "独家配方，无限续杯",
		START = "\"香浓\"的茶味",
		END = "茶味消散了",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

-- 文字描述
STRINGS.NAMES.AIP_OLDEN_TEA = LANG.NAME
STRINGS.RECIPE_DESC.AIP_OLDEN_TEA = LANG.REC_DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDEN_TEA = LANG.DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDEN_TEA_START = LANG.START
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDEN_TEA_END = LANG.END

------------------------------- 资源 -------------------------------
local assets = {
	Asset("ANIM", "anim/aip_olden_tea.zip"),
	Asset("ATLAS", "images/inventoryimages/aip_olden_tea.xml"),
	Asset("ATLAS", "images/inventoryimages/aip_olden_tea_half.xml"),
	Asset("ATLAS", "images/inventoryimages/aip_olden_tea_full.xml"),
}

------------------------------- 方法 -------------------------------
-- 更新充能状态
local function refreshStatus(inst)
	-- 更新贴图
	local ptg = inst.components.finiteuses == nil and 0 or inst.components.finiteuses:GetPercent()

	if ptg == 0 then
		inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_olden_tea.xml"
		inst.components.inventoryitem:ChangeImageName("aip_olden_tea")
		inst.AnimState:PlayAnimation("idle")
	elseif ptg == 1 then
		inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_olden_tea_full.xml"
		inst.components.inventoryitem:ChangeImageName("aip_olden_tea_full")
		inst.AnimState:PlayAnimation("full")
	else
		inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_olden_tea_half.xml"
		inst.components.inventoryitem:ChangeImageName("aip_olden_tea_half")
		inst.AnimState:PlayAnimation("half")
	end
end

-- 可以吃
local function canBeEat(inst, doer)
	if inst.components.finiteuses ~= nil then
		return inst.components.finiteuses:GetUses() > 0
	end
	return true
end

-- 茶味消散了
local function endTea(doer, data)
	if data ~= nil and data.name == "aip_olden_tea" then
		doer:RemoveEventCallback("timerdone", endTea)

		if doer.components.talker ~= nil then
			doer.components.talker:Say(
				STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDEN_TEA_END
			)
		end
	end
end

-- 开始享用
local function onDoEat(inst, doer)
	if inst.components.finiteuses == nil or inst.components.finiteuses:GetUses() == 0 then
		return
	end
	inst.components.finiteuses:Use()
	refreshStatus(inst)

	-- 恢复 1 点生命值
	if doer.components.health ~= nil then
		doer.components.health:DoDelta(1, false, inst.prefab)
	end

	-- 多了加少了减，5 点上下范围不作为 30%
	if doer.components.sanity ~= nil then
		local targetSanity = doer.components.sanity.max * 0.3
		local current = doer.components.sanity.current

		local diff = targetSanity - current
		local abs = math.abs(diff)
		if abs >= 5 then
			doer.components.sanity:DoDelta(diff > 0 and 5 or -5)
		end
	end

	if doer.components.timer ~= nil then
		doer.components.timer:StopTimer("aip_olden_tea")
		doer.components.timer:StartTimer("aip_olden_tea", dev_mode and 300 or 60)

		-- 喝茶时说一句话
		if doer.components.talker ~= nil then
			doer.components.talker:Say(
				STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_OLDEN_TEA_START
			)

			doer:ListenForEvent("timerdone", endTea)
		end
	end
end

-- 填满
local function OnFill(inst, from_object)
	inst.components.finiteuses:SetPercent(1)
	inst.SoundEmitter:PlaySound("turnoftides/common/together/water/emerge/small")

	refreshStatus(inst)

	return true
end

------------------------------- 实体 -------------------------------
local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)
	MakeInventoryFloatable(inst, "small", 0.1, 1)

	inst.AnimState:SetBank("aip_olden_tea")
	inst.AnimState:SetBuild("aip_olden_tea")
	inst.AnimState:PlayAnimation("idle")

	inst.entity:SetPristine()

	inst:AddComponent("aipc_action_client")
	inst.components.aipc_action_client.canBeEat = canBeEat

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("fillable")
	inst.components.fillable.overrideonfillfn = OnFill
	inst.components.fillable.showoceanaction = true
	inst.components.fillable.acceptsoceanwater = true

	inst:AddComponent("finiteuses")
	inst.components.finiteuses:SetMaxUses(3)
	inst.components.finiteuses:SetUses(0)

	inst:AddComponent("aipc_action")
	inst.components.aipc_action.onDoAction = onDoEat

	inst:AddComponent("inspectable")

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_olden_tea.xml"

	MakeHauntableLaunch(inst)

	inst:DoTaskInTime(0, refreshStatus)

	return inst
end

return Prefab("aip_olden_tea", fn, assets)