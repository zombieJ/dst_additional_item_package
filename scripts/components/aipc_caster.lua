--[[
  Type: line, area, target
]]

-------------------------------- Liner --------------------------------
local function ReticuleTargetFn()
  return Vector3(ThePlayer.entity:LocalToWorldSpace(6.5, 0, 0))
end

local function ReticuleMouseTargetFn(inst, mousepos)
  if mousepos ~= nil then
      local x, y, z = inst.Transform:GetWorldPosition()
      local dx = mousepos.x - x
      local dz = mousepos.z - z
      local l = dx * dx + dz * dz
      if l <= 0 then
          return inst.components.reticule.targetpos
      end
      l = 6.5 / math.sqrt(l)
      return Vector3(x + dx * l, 0, z + dz * l)
  end
end

local function ReticuleUpdatePositionFn(inst, pos, reticule, ease, smoothing, dt)
  local x, y, z = inst.Transform:GetWorldPosition()
  reticule.Transform:SetPosition(x, 0, z)
  local rot = -math.atan2(pos.z - z, pos.x - x) / DEGREES
  if ease and dt ~= nil then
      local rot0 = reticule.Transform:GetRotation()
      local drot = rot - rot0
      rot = Lerp((drot > 180 and rot0 + 360) or (drot < -180 and rot0 - 360) or rot0, rot, dt * smoothing)
  end
  reticule.Transform:SetRotation(rot)
end

-------------------------------- Area ---------------------------------
local function AreaReticuleTargetFn()
  local player = ThePlayer
  local ground = TheWorld.Map
  local pos = Vector3()
  --Cast range is 8, leave room for error
  --2 is the aoe range
  for r = 5, 0, -.25 do
      pos.x, pos.y, pos.z = player.entity:LocalToWorldSpace(r, 0, 0)
      if ground:IsPassableAtPoint(pos:Get()) and not ground:IsGroundTargetBlocked(pos) then
          return pos
      end
  end
  return pos
end

------------------------------ Component ------------------------------
-- Client only
local Caster = Class(function(self, inst)
    self.inst = inst
    self.reticule = {
        ease = false,
        smoothing = 6.66,
        targetfn = nil,
        reticuleprefab = "reticule",
        validcolour = {204 / 255, 131 / 255, 57 / 255, .3},
        invalidcolour = {1, 0, 0, .3},
        mouseenabled = false,
        pingprefab = nil,
        ispassableatallpoints = true,
    }

    self.active = nil -- 初始化时是 nil，卸载后才会变成 false
    self.type = nil

    self.onEquip = nil
    self.onUnequip = nil

    self.showIndicator = _G.net_bool(inst.GUID, "aipc_caster_indicator", "aipc_caster_indicator_dirty")
    if TheWorld.ismastersim then
      self.showIndicator:set(true)
    end
end)

local function RefreshReticule(inst)
  local owner = ThePlayer
  if owner ~= nil then
      local inventoryitem = inst.replica.inventoryitem
      if inventoryitem ~= nil and inventoryitem:IsHeldBy(owner) and owner.components.playercontroller ~= nil then
          owner.components.playercontroller:RefreshReticule()
      end
  end
end

function Caster:ToggleIndicator()
  self.showIndicator:set(not self.showIndicator:value())
  self:SetUp(self.type, true)
end

function Caster:SetUp(type, forceRefresh)
  local showIndicator = self.showIndicator:value()

  -- 如果类型变了就重置一下
  local needRefresh = self.type ~= type and self.active ~= false

  if needRefresh or not showIndicator or forceRefresh then
    self:StopTargeting()
  end

  -- 只有开启了指示器才显示
  if showIndicator then
    if type == "LINE" or type == "THROUGH" then
      self.reticule.reticuleprefab = "reticulelong"
      self.reticule.pingprefab = "reticulelongping"
      self.reticule.targetfn = ReticuleTargetFn
      self.reticule.mousetargetfn = ReticuleMouseTargetFn
      self.reticule.updatepositionfn = ReticuleUpdatePositionFn
      self.reticule.validcolour = {1, .75, 0, 1}
      self.reticule.invalidcolour = {.5, 0, 0, 1}
      self.reticule.ease = true
      self.reticule.mouseenabled = true
    elseif type == "AREA" then
      self.reticule.reticuleprefab = "reticuleaoesmall"
      self.reticule.pingprefab = "reticuleaoesmallping"
      self.reticule.targetfn = AreaReticuleTargetFn
      self.reticule.mousetargetfn = nil
      self.reticule.updatepositionfn = nil
      self.reticule.validcolour = { 1, .75, 0, 1 }
      self.reticule.invalidcolour = { .5, 0, 0, 1 }
      self.reticule.ease = true
      self.reticule.mouseenabled = true
    elseif type == "FOLLOW" then
      self.reticule.reticuleprefab = nil
      self.reticule.pingprefab = nil
      self.reticule.targetfn = nil
      self.reticule.mousetargetfn = nil
      self.reticule.updatepositionfn = nil
      self.reticule.validcolour = nil
      self.reticule.invalidcolour = nil
      self.reticule.ease = false
      self.reticule.mouseenabled = false
    end

    if needRefresh or forceRefresh then
      self:StartTargeting()
    end
  end

    self.type = type
end

-- Active when on equip. Client trigger
function Caster:OnEquip()
  if self.onEquip ~= nil then
    self.onEquip(self.inst)
  end

  if not self.active then
    self.active = true
    self:StartTargeting()
  end
end

function Caster:OnUnequip()
  if self.onUnequip ~= nil then
    self.onUnequip(self.inst)
  end

  if self.active then
    self.active = false
    self:StopTargeting()
  end
end

function Caster:StartTargeting()
    if self.inst.components.reticule == nil then
        self.inst:AddComponent("reticule")
        for k, v in pairs(self.reticule) do
            self.inst.components.reticule[k] = v
        end
        RefreshReticule(self.inst)
    end
end

function Caster:StopTargeting()
    if self.inst.components.reticule ~= nil then
        self.inst:RemoveComponent("reticule")
        RefreshReticule(self.inst)
    end
end

return Caster
