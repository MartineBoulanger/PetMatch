local _, addon = ...

local L = addon.L
local UpdateTeamButton = {}

function UpdateTeamButton:Create()
  if self.Frame then
    return self.Frame
  end

  if not PetJournal then
    return nil
  end

  local saveButton =
      addon.UI.Actions.SaveTeamButton
      and addon.UI.Actions.SaveTeamButton:Create()

  if not saveButton then
    return nil
  end

  local button =
      CreateFrame(
        "Button",
        "PetMatchUpdateTeamButton",
        PetJournal,
        "UIPanelButtonTemplate"
      )

  button:SetSize(110, 22)
  button:SetText(L["UPDATE_TEAM"])

  button:ClearAllPoints()
  button:SetPoint(
    "RIGHT",
    saveButton,
    "LEFT",
    -2,
    0
  )

  button:SetScript(
    "OnClick",
    function()
      self:UpdateSelectedTeam()
    end
  )

  button:Hide()

  self.Frame = button

  self:RegisterEvents()
  self:Refresh()

  return button
end

function UpdateTeamButton:GetSelectedTeam()
  return addon.Services.Team:GetSelected()
end

function UpdateTeamButton:UpdateSelectedTeam()
  local team = self:GetSelectedTeam()

  if not team then
    return
  end

  local pendingSpecialSlots =
      addon.Services.BattleSlot:
      GetPendingSpecialSlots()

  local updatedTeam, errorMessage =
      addon.Services.Team:
      ReplacePetsFromBattleSlots(
        team.id,
        pendingSpecialSlots
      )

  if not updatedTeam then
    addon.Logger:Warn(
      errorMessage
      or L["UNABLE_TO_UPDATE"]
    )
    return
  end

  addon.Services.BattleSlot:SetPendingSpecialSlots(updatedTeam.specialSlots)
  addon.Services.Team:SetActive(updatedTeam.id)
  addon.Services.LoadoutMonitor:ScheduleCheck()

  self:Refresh()
end

function UpdateTeamButton:Refresh()
  if not self.Frame then
    return
  end

  local team = self:GetSelectedTeam()

  local loadoutDirty =
      team ~= nil
      and addon.Services.LoadoutMonitor
      and addon.Services.LoadoutMonitor:
      IsTeamDirty(team.id)

  local specialSlotsDirty =
      team ~= nil
      and addon.Services.BattleSlot
      and addon.Services.BattleSlot:ArePendingSpecialSlotsDifferent(
        team.specialSlots
      )

  local isDirty =
      loadoutDirty
      or specialSlotsDirty

  if isDirty then
    self.Frame:Show()
  else
    self.Frame:Hide()
  end
end

function UpdateTeamButton:RegisterEvents()
  if self.EventsRegistered then
    return
  end

  self.EventsRegistered = true

  local function Refresh()
    self:Refresh()
  end

  addon.EventBus:Register(
    addon.Events.CURRENT_TEAM_DIRTY_CHANGED,
    Refresh
  )

  addon.EventBus:Register(
    addon.Events.TEAM_SELECTED,
    Refresh
  )

  addon.EventBus:Register(
    addon.Events.TEAM_LOADED,
    Refresh
  )

  addon.EventBus:Register(
    addon.Events.TEAM_UPDATED,
    Refresh
  )

  addon.EventBus:Register(
    addon.Events.TEAM_DELETED,
    Refresh
  )
end

function UpdateTeamButton:Show()
  self:Create()
  self:Refresh()
end

function UpdateTeamButton:Hide()
  if self.Frame then
    self.Frame:Hide()
  end
end

addon.UI.Actions.UpdateTeamButton = UpdateTeamButton
