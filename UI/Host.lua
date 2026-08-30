local _, addon = ...

local Host = {}

-- local function GetPanelName(frame)
--   if not frame then
--     return "nil"
--   end

--   return frame:GetName() or tostring(frame)
-- end

-- local function IsPetMatchAllowed()
--   if not PetJournal or not PetJournal:IsVisible() then
--     return false
--   end

--   local centerFrame = GetUIPanel and GetUIPanel("center") or nil

--   print(
--     "PetMatch panels:",
--     "CENTER =", GetPanelName(centerFrame)
--   )

--   return centerFrame == nil
-- end

-- function Host:Update()
--   if not PetJournal then
--     return
--   end

--   local petJournalVisible = PetJournal:IsVisible()
--   local petMatchVisible = IsPetMatchAllowed()

--   --------------------------------------------------
--   -- PetMatch
--   --------------------------------------------------
--   if petMatchVisible then
--     addon.UI.Manager:Show()
--   else
--     addon.UI.Manager:Hide()
--   end

--   --------------------------------------------------
--   -- Pet Journal actions
--   --------------------------------------------------
--   if petJournalVisible then
--     if addon.UI.Actions.SaveTeamButton then
--       addon.UI.Actions.SaveTeamButton:Show()
--     end

--     if addon.UI.Actions.UpdateTeamButton then
--       addon.UI.Actions.UpdateTeamButton:Show()
--     end

--     if addon.UI.Actions.PetJournalToolbar then
--       addon.UI.Actions.PetJournalToolbar:Show()
--     end

--     if addon.UI.Actions.RandomPetsButton then
--       addon.UI.Actions.RandomPetsButton:Show()
--     end
--   else
--     if addon.UI.Actions.SaveTeamButton then
--       addon.UI.Actions.SaveTeamButton:Hide()
--     end

--     if addon.UI.Actions.UpdateTeamButton then
--       addon.UI.Actions.UpdateTeamButton:Hide()
--     end

--     if addon.UI.Actions.PetJournalToolbar then
--       addon.UI.Actions.PetJournalToolbar:Hide()
--     end

--     if addon.UI.Actions.RandomPetsButton then
--       addon.UI.Actions.RandomPetsButton:Hide()
--     end
--   end
-- end

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

    if addon.UI.Actions.RandomPetsButton then
      addon.UI.Actions.RandomPetsButton:Show()
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

    if addon.UI.Actions.RandomPetsButton then
      addon.UI.Actions.RandomPetsButton:Hide()
    end
  end
end

addon.UI.Host = Host
