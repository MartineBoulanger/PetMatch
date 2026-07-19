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

    if addon.UI.Views.SaveTeamButton then
      addon.UI.Views.SaveTeamButton:Show()
    end

    if addon.UI.Views.PetJournalToolbar then
      addon.UI.Views.PetJournalToolbar:Show()
    end
  else
    addon.UI.Manager:Hide()

    if addon.UI.Views.SaveTeamButton then
      addon.UI.Views.SaveTeamButton:Hide()
    end

    if addon.UI.Views.PetJournalToolbar then
      addon.UI.Views.PetJournalToolbar:Hide()
    end
  end
end

addon.UI.Host = Host
