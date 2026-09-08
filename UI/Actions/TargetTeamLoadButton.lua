local _, addon = ...

local TargetTeamLoadButton = {}

--------------------------------------------------
-- Find battle slot anchor
--------------------------------------------------
local function FindBattleSlotAnchor()
  return _G.PetJournalLoadoutPet1
      or (PetJournal and PetJournal.Loadout)
      or PetJournal
end

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

  local anchor = FindBattleSlotAnchor()

  if not anchor then
    return nil
  end

  local button =
      CreateFrame(
        "Button",
        "PetMatchTargetTeamLoadButton",
        PetJournal,
        "UIPanelButtonTemplate"
      )

  button:SetSize(
    90,
    22
  )

  button:SetText(
    "Load Team"
  )

  button:SetScript(
    "OnClick",
    function()
      self:LoadTeam()
    end
  )

  button:ClearAllPoints()

  button:SetPoint(
    "BOTTOMLEFT",
    anchor,
    "TOPLEFT",
    -6,
    2
  )

  button:Hide()

  self.Frame = button
  self.Team = nil
  self.NPCID = nil

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

  button:SetText(
    "Load Team"
  )

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
