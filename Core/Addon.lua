local addonName, addon = ...

local frame = CreateFrame(
  "Frame",
  "PetMatchFrame"
)

local function Initialize()
  if addon.Initialized then
    return
  end
  addon.Logger:Info(
    "Initializing PetMatch",
    addon.Version
  )
  addon.ModuleManager:Initialize()
  addon.Database:Initialize()
  addon.Initialized = true
end

local function Enable()
  if addon.Enabled then
    return
  end
  addon.ModuleManager:Enable()
  addon.Enabled = true
  addon.Logger:Info(
    "PetMatch loaded successfully"
  )
end

frame:RegisterEvent("ADDON_LOADED")

frame:SetScript(
  "OnEvent",
  function(_, event, loadedAddon)
    if event == "ADDON_LOADED"
        and loadedAddon == addonName then
      Initialize()
      Enable()
    end
  end
)
