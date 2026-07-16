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
      print("[PetMatch DEBUG] PetJournal OnShow")
      addon.UI.Host:Update()
    end
  )

  PetJournal:HookScript(
    "OnHide",
    function()
      print("[PetMatch DEBUG] PetJournal OnHide")
      addon.UI.Host:Update()
    end
  )

  if addon.Services.LoadoutMonitor then
    addon.Services.LoadoutMonitor:Initialize()
  end

  print("[PetMatch] PetJournal visibility hooks active")
end

local frame = CreateFrame("Frame")

frame:RegisterEvent("ADDON_LOADED")
frame:SetScript(
  "OnEvent",
  function(_, event, name)
    if event == "ADDON_LOADED"
        and name == "Blizzard_Collections" then
      print("[PetMatch DEBUG] Blizzard_Collections loaded")
      Blizzard:Initialize()
    end
  end
)

addon.Blizzard = Blizzard
