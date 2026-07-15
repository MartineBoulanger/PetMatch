local addonName, addon = ...

addon.UI = addon.UI or {}

local Host = {}

function Host:Update()
  print(
    "[PetMatch DEBUG] Host Update",
    PetJournal and PetJournal:IsVisible()
  )


  if not PetJournal then
    return
  end


  if PetJournal:IsVisible() then
    addon.UI.Manager:Show()
  else
    addon.UI.Manager:Hide()
  end
end

addon.UI.Host = Host
