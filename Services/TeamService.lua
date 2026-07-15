local addonName, addon = ...

local TeamService = {}

local function GetProfile()
  return addon.Profiles:GetCurrentProfile()
end

function TeamService:GetTeams()
  local profile = GetProfile()
  if not profile
      or not profile.teams then
    return {}
  end
  return profile.teams
end

function TeamService:GetAllTeams()
  local profile = addon.Profiles:GetCurrentProfile()
  if not profile
      or not profile.teams then
    return {}
  end
  return profile.teams
end

function TeamService:GetFolders()
  local profile = GetProfile()
  profile.folders = profile.folders or {}
  return profile.folders
end

function TeamService:Create(name)
  local team = addon.Models.Team:Create(name)
  self:GetTeams()[team.id] = team
  addon.EventBus:Fire(
    addon.Events.TEAM_CREATED,
    team
  )
  print(
    "[PetMatch DEBUG] Team saved:",
    name
  )
  print(
    "[PetMatch DEBUG] Total teams:",
    #self:GetAllTeams()
  )
  return team
end

function TeamService:Get(id)
  return self:GetTeams()[id]
end

function TeamService:SetActive(id)
  local team =
      self:Get(id)
  if not team then
    return false
  end
  local profile = GetProfile()
  profile.activeTeam = id
  addon.EventBus:Fire(
    addon.Events.TEAM_SELECTED,
    team
  )
  return true
end

function TeamService:GetActive()
  local profile = GetProfile()
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
  local team = self:Get(teamID)
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
  local team = self:Get(teamID)
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
  local team = self:Get(teamID)
  if not team then
    return {}
  end
  return team.pets
end

function TeamService:AddPet(
    teamID,
    slot,
    petGUID
)
  local team = self:Get(teamID)
  if not team then
    return false
  end
  if slot < 1 or slot > 3 then
    return false
  end
  if not addon.Services.PetJournal:GetPet(
        petGUID
      ) then
    return false
  end
  team.pets[slot] = petGUID
  team.modified = time()
  addon.EventBus:Fire(
    addon.Events.PET_ADDED_TO_TEAM,
    team,
    slot,
    petGUID
  )
  addon.EventBus:Fire(
    addon.Events.TEAM_UPDATED,
    team
  )
  return true
end

function TeamService:Delete(teamID)
  local teams = self:GetTeams()
  local team = teams[teamID]

  if not team then
    return false
  end

  teams[teamID] = nil

  local profile =
      addon.Profiles:GetCurrentProfile()

  if profile.activeTeam == teamID then
    profile.activeTeam = nil
  end

  addon.EventBus:Fire(
    addon.Events.TEAM_DELETED,
    team
  )

  return true
end

-- function TeamService:Delete(id)
--   local teams = self:GetTeams()
--   local team = teams[id]
--   if not team then
--     return false
--   end
--   teams[id] = nil
--   addon.EventBus:Fire(
--     addon.Events.TEAM_DELETED,
--     team
--   )
--   return true
-- end

function TeamService:CreateFromBattleSlots(name)
  name = addon.Utils:Trim(name or "")
  if name == "" then
    return nil, "Enter a team name"
  end
  local slots = addon.Services.BattleSlot:GetCurrentSlots()
  local hasPet = false
  for slot = 1, 3 do
    if slots[slot] then
      hasPet = true
      break
    end
  end
  if not hasPet then
    return nil, "The current Battle Pet Slots are empty"
  end
  local team = self:Create(name)
  if not team then
    return nil, "Unable to create team"
  end
  for slot = 1, 3 do
    team.pets[slot] = slots[slot]
  end
  team.modified = time()
  addon.EventBus:Fire(
    addon.Events.TEAM_UPDATED,
    team
  )
  return team
end

function TeamService:Load(teamID)
  local team = self:Get(teamID)

  if not team then
    return false, "Team not found"
  end

  local success, errorMessage =
      addon.Services.BattleSlot:LoadPets(
        team.pets
      )

  if not success then
    return false, errorMessage
  end

  self:SetActive(team.id)

  addon.EventBus:Fire(
    addon.Events.TEAM_LOADED,
    team
  )

  return true
end

addon.Services.Team = TeamService
