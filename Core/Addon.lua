local addonName, addon = ...

local L = addon.L

local frame = CreateFrame(
  "Frame",
  "PetMatchFrame"
)

local function Initialize()
  if addon.Initialized then
    return
  end

  addon.Database:Initialize()
  addon.ModuleManager:Initialize()
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
  addon.ModuleManager:Enable()
  addon.Enabled = true

  if addon.Blizzard:IsCollectionsLoaded() then
    addon.Blizzard:Initialize()
  end

  C_Timer.After(
    2,
    function()
      addon.Services.PetJournal:Scan()
    end
  )

  addon.Logger:Info("v1.21.5 " .. L["LOADED"])
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
