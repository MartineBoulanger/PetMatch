local addonName, addon = ...

local TeamService = {}

local function GetProfile()
  return addon.Profiles:GetCurrentProfile()
end

local function SortTeams(teams, sortMode)
  table.sort(teams, function(left, right)
    if sortMode == "modified" then
      local leftModified =
          left.modified or 0

      local rightModified =
          right.modified or 0

      if leftModified ~= rightModified then
        return leftModified > rightModified
      end
    elseif sortMode == "favorites" then
      local leftFavorite =
          left.favorite == true

      local rightFavorite =
          right.favorite == true

      if leftFavorite ~= rightFavorite then
        return leftFavorite
      end
    end

    return string.lower(left.name or "")
        < string.lower(right.name or "")
  end)
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

  if self:GetSelectedID() == teamID then
    addon.Settings:SetUI(
      "selectedTeamID",
      nil
    )

    addon.EventBus:Fire(
      addon.Events.TEAM_SELECTED,
      nil,
      nil
    )
  end

  addon.EventBus:Fire(
    addon.Events.TEAM_DELETED,
    team
  )

  return true
end

function TeamService:CreateFromBattleSlots(name, folderID)
  name = addon.Utils:Trim(name or "")

  if name == "" then
    return nil, "Enter a team name"
  end

  if folderID
      and not addon.Services.Folder:Get(folderID) then
    return nil, "Folder not found"
  end

  local slots =
      addon.Services.BattleSlot:GetCurrentSlots()

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

  team.folderID = folderID
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

function TeamService:Rename(teamID, name)
  local team = self:Get(teamID)

  if not team then
    return nil, "Team not found"
  end

  name = addon.Utils:Trim(name or "")

  if name == "" then
    return nil, "Enter a team name"
  end

  team.name = name
  team.modified = time()

  addon.EventBus:Fire(
    addon.Events.TEAM_UPDATED,
    team
  )

  return team
end

function TeamService:ReplacePetsFromBattleSlots(teamID)
  local team = self:Get(teamID)

  if not team then
    return nil, "Team not found"
  end

  local slots =
      addon.Services.BattleSlot:GetCurrentSlots()

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

  team.pets = team.pets or {}

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

function TeamService:Edit(teamID, name, replacePets)
  local team, errorMessage =
      self:Rename(teamID, name)

  if not team then
    return nil, errorMessage
  end

  if replacePets then
    team, errorMessage =
        self:ReplacePetsFromBattleSlots(teamID)

    if not team then
      return nil, errorMessage
    end
  end

  return team
end

function TeamService:MoveToFolder(teamID, folderID)
  local team = self:Get(teamID)

  if not team then
    return nil, "Team not found"
  end

  if folderID
      and not addon.Services.Folder:Get(folderID) then
    return nil, "Folder not found"
  end

  team.folderID = folderID
  team.modified = time()

  addon.EventBus:Fire(
    addon.Events.TEAM_UPDATED,
    team
  )

  return team
end

function TeamService:GetTeamsInFolder(folderID)
  local result = {}

  for _, team in pairs(self:GetTeams()) do
    if team.folderID == folderID then
      table.insert(result, team)
    end
  end

  table.sort(result, function(left, right)
    return string.lower(left.name or "")
        < string.lower(right.name or "")
  end)

  return result
end

function TeamService:GetVisibleTeams(folderKey)
  folderKey =
      folderKey
      or addon.Services.Folder.ALL

  local result = {}

  for _, team in pairs(self:GetTeams()) do
    local matchesFolder = false

    if folderKey
        == addon.Services.Folder.ALL then
      matchesFolder = true
    elseif folderKey
        == addon.Services.Folder.FAVORITES then
      matchesFolder =
          team.favorite == true
    elseif folderKey
        == addon.Services.Folder.UNSORTED then
      matchesFolder =
          team.folderID == nil
    else
      matchesFolder =
          team.folderID == folderKey
    end

    local matchesSearch =
        addon.Services.Search:MatchesTeam(
          team
        )

    if matchesFolder and matchesSearch then
      table.insert(result, team)
    end
  end

  SortTeams(
    result,
    self:GetSortMode()
  )

  return result
