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
    #self:GetAll()
  )
  return team
end

function TeamService:Get(id)
  return self:GetTeams()[id]
end

function TeamService:Delete(id)
  local teams = self:GetTeams()
  local team = teams[id]
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

function TeamService:RemovePet(
    teamID,
    slot
)
  local team = self:Get(teamID)
  if not team then
    return false
  end
  team.pets[slot] = nil
  team.modified = time()
  addon.EventBus:Fire(
    addon.Events.PET_REMOVED_FROM_TEAM,
    team,
    slot
  )
  return true
end

function TeamService:CreateFromBattleSlots(name)
  local slots = addon.Services.BattleSlot:GetCurrentSlots()
  local team = self:Create(name)

  print(
    "[PetMatch DEBUG] Created team:",
    team.name,
    team.id
  )

  if not team then
    return nil
  end

  for slot = 1, 3 do
    team.pets[slot] = slots[slot]
  end

  team.modified = time()

  addon.EventBus:Fire(
    addon.Events.TEAM_UPDATED,
    team
  )

  print(
    "[PetMatch DEBUG] Pets saved:",
    team.pets[1],
    team.pets[2],
    team.pets[3]
  )

  return team
end

addon.Services.Team = TeamService
