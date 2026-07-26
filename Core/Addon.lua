local addonName, addon = ...

local frame = CreateFrame(
  "Frame",
  "PetMatchFrame"
)

local function Initialize()
  if addon.Initialized then
    return
  end

  addon.Database:Initialize()
  addon.Modules:Initialize()
  addon.Settings:Initialize()
  addon.EventBus:Fire(
    addon.Events.DATABASE_READY
  )
  addon.Initialized = true
end

local function Enable()
  if addon.Enabled then
    return
  end
  addon.Modules:Enable()
  addon.Enabled = true

  C_Timer.After(
    2,
    function()
      addon.Services.PetJournal:Scan()
    end
  )

  addon.Logger:Info("v1.5.0 Loaded - open the PetJournal to use the addon")
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
