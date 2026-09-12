local _, addon = ...

addon.Services = addon.Services or {}

local PetCollectionStatsService = {}

--------------------------------------------------
-- Helpers
--------------------------------------------------
local function GetOwnedSpeciesQuality(pets, petGUIDs)
  local bestQuality = nil

  for _, petGUID in ipairs(petGUIDs) do
    local pet = pets[petGUID]

    if pet then
      local quality = tonumber(pet.quality)

      if quality and (
            bestQuality == nil
            or quality > bestQuality) then
        bestQuality = quality
      end
    end
  end

  return bestQuality
end

local function GetCollectibleSpecies()
  ------------------------------------------------
  -- Save Pet Journal state
  ------------------------------------------------
  local collectedChecked =
      C_PetJournal.IsFilterChecked(
        LE_PET_JOURNAL_FILTER_COLLECTED
      )

  local notCollectedChecked =
      C_PetJournal.IsFilterChecked(
        LE_PET_JOURNAL_FILTER_NOT_COLLECTED
      )

  local sourceFilters = {}

  for sourceIndex = 1,
  C_PetJournal.GetNumPetSources() do
    sourceFilters[sourceIndex] =
        C_PetJournal.IsPetSourceChecked(sourceIndex)
  end

  local typeFilters = {}

  for petType = 1,
  C_PetJournal.GetNumPetTypes() do
    typeFilters[petType] =
        C_PetJournal.IsPetTypeChecked(petType)
  end

  local searchFilter = C_PetJournal.GetSearchFilter()

  ------------------------------------------------
  -- Show complete journal
  ------------------------------------------------
  C_PetJournal.ClearSearchFilter()

  C_PetJournal.SetFilterChecked(
    LE_PET_JOURNAL_FILTER_COLLECTED,
    true
  )

  C_PetJournal.SetFilterChecked(
    LE_PET_JOURNAL_FILTER_NOT_COLLECTED,
    true
  )

  C_PetJournal.SetAllPetSourcesChecked(
    true
  )

  C_PetJournal.SetAllPetTypesChecked(
    true
  )

  ------------------------------------------------
  -- Collect unique species
  ------------------------------------------------
  local species = {}
  local seenSpecies = {}

  local numPets = C_PetJournal.GetNumPets()
  numPets = tonumber(numPets) or 0

  for index = 1, numPets do
    local info = {
      C_PetJournal.GetPetInfoByIndex(index),
    }

    local speciesID = info[2]
    local petType = info[10]
    local obtainable = info[18]

    if speciesID and obtainable ~= false
        and not seenSpecies[speciesID] then
      seenSpecies[speciesID] = true
      species[#species + 1] = {
        speciesID = speciesID,
        petType = petType,
      }
    end
  end

  ------------------------------------------------
  -- Restore Pet Journal state
  ------------------------------------------------
  C_PetJournal.SetFilterChecked(
    LE_PET_JOURNAL_FILTER_COLLECTED,
    collectedChecked
  )

  C_PetJournal.SetFilterChecked(
    LE_PET_JOURNAL_FILTER_NOT_COLLECTED,
    notCollectedChecked
  )

  for sourceIndex, checked
  in pairs(sourceFilters) do
    C_PetJournal.SetPetSourceChecked(
      sourceIndex,
      checked
    )
  end

  for petType, checked
  in pairs(typeFilters) do
    C_PetJournal.SetPetTypeFilter(
      petType,
      checked
    )
  end

  if searchFilter
      and searchFilter ~= "" then
    C_PetJournal.SetSearchFilter(
      searchFilter
    )
  else
    C_PetJournal.ClearSearchFilter()
  end

  return species
end

local function GetTotalCollectibleSpecies()
  return #GetCollectibleSpecies()
end