end

function TeamService:SelectForUI(teamID)
  if teamID == nil then
    addon.Settings:SetUI(
      "selectedTeamID",
      nil
    )

    addon.EventBus:Fire(
      addon.Events.TEAM_SELECTED,
      nil,
      nil
    )

    return nil
  end

  local team = self:Get(teamID)

  if not team then
    return nil
  end

  addon.Settings:SetUI(
    "selectedTeamID",
    teamID
  )

  addon.EventBus:Fire(
    addon.Events.TEAM_SELECTED,
    team,
    nil
  )

  return team
end

function TeamService:GetSelectedID()
  local teamID =
      addon.Settings:GetUI(
        "selectedTeamID"
      )

  if teamID and self:Get(teamID) then
    return teamID
  end

  return nil
end

function TeamService:GetSelected()
  local teamID = self:GetSelectedID()

  return teamID and self:Get(teamID) or nil
end

function TeamService:SetSortMode(sortMode)
  local validModes = {
    name = true,
    modified = true,
    favorites = true,
  }

  if not validModes[sortMode] then
    return false
  end

  addon.Settings:SetUI(
    "teamSortMode",
    sortMode
  )

  addon.EventBus:Fire(
    addon.Events.TEAM_SORT_CHANGED,
    sortMode
  )

  return true
end

function TeamService:GetSortMode()
  return addon.Settings:GetUI(
    "teamSortMode"
  ) or "name"
end

function TeamService:SetFavorite(teamID, favorite)
  local team = self:Get(teamID)

  if not team then
    return nil, "Team not found"
  end

  favorite = favorite == true

  if team.favorite == favorite then
    return team
  end

  team.favorite = favorite
  team.modified = time()

  addon.EventBus:Fire(
    addon.Events.TEAM_FAVORITE_CHANGED,
    team,
    favorite
  )

  addon.EventBus:Fire(
    addon.Events.TEAM_UPDATED,
    team
  )

  return team
end

function TeamService:ToggleFavorite(teamID)
  local team = self:Get(teamID)

  if not team then
    return nil, "Team not found"
  end

  return self:SetFavorite(
    teamID,
    not team.favorite
  )
end

function TeamService:AddTag(teamID, tagID)
  local team = self:Get(teamID)

  if not team then
    return nil, "Team not found"
  end

  if not addon.Services.Tag:Get(tagID) then
    return nil, "Tag not found"
  end

  team.tags = team.tags or {}

  if team.tags[tagID] then
    return team
  end

  team.tags[tagID] = true
  team.modified = time()

  addon.EventBus:Fire(
    addon.Events.TEAM_TAGS_CHANGED,
    team
  )

  addon.EventBus:Fire(
    addon.Events.TEAM_UPDATED,
    team
  )

  return team
end

function TeamService:RemoveTag(teamID, tagID)
  local team = self:Get(teamID)

  if not team then
    return nil, "Team not found"
  end

  team.tags = team.tags or {}

  if not team.tags[tagID] then
    return team
  end

  team.tags[tagID] = nil
  team.modified = time()

  addon.EventBus:Fire(
    addon.Events.TEAM_TAGS_CHANGED,
    team
  )

  addon.EventBus:Fire(
    addon.Events.TEAM_UPDATED,
    team
  )

  return team
end

function TeamService:ToggleTag(teamID, tagID)
  local team = self:Get(teamID)

  if not team then
    return nil, "Team not found"
  end

  team.tags = team.tags or {}

  if team.tags[tagID] then
    return self:RemoveTag(teamID, tagID)
  end

  return self:AddTag(teamID, tagID)
end

function TeamService:HasTag(team, tagID)
  return team ~= nil
      and team.tags ~= nil
      and team.tags[tagID] == true
end

addon.Services.Team = TeamService
