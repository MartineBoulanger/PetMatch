local addonName, addon = ...

local PetJournalHook = {}

function PetJournalHook:Initialize()
  addon.Logger:Info(
    "PetJournalHook ready"
  )
end

addon.UI = addon.UI or {}

addon.UI.PetJournalHook = PetJournalHook
