local foldername = KnownModIndex:GetModActualName(TUNING.ZOMBIEJ_ADDTIONAL_PACKAGE)

local Empty = Class(function()
end)

-- 体验关闭
local additional_experiment = GetModConfigData("additional_experiment", foldername)
if additional_experiment ~= "open" then
	return Empty
end

-- 建筑关闭
local additional_building = GetModConfigData("additional_building", foldername)
if additional_building ~= "open" then
	return Empty
end

-- 食物关闭
local additional_food = GetModConfigData("additional_food", foldername)
if additional_food ~= "open" then
	return Empty
end

local ShadowFollower = Class(function(self, inst)
	self.inst = inst

	-- 创建跟随者
	inst:DoTaskInTime(0, function()
		local x, y, z = inst.Transform:GetWorldPosition()

		-- 可视化跟随者
		self.vest = SpawnPrefab("dark_observer_vest")
		self.vest.Transform:SetPosition(x, y, z)
		self.vest.MiniMapEntity:SetEnabled(false)

		-- 地图跟随者
		self.icon = SpawnPrefab("globalmapicon")
		self.icon.MiniMapEntity:SetPriority(10)
		self.icon.MiniMapEntity:SetRestriction("player")
		self.icon.MiniMapEntity:SetIcon("dark_observer_vest.tex")
		self.icon.Transform:SetPosition(x, y, z)
		self.icon.MiniMapEntity:SetEnabled(false)

		-- 刷新跟随坐标
		inst:DoPeriodicTask(1, function()
			self:RefreshIcon()
		end)
	end)

	inst:ListenForEvent("onremove", function()
		self:OnRemoveFromEntity()
	end)
end)

-- 刷新单位图标
function ShadowFollower:RefreshIcon()
	if TheWorld.components.world_common_store:isShadowFollowing() then
		-- 跟踪怪物图标
		local x, y, z = self.inst.Transform:GetWorldPosition()

		if self.vest then
			self.vest.MiniMapEntity:SetEnabled(true)
			self.vest.Transform:SetPosition(x, y, z)
		end
		if self.icon then
			self.icon.MiniMapEntity:SetEnabled(true)
			self.icon.Transform:SetPosition(x, y, z)
		end
	else
		-- 隐藏怪物图标
		if self.vest then
			self.vest.MiniMapEntity:SetEnabled(false)
		end
		if self.icon then
			self.icon.MiniMapEntity:SetEnabled(false)
		end
	end
end

-- 移除组件
function ShadowFollower:OnRemoveFromEntity()
	-- 移除跟随者
	if self.vest then
		self.vest:Remove()
	end
	if self.icon then
		self.icon:Remove()
	end
end

function ShadowFollower:OnSave()
	local data = {}
	return data
end

function ShadowFollower:OnLoad(data)
end

return ShadowFollower