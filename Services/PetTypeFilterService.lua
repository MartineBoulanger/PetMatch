local _, addon = ...

local PetTypeFilterService = {}
PetTypeFilterService.Initialized = false

--------------------------------------------------
-- Pet types
--------------------------------------------------
local PET_TYPES = {
  HUMANOID   = 1,
  DRAGONKIN  = 2,
  FLYING     = 3,
  UNDEAD     = 4,
  CRITTER    = 5,
  MAGIC      = 6,
  ELEMENTAL  = 7,
  BEAST      = 8,
  AQUATIC    = 9,
  MECHANICAL = 10,
}

--------------------------------------------------
-- Modes
--------------------------------------------------
local DEFAULT_MODE = "petType"

local VALID_MODES = {
  petType = true,
  strongVs = true,
  weakVs = true,
  takesMoreFrom = true,
  takesLessFrom = true,
}

--------------------------------------------------
-- Matchup data
--------------------------------------------------
local MATCHUPS = {
  [PET_TYPES.BEAST] = {
    strongVs = PET_TYPES.CRITTER,
    weakVs = PET_TYPES.FLYING,
    takesMoreFrom = PET_TYPES.MECHANICAL,
    takesLessFrom = PET_TYPES.HUMANOID,
  },

  [PET_TYPES.MECHANICAL] = {
    strongVs = PET_TYPES.BEAST,
    weakVs = PET_TYPES.ELEMENTAL,
    takesMoreFrom = PET_TYPES.ELEMENTAL,
    takesLessFrom = PET_TYPES.MAGIC,
  },

  [PET_TYPES.FLYING] = {
    strongVs = PET_TYPES.AQUATIC,
    weakVs = PET_TYPES.DRAGONKIN,
    takesMoreFrom = PET_TYPES.MAGIC,
    takesLessFrom = PET_TYPES.BEAST,
  },

  [PET_TYPES.DRAGONKIN] = {
    strongVs = PET_TYPES.MAGIC,
    weakVs = PET_TYPES.UNDEAD,
    takesMoreFrom = PET_TYPES.HUMANOID,
    takesLessFrom = PET_TYPES.FLYING,
  },

  [PET_TYPES.AQUATIC] = {
    strongVs = PET_TYPES.ELEMENTAL,
    weakVs = PET_TYPES.MAGIC,
    takesMoreFrom = PET_TYPES.FLYING,
    takesLessFrom = PET_TYPES.UNDEAD,
  },

  [PET_TYPES.CRITTER] = {
    strongVs = PET_TYPES.UNDEAD,
    weakVs = PET_TYPES.HUMANOID,
    takesMoreFrom = PET_TYPES.BEAST,
    takesLessFrom = PET_TYPES.ELEMENTAL,
  },

  [PET_TYPES.HUMANOID] = {
    strongVs = PET_TYPES.DRAGONKIN,
    weakVs = PET_TYPES.BEAST,
    takesMoreFrom = PET_TYPES.UNDEAD,
    takesLessFrom = PET_TYPES.CRITTER,
  },

  [PET_TYPES.MAGIC] = {
    strongVs = PET_TYPES.FLYING,
    weakVs = PET_TYPES.MECHANICAL,
    takesMoreFrom = PET_TYPES.DRAGONKIN,
    takesLessFrom = PET_TYPES.AQUATIC,
  },

  [PET_TYPES.ELEMENTAL] = {
    strongVs = PET_TYPES.MECHANICAL,
    weakVs = PET_TYPES.CRITTER,
    takesMoreFrom = PET_TYPES.AQUATIC,
    takesLessFrom = PET_TYPES.MECHANICAL,
  },

  [PET_TYPES.UNDEAD] = {
    strongVs = PET_TYPES.HUMANOID,
    weakVs = PET_TYPES.AQUATIC,
    takesMoreFrom = PET_TYPES.CRITTER,
    takesLessFrom = PET_TYPES.DRAGONKIN,
  },
}

--------------------------------------------------
-- State
--------------------------------------------------
PetTypeFilterService.Mode = DEFAULT_MODE
PetTypeFilterService.Level25Only = false

