local _, addon = ...

addon.Services = addon.Services or {}

local BreedTooltipService = {}

local BREED_NAMES = {
  [3] = "B/B",
  [4] = "P/P",
  [5] = "S/S",
  [6] = "H/H",
  [7] = "H/P",
  [8] = "P/S",
  [9] = "H/S",
  [10] = "P/B",
  [11] = "S/B",
  [12] = "H/B",
}

local ALL_BREED_COUNT = 10

-- BattlePetBreedID toont level-25-stats standaard
-- als Rare kwaliteit.
local DEFAULT_LEVEL_25_QUALITY = 4

local function IsValidBreedID(breedID)
  return type(breedID) == "number"
      and BREED_NAMES[breedID] ~= nil
end

local function GetBreedName(breedID)
  return BREED_NAMES[breedID]
      or tostring(breedID or "Unknown")
end

local function InitializeArrays()
  if type(BPBID_Arrays) ~= "table" then
    return nil
  end

  if not BPBID_Arrays.BasePetStats
      and type(BPBID_Arrays.InitializeArrays)
      == "function" then
    BPBID_Arrays.InitializeArrays()
  end

  return BPBID_Arrays
end

local function GetCurrentBreedID(pet)
  if not pet then
    return nil
  end

  local petBreedID = tonumber(pet.breedID)

  if IsValidBreedID(petBreedID) then
    return petBreedID
  end

  local breedService = addon.Services.Breed

  if not breedService
      or not pet.petGUID
      or type(breedService.GetJournalBreed)
      ~= "function" then
    return nil
  end

  local breedID =
      tonumber(
        breedService:GetJournalBreed(
          pet.petGUID
        )
      )

  if not IsValidBreedID(breedID) then
    return nil
  end

  return breedID
end