--------------------------------------------------
-- General statistics
--------------------------------------------------
function PetCollectionStatsService:GetOverview()
  local petJournal = addon.Services.PetJournal

  if not petJournal then
    return nil
  end

  petJournal:EnsureIndex()

  local pets = petJournal:GetAll()
  local ownedBySpecies = petJournal.OwnedPetsBySpeciesID

  local stats = {
    totalOwned = 0,
    uniqueOwned = 0,
    totalCollectible = 0,
    missing = 0,
    duplicates = 0,
    rare = 0,
    maxLevel = 0,
    qualities = {},
  }

  ------------------------------------------------
  -- Owned pets
  ------------------------------------------------
  for _, pet in pairs(pets) do
    stats.totalOwned = stats.totalOwned + 1

    if tonumber(pet.quality) == 4 then
      stats.rare = stats.rare + 1
    end

    if tonumber(pet.level) == 25 then
      stats.maxLevel = stats.maxLevel + 1
    end
  end

  ------------------------------------------------
  -- Unique owned species + quality distribution
  ------------------------------------------------
  for speciesID, petGUIDs in pairs(ownedBySpecies) do
    if speciesID and type(petGUIDs) == "table"
        and #petGUIDs > 0 then
      stats.uniqueOwned = stats.uniqueOwned + 1

      local quality =
          GetOwnedSpeciesQuality(
            pets,
            petGUIDs
          )

      if quality ~= nil then
        stats.qualities[quality] =
            (
              stats.qualities[quality]
              or 0
            ) + 1
      end
    end
  end

  stats.duplicates =
      math.max(
        0,
        stats.totalOwned
        - stats.uniqueOwned
      )

  ------------------------------------------------
  -- Total collectible unique species
  ------------------------------------------------
  stats.totalCollectible = GetTotalCollectibleSpecies()

  stats.missing =
      math.max(
        0,
        stats.totalCollectible
        - stats.uniqueOwned
      )

  ------------------------------------------------
  -- Collection percentage
  ------------------------------------------------
  if stats.totalCollectible > 0 then
    stats.percentage =
        (
          stats.uniqueOwned
          / stats.totalCollectible
        ) * 100
  else
    stats.percentage = 0
  end

  return stats
end

--------------------------------------------------
-- Pet Family statistics
--------------------------------------------------
function PetCollectionStatsService:GetFamilyStats()
  local petJournal = addon.Services.PetJournal

  petJournal:EnsureIndex()

  local collectibleSpecies = GetCollectibleSpecies()

  local families = {}

  ------------------------------------------------
  -- Initialize all pet families
  ------------------------------------------------
  for familyID = 1, 10 do
    families[familyID] = {
      familyID = familyID,
      name =
          _G["BATTLE_PET_NAME_" .. familyID]
          or tostring(familyID),
      owned = 0,
      maximum = 0,
      missing = 0,
      percentage = 0,
    }
  end

  ------------------------------------------------
  -- Maximum collectible per family
  ------------------------------------------------
  for _, species in ipairs(collectibleSpecies) do
    local family = families[species.petType]

    if family then
      family.maximum = family.maximum + 1
    end
  end

  ------------------------------------------------
  -- Unique owned species per family
  ------------------------------------------------
  for speciesID, petGUIDs in pairs(
    petJournal.OwnedPetsBySpeciesID or {}) do
    local petGUID = petGUIDs and petGUIDs[1]
    local pet = petGUID and petJournal.Cache[petGUID]

    if pet and pet.petType then
      local family = families[pet.petType]

      if family then
        family.owned = family.owned + 1
      end
    end
  end

  ------------------------------------------------
  -- Derived values
  ------------------------------------------------
  for familyID = 1, 10 do
    local family = families[familyID]

    family.missing =
        math.max(0, family.maximum - family.owned)

    if family.maximum > 0 then
      family.percentage = (family.owned / family.maximum) * 100
    end
  end

  return families
end

