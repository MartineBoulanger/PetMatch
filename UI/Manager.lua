local addonName, addon = ...

addon.UI = addon.UI or {}

local Manager = {}

function Manager:ShowPetJournal()
  if not addon.UI.Views or not addon.UI.Views.TeamPanel then
    print("[PetMatch] TeamPanel not available")
    return
  end
  addon.UI.Views.TeamPanel:Initialize()
end

addon.UI.Manager = Manager
