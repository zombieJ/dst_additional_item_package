-- 这个组件用于清除 side effect
-------------------------------------------------------------------------------
local function OnEquip(inst, data)
	if data.eslot == EQUIPSLOTS.HANDS then
		if data.item.components.aipc_caster ~= nil then
			inst.components.aipc_caster:OnEquip()
		end
	end
end

local function OnUnequip(inst, data)
	if data.eslot == EQUIPSLOTS.HANDS then
		if data.item.components.aipc_caster ~= nil then
			inst.components.aipc_caster:OnUnequip()
		end
	end
end

-------------------------------------------------------------------------------
local Player = Class(function(self, inst)
	self.inst = inst

	inst:ListenForEvent("death", function()
		self:Death()
	end)

	-- Client only
	if self.inst == ThePlayer then
		self.inst:ListenForEvent("equip", OnEquip)
		self.inst:ListenForEvent("unequip", OnUnequip)
	end
end)

function Player:OffMineCar()
	local player = self.inst

	if not TheWorld.ismastersim then
		return
	end

	if player:HasTag("aip_minecar_driver") then
		local x, y, z = player.Transform:GetWorldPosition()
		local mineCars = TheSim:FindEntities(x, y, z, 10, { "aip_minecar" })

		for i, mineCar in ipairs(mineCars) do
			local aipc_minecar = mineCar.components.aipc_minecar
			if aipc_minecar and aipc_minecar.driver == player then
				aipc_minecar:RemoveDriver(player)
			end
		end
	end
end

-------------------------------------------------------------------------------
function Player:Death()
	---------------------------------- Server ----------------------------------
	if not TheWorld.ismastersim then
		return
	end

	self:OffMineCar()
end

function Player:Destroy()
	local player = self.inst

	self.inst:RemoveEventCallback("equip", OnEquip)
	self.inst:RemoveEventCallback("unequip", OnUnequip)

	aipPrint("Player leave:", player.name, "(", player.userid, ")")

	---------------------------------- Client ----------------------------------

	---------------------------------- Server ----------------------------------
	if not TheWorld.ismastersim then
		return
	end

	self:OffMineCar()
end

Player.OnRemoveEntity = Player.Destroy

return Player