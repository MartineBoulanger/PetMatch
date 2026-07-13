local addonName, addon = ...

local TeamService = {}

function TeamService:GetTeams()
  local profile =
      addon.Profiles:GetCurrentProfile()
  if not profile.teams then
    profile.teams = {}
  end
  return profile.teams
end

function TeamService:Create(name)
  local team =
      addon.Models.Team:Create(
        name
      )
  table.insert(
    self:GetTeams(),
    team
  )
  addon.EventBus:Fire(
    addon.Events.TEAM_CREATED,
    team
  )
  return team
end

function TeamService:Delete(team)
  local teams =
      self:GetTeams()
  for index, item in ipairs(teams) do
    if item.id == team.id then
      table.remove(
        teams,
        index
      )
      addon.EventBus:Fire(
        addon.Events.TEAM_DELETED,
        team
      )
      return true
    end
  end
  return false
end

function TeamService:FindByName(name)
  for _, team in ipairs(
    self:GetTeams()
  ) do
    if team.name == name then
      return team
    end
  end
  return nil
end

addon.Services.Team = TeamService
