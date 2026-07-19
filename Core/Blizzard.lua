local addonName, addon = ...

local Blizzard = {}

Blizzard.Hooked = false

function Blizzard:Initialize()
  if self.Hooked then
    return
  end

  if not PetJournal then
    return
  end

  self.Hooked = true

  PetJournal:HookScript(
    "OnShow",
    function()
      addon.UI.Host:Update()
    end
  )

  PetJournal:HookScript(
    "OnHide",
    function()
      addon.UI.Host:Update()
    end
  )

  if addon.Services.LoadoutMonitor then
    addon.Services.LoadoutMonitor:Initialize()
  end
end

local frame = CreateFrame("Frame")

frame:RegisterEvent("ADDON_LOADED")
frame:SetScript(
  "OnEvent",
  function(_, event, name)
    if event == "ADDON_LOADED"
        and name == "Blizzard_Collections" then
      Blizzard:Initialize()
    end
  end
)

addon.Blizzard = Blizzard
