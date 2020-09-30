local Vector3 = GLOBAL.Vector3
local STRINGS = GLOBAL.STRINGS

---------------------------------------- 操作 ----------------------------------------
local AIP_ACTION = env.AddAction("AIP_ACTION", "Operate", function(act)
	-- Client Only Code
	local doer = act.doer
	local target = act.target

	-- 操作
	if target.components.aipc_action ~= nil then
		target.components.aipc_action:DoAction(doer)
		return true
	end
	return false, "INUSE"
end)
AddStategraphActionHandler("wilson", GLOBAL.ActionHandler(AIP_ACTION, "doshortaction"))
AddStategraphActionHandler("wilson_client", GLOBAL.ActionHandler(AIP_ACTION, "doshortaction"))

---------------------------------------- 配置 ----------------------------------------
local getNectarValues = GLOBAL.require("utils/aip_nectar_util")
local params = {}

----------------- 焚烧炉 -----------------
params.incinerator =
{
	widget =
	{
		slotpos =
		{
			Vector3(0, 64 + 32 + 8 + 4, 0), 
			Vector3(0, 32 + 4, 0),
			Vector3(0, -(32 + 4), 0), 
			Vector3(0, -(64 + 32 + 8 + 4), 0),
		},
		animbank = "ui_cookpot_1x4",
		animbuild = "ui_cookpot_1x4",
		pos = Vector3(200, 0, 0),
		side_align_tip = 100,
		buttoninfo =
		{
			text = STRINGS.ACTIONS.ABANDON,
			position = Vector3(0, -165, 0),
		}
	},
	acceptsstacks = true,
	type = "chest",
}

function params.incinerator.itemtestfn(container, item, slot)
	if item:HasTag("irreplaceable") or item.prefab == "ash" then
		return false, "INCINERATOR_NOT_BURN"
	end

	return true
end

function params.incinerator.widget.buttoninfo.fn(inst)
	if inst.components.container ~= nil then
		GLOBAL.BufferedAction(inst.components.container.opener, inst, AIP_ACTION):Do()
	elseif inst.replica.container ~= nil and not inst.replica.container:IsBusy() then
		GLOBAL.SendRPCToServer(GLOBAL.RPC.DoWidgetButtonAction, AIP_ACTION.code, inst, AIP_ACTION.mod_name)
	end
end

function params.incinerator.widget.buttoninfo.validfn(inst)
	return inst.replica.container ~= nil
end

--------------- 花蜜酿造机 ---------------
params.aip_nectar_maker =
{
	widget =
	{
		slotpos = {},
		animbank = "ui_icepack_2x3",
		animbuild = "ui_icepack_2x3",
		pos = Vector3(200, 0, 0),

		buttoninfo =
		{
			text = STRINGS.ACTIONS.COOK,
			position = Vector3(-125, -130, 0),
		}
	},
	acceptsstacks = false,
	type = "chest",
}

for y = 0, 2 do
	table.insert(params.aip_nectar_maker.widget.slotpos, Vector3(-162, -75 * y + 75, 0))
	table.insert(params.aip_nectar_maker.widget.slotpos, Vector3(-162 + 75, -75 * y + 75, 0))
end

function params.aip_nectar_maker.itemtestfn(container, item, slot)
	local values = getNectarValues(item)
	return GLOBAL.next(values) ~= nil
end

function params.aip_nectar_maker.widget.buttoninfo.fn(inst)
	if inst.components.container ~= nil then
		GLOBAL.BufferedAction(inst.components.container.opener, inst, AIP_ACTION):Do()
	elseif inst.replica.container ~= nil and not inst.replica.container:IsBusy() then
		GLOBAL.SendRPCToServer(GLOBAL.RPC.DoWidgetButtonAction, AIP_ACTION.code, inst, AIP_ACTION.mod_name)
	end
end

function params.aip_nectar_maker.widget.buttoninfo.validfn(inst)
	return inst.replica.container ~= nil and not inst.replica.container:IsEmpty()
end

