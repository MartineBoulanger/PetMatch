local _, addon = ...

local L = addon.L
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

local function SummonButton()
  local frame = _G.PetJournalSummonButton

  if type(frame) == "table"
      and type(frame.IsShown) == "function"
      and frame:IsShown() then
    return frame
  end

  return nil
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

function SaveTeamButton:UpdatePetTrackerAnchor()
  local toggle = ZoneTrackerToggle()

  if not toggle then
    return
  end

  local summonButton = SummonButton()

  if not summonButton then
    return
  end

  toggle:ClearAllPoints()

  toggle:SetPoint(
    "LEFT",
    summonButton,
    "RIGHT",
    0,
    -1
  )
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
  button:SetText(L["SAVE_AS"])

  button:SetScript(
    "OnClick",
    function()
      addon.UI.Dialogs.SaveTeamDialog:Show()
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
      L["FIND_BATTLE_ERROR"]
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
    self:UpdatePetTrackerAnchor()
  end
end

function SaveTeamButton:Hide()
  if self.Frame then
    self.Frame:Hide()
  end
end

addon.UI.Actions.SaveTeamButton = SaveTeamButton
