local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Magic Rubik",
		DESC = "We need reset it!",
	},
	chinese = {
		NAME = "魔力方阵",
		DESC = "我们需要重置它！",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_RUBIK = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_RUBIK = LANG.DESC

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_22_fish.zip"),
	Asset("ATLAS", "images/inventoryimages/aip_22_fish.xml"),
}

local prefabs = {
	"aip_rubik_fire_blue",
	"aip_rubik_fire_green",
	"aip_rubik_fire_red",
}

------------------------------- 事件 -------------------------------

------------------------------- 魔方 -------------------------------
local function CreateFire(inst, colorName, x, y, z)
	local tgt = SpawnPrefab("aip_rubik_fire_"..colorName)
	inst:AddChild(tgt)
	tgt.Transform:SetPosition(x, y, z)
end

local function initRubik(inst)
	local offset = 2
	local height = 4
	local colors = {"green", "red","blue"}

	for oy = 1, 3 do
		local scaleOffset = 1 -- + (3 - oy) / 6

		for ox = -1, 1 do
			for oz = -1, 1 do
				CreateFire(
					inst,
					colors[oy],
					ox * offset * scaleOffset,
					oy * offset + height,
					oz * offset * scaleOffset
				)
			end
		end
	end
end

------------------------------- 实体 -------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("aip_22_fish")
    inst.AnimState:SetBuild("aip_22_fish")
    inst.AnimState:PlayAnimation("idle")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_22_fish.xml"
	inst.components.inventoryitem.imagename = "aip_22_fish"

	initRubik(inst)

	return inst
end

return Prefab("aip_rubik", fn, assets, prefabs)
