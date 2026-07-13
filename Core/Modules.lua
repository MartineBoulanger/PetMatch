local _, addon = ...

local Modules = {}

function Modules:Register(name, module)
  if self[name] then
    addon.Logger:Warn(
      "Module already exists:",
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
        "Initializing",
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
        "Enabling",
        module.Name
      )
      module:Enable()
    end
  end
end

addon.ModuleManager = Modules
