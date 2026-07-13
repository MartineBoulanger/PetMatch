local addonName, addon = ...

local TeamService = {}

local function GetProfile()
  return addon.Profiles:GetCurrentProfile()
end

function TeamService:GetTeams()
  local profile = GetProfile()
  profile.teams =
      profile.teams or {}
  return profile.teams
end

function TeamService:GetFolders()
  local profile = GetProfile()
  profile.folders =
      profile.folders or {}
  return profile.folders
end

function TeamService:Create(name)
  local team =
      addon.Models.Team:Create(
        name
      )
  self:GetTeams()[team.id] = team
  addon.EventBus:Fire(
    addon.Events.TEAM_CREATED,
    team
  )
  return team
end

function TeamService:Get(id)
  return self:GetTeams()[id]
end

function TeamService:Delete(id)
  local teams =
      self:GetTeams()
  local team =
      teams[id]
  if not team then
    return false
  end
  teams[id] = nil
  addon.EventBus:Fire(
    addon.Events.TEAM_DELETED,
    team
  )
  return true
end

function TeamService:SetActive(id)
  local team =
      self:Get(id)
  if not team then
    return false
  end
  local profile =
      GetProfile()
  profile.activeTeam = id
  addon.EventBus:Fire(
    addon.Events.TEAM_SELECTED,
    team
  )
  return true
end

function TeamService:GetActive()
  local profile =
      GetProfile()
  if not profile.activeTeam then
    return nil
  end
  return self:Get(
    profile.activeTeam
  )
end

function TeamService:AddToFolder(
    teamID,
    folderID
)
  local team =
      self:Get(teamID)
  if not team then
    return false
  end
  team.folderID = folderID
  team.modified = time()
  return true
end

function TeamService:SetPet(
    teamID,
    slot,
    petGUID
)
  local team =
      self:Get(teamID)
  if not team then
    return false
  end
  if slot < 1 or slot > 3 then
    return false
  end
  team.pets[slot] = petGUID
  team.modified = time()
  addon.EventBus:Fire(
    addon.Events.TEAM_UPDATED,
    team
  )
  return true
end

function TeamService:GetPets(teamID)
  local team =
      self:Get(teamID)
  if not team then
    return {}
  end
  return team.pets
end

addon.Services.Team = TeamService