PetTypeFilterService.SelectedTypes = {
  petType = {},
  strongVs = {},
  weakVs = {},
  takesMoreFrom = {},
  takesLessFrom = {},
}

--------------------------------------------------
-- Helpers
--------------------------------------------------
local function IsValidMode(mode)
  return VALID_MODES[mode] == true
end

local function IsValidPetType(petType)
  petType = tonumber(petType)
  return petType and petType >= 1 and petType <= 10
end

local function GetAbilityData(speciesID, level)
  speciesID = tonumber(speciesID)
  level = tonumber(level) or 0

  if not speciesID then
    return {}, {}
  end

  local abilityIDs = {}
  local abilityLevels = {}

  C_PetJournal.GetPetAbilityList(
    speciesID,
    abilityIDs,
    abilityLevels
  )

  local abilityTypes = {}
  local abilitiesByType = {}

  for index, abilityID in ipairs(abilityIDs) do
    local requiredLevel =
        tonumber(
          abilityLevels[index]
        ) or 1

    local abilityAvailable =
        level == 0 or level >= requiredLevel

    if abilityAvailable then
      local _, _, abilityType =
          C_PetJournal.GetPetAbilityInfo(
            abilityID
          )

      abilityType = tonumber(abilityType)

      if IsValidPetType(abilityType) then
        abilityTypes[abilityType] = true

        abilitiesByType[abilityType] =
            abilitiesByType[abilityType] or {}

        abilitiesByType[abilityType][abilityID] = true
      end
    end
  end

  return abilityTypes, abilitiesByType
end

--------------------------------------------------
-- Mode
--------------------------------------------------
function PetTypeFilterService:SetMode(mode)
  if not IsValidMode(mode) then
    return false
  end

  if self.Mode == mode then
    return true
  end

  self.Mode = mode

  return true
end

function PetTypeFilterService:GetMode()
  return self.Mode or DEFAULT_MODE
end

--------------------------------------------------
-- Level 25
--------------------------------------------------
function PetTypeFilterService:SetLevel25Only(enabled)
  self.Level25Only = enabled == true
end

function PetTypeFilterService:ToggleLevel25Only()
  self.Level25Only = not self.Level25Only
  return self.Level25Only
end

function PetTypeFilterService:IsLevel25Only()
  return self.Level25Only == true
end

--------------------------------------------------
-- Selected types
--------------------------------------------------
function PetTypeFilterService:GetSelectedTypes(mode)
  mode = mode or self:GetMode()

  if not IsValidMode(mode) then
    return nil
  end

  return self.SelectedTypes[mode]
end

function PetTypeFilterService:IsTypeSelected(petType, mode)
  petType = tonumber(petType)

  if not IsValidPetType(petType) then
    return false
  end

  local selected = self:GetSelectedTypes(mode)

  if not selected then
    return false
  end

  return selected[petType] == true
end

function PetTypeFilterService:SetTypeSelected(petType, selected, mode)
  petType = tonumber(petType)

  if not IsValidPetType(petType) then
    return false
  end

  local selectedTypes = self:GetSelectedTypes(mode)

  if not selectedTypes then
    return false
  end

  if selected == true then
    selectedTypes[petType] = true
  else
    selectedTypes[petType] = nil
  end

  return true
end

function PetTypeFilterService:ToggleType(petType, mode)
  petType = tonumber(petType)

  if not IsValidPetType(petType) then
    return false
  end

  mode = mode or self:GetMode()

  local currentlySelected =
      self:IsTypeSelected(
        petType,
        mode
      )

  return self:SetTypeSelected(
    petType,
    not currentlySelected,
    mode
  )
end

--------------------------------------------------
-- Clear
--------------------------------------------------
function PetTypeFilterService:ClearMode(mode)
  mode = mode or self:GetMode()

  local selected = self:GetSelectedTypes(mode)

  if not selected then
    return false
  end

  wipe(selected)

  return true
end

