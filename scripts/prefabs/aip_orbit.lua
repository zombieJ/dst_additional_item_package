local foldername = KnownModIndex:GetModActualName(TUNING.ZOMBIEJ_ADDTIONAL_PACKAGE)

------------------------------------ 配置 ------------------------------------
-- 轨道关闭
local additional_orbit = GetModConfigData("additional_orbit", foldername)
if additional_orbit ~= "open" then
	return nil
end

local language = GetModConfigData("language", foldername)

local LANG_MAP = {
	["english"] = {
		["NAME"] = "Orbit",
		["REC_DESC"] = "Play with the train!",
		["DESC"] = "That's old style",

		["ACTIONFAIL"] = {
			["GENERIC"] = "It's not a mine car!",
		},
	},
	["chinese"] = {
		["NAME"] = "轨道模组",
		["REC_DESC"] = "在饥荒里搭火车吧！",
		["DESC"] = "古老的艺术",

		["ACTIONFAIL"] = {
			["GENERIC"] = "这根本不是矿车",
			["WAXWELL"] = "用它能干什么",
			["WOLFGANG"] = "用它可找不到吃的",
			["WX78"] = "参数错误，流处理失败",
			["WILLOW"] = "不能用就烧了吧",
			["WENDY"] = "这是被遗弃的东西",
			["WOODIE"] = "露西也不喜欢它",
			["WICKERBOTTOM"] = "知识告诉我这是不对的",
			["WATHGRITHR"] = "它能表现的像个矿车吗？",
			["WEBBER"] = "不匹配不纯粹",
			["WINONA"] = "我该做一辆矿车",
		},
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english

-- 资源
local assets =
{
	-- 不知道为什么aip_orbit.xml不work，看起来是因为和配方相关？
	Asset("ATLAS", "images/inventoryimages/aip_orbit_item.xml"),
	Asset("ANIM", "anim/aip_orbit.zip"),
	Asset("ANIM", "anim/aip_orbit_x.zip"),
}

local prefabs =
{
}

-- 文字描述
STRINGS.NAMES.AIP_ORBIT_ITEM = LANG.NAME
STRINGS.RECIPE_DESC.AIP_ORBIT_ITEM = LANG.REC_DESC
STRINGS.NAMES.AIP_ORBIT = LANG.NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_ORBIT = LANG.DESC

STRINGS.CHARACTERS.GENERIC.ACTIONFAIL.GIVE.ITEM_NOT_MINE_CAR = LANG.ACTIONFAIL.GENERIC
STRINGS.CHARACTERS.WAXWELL.ACTIONFAIL.GIVE.ITEM_NOT_MINE_CAR = LANG.ACTIONFAIL.WAXWELL or LANG.ACTIONFAIL.GENERIC
STRINGS.CHARACTERS.WOLFGANG.ACTIONFAIL.GIVE.ITEM_NOT_MINE_CAR = LANG.ACTIONFAIL.WOLFGANG or LANG.ACTIONFAIL.GENERIC
STRINGS.CHARACTERS.WX78.ACTIONFAIL.GIVE.ITEM_NOT_MINE_CAR = LANG.ACTIONFAIL.WX78 or LANG.ACTIONFAIL.GENERIC
STRINGS.CHARACTERS.WILLOW.ACTIONFAIL.GIVE.ITEM_NOT_MINE_CAR = LANG.ACTIONFAIL.WILLOW or LANG.ACTIONFAIL.GENERIC
STRINGS.CHARACTERS.WENDY.ACTIONFAIL.GIVE.ITEM_NOT_MINE_CAR = LANG.ACTIONFAIL.WENDY or LANG.ACTIONFAIL.GENERIC
STRINGS.CHARACTERS.WOODIE.ACTIONFAIL.GIVE.ITEM_NOT_MINE_CAR = LANG.ACTIONFAIL.WOODIE or LANG.ACTIONFAIL.GENERIC
STRINGS.CHARACTERS.WICKERBOTTOM.ACTIONFAIL.GIVE.ITEM_NOT_MINE_CAR = LANG.ACTIONFAIL.WICKERBOTTOM or LANG.ACTIONFAIL.GENERIC
STRINGS.CHARACTERS.WATHGRITHR.ACTIONFAIL.GIVE.ITEM_NOT_MINE_CAR = LANG.ACTIONFAIL.WATHGRITHR or LANG.ACTIONFAIL.GENERIC
STRINGS.CHARACTERS.WEBBER.ACTIONFAIL.GIVE.ITEM_NOT_MINE_CAR = LANG.ACTIONFAIL.WEBBER or LANG.ACTIONFAIL.GENERIC
STRINGS.CHARACTERS.WINONA.ACTIONFAIL.GIVE.ITEM_NOT_MINE_CAR = LANG.ACTIONFAIL.WINONA or LANG.ACTIONFAIL.GENERIC

-- 配方
local aip_orbit_item = Recipe("aip_orbit_item", {Ingredient("boards", 1)}, RECIPETABS.TOWN, TECH.SCIENCE_ONE, nil, nil, nil, 4)
aip_orbit_item.atlas = "images/inventoryimages/aip_orbit_item.xml"

----------------------------- 函数 -----------------------------
-- 重置轨道角度
local function updateOrbitRotation(inst, vertical, horizontal)
	if vertical and horizontal then
		inst.AnimState:SetBank("aip_orbit_x")
		inst.AnimState:SetBuild("aip_orbit_x")

		inst.Transform:SetRotation(180)
	else
		inst.AnimState:SetBank("aip_orbit")
		inst.AnimState:SetBuild("aip_orbit")
		
		if vertical then
			inst.Transform:SetRotation(90)
		else
			inst.Transform:SetRotation(180)
		end
	end

	inst.AnimState:PlayAnimation("idle")
end

-- 遍历轨道
local function adjustOrbit(inst, conductive)
	local x, y, z = inst.Transform:GetWorldPosition()
	local orbits = TheSim:FindEntities(x, y, z, 1.2, { "aip_orbit" })

	local vertical = false
	local horizontal = false

	for i, target in ipairs(orbits) do
		if target ~= inst then
			local e_x, e_y, e_z = target.Transform:GetWorldPosition()

			if e_z ~= z then
				vertical = true
			elseif e_x ~= x then
				horizontal = true
			end

			if conductive then
				-- 延迟0秒以等待其他Orbit更新完毕
				target:DoTaskInTime(0, function()
					adjustOrbit(target, false)
				end)
			end
		end
	end

	updateOrbitRotation(inst, vertical, horizontal)
end

-- 放置轨道
local function onDeployOrbit(inst, pt, deployer)
	local orbit = SpawnPrefab("aip_orbit")
	if orbit ~= nil then 
		local x = math.floor(pt.x) + .5
		local y = 0
		local z = math.floor(pt.z) + .5
		orbit.Physics:SetCollides(false)
		orbit.Physics:Teleport(x, y, z)
		-- wall.Physics:SetCollides(true)
		inst.components.stackable:Get():Remove()

		-- 轨道重排
		adjustOrbit(orbit, true)

		orbit.SoundEmitter:PlaySound("dontstarve/common/place_structure_wood")
	end
end

-- 检查是否可以放置矿车
local function acceptMineCarTest(inst, item)
	if item:HasTag("aip_minecar") then
		return true
	end

	return false, "ITEM_NOT_MINE_CAR"
end

local function onAcceptMineCar(inst, giver, item)

end

--------------------------- 轨道物品 ---------------------------
local function itemfn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)

	inst:AddTag("orbitbuilder")

	inst.AnimState:SetBank("aip_orbit")
	inst.AnimState:SetBuild("aip_orbit")
	inst.AnimState:PlayAnimation("idle")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("stackable")
	inst.components.stackable.maxsize = TUNING.STACK_SIZE_MEDITEM

	inst:AddComponent("inspectable")
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/aip_orbit_item.xml"

	inst:AddComponent("deployable")
	inst.components.deployable.ondeploy = onDeployOrbit
	inst.components.deployable:SetDeployMode(DEPLOYMODE.WALL)

	MakeHauntableLaunch(inst)

	return inst
end

----------------------------- 轨道 -----------------------------
local function onhammered(inst, worker)
	if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
		inst.components.burnable:Extinguish()
	end

	-- 物品掉落
	-- inst.components.lootdropper:DropLoot()
	inst.components.lootdropper:SpawnLootPrefab('log')

	-- 重置其他轨道角度
	adjustOrbit(inst, true)

	local fx = SpawnPrefab("collapse_small")
	fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
	fx:SetMaterial("wood")
	inst:Remove()
end

local function onhit(inst, worker)
	if not inst:HasTag("burnt") then
		inst.AnimState:PlayAnimation("hit")
		inst.AnimState:PushAnimation("idle", false)
	end
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	inst.Transform:SetEightFaced()
	-- inst.Transform:SetScale(0.5, 0.5, 0.5)
	-- inst.AnimState:GetCurrentFacing()
	-- https://forums.kleientertainment.com/topic/71094-modding-help/
	-- https://forums.kleientertainment.com/topic/72978-is-it-possible-to-access-variables-from-behaviors/

	MakeObstaclePhysics(inst, .5)
	inst.Physics:SetDontRemoveOnSleep(true)
	inst.Physics:SetCollides(false)

	inst:AddTag("aip_orbit")
	inst:AddTag("noauradamage")
	inst:AddTag("nointerpolate")
	inst:AddTag("wood")

	inst.AnimState:SetBank("aip_orbit")
	inst.AnimState:SetBuild("aip_orbit")
	inst.AnimState:PlayAnimation("idle")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("savedrotation")

	inst:AddComponent("inspectable")
	inst:AddComponent("lootdropper")

	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
	inst.components.workable:SetWorkLeft(3)
	inst.components.workable:SetOnFinishCallback(onhammered)
	inst.components.workable:SetOnWorkCallback(onhit)

	MakeHauntableWork(inst)

	-- 重置一下角度
	inst:DoTaskInTime(0.5, function()
		adjustOrbit(inst, false)
	end)

	-- 接受矿车
	inst:AddComponent("trader")
	inst.components.trader:SetAbleToAcceptTest(acceptMineCarTest)
	inst.components.trader.onaccept = onAcceptMineCar
	inst.components.trader.acceptnontradable = true

	--[[ inst:DoPeriodicTask(1, function()
		local x, y, z = inst.Transform:GetWorldPosition()
		print(">>> Facing:"..tostring(inst.AnimState:GetCurrentFacing()))
		print(">>> Rotation:"..tostring(inst.Transform:GetRotation()))
		print(">>> Position:"..tostring(x).."/"..tostring(y).."/"..tostring(z))
	end) ]]

	return inst
end

return Prefab("aip_orbit", fn, assets, prefabs),
	Prefab("aip_orbit_item", itemfn, assets, { "aip_orbit", "aip_orbit_item_placer" }),
	MakePlacer("aip_orbit_item_placer", "aip_orbit", "aip_orbit", "idle", false, false, true, nil, -90, "eight")