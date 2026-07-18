local addonName, addon = ...

local LoadoutMonitorService = {
  Initialized = false,
  DirtyTeamID = nil,
  ChangedSlots = {},
  SuspendCount = 0,
}

function LoadoutMonitorService:Initialize()
  if self.Initialized then
    return
  end

  self.Initialized = true

  hooksecurefunc(
    C_PetJournal,
    "SetPetLoadOutInfo",
    function()
      self:ScheduleCheck()
    end
  )

  hooksecurefunc(
    C_PetJournal,
    "SetAbility",
    function()
      self:ScheduleCheck()
    end
  )

  self.EventFrame =
      self.EventFrame
      or CreateFrame("Frame")

  self.EventFrame:RegisterEvent(
    "PET_JOURNAL_LIST_UPDATE"
  )

  self.EventFrame:SetScript(
    "OnEvent",
    function(_, event)
      if event == "PET_JOURNAL_LIST_UPDATE" then
        self:ScheduleCheck()
      end
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
  if self:IsSuspended() then
    return
  end

  if self.CheckScheduled then
    return
  end

  self.CheckScheduled = true

  C_Timer.After(0.05, function()
    self.CheckScheduled = false
    self:Check()
  end)
end

function LoadoutMonitorService:Check()
  if self:IsSuspended() then
    return
  end

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

function LoadoutMonitorService:Suspend()
  self.SuspendCount =
      (self.SuspendCount or 0) + 1
end

function LoadoutMonitorService:Resume()
  self.SuspendCount =
      math.max(
        0,
        (self.SuspendCount or 0) - 1
      )

  if self.SuspendCount == 0 then
    self:ScheduleCheck()
  end
end

function LoadoutMonitorService:IsSuspended()
  return (self.SuspendCount or 0) > 0
end

addon.Services.LoadoutMonitor =
    LoadoutMonitorService