local function GetPossibleBreedIDs(
    arrays,
    speciesID
)
  if not arrays
      or not arrays.BreedsPerSpecies
      or not speciesID then
    return {}
  end

  local source =
      arrays.BreedsPerSpecies[speciesID]

  if type(source) ~= "table" then
    return {}
  end

  local result = {}

  for _, breedID in ipairs(source) do
    if IsValidBreedID(breedID) then
      result[#result + 1] = breedID
    end
  end

  return result
end

local function GetSpeciesBaseStats(
    arrays,
    speciesID
)
  if not arrays
      or not arrays.BasePetStats
      or not speciesID then
    return nil
  end

  local stats =
      arrays.BasePetStats[speciesID]

  if type(stats) ~= "table" then
    return nil
  end

  return {
    health = stats[1],
    power = stats[2],
    speed = stats[3],
  }
end

local function GetBreedBaseStats(
    arrays,
    speciesID,
    breedID
)
  if not arrays
      or not arrays.BasePetStats
      or not arrays.BreedStats then
    return nil
  end

  local speciesStats =
      arrays.BasePetStats[speciesID]

  local breedStats =
      arrays.BreedStats[breedID]

  if type(speciesStats) ~= "table"
      or type(breedStats) ~= "table" then
    return nil
  end

  return {
    health =
        speciesStats[1]
        + breedStats[1],

    power =
        speciesStats[2]
        + breedStats[2],

    speed =
        speciesStats[3]
        + breedStats[3],
  }
end

local function GetLevel25Stats(
    arrays,
    speciesID,
    breedID,
    quality
)
  if not arrays
      or not arrays.RealRarityValues then
    return nil
  end

  local baseStats =
      GetBreedBaseStats(
        arrays,
        speciesID,
        breedID
      )

  if not baseStats then
    return nil
  end

  quality =
      tonumber(quality)
      or DEFAULT_LEVEL_25_QUALITY

  local rarityValue =
      arrays.RealRarityValues[quality]

  if not rarityValue then
    rarityValue =
        arrays.RealRarityValues[
        DEFAULT_LEVEL_25_QUALITY
        ]
  end

  if not rarityValue then
    return nil
  end

  local multiplier =
      ((rarityValue - 0.5) * 2) + 1

  return {
    health = math.ceil(
      baseStats.health
      * 25
      * multiplier
      * 5
      + 100
      - 0.5
    ),

    power = math.ceil(
      baseStats.power
      * 25
      * multiplier
      - 0.5
    ),

    speed = math.ceil(
      baseStats.speed
      * 25
      * multiplier
      - 0.5
    ),
  }
end

local function GetCollectedPets(speciesID)
  if not speciesID then
    return {}
  end

  local collected = {}

  local searchFilter =
      C_PetJournal.GetSearchFilter()

  local hadSearchFilter =
      searchFilter
      and searchFilter ~= ""

  if hadSearchFilter then
    C_PetJournal.ClearSearchFilter()
  end

  local numPets =
      C_PetJournal.GetNumPets()

  for index = 1, numPets do
    local petID,
    petSpeciesID,
    owned,
    _,
    level =
        C_PetJournal.GetPetInfoByIndex(
          index
        )

    if owned
        and petID
        and petSpeciesID == speciesID then
      local _, _, _, _, quality =
          C_PetJournal.GetPetStats(
            petID
          )

      local breedID

      if type(GetBreedID_Journal)
          == "function" then
        local success, result =
            pcall(
              GetBreedID_Journal,
              petID
            )

        if success then
          breedID = tonumber(result)
        end
      end

      if IsValidBreedID(breedID) then
        local breedName =
            GetBreedName(breedID)

        local text =
            string.format(
              "L%d (%s)",
              level or 0,
              breedName
            )

        local qualityColor =
            ITEM_QUALITY_COLORS[
            math.max(
              0,
              (quality or 1) - 1
            )
            ]

        if qualityColor
            and qualityColor.hex then
          text =
              qualityColor.hex
              .. text
              .. "|r"
        end

        collected[#collected + 1] = {
          petGUID = petID,
          level = level or 0,
          quality = quality or 1,
          breedID = breedID,
          breedName = breedName,
          text = text,
        }
      end
    end
  end

  if hadSearchFilter then
    C_PetJournal.SetSearchFilter(
      searchFilter
    )
  end

  table.sort(
    collected,
    function(left, right)
      if left.level ~= right.level then
        return left.level > right.level
      end

      if left.quality ~= right.quality then
        return left.quality > right.quality
      end

      return left.breedID < right.breedID
    end
  )

  return collected
end

function BreedTooltipService:IsAvailable()
  local arrays = InitializeArrays()

  return arrays ~= nil
      and arrays.BasePetStats ~= nil
      and arrays.BreedStats ~= nil
      and arrays.BreedsPerSpecies ~= nil
end

function BreedTooltipService:GetDetails(pet)
  if not pet or not pet.speciesID then
    return nil
  end

  local arrays = InitializeArrays()

  if not arrays then
    return nil
  end

  local currentBreedID =
      GetCurrentBreedID(pet)

  local possibleBreedIDs =
      GetPossibleBreedIDs(
        arrays,
        pet.speciesID
      )

  local breedBaseStats = {}
  local level25Stats = {}

  for _, breedID
  in ipairs(possibleBreedIDs) do
    breedBaseStats[#breedBaseStats + 1] = {
      breedID = breedID,
      breedName = GetBreedName(breedID),

      isCurrent =
          currentBreedID == breedID,

      stats =
          GetBreedBaseStats(
            arrays,
            pet.speciesID,
            breedID
          ),
    }

    level25Stats[#level25Stats + 1] = {
      breedID = breedID,
      breedName = GetBreedName(breedID),

      isCurrent =
          currentBreedID == breedID,

      stats =
          GetLevel25Stats(
            arrays,
            pet.speciesID,
            breedID,
            DEFAULT_LEVEL_25_QUALITY
          ),
    }
  end

  return {
    currentBreedID = currentBreedID,

    currentBreedName =
        currentBreedID
        and GetBreedName(currentBreedID)
        or nil,

    possibleBreedIDs =
        possibleBreedIDs,

    allBreedsPossible =
        #possibleBreedIDs
        == ALL_BREED_COUNT,

    speciesBaseStats =
        GetSpeciesBaseStats(
          arrays,
          pet.speciesID
        ),

    collected =
        GetCollectedPets(
          pet.speciesID
        ),

    breedBaseStats =
        breedBaseStats,

    level25Stats =
        level25Stats,

    level25Quality =
        DEFAULT_LEVEL_25_QUALITY,
  }
end

addon.Services.BreedTooltip =
    BreedTooltipService
