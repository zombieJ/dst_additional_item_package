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
            -- Asset("ANIM", "anim/swap_aip_minecar_down_front.zip"),
        },
    },
}

---------------------------------------------------------------------
--                               实体                               --
---------------------------------------------------------------------
local function getFn(data)
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

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("inspectable")
        
        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_22_fish.xml"

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
