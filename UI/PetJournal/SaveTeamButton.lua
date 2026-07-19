local addonName, addon = ...

addon.UI = addon.UI or {}
addon.UI.Views = addon.UI.Views or {}

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

function SaveTeamButton:Create()
  if self.Frame then
    return self.Frame
  end

  if not PetJournal then
    return nil
  end

  local findBattleButton =
      FindBattleButton()

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
      addon.UI.Views.SaveTeamDialog:Show()
    end
  )

  button:ClearAllPoints()

  if findBattleButton then
    button:SetPoint(
      "RIGHT",
      findBattleButton,
      "LEFT",
      -2,
      0
    )
  else
    -- Veilige fallback als Blizzard de interne knopnaam wijzigt.
    button:SetPoint(
      "BOTTOMRIGHT",
      PetJournal,
      "BOTTOMRIGHT",
      -12,
      12
    )

    addon.Logger:Warn(
      "Find Battle button was not found; using fallback position"
    )
  end

  button:Hide()

  self.Frame = button

  return button
end

function SaveTeamButton:Show()
  local button = self:Create()

  if button then
    button:Show()
  end
end

function SaveTeamButton:Hide()
  if self.Frame then
    self.Frame:Hide()
  end
end

addon.UI.Views.SaveTeamButton =
    SaveTeamButton
