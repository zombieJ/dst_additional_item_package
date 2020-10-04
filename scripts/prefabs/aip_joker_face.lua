-- 配置
local dress_uses = aipGetModConfig("dress_uses")
local language = aipGetModConfig("language")

-- 默认参数
local PERISH_MAP = {
	less = 0.5,
	normal = 1,
	much = 2,
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

TUNING.AIP_JOKER_FACE_FUEL = TUNING.SPIDERHAT_PERISHTIME * PERISH_MAP[dress_uses]

-- 文字描述
STRINGS.NAMES.AIP_JOKER_FACE = LANG.NAME
STRINGS.RECIPE_DESC.AIP_JOKER_FACE = LANG.REC_DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_JOKER_FACE = LANG.DESC

-- 配方
local aip_joker_face = Recipe("aip_joker_face", {Ingredient("livinglog", 3), Ingredient("spidereggsack", 1), Ingredient("razor", 1)}, RECIPETABS.DRESS, TECH.SCIENCE_TWO)
aip_joker_face.atlas = "images/inventoryimages/aip_joker_face.xml"

------------------------------------------------------- 环形球 -------------------------------------------------------
local function jokerOrbFn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	MakeFlyingCharacterPhysics(inst, 1, .5)

	inst.AnimState:SetBank("projectile")
	inst.AnimState:SetBuild("staff_projectile")
	inst.AnimState:PlayAnimation("fire_spin_loop", true)
	
	inst:AddTag("projectile")
	inst:AddTag("flying")
	inst:AddTag("ignorewalkableplatformdrowning")

	inst.entity:SetPristine() -- 客户端执行相同实体，Transform AnimState Network 等等

	if not TheWorld.ismastersim then
		return inst
	end

	return inst
end

local jokerOrbPrefab = Prefab("aip_joker_orb", jokerOrbFn, { Asset("ANIM", "anim/staff_projectile.zip") })

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
		inst.components.aipc_guardian_orb:Start()
	end,
	onUnequip = function(inst, owner)
		inst.components.aipc_guardian_orb:Stop()
	end,
	postInst = function(inst)
		-- 不能修
		inst.components.fueled.no_sewing = true

		-- 添加守护法球组件
		inst:AddComponent("aipc_guardian_orb")
		inst.components.aipc_guardian_orb.spawnPrefab = "aip_joker_orb"
	end,
})

return { prefab, jokerOrbPrefab }