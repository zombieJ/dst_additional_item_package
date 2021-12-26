local language = aipGetModConfig("language")

-------------------------------- 数据 --------------------------------
local list = {
    {
        name = "aip_glass_minecar",
        lang = {
            english = {
                NAME = "Glass Minecar",
                DESC = "Takes where you go",
                RECIPE_DESC = "Works on the glass orbit",
            },
            chinese = {
                NAME = "玻璃矿车",
                DESC = "可以带去想要去的地方",
                RECIPE_DESC = "可以使用玻璃轨道的矿车",
            },
        },
        assets = {
            Asset("ANIM", "anim/aip_glass_minecar.zip"),
            Asset("ATLAS", "images/inventoryimages/aip_glass_minecar.xml"),
        },
    },
}

---------------------------------------------------------------------
--                               实体                               --
---------------------------------------------------------------------
local function canActOn(inst, doer, target)
	return target.prefab == "aip_glass_orbit_point"
end

local function onDoTargetAction(inst, doer, target)
    if target.components.aipc_orbit_point ~= nil then
        target.components.aipc_orbit_point:SetMineCar(inst)
    end
end


local function getFn(data)
    local upStr = string.upper(data.name)

    local LANG = data.lang[language] or data.lang.english

    -- 文字描述
    STRINGS.NAMES[upStr] = LANG.NAME
    STRINGS.RECIPE_DESC[upStr] = LANG.REC_DESC
    STRINGS.CHARACTERS.GENERIC.DESCRIBE[upStr] = LANG.DESC

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)

        inst.AnimState:SetBank("aip_glass_minecar")
        inst.AnimState:SetBuild("aip_glass_minecar")
        inst.AnimState:PlayAnimation("idle")

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
        inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_glass_minecar.xml"

        MakeHauntableLaunch(inst)

        return inst
    end

    return fn
end

-------------------------------- 生成 --------------------------------
local prefabs = {}

for i, data in ipairs(list) do
	table.insert(prefabs, Prefab(data.name, getFn(data), data.assets, data.prefabs))
end

return unpack(prefabs)
