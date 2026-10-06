local _, addon = ...

local L = addon.L
local UnloadTeamButton = {}

function UnloadTeamButton:Unload()
  local battleSlotService =
      addon.Services.BattleSlot

  if not battleSlotService then
    return false
  end

  --------------------------------------------------
  -- Clear Blizzard battle pet slots
  --------------------------------------------------
  local success, errorMessage = battleSlotService:Clear()

  if not success then
    if errorMessage then
      addon.Logger:Warn(errorMessage)
    end

    return false
  end

  --------------------------------------------------
  -- Clear active PetMatch team
  --------------------------------------------------
  local teamService = addon.Services.Team

  if teamService then
    teamService:ClearActive()
  end

  --------------------------------------------------
  -- Clear Team Setup state
  --------------------------------------------------
  local teamSetupService = addon.Services.TeamSetup

  if teamSetupService then
    for slot = 1, 3 do
      teamSetupService:SetNormalSlot(slot)
    end

    teamSetupService:ClearTargetNPC()
  end

  --------------------------------------------------
  -- Clear Target Team Card
  --------------------------------------------------
  local targetTeamCard = addon.UI and addon.UI.Components
      and addon.UI.Components.TargetTeamCard

  if targetTeamCard then
    targetTeamCard:Clear()
  end

  --------------------------------------------------
  -- Reset Blizzard loadout title
  --------------------------------------------------
  if addon.Blizzard then
    addon.Blizzard:UpdateLoadoutTitle(nil)
  end

  return true
end

function UnloadTeamButton:Create()
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
      or _G.PetJournalHealPetButton or _G.PetJournalHealButton

  local styleSource = healFrame and healFrame.Button

  --------------------------------------------------
  -- Button
  --------------------------------------------------
  local control = addon.UI.Components.ToolbarIconButton:Create(
    PetJournal,
    {
      name = "PetMatchUnloadTeamButton",
      texture = "Interface\\AddOns\\PetMatch\\Media\\unload-team",
      width = 36,
      height = 36,
      styleSource = styleSource,
      tooltipTitle = L["UNLOAD_TEAM"],
      tooltipDescription = L["UNLOAD_TEAM_DESCRIPTION"],
      onClick = function()
        self:Unload()
      end,
    }
  )

  local button = control:GetFrame()

  --------------------------------------------------
  -- Position
  --------------------------------------------------
  local firstSlot = _G.PetJournalLoadoutPet1

  if firstSlot then
    button:SetPoint(
      "BOTTOMRIGHT", firstSlot, "TOPRIGHT", 5, 5
    )
  end

  self.Frame = button

  return button
end

function UnloadTeamButton:Show()
  local button = self:Create()

  if button then
    button:Show()
  end
end

function UnloadTeamButton:Hide()
  if self.Frame then
    self.Frame:Hide()
  end
end

addon.UI.Actions.UnloadTeamButton = UnloadTeamButton
