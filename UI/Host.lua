local _, addon = ...

addon.UI = addon.UI or {}

local Host = {}

function Host:Update()
  if not PetJournal then
    return
  end


  if PetJournal:IsVisible() then
    addon.UI.Manager:Show()

    if addon.UI.Actions.SaveTeamButton then
      addon.UI.Actions.SaveTeamButton:Show()
    end

    if addon.UI.Actions.UpdateTeamButton then
      addon.UI.Actions.UpdateTeamButton:Show()
    end

    if addon.UI.Actions.PetJournalToolbar then
      addon.UI.Actions.PetJournalToolbar:Show()
    end
  else
    addon.UI.Manager:Hide()

    if addon.UI.Actions.SaveTeamButton then
      addon.UI.Actions.SaveTeamButton:Hide()
    end

    if addon.UI.Actions.UpdateTeamButton then
      addon.UI.Actions.UpdateTeamButton:Hide()
    end

    if addon.UI.Actions.PetJournalToolbar then
      addon.UI.Actions.PetJournalToolbar:Hide()
    end
  end
end

addon.UI.Host = Host
