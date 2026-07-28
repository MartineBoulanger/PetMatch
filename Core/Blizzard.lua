local _, addon = ...

addon.Blizzard = addon.Blizzard or {}
local Blizzard = {}

Blizzard.Hooked = false

function Blizzard:AttachPetLoadoutTooltips()
  if not PetJournalLoadout then
    return
  end

  local slots = {
    PetJournalLoadout.Pet1,
    PetJournalLoadout.Pet2,
    PetJournalLoadout.Pet3,
  }

  for _, slot in ipairs(slots) do
    if slot then
      addon.UI.Components.PetTooltip:Attach(
        slot,
        function(control)
          return "petGUID",
              control.petID
              or control.petGUID
        end
      )
    end
  end
end

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

  hooksecurefunc(
    "PetJournal_InitPetButton",
    function(button)
      addon.UI.Components.PetTooltip:Attach(
        button,
        function(control)
          if not control.petID then
            return nil
          end
          return "petGUID", control.petID
        end
      )
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