---------------- 木之图腾 ----------------
params.aip_woodener =
{
	widget =
	{
		slotpos = {},
		animbank = "ui_chest_3x3",
		animbuild = "ui_chest_3x3",
		pos = Vector3(0, 200, 0),
		side_align_tip = 160,

		buttoninfo =
		{
			text = STRINGS.ACTIONS.CRAFT,
			position = Vector3(0, -140, 0),
		}
	},
	acceptsstacks = true,
	type = "chest",
}

for y = 2, 0, -1 do
	for x = 0, 2 do
		table.insert(params.aip_woodener.widget.slotpos, Vector3(80 * x - 80 * 2 + 80, 80 * y - 80 * 2 + 80, 0))
	end
end

function params.aip_woodener.itemtestfn(container, item, slot)
	if item.prefab ~= "log" and item.prefab ~= "livinglog" and item.prefab ~= "driftwood_log" then
		return false, "AIP_WOODENER_LOG_ONLY"
	end

	return true
end

-- 操作按钮
function params.aip_woodener.widget.buttoninfo.fn(inst)
	if inst.components.container ~= nil then
		GLOBAL.BufferedAction(inst.components.container.opener, inst, AIP_ACTION):Do()
	elseif inst.replica.container ~= nil and not inst.replica.container:IsBusy() then
		GLOBAL.SendRPCToServer(GLOBAL.RPC.DoWidgetButtonAction, AIP_ACTION.code, inst, AIP_ACTION.mod_name)
	end
end

-- 校验是否可以按下
function params.aip_woodener.widget.buttoninfo.validfn(inst)
	return inst.replica.container ~= nil and not inst.replica.container:IsEmpty()
end

---------------- 暗影宝箱 ----------------
params.aip_shadow_chest =
{
	widget =
	{
		slotpos = {},
		animbank = "ui_chest_3x3",
		animbuild = "ui_chest_3x3",
		pos = Vector3(0, 200, 0),
		side_align_tip = 160,
		
		buttoninfo =
		{
			text = STRINGS.UI.HELP.CONFIGURE,
			position = Vector3(0, -140, 0),
		}
	},
	acceptsstacks = true,
	type = "chest",
}

for y = 2, 0, -1 do
	for x = 0, 2 do
		table.insert(params.aip_shadow_chest.widget.slotpos, Vector3(80 * x - 80 * 2 + 80, 80 * y - 80 * 2 + 80, 0))
	end
end

local tmpConfig = {
	--[[prompt = "Write on the sign",
	animbank = "ui_board_5x3",
	animbuild = "ui_board_5x3",
	menuoffset = Vector3(6, -70, 0),]]

	cancelbtn = { text = "Cancel", cb = nil, control = CONTROL_CANCEL },
	-- middlebtn = { text = "Random", cb = nil, control = CONTROL_MENU_MISC_2 },
	acceptbtn = { text = "Confirm", cb = nil, control = CONTROL_ACCEPT },

	--[[config = {
		{
			name = "autoCollect",
			label = "Auto Collect Item",
			options =
			{
				{description = "True", data = "true"},
				{description = "False", data = "false"},
			},
			default = "false",
		},
	},]]
}

function params.aip_shadow_chest.widget.buttoninfo.fn(inst)
	local player = GLOBAL.ThePlayer

	if player and player.HUD then
		return player.HUD:ShowAIPAutoConfigWidget(inst, tmpConfig)
	end
end

-------------- 月光豆酱雕塑 --------------
params.chesspiece_aip_doujiang =
{
	widget =
	{
		animbank = "aip_ui_doujiang_chest",
		animbuild = "aip_ui_doujiang_chest",
		pos = Vector3(300, 50, 0), -- x, y(越大越上)
		side_align_tip = 160,

		slotpos = {
			Vector3(0, -170, 0),
			Vector3(0, 170, 0),
			Vector3(156, 90, 0),
			Vector3(156, -90, 0),
			Vector3(-156, 90, 0),
			Vector3(-156, -90, 0),
		},

		slotbg = {},

		buttoninfo =
		{
			text = STRINGS.ACTIONS.CRAFT,
			position = Vector3(0, -88, 0),
		}
	},
	acceptsstacks = false,
	type = "chest",
}

