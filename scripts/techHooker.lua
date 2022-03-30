local _G = GLOBAL
local TechTree = require("techtree")

table.insert(TechTree.AVAILABLE_TECH, "AIP_DOU_SCEPTER")
table.insert(TechTree.AVAILABLE_TECH, "AIP_DOU_TOTEM")

local originCreate = TechTree.Create
TechTree.Create = function(t)
  local t = originCreate(t)
  if t.AIP_DOU_SCEPTER == nil then
    t.AIP_DOU_SCEPTER = 0
  end
  if t.AIP_DOU_TOTEM == nil then
    t.AIP_DOU_TOTEM = 0
  end
  return t
end

----------
_G.TECH.NONE.AIP_DOU_SCEPTER = 0
_G.TECH.AIP_DOU_SCEPTER = { AIP_DOU_SCEPTER = 2 }

_G.TECH.NONE.AIP_DOU_TOTEM = 0
_G.TECH.AIP_DOU_TOTEM = { AIP_DOU_TOTEM = 2 }

----------
for k,v in pairs(_G.TUNING.PROTOTYPER_TREES) do
  v.AIP_DOU_SCEPTER = 0
  v.AIP_DOU_TOTEM = 0
end

----------
_G.TUNING.PROTOTYPER_TREES.AIP_DOU_SCEPTER = TechTree.Create({
  AIP_DOU_SCEPTER = 2,
})
_G.TUNING.PROTOTYPER_TREES.AIP_DOU_TOTEM = TechTree.Create({
  AIP_DOU_TOTEM = 2,
})

----------
for i, v in pairs(_G.AllRecipes) do
  if v.level.AIP_DOU_SCEPTER == nil then
      v.level.AIP_DOU_SCEPTER = 0
  end
  if v.level.AIP_DOU_TOTEM == nil then
    v.level.AIP_DOU_TOTEM = 0
  end
end