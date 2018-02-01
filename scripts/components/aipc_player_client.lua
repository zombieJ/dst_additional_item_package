-- 这个组件用于清除 side effect
local Player = Class(function(self, inst)
	self.inst = inst

	inst:ListenForEvent("death", function()
		self:Death()
	end)
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