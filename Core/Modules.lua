local _, addon = ...

addon.ModuleManager = addon.ModuleManager or {}

local L = addon.L
local Modules = {}

function Modules:Register(name, module)
  if self[name] then
    addon.Logger:Warn(
      L["MODULE_EXISTS"],
      name
    )
    return
  end
  module.Name = name
  self[name] = module
  table.insert(
    addon.Modules,
    module
  )
end

function Modules:Initialize()
  for _, module in ipairs(addon.Modules) do
    if module.Initialize then
      addon.Logger:Debug(
        L["INIT_MODULE"],
        module.Name
      )
      module:Initialize()
    end
  end
end

function Modules:Enable()
  for _, module in ipairs(addon.Modules) do
    if module.Enable then
      addon.Logger:Debug(
        L["ENABLING_MODULE"],
        module.Name
      )
      module:Enable()
    end
  end
end

addon.ModuleManager = Modules
