local _, addon = ...

local L = addon.L
local TargetTeamLoadButton = {}

--------------------------------------------------
-- Create
--------------------------------------------------
function TargetTeamLoadButton:Create()
  if self.Frame then
    return self.Frame
  end

  if not PetJournal then
    return nil
  end

  --------------------------------------------------
  -- Blizzard style source
  --------------------------------------------------
  local healFrame = PetJournal.HealPetSpellFrame
      or PetJournal.HealPetButton or PetJournal.HealButton
      or _G.PetJournalHealPetSpellFrame
      or _G.PetJournalHealPetButton
      or _G.PetJournalHealButton

  local styleSource = healFrame and healFrame.Button

  --------------------------------------------------
  -- Button
  --------------------------------------------------
  local control =
      addon.UI.Components.ToolbarIconButton:Create(
        PetJournal,
        {
          name = "PetMatchTargetTeamLoadButton",
          texture = "Interface\\AddOns\\PetMatch\\Media\\load-team",
          width = 36,
          height = 36,
          styleSource = styleSource,
          tooltipTitle = L["LOAD_TEAM"],
          onClick = function()
            self:LoadTeam()
          end,
        }
      )

  local button = control:GetFrame()

  --------------------------------------------------
  -- Position
  --------------------------------------------------
  local anchor = _G.PetJournalLoadoutPet1

  if anchor then
    button:SetPoint(
      "BOTTOMLEFT",
      anchor,
      "TOPLEFT",
      -5,
      5
    )
  end

  self.Frame = button

  return button
end

--------------------------------------------------
-- Set team
--------------------------------------------------
function TargetTeamLoadButton:SetTeam(team, npcID)
  if not team or not team.id then
    self:Hide()
    return
  end

  local button = self:Create()

  if not button then
    return
  end

  self.Team = team
  self.NPCID = npcID

  button:SetText(L["LOAD_TEAM"])

  button:Show()
end

--------------------------------------------------
-- Load team
--------------------------------------------------
function TargetTeamLoadButton:LoadTeam()
  local team = self.Team

  if not team or not team.id then
    return
  end

  local teamService = addon.Services.Team

  if not teamService then
    return
  end

  local success = teamService:Load(team.id)

  if success then
    self:Hide()
  end
end

--------------------------------------------------
-- Hide
--------------------------------------------------
function TargetTeamLoadButton:Hide()
  self.Team = nil
  self.NPCID = nil

  if self.Frame then
    self.Frame:Hide()
  end
end

--------------------------------------------------
-- Register
--------------------------------------------------
addon.UI.Actions.TargetTeamLoadButton = TargetTeamLoadButton
