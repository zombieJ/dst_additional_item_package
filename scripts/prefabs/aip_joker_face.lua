-- 配置
local dress_uses = aipGetModConfig("dress_uses")
local weapon_damage = aipGetModConfig("weapon_damage")
local language = aipGetModConfig("language")

-- 默认参数
local PERISH_MAP = {
	less = 0.5,
	normal = 1,
	much = 2,
}
local DAMAGE_MAP = {
	less = TUNING.SPEAR_DAMAGE * 0.5,
	normal = TUNING.SPEAR_DAMAGE,
	large = TUNING.SPEAR_DAMAGE * 2,
}

local LANG_MAP = {
	english = {
		NAME = "Joker Face",
		REC_DESC = "Neurotic awards",
		DESC = "Something seems to surround it",
	},
	chinese = {
		NAME = "诙谐面具",
		REC_DESC = "神经质的嘉奖",
		DESC = "似乎有什么环绕着它",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

TUNING.AIP_JOKER_FACE_FUEL = TUNING.ONEMANBAND_PERISHTIME * PERISH_MAP[dress_uses]
TUNING.AIP_JOKER_FACE_MAX_RANGE = 12
TUNING.AIP_JOKER_FACE_DAMAGE = DAMAGE_MAP[weapon_damage]

-- 文字描述
STRINGS.NAMES.AIP_JOKER_FACE = LANG.NAME
STRINGS.RECIPE_DESC.AIP_JOKER_FACE = LANG.REC_DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_JOKER_FACE = LANG.DESC

-- 配方
local aip_joker_face = Recipe("aip_joker_face", {Ingredient("livinglog", 3), Ingredient("spidereggsack", 1), Ingredient("razor", 1)}, RECIPETABS.DRESS, TECH.SCIENCE_TWO)
aip_joker_face.atlas = "images/inventoryimages/aip_joker_face.xml"

---------------------------------------------------- 注入燃料类型 ----------------------------------------------------
FUELTYPE.AIP_LIVINGLOG = "LIVINGLOG"

------------------------------------------------------- 环形球 -------------------------------------------------------
local function jokerOrbFn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddLight()
	inst.entity:AddNetwork()

	MakeFlyingCharacterPhysics(inst, 1, .5)

	inst.AnimState:SetBank("projectile")
	inst.AnimState:SetBuild("staff_projectile")
	inst.AnimState:PlayAnimation("fire_spin_loop", true)
	
	inst:AddTag("projectile")
	inst:AddTag("flying")
	inst:AddTag("ignorewalkableplatformdrowning")

	-- 添加一抹灯光
	inst.Light:SetIntensity(.6)
	inst.Light:SetRadius(.5)
	inst.Light:SetFalloff(.6)
	inst.Light:Enable(true)
	inst.Light:SetColour(180 / 255, 195 / 255, 225 / 255)

	inst.entity:SetPristine() -- 客户端执行相同实体，Transform AnimState Network 等等

	if not TheWorld.ismastersim then
		return inst
	end

	
	inst:DoTaskInTime(0.5, function()
		if inst._master ~= true then
			inst:Remove()
		end
	end)

	return inst
end

local jokerOrbPrefab = Prefab("aip_joker_orb", jokerOrbFn, { Asset("ANIM", "anim/staff_projectile.zip") }, { "fire_projectile" })

-------------------------------------------------------- 函数 --------------------------------------------------------
local function canAcceptFuelFn(inst, item)
	return item ~= nil and item.prefab == "livinglog"
end

------------------------------------------------------ 面具实体 ------------------------------------------------------
local tempalte = require("prefabs/aip_dress_template")
local prefab = tempalte("aip_joker_face", {
	keepHead = true,
	prefabs = {
		"aip_joker_orb"
	},
	fueled = {
		level = TUNING.AIP_JOKER_FACE_FUEL,
	},
	onEquip = function(inst, owner)
		inst.components.aipc_guardian_orb:Start(owner)
	end,
	onUnequip = function(inst, owner)
		inst.components.aipc_guardian_orb:Stop()
	end,
	postInst = function(inst)
		-- 添加守护法球组件
		inst:AddComponent("aipc_guardian_orb")
		inst.components.aipc_guardian_orb.spawnPrefab = "aip_joker_orb"
		inst.components.aipc_guardian_orb.projectilePrefab = "fire_projectile"

		-- 添加武器类型
		inst:AddComponent("weapon")
		inst.components.weapon:SetDamage(TUNING.AIP_JOKER_FACE_DAMAGE)
		inst.components.weapon:SetRange(0, 0)

		-- 接受充能
		inst.components.fueled.fueltype = FUELTYPE.AIP_LIVINGLOG
		inst.components.fueled:SetSections(5)
		inst.components.fueled.accepting = true
		inst.components.fueled.canAcceptFuelFn = canAcceptFuelFn
		inst.components.fueled.bonusmult = TUNING.AIP_JOKER_FACE_FUEL / 5 / TUNING.MED_FUEL -- 每次添加 1/5
	end,
})

return { prefab, jokerOrbPrefab }