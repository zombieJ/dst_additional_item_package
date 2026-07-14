local questConfig = require("configurations/aip_pig_village_quest")
local MAX_INDICATOR_RANGE = TUNING.MAX_INDICATOR_RANGE * 1.5

STRINGS.NAMES.AIP_PIG_VILLAGE_QUEST_MARKER = questConfig.LANG.INDICATOR_NAME

-- 只在任务目标位于屏幕外且距离玩家较近时显示原版问号引导。
local function ShouldTrack(inst, viewer)
	return inst:IsValid() and
		viewer ~= nil and viewer:IsValid() and
		viewer:IsNear(inst, MAX_INDICATOR_RANGE) and
		not inst.entity:FrustumCheck() and
		CanEntitySeeTarget(viewer, inst)
end

-- 创建跟随任务猪人或猪窝的感叹号标记。
local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddNetwork()
	inst.entity:AddLabel()

	inst.Label:SetText("!")
	inst.Label:SetFontSize(50)
	inst.Label:SetFont(DEFAULTFONT)
	inst.Label:SetWorldOffset(0, 3, 0)
	inst.Label:SetColour(1, 0.82, 0.1)
	inst.Label:Enable(true)

	inst:AddTag("FX")
	inst:AddTag("NOCLICK")

	-- 复用原版 NPC 的屏幕边缘目标引导，缺省头像会显示为问号。
	if not TheNet:IsDedicated() then
		inst:AddComponent("hudindicatable")
		inst.components.hudindicatable:SetShouldTrackFunction(ShouldTrack)
	end

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst.persists = false

	return inst
end

return Prefab("aip_pig_village_quest_marker", fn)