--------------------------------------------------
-- Pet Source statistics
--------------------------------------------------
function PetCollectionStatsService:GetSourceStats()
  local petJournal = addon.Services.PetJournal

  petJournal:EnsureIndex()

  ------------------------------------------------
  -- Save Pet Journal state
  ------------------------------------------------
  local collectedChecked =
      C_PetJournal.IsFilterChecked(
        LE_PET_JOURNAL_FILTER_COLLECTED
      )

  local notCollectedChecked =
      C_PetJournal.IsFilterChecked(
        LE_PET_JOURNAL_FILTER_NOT_COLLECTED
      )

  local sourceFilters = {}

  local numSources =
      C_PetJournal.GetNumPetSources()

  for sourceID = 1, numSources do
    sourceFilters[sourceID] =
        C_PetJournal.IsPetSourceChecked(
          sourceID
        )
  end

  local typeFilters = {}

  local numTypes =
      C_PetJournal.GetNumPetTypes()

  for petType = 1, numTypes do
    typeFilters[petType] =
        C_PetJournal.IsPetTypeChecked(
          petType
        )
  end

  local searchFilter =
      C_PetJournal.GetSearchFilter()

  ------------------------------------------------
  -- Prepare complete journal
  ------------------------------------------------
  C_PetJournal.ClearSearchFilter()

  C_PetJournal.SetFilterChecked(
    LE_PET_JOURNAL_FILTER_COLLECTED,
    true
  )

  C_PetJournal.SetFilterChecked(
    LE_PET_JOURNAL_FILTER_NOT_COLLECTED,
    true
  )

  C_PetJournal.SetAllPetTypesChecked(
    true
  )

  ------------------------------------------------
  -- Collect stats per source
  ------------------------------------------------
  local sources = {}

  for sourceID = 1, numSources do
    ----------------------------------------------
    -- Enable only this source
    ----------------------------------------------
    C_PetJournal.SetAllPetSourcesChecked(
      false
    )

    C_PetJournal.SetPetSourceChecked(
      sourceID,
      true
    )

    local seenSpecies = {}
    local ownedSpecies = {}

    local maximum = 0
    local owned = 0

    local numPets = C_PetJournal.GetNumPets()
    numPets = tonumber(numPets) or 0

    ----------------------------------------------
    -- Scan source
    ----------------------------------------------
    for index = 1, numPets do
      local petGUID,
      speciesID,
      isOwned,
      _customName,
      _level,
      _favorite,
      _isRevoked,
      _speciesName,
      _icon,
      _petType,
      _companionID,
      _tooltip,
      _description,
      _isWild,
      _canBattle,
      _isTradeable,
      _isUnique,
      obtainable = C_PetJournal.GetPetInfoByIndex(index)

      if speciesID and obtainable ~= false
          and not seenSpecies[speciesID] then
        seenSpecies[speciesID] = true

        maximum = maximum + 1

        if isOwned
            or petJournal.OwnedPetsBySpeciesID[speciesID] then
          ownedSpecies[speciesID] = true
        end
      end
    end

    for _ in pairs(ownedSpecies) do
      owned = owned + 1
    end

    local missing = math.max(0, maximum - owned)
    local percentage = 0

    if maximum > 0 then
      percentage = (owned / maximum) * 100
    end

    sources[sourceID] = {
      sourceID = sourceID,
      name = _G["BATTLE_PET_SOURCE_" .. sourceID] or tostring(sourceID),
      owned = owned,
      maximum = maximum,
      missing = missing,
      percentage = percentage,
    }
  end

  ------------------------------------------------
  -- Restore Pet Journal state
  ------------------------------------------------
  C_PetJournal.SetFilterChecked(
    LE_PET_JOURNAL_FILTER_COLLECTED,
    collectedChecked
  )

  C_PetJournal.SetFilterChecked(
    LE_PET_JOURNAL_FILTER_NOT_COLLECTED,
    notCollectedChecked
  )

  for sourceID, checked in pairs(sourceFilters) do
    C_PetJournal.SetPetSourceChecked(
      sourceID,
      checked
    )
  end

  for petType, checked in pairs(typeFilters) do
    C_PetJournal.SetPetTypeFilter(
      petType,
      checked
    )
  end

  if searchFilter and searchFilter ~= "" then
    C_PetJournal.SetSearchFilter(searchFilter)
  else
    C_PetJournal.ClearSearchFilter()
  end

  return sources
end

