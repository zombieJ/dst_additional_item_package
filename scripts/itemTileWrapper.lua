-- 体验关闭
local additional_experiment = GLOBAL.aipGetModConfig("additional_experiment")
if additional_experiment ~= "open" then
	return nil
end

local tooltip_enhance = GLOBAL.aipGetModConfig("tooltip_enhance")
if tooltip_enhance ~= "open" then
	return nil
end

------------------------------------------------------------------
local aipPrint = GLOBAL.aipPrint
local AIP_SlotInfo = GLOBAL.require("widgets/aipInfo")

local function AddItemHook(slot)
	slot.aipSlotInfo = AIP_SlotInfo(slot)
end

AddClassPostConstruct("widgets/invslot", AddItemHook)