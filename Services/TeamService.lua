local _, addon = ...

local TeamService = {}

local resolvedPetsBySpeciesID = {}

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
  return team
end

function TeamService:Get(id)
  return self:GetTeams()[id]
end

function TeamService:SetActive(id)
  local team = self:Get(id)
  if not team then
    return false
  end
  local profile = GetProfile()
  profile.activeTeam = id
  self:SetSelected(id)
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

  local loadout =
      addon.Services.BattleSlot:GetCurrentLoadout()

  local slots =
      loadout.pets

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

  team.pets = team.pets or {}
  team.abilities = team.abilities or {}

  for slot = 1, 3 do
    team.pets[slot] =
        loadout.pets[slot]

    local abilities =
        loadout.abilities[slot]

    if abilities then
      team.abilities[slot] = {
        [1] = abilities[1],
        [2] = abilities[2],
        [3] = abilities[3],
      }
    else
      team.abilities[slot] = nil
    end
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
        team.pets,
        team.abilities,
        team.specialSlots
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

function TeamService:SetNotes(
    teamID,
    notes
)
  local team = self:Get(teamID)

  if not team then
    return nil, "Team not found"
  end

  notes = tostring(notes or "")

  team.notes = notes
  team.modified = time()

  addon.EventBus:Fire(
    addon.Events.TEAM_UPDATED,
    team
  )

  return team
end

function TeamService:SetScript(
    teamID,
    script
)
  local team = self:Get(teamID)

  if not team then
    return nil, "Team not found"
  end

  team.script = addon.Utils:Trim(script or "")
  team.modified = time()

  addon.EventBus:Fire(
    addon.Events.TEAM_UPDATED,
    team
  )

  return team
end

function TeamService:ReplacePetsFromBattleSlots(
    teamID
)
  local team = self:Get(teamID)

  if not team then
    return nil, "Team not found"
  end

  local loadout =
      addon.Services.BattleSlot:
      GetCurrentLoadout()

  local hasPet = false

  for slot = 1, 3 do
    if loadout.pets[slot] then
      hasPet = true
      break
    end
  end

  if not hasPet then
    return nil,
        "The current Battle Pet Slots are empty"
  end

  team.pets = team.pets or {}
  team.abilities = team.abilities or {}

  for slot = 1, 3 do
    team.pets[slot] =
        loadout.pets[slot]

    local abilities =
        loadout.abilities[slot]

    if abilities then
      team.abilities[slot] = {
        [1] = abilities[1],
        [2] = abilities[2],
        [3] = abilities[3],
      }
    else
      team.abilities[slot] = nil
    end
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
  if not teamID then
    return nil
  end
  return self:Get(teamID)
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

