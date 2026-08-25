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
  if self:IsLevel25Only() and tonumber(pet.level) ~= 25 then
    return false
  end

  --------------------------------------------------
  -- Active mode
  --------------------------------------------------
  local mode = self:GetMode()
  local selectedTypes = self:GetSelectedTypes(mode)

  if not selectedTypes or next(selectedTypes) == nil then
    return true
  end

  local petType = tonumber(pet.petType)

  if not IsValidPetType(petType) then
    return false
  end

  --------------------------------------------------
  -- Direct pet type
  --------------------------------------------------
  if mode == "petType" then
    return selectedTypes[petType] == true
  end

  --------------------------------------------------
  -- Matchup-based filtering
  --------------------------------------------------
  local matchup = self:GetMatchup(petType)

  if not matchup then
    return false
  end

  local targetType

  if mode == "strongVs" then
    targetType = matchup.strongVs
  elseif mode == "weakVs" then
    targetType = matchup.weakVs
  elseif mode == "takesMoreFrom" then
    targetType = matchup.takesMoreFrom
  elseif mode == "takesLessFrom" then
    targetType = matchup.takesLessFrom
  end

  if not targetType then
    return false
  end

  return selectedTypes[targetType] == true
end

function PetTypeFilterService:DoesPetDataMatch(level, petType)
  --------------------------------------------------
  -- Level 25
  --------------------------------------------------
  if self:IsLevel25Only() and tonumber(level) ~= 25 then
    return false
  end

  --------------------------------------------------
  -- Active mode
  --------------------------------------------------
  local mode = self:GetMode()
  local selectedTypes = self:GetSelectedTypes(mode)

  if not selectedTypes or next(selectedTypes) == nil then
    return true
  end

  petType = tonumber(petType)

  if not IsValidPetType(petType) then
    return false
  end

  --------------------------------------------------
  -- Direct pet type
  --------------------------------------------------
  if mode == "petType" then
    return selectedTypes[petType] == true
  end

  --------------------------------------------------
  -- Matchup
  --------------------------------------------------
  local matchup = MATCHUPS[petType]

  if not matchup then
    return false
  end

  local targetType

  if mode == "strongVs" then
    targetType = matchup.strongVs
  elseif mode == "weakVs" then
    targetType = matchup.weakVs
  elseif mode == "takesMoreFrom" then
    targetType = matchup.takesMoreFrom
  elseif mode == "takesLessFrom" then
    targetType = matchup.takesLessFrom
  end

  if not targetType then
    return false
  end

  return selectedTypes[targetType] == true
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
