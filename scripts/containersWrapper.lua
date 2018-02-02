local Vector3 = GLOBAL.Vector3
local STRINGS = GLOBAL.STRINGS

---------------------------------------- 驾驶 ----------------------------------------
local AIP_ACTION = env.AddAction("AIP_ACTION", "Operate", function(act)
	-- Client Only Code
	local doer = act.doer
	local target = act.target

	-- 驾驶吧
	if target.components.aipc_action ~= nil then
		target.components.aipc_action:DoAction(doer)
		return true
	end
	return false, "INUSE"
end)
AddStategraphActionHandler("wilson", GLOBAL.ActionHandler(AIP_ACTION, "doshortaction"))
AddStategraphActionHandler("wilson_client", GLOBAL.ActionHandler(AIP_ACTION, "doshortaction"))

---------------------------------------- 配置 ----------------------------------------
local cooking = GLOBAL.require("cooking")
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
	type = "pack",
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
params.nectar_maker =
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
	type = "pack",
}

for y = 0, 2 do
	table.insert(params.nectar_maker.widget.slotpos, Vector3(-162, -75 * y + 75, 0))
	table.insert(params.nectar_maker.widget.slotpos, Vector3(-162 + 75, -75 * y + 75, 0))
end

function params.nectar_maker.itemtestfn(container, item, slot)
	ingredient = cooking.ingredients[item.prefab]
	if ingredient and ingredient.tags then
		if ingredient.tags.fruit or ingredient.tags.sweetener or ingredient.tags.frozen then
			return true
		end
	end

	if item:HasTag("aip_nectar_material") then
		return true
	end
	
	return false
end

function params.nectar_maker.widget.buttoninfo.fn(inst)
	if inst.components.container ~= nil then
		GLOBAL.BufferedAction(inst.components.container.opener, inst, AIP_ACTION):Do()
	elseif inst.replica.container ~= nil and not inst.replica.container:IsBusy() then
		GLOBAL.SendRPCToServer(GLOBAL.RPC.DoWidgetButtonAction, AIP_ACTION.code, inst, AIP_ACTION.mod_name)
	end
end

function params.nectar_maker.widget.buttoninfo.validfn(inst)
	return inst.replica.container ~= nil and not inst.replica.container:IsEmpty()
end

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