function PetTypeFilterService:ClearAll()
  self.Level25Only = false
  self.Mode = DEFAULT_MODE

  for mode in pairs(
    VALID_MODES
  ) do
    wipe(
      self.SelectedTypes[mode]
    )
  end
end

--------------------------------------------------
-- State checks
--------------------------------------------------
function PetTypeFilterService:HasSelectedTypes(mode)
  local selected = self:GetSelectedTypes(mode)
  return selected and next(selected) ~= nil or false
end

function PetTypeFilterService:HasAnyActiveFilter()
  if self:IsLevel25Only() then
    return true
  end

  for mode in pairs(VALID_MODES) do
    if self:HasSelectedTypes(mode) then
      return true
    end
  end

  return false
end

--------------------------------------------------
-- Matchup
--------------------------------------------------
function PetTypeFilterService:GetMatchup(petType)
  petType = tonumber(petType)

  if not IsValidPetType(petType) then
    return nil
  end

  return MATCHUPS[petType]
end

--------------------------------------------------
-- Matching
--------------------------------------------------
function PetTypeFilterService:DoesPetMatch(pet)
  if type(pet) ~= "table" then
    return false
  end

  --------------------------------------------------
  -- Level 25
  --------------------------------------------------
  if self:IsLevel25Only()
      and tonumber(pet.level) ~= 25 then
    return false
  end

  --------------------------------------------------
  -- Pet type
  --------------------------------------------------
  local petType = tonumber(pet.petType)

  if not IsValidPetType(petType) then
    return false
  end

  --------------------------------------------------
  -- Direct pet type filter
  --------------------------------------------------
  local petTypeFilter =
      self:GetSelectedTypes(
        "petType"
      )

  if petTypeFilter
      and next(petTypeFilter) ~= nil
      and petTypeFilter[petType] ~= true then
    return false
  end

  --------------------------------------------------
  -- Matchup data
  --------------------------------------------------
  local matchup = self:GetMatchup(petType)

  if not matchup then
    return false
  end

  --------------------------------------------------
  -- Strong Vs
  --------------------------------------------------
  local strongVs =
      self:GetSelectedTypes(
        "strongVs"
      )

  if strongVs
      and next(strongVs) ~= nil
      and strongVs[
      matchup.strongVs
      ] ~= true then
    return false
  end

  --------------------------------------------------
  -- Weak Vs
  --------------------------------------------------
  local weakVs =
      self:GetSelectedTypes(
        "weakVs"
      )

  if weakVs
      and next(weakVs) ~= nil
      and weakVs[
      matchup.weakVs
      ] ~= true then
    return false
  end

  --------------------------------------------------
  -- Takes More From
  --------------------------------------------------
  local takesMoreFrom =
      self:GetSelectedTypes(
        "takesMoreFrom"
      )

  if takesMoreFrom
      and next(takesMoreFrom) ~= nil
      and takesMoreFrom[
      matchup.takesMoreFrom
      ] ~= true then
    return false
  end

  --------------------------------------------------
  -- Takes Less From
  --------------------------------------------------
  local takesLessFrom =
      self:GetSelectedTypes(
        "takesLessFrom"
      )

  if takesLessFrom
      and next(takesLessFrom) ~= nil
      and takesLessFrom[
      matchup.takesLessFrom
      ] ~= true then
    return false
  end

  return true
end

