local _, addon = ...

addon.API = addon.API or {}

local API = addon.API
API.Listeners = API.Listeners or {}

local function GetTeamService()
  return addon.Services
      and addon.Services.Team
      or nil
end

local function NormalizeScript(script)
  script = tostring(script or "")
  script = script:gsub("\r\n", "\n")
  script = script:gsub("\r", "\n")
  return script
end

function API:GetTeam(teamID)
  local service = GetTeamService()

  if not service or not service.Get then
    return nil
  end

  return service:Get(teamID)
end

function API:GetTeams()
  local service = GetTeamService()

  if not service or not service.GetTeams then
    return {}
  end

  return service:GetTeams()
end

function API:GetSelectedTeam()
  local service = GetTeamService()

  if not service or not service.GetSelected then
    return nil
  end

  return service:GetSelected()
end

function API:GetActiveTeam()
  local service = GetTeamService()

  if not service or not service.GetActive then
    return nil
  end

  return service:GetActive()
end

function API:GetCurrentTeam()
  return self:GetActiveTeam() or self:GetSelectedTeam()
end

function API:GetScript(teamID)
  local team = self:GetTeam(teamID)

  if not team then
    return nil
  end

  return team.script or ""
end

function API:SetScript(teamID, script)
  local service = GetTeamService()

  if not service then
    return nil, "Team service is unavailable"
  end

  script = NormalizeScript(script)

  if service.SetScript then
    return service:SetScript(
      teamID,
      script
    )
  end

  local team =
      service.Get
      and service:Get(teamID)
      or nil

  if not team then
    return nil, "Team not found"
  end

  team.script = script
  team.modified = time()

  if addon.EventBus
      and addon.EventBus.Fire
      and addon.Events
      and addon.Events.TEAM_UPDATED then
    addon.EventBus:Fire(
      addon.Events.TEAM_UPDATED,
      team
    )
  end

  return team
end

function API:RegisterCallback(eventName, callback)
  if type(eventName) ~= "string"
      or eventName == "" then
    return false
  end

  if type(callback) ~= "function" then
    return false
  end

  self.Listeners[eventName] =
      self.Listeners[eventName]
      or {}

  table.insert(
    self.Listeners[eventName],
    callback
  )

  return true
end

function API:UnregisterCallback(eventName, callback)
  local listeners = self.Listeners[eventName]

  if not listeners then
    return false
  end

  for index = #listeners, 1, -1 do
    if listeners[index] == callback then
      table.remove(
        listeners,
        index
      )
    end
  end

  if #listeners == 0 then
    self.Listeners[eventName] = nil
  end

  return true
end

function API:FireCallback(eventName, ...)
  local listeners = self.Listeners[eventName]

  if not listeners then
    return
  end

  for _, callback in ipairs(
    listeners
  ) do
    callback(...)
  end
end

if addon.EventBus and addon.Events then
  addon.EventBus:Register(
    addon.Events.TEAM_CREATED,
    function(team)
      API:FireCallback(
        "TEAM_CREATED",
        team
      )
    end
  )

  addon.EventBus:Register(
    addon.Events.TEAM_UPDATED,
    function(team)
      API:FireCallback(
        "TEAM_UPDATED",
        team
      )
    end
  )

  addon.EventBus:Register(
    addon.Events.TEAM_DELETED,
    function(team)
      API:FireCallback(
        "TEAM_DELETED",
        team
      )
    end
  )
end


_G.PetMatch = addon
