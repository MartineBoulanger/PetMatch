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
  local ownedPetGUIDs = C_PetJournal.GetOwnedPetIDs()

  if type(ownedPetGUIDs) == "table" then
    for _, petGUID in ipairs(ownedPetGUIDs) do
      local speciesID,
      customName,
      level,
      _xp,
      _maxXP,
      _displayID,
      favorite,
      speciesName,
      icon,
      petType,
      _creatureID,
      _sourceText,
      _description,
      _isWild,
      canBattle =
          C_PetJournal.GetPetInfoByPetID(petGUID)

      if speciesID then
        local quality =
            select(
              5,
              C_PetJournal.GetPetStats(petGUID)
            )

        level = tonumber(level) or 0
        quality = tonumber(quality) or 0

        ----------------------------------------------
        -- Lightweight cached pet data
        ----------------------------------------------
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

        ----------------------------------------------
        -- Keep all owned instances grouped by species
        ----------------------------------------------
        local speciesPets =
            self.OwnedPetsBySpeciesID[speciesID]

        if not speciesPets then
          speciesPets = {}
          self.OwnedPetsBySpeciesID[speciesID] = speciesPets
        end

        speciesPets[#speciesPets + 1] = petGUID

        ----------------------------------------------
        -- Best owned pet for this species
        ----------------------------------------------
        local bestLevel = bestLevels[speciesID]
        local bestQuality = bestQualities[speciesID]

        if IsBetterPet(
              level,
              quality,
              bestLevel,
              bestQuality
            ) then
          self.BestOwnedPetBySpeciesID[speciesID] = petGUID

          bestLevels[speciesID] = level
          bestQualities[speciesID] = quality
        end
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

  local petGUIDs =
      self.OwnedPetsBySpeciesID[
      speciesID
      ]

  if type(petGUIDs) ~= "table"
      or #petGUIDs == 0 then
    return nil
  end

  local breedService =
      addon.Services
      and addon.Services.Breed

  local requestedBreed =
      breedID
      and breedID > 0

  local candidates = {}

  --------------------------------------------------
  -- Normal imported team slots only use
  -- level 25 pets.
  --------------------------------------------------
  for _, petGUID in ipairs(petGUIDs) do
    if not usedPetGUIDs[petGUID] then
      local pet =
          self.Cache[petGUID]

      if pet
          and pet.canBattle ~= false
          and tonumber(pet.level) == 25 then
        local health,
        maxHealth =
            C_PetJournal.GetPetStats(
              petGUID
            )

        health =
            tonumber(health)
            or 0

        maxHealth =
            tonumber(maxHealth)
            or 0

        --------------------------------------------------
        -- Health priority:
        --
        -- 3 = Full health
        -- 2 = Damaged
        -- 1 = Dead
        --------------------------------------------------
        local healthState

        if health <= 0 then
          healthState = 1
        elseif maxHealth > 0
            and health >= maxHealth then
          healthState = 3
        else
          healthState = 2
        end

        --------------------------------------------------
        -- Check requested breed.
        --------------------------------------------------
        local breedMatch = false

        if requestedBreed
            and breedService
            and type(
              breedService.GetJournalBreedID
            ) == "function" then
          local journalBreedID =
              breedService:
              GetJournalBreedID(
                petGUID
              )

          breedMatch =
              journalBreedID ~= nil
              and tonumber(
                journalBreedID
              ) == breedID
        end

        candidates[
        #candidates + 1
        ] = {
          petGUID = petGUID,
          pet = pet,
          healthState = healthState,
          breedMatch = breedMatch,
        }
      end
    end
  end

  --------------------------------------------------
  -- No unused level 25 copy exists.
  --------------------------------------------------
  if #candidates == 0 then
    return nil
  end

  --------------------------------------------------
  -- Find the best available health state.
  --
  -- Full > Damaged > Dead
  --------------------------------------------------
  local bestHealthState = 0

  for _, candidate in ipairs(candidates) do
    if candidate.healthState
        > bestHealthState then
      bestHealthState =
          candidate.healthState
    end
  end

  --------------------------------------------------
  -- Only compare pets from the best available
  -- health state.
  --------------------------------------------------
  local pool = {}

  for _, candidate in ipairs(candidates) do
    if candidate.healthState
        == bestHealthState then
      pool[#pool + 1] =
          candidate
    end
  end

  --------------------------------------------------
  -- Within the best health state, prefer the
  -- requested breed.
  --------------------------------------------------
  if requestedBreed then
    local bestBreedPetGUID = nil
    local bestBreedQuality = -1

    for _, candidate in ipairs(pool) do
      if candidate.breedMatch then
        local quality =
            tonumber(
              candidate.pet.quality
            ) or 0

        if not bestBreedPetGUID
            or quality > bestBreedQuality then
          bestBreedPetGUID =
              candidate.petGUID

          bestBreedQuality =
              quality
        end
      end
    end

    if bestBreedPetGUID then
      return bestBreedPetGUID
    end
  end

  --------------------------------------------------
  -- Requested breed is not available in the best
  -- health state, or no breed was requested.
  --
  -- Use quality as the final tie-breaker.
  --------------------------------------------------
  local bestPetGUID = nil
  local bestQuality = -1

  for _, candidate in ipairs(pool) do
    local quality =
        tonumber(
          candidate.pet.quality
        ) or 0

    if not bestPetGUID
        or quality > bestQuality then
      bestPetGUID =
          candidate.petGUID

      bestQuality =
          quality
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
