local _, addon = ...

local PetJournalService = {}

PetJournalService.Cache = {}
PetJournalService.BestOwnedPetBySpeciesID = {}
PetJournalService.OwnedPetsBySpeciesID = {}

PetJournalService.IndexReady = false
PetJournalService.Initialized = false

PetJournalService.ScanTimer = nil

local SCAN_DELAY = 0.35

--------------------------------------------------
-- Helpers
--------------------------------------------------
local function IsBetterPet(level, quality, bestLevel, bestQuality)
  level = tonumber(level) or 0
  quality = tonumber(quality) or 0
  bestLevel = tonumber(bestLevel) or -1
  bestQuality = tonumber(bestQuality) or -1

  return level > bestLevel
      or (
        level == bestLevel
        and quality > bestQuality
      )
end

--------------------------------------------------
-- Scheduled scan
--------------------------------------------------
function PetJournalService:CancelScheduledScan()
  if not self.ScanTimer then
    return
  end

  self.ScanTimer:Cancel()
  self.ScanTimer = nil
end

function PetJournalService:ScheduleScan()
  self:CancelScheduledScan()

  self.IndexReady = false

  self.ScanTimer =
      C_Timer.NewTimer(
        SCAN_DELAY,

        function()
          self.ScanTimer = nil

          self:Scan()
        end
      )
end

