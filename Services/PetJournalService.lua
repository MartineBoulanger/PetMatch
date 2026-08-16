local _, addon                            = ...

local PetJournalService                   = {}

PetJournalService.Cache                   = {}
PetJournalService.BestOwnedPetBySpeciesID = {}
PetJournalService.IndexReady              = false
PetJournalService.Initialized             = false
PetJournalService.ScanScheduled           = false

local function IsBetterPet(
    level,
    quality,
    bestLevel,
    bestQuality
)
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

function PetJournalService:Scan()
  wipe(self.Cache)
  wipe(self.BestOwnedPetBySpeciesID)

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
    isRevoked,
    speciesName,
    icon,
    petType,
    creatureID,
    sourceText,
    description,
    isHatchable,
    canBattle,
    tradable,
    unique = C_PetJournal.GetPetInfoByIndex(index)

    if isOwned and petGUID and speciesID then
      local _, _, _, _, quality = C_PetJournal.GetPetStats(petGUID)
      level = tonumber(level) or 0
      quality = tonumber(quality) or 0

      local pet = {
        petGUID = petGUID,
        speciesID = speciesID,
        name = customName or speciesName,
        level = level,
        favorite = favorite,
        icon = icon,
        petType = petType,
        canBattle = canBattle == true,
      }

      self.Cache[petGUID] = pet

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

function PetJournalService:EnsureIndex()
  if self.IndexReady then
    return
  end

  self:Scan()
end

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

function PetJournalService:InvalidateCache()
  self.IndexReady = false
  wipe(self.BestOwnedPetBySpeciesID)
end

function PetJournalService:ScheduleScan()
  if self.ScanScheduled then
    return
  end

  self.ScanScheduled = true

  C_Timer.After(
    0,
    function()
      self.ScanScheduled = false
      self:InvalidateCache()
      self:Scan()
    end
  )
end

function PetJournalService:Initialize()
  if self.Initialized then
    return
  end

  self.Initialized = true

  self.EventFrame =
      self.EventFrame
      or CreateFrame("Frame")

  self.EventFrame:RegisterEvent(
    "PET_JOURNAL_LIST_UPDATE"
  )

  self.EventFrame:SetScript(
    "OnEvent",
    function(_, event)
      if event
          ~= "PET_JOURNAL_LIST_UPDATE" then
        return
      end

      self:ScheduleScan()
    end
  )

  --------------------------------------------------
  -- Initial scan.
  --
  -- This establishes the initial known-pet baseline
  -- for the Levelling Queue.
  --------------------------------------------------

  self:ScheduleScan()
end

function PetJournalService:GetSpeciesID(petGUID)
  local pet = self:GetPet(petGUID)
  return pet and pet.speciesID or nil
end

function PetJournalService:GetAbilityChoices(
    speciesID,
    selectedAbilities
)
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
        selectedAbilities
        and selectedAbilities[slot]

    local firstChoiceID =
        abilityIDs[slot]

    local secondChoiceID =
        abilityIDs[slot + 3]

    if selectedAbilityID
        and selectedAbilityID == secondChoiceID then
      choices[slot] = 2
    else
      choices[slot] = 1
    end
  end

  return choices
end

addon.Services.PetJournal = PetJournalService
