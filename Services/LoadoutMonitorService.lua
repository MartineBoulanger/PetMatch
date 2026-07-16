local addonName, addon = ...

local LoadoutMonitorService = {
  Initialized = false,
  DirtyTeamID = nil,
  ChangedSlots = {},
}

function LoadoutMonitorService:Initialize()
  if self.Initialized then
    return
  end

  self.Initialized = true

  -- Blizzard en PetMatch gebruiken deze functie om
  -- een pet in een loadoutslot te plaatsen.
  hooksecurefunc(
    C_PetJournal,
    "SetPetLoadOutInfo",
    function()
      self:ScheduleCheck()
    end
  )

  addon.EventBus:Register(
    addon.Events.TEAM_SELECTED,
    function()
      self:ScheduleCheck()
    end
  )

  addon.EventBus:Register(
    addon.Events.TEAM_LOADED,
    function()
      self:ScheduleCheck()
    end
  )

  addon.EventBus:Register(
    addon.Events.TEAM_UPDATED,
    function()
      self:ScheduleCheck()
    end
  )

  addon.EventBus:Register(
    addon.Events.TEAM_DELETED,
    function()
      self:ScheduleCheck()
    end
  )

  self:ScheduleCheck()
end

function LoadoutMonitorService:ScheduleCheck()
  if self.CheckScheduled then
    return
  end

  self.CheckScheduled = true

  C_Timer.After(0, function()
    self.CheckScheduled = false
    self:Check()
  end)
end

function LoadoutMonitorService:Check()
  local selectedTeam =
      addon.Services.Team:GetSelected()

  local dirty = false
  local changedSlots = {}
  local dirtyTeamID = nil

  if selectedTeam then
    dirty, changedSlots =
        addon.Services.TeamCompare:
        CompareWithCurrentSlots(
          selectedTeam
        )

    if dirty then
      dirtyTeamID = selectedTeam.id
    end
  end

  local stateChanged =
      self.DirtyTeamID ~= dirtyTeamID

  if not stateChanged then
    for slot = 1, 3 do
      if self.ChangedSlots[slot]
          ~= changedSlots[slot] then
        stateChanged = true
        break
      end
    end
  end

  self.DirtyTeamID = dirtyTeamID
  self.ChangedSlots = changedSlots

  if stateChanged then
    addon.EventBus:Fire(
      addon.Events.CURRENT_TEAM_DIRTY_CHANGED,
      selectedTeam,
      dirty,
      changedSlots
    )
  end
end

function LoadoutMonitorService:IsTeamDirty(teamID)
  return teamID ~= nil
      and self.DirtyTeamID == teamID
end

function LoadoutMonitorService:IsSlotChanged(slot)
  return self.ChangedSlots[slot] == true
end

addon.Services.LoadoutMonitor =
    LoadoutMonitorService
