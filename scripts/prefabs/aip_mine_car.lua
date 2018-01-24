local foldername = KnownModIndex:GetModActualName(TUNING.ZOMBIEJ_ADDTIONAL_PACKAGE)

------------------------------------ 配置 ------------------------------------
-- 矿车关闭
local additional_orbit = GetModConfigData("additional_orbit", foldername)
if additional_orbit ~= "open" then
	return nil
end

local language = GetModConfigData("language", foldername)

local LANG_MAP = {
	["english"] = {
		["NAME"] = "Mine Car",
		["REC_DESC"] = "Let's drive it!",
		["DESC"] = "Where will we go?",
	},
	["chinese"] = {
		["NAME"] = "矿车",
		["REC_DESC"] = "让我们兜风吧！",
		["DESC"] = "登船靠岸停稳！~",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

-- 资源
local assets =
{
	Asset("ATLAS", "images/inventoryimages/aip_mine_car.xml"),
	Asset("IMAGE", "images/inventoryimages/aip_mine_car.tex"),
	Asset("ANIM", "anim/aip_mine_car.zip"),
}

local prefabs =
{
}

-- 文字描述
STRINGS.NAMES.AIP_MINE_CAR = LANG.NAME
STRINGS.RECIPE_DESC.AIP_MINE_CAR = LANG.REC_DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_MINE_CAR = LANG.DESC

-- 配方
local aip_mine_car = Recipe("aip_mine_car", {Ingredient("boards", 5)}, RECIPETABS.TOWN, TECH.SCIENCE_ONE)
aip_mine_car.atlas = "images/inventoryimages/aip_mine_car.xml"

-------------------------------------- 实体 --------------------------------------
-- 位移到最近的轨道上
local function moveToOrbit(inst, distance)
	local x, y, z = inst.Transform:GetWorldPosition()
	local instPoint = Point(inst.Transform:GetWorldPosition())
	local orbits = TheSim:FindEntities(x, y, z, distance or 2, { "orbit" })

	-- Find closest one
	local closestDist = 100
	local closest = nil
	for i, target in ipairs(orbits) do
		local targetPoint = Point(target.Transform:GetWorldPosition())
		local dsq = distsq(instPoint, targetPoint)

		if closestDist > dsq then
			closestDist = dsq
			closest = target
		end
	end

	if closest ~= nil then
		local tx, ty, tz = closest.Transform:GetWorldPosition()
		inst.Transform:SetPosition(tx, 10, tz)
	end

	return #orbits
end

-- 丢弃矿车
local function OnDropped(inst)
	local hasOrbit = moveToOrbit(inst, 2) > 0

	if hasOrbit then
		inst.components.inventoryitem.canbepickedup = false
	end
end


function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()
	
	MakeInventoryPhysics(inst)
	
	inst.AnimState:SetBank("aip_mine_car")
	inst.AnimState:SetBuild("aip_mine_car")
	inst.AnimState:PlayAnimation("idle")

	inst:AddTag("aip_minecar")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("inventoryitem")
	-- inst.components.inventoryitem.canbepickedup = false
	-- inst.components.inventoryitem.nobounce = true
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_mine_car.xml"
	-- inst.components.inventoryitem:SetOnDroppedFn(OnDropped)

	inst:AddComponent("inspectable")

	return inst
end

return Prefab( "aip_mine_car", fn, assets, prefabs) 