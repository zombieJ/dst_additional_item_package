-- 配置
local additional_survival = aipGetModConfig("additional_survival")
if additional_survival ~= "open" then
	return nil
end

local survival_effect = aipGetModConfig("survival_effect")
local language = aipGetModConfig("language")
local dev_mode = aipGetModConfig("dev_mode") == "enabled"

-- 默认参数
local HEAL_MAP = {
	less = TUNING.HEALING_MED,
	normal = TUNING.HEALING_HUGE,
	large = TUNING.HEALING_SUPERHUGE,
}

-- 语言
local LANG_MAP = {
	english = {
		NAME = "Fig Salve",
		DESC = "Good stuff that can't be used continuously",
		DESCRIBE = "Absorbed through the face to create a therapeutic effect, the light can be seen on the body of the living being. However, the effect will be greatly reduced if it is used continuously before it fails.",
	},
	chinese = {
		NAME = "明目药膏",
		DESC = "不能连续使用的好东西",
		DESCRIBE = "通过面部吸收产生治疗效果，可以看到生物身上的光芒。但是在失效之前连续使用效果就会大打折扣。",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

-- 资源
local assets = {
	Asset("ANIM", "anim/aip_fig_salve.zip"),
	Asset("ATLAS", "images/inventoryimages/aip_fig_salve.xml"),
}

-- 文字描述
STRINGS.NAMES.AIP_FIG_SALVE = LANG.NAME
STRINGS.RECIPE_DESC.AIP_FIG_SALVE = LANG.DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_FIG_SALVE = LANG.DESCRIBE


-------------------------------------- 方法 --------------------------------------
aipBufferRegister("aip_see_petable", {
    clientFn = function(inst)
        if inst ~= nil and inst == ThePlayer then
            local pt = inst:GetPosition()

            local ents = TheSim:FindEntities(pt.x, pt.y, pt.z, 10, {"aip_petable"})

			for k, v in pairs(ents) do
				if v.components.aipc_petable ~= nil then
					v.components.aipc_petable:ShowAura()
				end
			end
        end
    end,

    showFX = false,
})

-- 治疗时判断一下之前有没有治疗过，同时添加一个 buff
local function onHeal(inst, target)
	if not aipBufferExist(target, "aip_see_petable") then
		if target.components.health ~= nil then
			target.components.health:DoDelta(
				HEAL_MAP[survival_effect],
				false,
				inst.prefab
			)
		end
	end

	aipBufferPatch(inst, target, "aip_see_petable", dev_mode and 10 or 120)
end

-------------------------------------- 实例 --------------------------------------
local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)

	inst.AnimState:SetBank("aip_fig_salve")
	inst.AnimState:SetBuild("aip_fig_salve")
	inst.AnimState:PlayAnimation("idle")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("stackable")
	inst.components.stackable.maxsize = TUNING.STACK_SIZE_MEDITEM

	inst:AddComponent("inspectable")

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_fig_salve.xml"

	inst:AddComponent("healer")
	inst.components.healer:SetHealthAmount(1)
	inst.components.healer.onhealfn = onHeal

	MakeHauntableLaunch(inst)

	return inst
end

return Prefab("aip_fig_salve", fn, assets)