local aip_doujiang_slot_bgs = {
	{ name="ash",prefab="fertilizer",fail="AIP_ASH_ONLY" },
	{ name="electricity",prefab="nightstick",fail="AIP_ELECTRICITY_ONLY" },
	{ name="fire",prefab="firestaff",fail="AIP_FIRE_ONLY" },
	{ name="plant",prefab="boards",fail="AIP_PLANT_ONLY" },
	{ name="water",prefab="waterballoon",fail="AIP_WATER_ONLY" },
	{ name="wind",prefab="featherfan",fail="AIP_WIND_ONLY" },
}

for i, v in ipairs(aip_doujiang_slot_bgs) do
	local name = v.name
	table.insert(
		params.chesspiece_aip_doujiang.widget.slotbg,
		{
			atlas = "images/inventoryimages/aip_doujiang_slot_"..name.."_bg.xml",
			image = "aip_doujiang_slot_"..name.."_bg.tex",
		}
	)
end

function params.chesspiece_aip_doujiang.itemtestfn(container, item, slot)
	local ret = true
	local fail = nil

	if slot == nil or aip_doujiang_slot_bgs[slot] == nil then
		ret = false
		fail = "AIP_SLOT_ONLY"
	elseif aip_doujiang_slot_bgs[slot].prefab ~= item.prefab then
		ret = false
		fail = aip_doujiang_slot_bgs[slot].fail
	end

	if container.inst ~= nil and container.inst.components.talker ~= nil then
		container.inst.components.talker:Say(
			STRINGS.CHARACTERS.GENERIC.ACTIONFAIL.GIVE[fail]
		)
	end

	return ret
end

-- 操作按钮
function params.chesspiece_aip_doujiang.widget.buttoninfo.fn(inst)
	if inst.components.container ~= nil then
		GLOBAL.BufferedAction(inst.components.container.opener, inst, AIP_ACTION):Do()
	elseif inst.replica.container ~= nil and not inst.replica.container:IsBusy() then
		GLOBAL.SendRPCToServer(GLOBAL.RPC.DoWidgetButtonAction, AIP_ACTION.code, inst, AIP_ACTION.mod_name)
	end
end

-- 校验是否可以按下
function params.chesspiece_aip_doujiang.widget.buttoninfo.validfn(inst)
	return inst.replica.container ~= nil and inst.replica.container:IsFull()
end

---------------- 豆酱权杖 ----------------
function fillDouScepter(slotCount)
	local name = "aip_dou_scepter"..tostring(slotCount)
	local loopIndex = slotCount - 1

	params[name] = {
		widget = {
			slotpos = {},
			animbank = "ui_cookpot_1x4",
			animbuild = "ui_cookpot_1x4",
			pos = Vector3(0, -30 + loopIndex * 45, 0),
		},
		acceptsstacks = false,
		usespecificslotsforitems = true,
		type = "hand_inv",
	}

	for y = 0, loopIndex do
		table.insert(params[name].widget.slotpos, Vector3(0, 108 - 72 * y, 0))
	end

	-- 只接受魔法元素
	params[name].itemtestfn = function(container, item, slot)
		return item:HasTag("aip_dou_inscription")
	end
end

fillDouScepter(4)

-- 容器名字必须和物品名字一样，sad
params.aip_dou_scepter = params.aip_dou_scepter4

----------------------------------------------------------------------------------------------
local containers = GLOBAL.require "containers"
local old_widgetsetup = containers.widgetsetup

-- 豪华锅 和 冰箱 代码有BUG，只能注入一下了
-- Some mod inject the `widgetsetup` function with missing the `data` arguments cause customize data not work anymore.
-- Have to inject the function also, so sad.
function containers.widgetsetup(container, prefab, data)
	local pref = prefab or container.inst.prefab

	-- Hook
	local containerParams = params[pref]
	if containerParams then
		for k, v in pairs(containerParams) do
			container[k] = v
		end
		container:SetNumSlots(container.widget.slotpos ~= nil and #container.widget.slotpos or 0)
		return
	end

	return old_widgetsetup(container, prefab, data)
end

for k, v in pairs(params) do
	containers.MAXITEMSLOTS = math.max(containers.MAXITEMSLOTS, v.widget.slotpos ~= nil and #v.widget.slotpos or 0)
end