--------------------------------------------------
-- Scan
--------------------------------------------------
function PetJournalService:Scan()
  self:CancelScheduledScan()

  wipe(self.Cache)
  wipe(self.BestOwnedPetBySpeciesID)
  wipe(self.OwnedPetsBySpeciesID)

  local bestLevels = {}
  local bestQualities = {}
  local numPets = C_PetJournal.GetNumPets()

  for index = 1, numPets do
    local petGUID,
    speciesID,
    isOwned,
    customName,
    level,
    favorite,
    _isRevoked,
    speciesName,
    icon,
    petType,
    _creatureID,
    _sourceText,
    _description,
    _isHatchable,
    canBattle = C_PetJournal.GetPetInfoByIndex(index)

    if isOwned and petGUID and speciesID then
      local quality =
          select(
            5,
            C_PetJournal.GetPetStats(petGUID)
          )

      level = tonumber(level) or 0
      quality = tonumber(quality) or 0

      ------------------------------------------------
      -- Lightweight cached pet data
      ------------------------------------------------
      local pet = {
        petGUID = petGUID,
        speciesID = speciesID,
        name = customName or speciesName,
        level = level,
        quality = quality,
        favorite = favorite == true,
        icon = icon,
        petType = petType,
        canBattle = canBattle == true,
      }

      self.Cache[petGUID] = pet

      ------------------------------------------------
      -- Keep all owned instances grouped by species
      ------------------------------------------------
      local speciesPets = self.OwnedPetsBySpeciesID[speciesID]

      if not speciesPets then
        speciesPets = {}
        self.OwnedPetsBySpeciesID[speciesID] = speciesPets
      end

      speciesPets[#speciesPets + 1] = petGUID

      ------------------------------------------------
      -- Best owned pet for this species
      ------------------------------------------------
      local bestLevel = bestLevels[speciesID]
      local bestQuality = bestQualities[speciesID]

      if IsBetterPet(level, quality, bestLevel, bestQuality) then
        self.BestOwnedPetBySpeciesID[speciesID] = petGUID
        bestLevels[speciesID] = level
        bestQualities[speciesID] = quality
      end
    end
  end

  self.IndexReady = true

  addon.EventBus:Fire(
    addon.Events.PET_JOURNAL_UPDATED,
    self.Cache
  )
end

--------------------------------------------------
-- Index
--------------------------------------------------
function PetJournalService:EnsureIndex()
  if self.IndexReady then
    return
  end

  self:Scan()
end

function PetJournalService:InvalidateCache()
  self.IndexReady = false
  wipe(self.BestOwnedPetBySpeciesID)
  wipe(self.OwnedPetsBySpeciesID)
end

--------------------------------------------------
-- Pet access
--------------------------------------------------
function PetJournalService:GetPet(petGUID)
  if type(petGUID) ~= "string" or petGUID == "" then
    return nil
  end

  local speciesID,
  customName,
  level,
  xp,
  maxXP,
  displayID,
  favorite,
  speciesName,
  icon,
  petType,
  creatureID,
  sourceText,
  description,
  isWild,
  canBattle,
  tradable,
  unique,
  obtainable = C_PetJournal.GetPetInfoByPetID(petGUID)

  if not speciesID then
    return nil
  end

  local quality =
      select(
        5,
        C_PetJournal.GetPetStats(petGUID)
      )

  quality = tonumber(quality) or 0

  return {
    guid = petGUID,
    petGUID = petGUID,
    speciesID = speciesID,
    customName = customName,
    speciesName = speciesName,
    name = customName or speciesName or "Unknown",
    level = level or 0,
    xp = xp or 0,
    maxXP = maxXP or 0,
    displayID = displayID,
    favorite = favorite == true,
    icon = icon,
    petType = petType,
    quality = quality,
    creatureID = creatureID,
    sourceText = sourceText,
    description = description,
    isWild = isWild == true,
    canBattle = canBattle == true,
    tradable = tradable == true,
    unique = unique == true,
    obtainable = obtainable ~= false,
  }
end

function PetJournalService:GetAll()
  return self.Cache
end

function PetJournalService:GetPetName(petGUID)
  local pet = self:GetPet(petGUID)

  return pet and pet.name or nil
end

function PetJournalService:FindOwnedPetBySpeciesID(speciesID)
  speciesID = tonumber(speciesID)

  if not speciesID then
    return nil
  end

  self:EnsureIndex()

  return self.BestOwnedPetBySpeciesID[speciesID]
end

function PetJournalService:FindOwnedPetForImport(speciesID, breedID, usedPetGUIDs)
  speciesID = tonumber(speciesID)
  breedID = tonumber(breedID)

  if not speciesID then
    return nil
  end

  self:EnsureIndex()

  usedPetGUIDs = usedPetGUIDs or {}

  local candidates = self.OwnedPetsBySpeciesID[speciesID]

  if type(candidates) ~= "table" or #candidates == 0 then
    return nil
  end

  local breedService = addon.Services and addon.Services.Breed

  local exactBreedCandidates = {}
  local fallbackCandidates = {}

  --------------------------------------------------
  -- Split available pets into:
  --
  -- 1. Exact requested breed
  -- 2. Same species, another breed
  --------------------------------------------------
  for _, petGUID in ipairs(candidates) do
    if not usedPetGUIDs[petGUID] then
      local pet = self.Cache[petGUID]

      if pet then
        local breedMatch = false

        if not breedID or breedID == 0 then
          breedMatch = true
        elseif breedService
            and type(
              breedService.GetJournalBreedID
            ) == "function" then
          local journalBreedID =
              breedService:GetJournalBreedID(petGUID)

          breedMatch =
              journalBreedID ~= nil
              and tonumber(
                journalBreedID
              ) == breedID
        end

        local candidate = {
          petGUID = petGUID,
          pet = pet,
        }

        if breedMatch then
          exactBreedCandidates[
          #exactBreedCandidates + 1
          ] = candidate
        else
          fallbackCandidates[
          #fallbackCandidates + 1
          ] = candidate
        end
      end
    end
  end

  --------------------------------------------------
  -- Prefer the exact breed.
  --
  -- If that breed is not owned, use another
  -- available copy of the exact same species.
  --------------------------------------------------
  local pool

  if #exactBreedCandidates > 0 then
    pool = exactBreedCandidates
  else
    pool = fallbackCandidates
  end

  if #pool == 0 then
    return nil
  end

  --------------------------------------------------
  -- Within the chosen pool:
  -- highest level, then highest quality
  --------------------------------------------------
  local bestPetGUID = nil
  local bestLevel = -1
  local bestQuality = -1

  for _, candidate in ipairs(pool) do
    local pet = candidate.pet

    local level = tonumber(pet.level) or 0
    local quality = tonumber(pet.quality) or 0

    if level > bestLevel
        or (level == bestLevel
          and quality > bestQuality
        ) then
      bestPetGUID = candidate.petGUID

      bestLevel = level
      bestQuality = quality
    end
  end

  return bestPetGUID
end

function PetJournalService:GetSpeciesID(petGUID)
  local pet = self:GetPet(petGUID)

  return pet and pet.speciesID or nil
end

--------------------------------------------------
-- Ability choices
--------------------------------------------------
function PetJournalService:GetAbilityChoices(speciesID, selectedAbilities)
  speciesID = tonumber(speciesID)

  if not speciesID then
    return nil, "Invalid species ID"
  end

  local abilityIDs = {}
  local abilityLevels = {}

  C_PetJournal.GetPetAbilityList(
    speciesID,
    abilityIDs,
    abilityLevels
  )

  local choices = {}

  for slot = 1, 3 do
    local selectedAbilityID =
        selectedAbilities and selectedAbilities[slot]

    local firstChoiceID = abilityIDs[slot]
    local secondChoiceID = abilityIDs[slot + 3]

    if selectedAbilityID
        and selectedAbilityID == secondChoiceID then
      choices[slot] = 2
    else
      choices[slot] = 1
    end
  end

  return choices
end

--------------------------------------------------
-- Initialize
--------------------------------------------------
function PetJournalService:Initialize()
  if self.Initialized then
    return
  end

  self.Initialized = true

  self.EventFrame =
      self.EventFrame
      or CreateFrame(
        "Frame"
      )

  self.EventFrame:RegisterEvent(
    "PET_JOURNAL_LIST_UPDATE"
  )

  self.EventFrame:SetScript(
    "OnEvent",

    function(_, event)
      if event ~= "PET_JOURNAL_LIST_UPDATE" then
        return
      end
      self:ScheduleScan()
    end
  )

  self:ScheduleScan()
end

addon.Services.PetJournal = PetJournalService