function TeamService:BuildFromImport(importData, resolvedPetsBySpeciesID)
  if type(importData) ~= "table" then
    return nil, "Invalid import data", {}
  end

  resolvedPetsBySpeciesID = resolvedPetsBySpeciesID or {}

  local team = {
    name = addon.Utils:Trim(importData.name or ""),
    pets = {},
    abilities = {},
    breeds = {},
    specialSlots = {},
    folderID = importData.folderID,
    favorite = importData.favorite == true,
    notes = importData.notes or "",
    script = importData.script or "",
    targetNPCIDs = importData.npcIDs or {},
    importSource = importData.format or "unknown",
  }

  if team.name == "" then
    team.name = "Imported Team"
  end

  local missingSpecies = {}

  for slot = 1, 3 do
    local slotData = importData.slots and importData.slots[slot]

    if slotData then
      if slotData.special then
        team.specialSlots[slot] = {
          type = slotData.type,
          petType = slotData.petType,
          level = slotData.level,
          rarity = slotData.rarity,
          minimumLevel = slotData.minimumLevel,
          minimumHealth = slotData.minimumHealth,
          rawPetTag = slotData.rawPetTag,
        }
      elseif slotData.speciesID then
        local speciesID = tonumber(slotData.speciesID)

        if speciesID then
          local cachedPet = resolvedPetsBySpeciesID[speciesID]
          local petGUID

          if cachedPet ~= nil then
            if cachedPet ~= false then
              petGUID = cachedPet
            end
          else
            petGUID = addon.Services.PetJournal:FindOwnedPetBySpeciesID(slotData.speciesID)
            resolvedPetsBySpeciesID[speciesID] = petGUID or false
          end

          if petGUID then
            team.pets[slot] = petGUID
          else
            missingSpecies[#missingSpecies + 1] = slotData.speciesID
          end
        end

        team.abilities[slot] = slotData.abilities or {}
        team.breeds[slot] = slotData.breedID or 0
      end
    end
  end

  return team, nil, missingSpecies
end

function TeamService:CreateFromImport(importData, options)
  options = options or {}

  local importedTeam, errorMessage, missingSpecies =
      self:BuildFromImport(importData, options.resolvedPetsBySpeciesID)

  if not importedTeam then
    return nil, errorMessage, missingSpecies
  end

  local conflictMode =
      options.conflictMode
      or "replace"

  local team =
      self:FindByName(
        importedTeam.name,
        importedTeam.folderID
      )

  if team then
    if conflictMode == "skip" then
      return nil, "Team already exists", missingSpecies
    elseif conflictMode == "keep" then
      local uniqueName =
          self:GetUniqueName(
            importedTeam.name,
            importedTeam.folderID
          )

      team = self:Create(uniqueName)

      if not team then
        return nil, "Unable to create team", missingSpecies
      end
    elseif conflictMode == "replace" then
      -- Gebruik het bestaande team.
    else
      return nil, "Unknown conflict mode", missingSpecies
    end
  else
    team = self:Create(importedTeam.name)

    if not team then
      return nil, "Unable to create team", missingSpecies
    end
  end

  team.pets = importedTeam.pets
  team.abilities = importedTeam.abilities
  team.breeds = importedTeam.breeds
  team.specialSlots = importedTeam.specialSlots
  team.targetNPCIDs = importedTeam.targetNPCIDs
  team.folderID = importedTeam.folderID
  team.favorite = importedTeam.favorite
  team.notes = importedTeam.notes
  team.script = importedTeam.script
  team.importSource = importedTeam.importSource
  team.modified = time()

  addon.EventBus:Fire(addon.Events.TEAM_UPDATED, team)
  addon.EventBus:Fire(addon.Events.TEAM_IMPORTED, team, missingSpecies)

  return team, nil, missingSpecies
end

function TeamService:OverrideFromImport(
    teamID,
    importData
)
  local existingTeam =
      self:Get(teamID)

  if not existingTeam then
    return nil, "No team selected", {}
  end

  local importedTeam,
  errorMessage,
  missingSpecies =
      self:BuildFromImport(importData)

  if not importedTeam then
    return nil,
        errorMessage,
        missingSpecies
  end

  existingTeam.name =
      importedTeam.name

  existingTeam.pets =
      importedTeam.pets

  existingTeam.abilities =
      importedTeam.abilities

  existingTeam.breeds =
      importedTeam.breeds

  existingTeam.specialSlots =
      importedTeam.specialSlots

  existingTeam.targetNPCIDs =
      importedTeam.targetNPCIDs

  existingTeam.folderID =
      importedTeam.folderID

  existingTeam.favorite =
      importedTeam.favorite

  existingTeam.notes =
      importedTeam.notes

  existingTeam.script =
      importedTeam.script

  existingTeam.importSource =
      importedTeam.importSource

  existingTeam.modified = time()

  addon.EventBus:Fire(
    addon.Events.TEAM_UPDATED,
    existingTeam
  )

  addon.EventBus:Fire(
    addon.Events.TEAM_IMPORTED,
    existingTeam,
    missingSpecies
  )

  return existingTeam,
      nil,
      missingSpecies
end

function TeamService:LoadFromImport(
    importData
)
  local importedTeam,
  errorMessage,
  missingSpecies =
      self:BuildFromImport(importData)

  if not importedTeam then
    return false,
        errorMessage,
        missingSpecies
  end

  local success, loadError =
      addon.Services.BattleSlot:
      LoadPets(
        importedTeam.pets,
        importedTeam.abilities
      )

  if not success then
    return false,
        loadError,
        missingSpecies
  end

  addon.EventBus:Fire(
    addon.Events.TEAM_LOADED,
    importedTeam
  )

  return true,
      nil,
      missingSpecies
end

function TeamService:FindByName(
    name,
    folderID
)
  local normalizedName =
      string.lower(
        addon.Utils:Trim(name or "")
      )

  for _, team in pairs(
    self:GetTeams()
  ) do
    local teamName =
        string.lower(
          addon.Utils:Trim(
            team.name or ""
          )
        )

    local sameFolder =
        team.folderID == folderID

    if teamName == normalizedName
        and sameFolder then
      return team
    end
  end

  return nil
end

function TeamService:GetUniqueName(
    name,
    folderID
)
  if not self:FindByName(
        name,
        folderID
      ) then
    return name
  end

  local index = 2
  local candidate

  repeat
    candidate = string.format(
      "%s (%d)",
      name,
      index
    )

    index = index + 1
  until not self:FindByName(
      candidate,
      folderID
    )

  return candidate
end

function TeamService:SetSelected(id)
  addon.Settings:SetUI(
    "selectedTeamID",
    id
  )

  local team = self:Get(id)

  addon.EventBus:Fire(
    addon.Events.TEAM_SELECTED,
    team
  )
end

function TeamService:IsPetInAnyTeam(petGUID)
  if type(petGUID) ~= "string"
      or petGUID == "" then
    return false
  end

  for _, team in pairs(
    self:GetTeams()
  ) do
    if type(team) == "table"
        and type(team.pets) == "table" then
      for slot = 1, 3 do
        if team.pets[slot] == petGUID then
          return true
        end
      end
    end
  end

  return false
end

addon.Services.Team = TeamService