--------------------------------------------------
-- Pet Expansion statistics
--------------------------------------------------
function PetCollectionStatsService:GetExpansionStats()
  local petJournal = addon.Services.PetJournal

  petJournal:EnsureIndex()

  local collectibleSpecies = GetCollectibleSpecies()
  local petExpansion = addon.Data and addon.Data.PetExpansion

  if not petExpansion then
    return {}
  end

  local expansions = {}

  ------------------------------------------------
  -- Maximum collectible per expansion
  ------------------------------------------------
  for _, species in ipairs(collectibleSpecies) do
    local expansionID =
        petExpansion:GetExpansionID(species.speciesID)

    if expansionID ~= nil then
      local expansion = expansions[expansionID]

      if not expansion then
        expansion = {
          expansionID = expansionID,
          name = petExpansion:GetExpansionNameByID(expansionID) or tostring(expansionID),
          owned = 0,
          maximum = 0,
          missing = 0,
          percentage = 0,
        }

        expansions[expansionID] = expansion
      end

      expansion.maximum = expansion.maximum + 1
    end
  end

  ------------------------------------------------
  -- Unique owned species per expansion
  ------------------------------------------------
  for speciesID in pairs(petJournal.OwnedPetsBySpeciesID or {}) do
    local expansionID = petExpansion:GetExpansionID(speciesID)

    if expansionID ~= nil then
      local expansion = expansions[expansionID]

      if expansion then
        expansion.owned = expansion.owned + 1
      end
    end
  end

  ------------------------------------------------
  -- Derived values
  ------------------------------------------------
  for _, expansion in pairs(expansions) do
    expansion.missing = math.max(0, expansion.maximum - expansion.owned)

    if expansion.maximum > 0 then
      expansion.percentage = (expansion.owned / expansion.maximum) * 100
    end
  end

  return expansions
end

--------------------------------------------------
-- Pet Breed statistics
--------------------------------------------------
function PetCollectionStatsService:GetBreedStats()
  local breedService = addon.Services.Breed

  if not breedService or not breedService:IsAvailable() then
    return {}
  end

  local petJournal = addon.Services.PetJournal

  petJournal:EnsureIndex()

  local breeds = {}

  ------------------------------------------------
  -- Initialize known breeds
  ------------------------------------------------
  for breedID, breedName in pairs(addon.Constants.PET_BREED_NAMES or {}) do
    breeds[breedID] = {
      breedID = breedID,
      name = breedName,
      owned = 0,
      maximum = 0,
      missing = 0,
      percentage = 0,
    }
  end

  ------------------------------------------------
  -- Maximum possible species per breed
  ------------------------------------------------
  local collectibleSpecies = GetCollectibleSpecies()

  for _, species in ipairs(collectibleSpecies) do
    local possibleBreeds =
        breedService:GetPossibleBreeds(species.speciesID)

    for _, possibleBreed in ipairs(possibleBreeds or {}) do
      local breedID = possibleBreed.id
      local breed = breedID and breeds[breedID]

      if breed then
        breed.maximum = breed.maximum + 1
      end
    end
  end

  ------------------------------------------------
  -- Owned species per breed
  ------------------------------------------------
  for speciesID, petGUIDs in pairs(petJournal.OwnedPetsBySpeciesID or {}) do
    local ownedBreeds = {}

    for _, petGUID in ipairs(petGUIDs or {}) do
      local breedID = breedService:GetJournalBreedID(petGUID)

      if breedID then
        ownedBreeds[breedID] = true
      end
    end

    for breedID in pairs(ownedBreeds) do
      local breed = breeds[breedID]

      if breed then
        breed.owned = breed.owned + 1
      end
    end
  end

  ------------------------------------------------
  -- Derived values
  ------------------------------------------------
  for _, breed in pairs(breeds) do
    breed.missing = math.max(0, breed.maximum - breed.owned)

    if breed.maximum > 0 then
      breed.percentage = (breed.owned / breed.maximum) * 100
    end
  end

  return breeds
end

--------------------------------------------------
-- Register
--------------------------------------------------
addon.Services.PetCollectionStats = PetCollectionStatsService
