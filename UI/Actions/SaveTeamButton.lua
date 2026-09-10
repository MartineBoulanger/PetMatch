local _, addon = ...

local SaveTeamButton = {}

local function FindBattleButton()
  return PetJournal
      and (
        PetJournal.FindBattleButton
        or PetJournal.FindBattle
      )
      or _G.PetJournalFindBattleButton
      or _G.PetJournalFindBattle
end

local function ZoneTrackerToggle()
  local frame = _G.PetTrackerTrackToggle

  if type(frame) == "table"
      and type(frame.IsShown) == "function"
      and frame:IsShown() then
    return frame
  end

  return nil
end

function SaveTeamButton:Create()
  if self.Frame then
    return self.Frame
  end

  if not PetJournal then
    return nil
  end

  local button =
      CreateFrame(
        "Button",
        "PetMatchSaveTeamButton",
        PetJournal,
        "UIPanelButtonTemplate"
      )

  button:SetSize(90, 22)
  button:SetText("Save As")

  button:SetScript(
    "OnClick",
    function()
      addon.UI.Dialogs.SaveTeamDialog:Show()
    end
  )

  button:Hide()

  self.Frame = button
  self:UpdateAnchor()
  
  return button
end

function SaveTeamButton:UpdateAnchor()
  local button = self.Frame

  if not button then
    return
  end

  local findBattleButton = FindBattleButton()

  button:ClearAllPoints()

  if not findBattleButton then
    -- Veilige fallback als Blizzard de interne knopnaam wijzigt.
    button:SetPoint(
      "BOTTOMRIGHT",
      PetJournal,
      "BOTTOMRIGHT",
      -12,
      12
    )

    if not self.FallbackUsed then
      self.FallbackUsed = true

      addon.Logger:Warn(
        "Find Battle button was not found; using fallback position"
      )
    end

    return
  end

  local zoneTrackerToggle = ZoneTrackerToggle()

  if zoneTrackerToggle then
    button:SetPoint(
      "RIGHT",
      zoneTrackerToggle,
      "LEFT",
      -8,
      1
    )
  else
    button:SetPoint(
      "RIGHT",
      findBattleButton,
      "LEFT",
      -2,
      0
    )
  end
end

function SaveTeamButton:Show()
  local button = self:Create()

  if button then
    self:UpdateAnchor()
    button:Show()
  end
end

function SaveTeamButton:Hide()
  if self.Frame then
    self.Frame:Hide()
  end
end

addon.UI.Actions.SaveTeamButton = SaveTeamButton