function PetTypeFilterService:DoesPetDataMatch(level, petType, speciesID)
  --------------------------------------------------
  -- Level 25
  --------------------------------------------------
  if self:IsLevel25Only()
      and tonumber(level) ~= 25 then
    return false
  end

  --------------------------------------------------
  -- Pet type
  --------------------------------------------------
  petType = tonumber(petType)

  if not IsValidPetType(petType) then
    return false
  end

  local abilityTypes, abilitiesByType =
      GetAbilityData(
        speciesID,
        level
      )


  --------------------------------------------------
  -- Direct pet type filter
  --------------------------------------------------
  local petTypeFilter =
      self:GetSelectedTypes(
        "petType"
      )

  if petTypeFilter
      and next(petTypeFilter) ~= nil
      and petTypeFilter[petType] ~= true then
    return false
  end

  --------------------------------------------------
  -- Matchup data
  --------------------------------------------------
  local matchup = self:GetMatchup(petType)

  if not matchup then
    return false
  end

  --------------------------------------------------
  -- Strong Vs
  --------------------------------------------------
  local strongVs =
      self:GetSelectedTypes(
        "strongVs"
      )

  if strongVs and next(strongVs) ~= nil then
    local matchesStrongVs = false

    for abilityType in pairs(abilityTypes) do
      local abilityMatchup =
          self:GetMatchup(
            abilityType
          )

      if abilityMatchup
          and strongVs[abilityMatchup.strongVs] == true then
        matchesStrongVs = true
      end
    end

    if not matchesStrongVs then
      return false
    end
  end

  --------------------------------------------------
  -- Weak Vs
  --------------------------------------------------
  local weakVs =
      self:GetSelectedTypes(
        "weakVs"
      )

  if weakVs and next(weakVs) ~= nil then
    local matchesWeakVs = false

    for abilityType in pairs(abilityTypes) do
      local abilityMatchup =
          self:GetMatchup(
            abilityType
          )

      if abilityMatchup
          and weakVs[abilityMatchup.weakVs] == true then
        matchesWeakVs = true
      end
    end

    if not matchesWeakVs then
      return false
    end
  end

  --------------------------------------------------
  -- Takes More From
  --------------------------------------------------
  local takesMoreFrom =
      self:GetSelectedTypes(
        "takesMoreFrom"
      )

  if takesMoreFrom
      and next(takesMoreFrom) ~= nil
      and takesMoreFrom[
      matchup.takesMoreFrom
      ] ~= true then
    return false
  end

  --------------------------------------------------
  -- Takes Less From
  --------------------------------------------------
  local takesLessFrom =
      self:GetSelectedTypes(
        "takesLessFrom"
      )

  if takesLessFrom
      and next(takesLessFrom) ~= nil
      and takesLessFrom[
      matchup.takesLessFrom
      ] ~= true then
    return false
  end

  return true
end

function PetTypeFilterService:GetMatchedAbilities(
    speciesID,
    level
)
  speciesID = tonumber(speciesID)
  level = tonumber(level) or 0

  if not speciesID then
    return {}
  end

  local abilityTypes,
  abilitiesByType =
      GetAbilityData(
        speciesID,
        level
      )

  local matchedAbilities = {}

  --------------------------------------------------
  -- Strong Vs
  --------------------------------------------------

  local strongVs =
      self:GetSelectedTypes(
        "strongVs"
      )

  if strongVs
      and next(strongVs) ~= nil then
    for abilityType in pairs(
      abilityTypes
    ) do
      local matchup =
          self:GetMatchup(
            abilityType
          )

      if matchup
          and strongVs[
          matchup.strongVs
          ] == true then
        local abilities =
            abilitiesByType[
            abilityType
            ]

        if abilities then
          for abilityID in pairs(
            abilities
          ) do
            matchedAbilities[
            abilityID
            ] = true
          end
        end
      end
    end
  end

  --------------------------------------------------
  -- Weak Vs
  --------------------------------------------------

  local weakVs =
      self:GetSelectedTypes(
        "weakVs"
      )

  if weakVs
      and next(weakVs) ~= nil then
    for abilityType in pairs(
      abilityTypes
    ) do
      local matchup =
          self:GetMatchup(
            abilityType
          )

      if matchup
          and weakVs[
          matchup.weakVs
          ] == true then
        local abilities =
            abilitiesByType[
            abilityType
            ]

        if abilities then
          for abilityID in pairs(
            abilities
          ) do
            matchedAbilities[
            abilityID
            ] = true
          end
        end
      end
    end
  end

  return matchedAbilities
end

--------------------------------------------------
-- Expose static data
--------------------------------------------------
function PetTypeFilterService:GetPetTypes()
  return PET_TYPES
end

function PetTypeFilterService:GetValidModes()
  return VALID_MODES
end

--------------------------------------------------
-- Register
--------------------------------------------------
addon.Services.PetTypeFilter = PetTypeFilterService
