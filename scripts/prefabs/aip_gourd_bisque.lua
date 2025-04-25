local language = aipGetModConfig("language")

-- 文字描述
local LANG_MAP = {
	english = {
		NAME = "Gourd Bisque",
		DESC = "Needs last bake",
	},
	chinese = {
		NAME = "葫芦素胚",
		DESC = "再需最后的烤制",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

STRINGS.NAMES.AIP_GOURD_BISQUE = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_GOURD_BISQUE = LANG.DESC

-- 资源
local assets = {
    Asset("ANIM", "anim/aip_gourd.zip"),
	Asset("ATLAS", "images/inventoryimages/aip_gourd_bisque.xml"),
}

------------------------------- 方法 -------------------------------
local function canActOn(inst, doer, target)
	return target and (target:HasTag("lava") or target.prefab == "dragonflyfurnace")
end

local function onDoTargetAction(inst, doer, target)
	if target and target:HasTag("lava") then
        -- 岩浆会有极低概率得到好的葫芦
        local loot = {
			aip_gourd_lao = 100,
			aip_gourd_zhengxianhong = 1,
			aip_gourd_wugui = 1,
			aip_gourd_baolianyu = 1,
			aip_gourd_qingtian = 1,
		}

		local targetPrefab = aipRandomLoot(loot)
		aipReplacePrefab(inst, targetPrefab)
    elseif target and target.prefab == "dragonflyfurnace" then
        -- 龙蝇炉只会得到好的葫芦
        local loot = {
			aip_gourd_lao = 0,
			aip_gourd_zhengxianhong = 1,
			aip_gourd_wugui = 1,
			aip_gourd_baolianyu = 1,
			aip_gourd_qingtian = 1,
		}

		local targetPrefab = aipRandomLoot(loot)
		aipReplacePrefab(inst, targetPrefab)
    end
end

------------------------------- 实体 -------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("aip_gourd")
    inst.AnimState:SetBuild("aip_gourd")
    inst.AnimState:PlayAnimation("bisque")

    MakeInventoryFloatable(inst, "med", 0.3, 1)

    inst.entity:SetPristine()

    inst:AddComponent("aipc_action_client")
	inst.components.aipc_action_client.canActOn = canActOn

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("aipc_action")
	inst.components.aipc_action.onDoTargetAction = onDoTargetAction

    inst:AddComponent("inspectable")

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_gourd_bisque.xml"

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("aip_gourd_bisque", fn, assets)
