local addonName, addon = ...

local PetJournalService = {}

PetJournalService.Cache = {}

function PetJournalService:Scan()
  wipe(self.Cache)
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
    if isOwned then
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
    end
  end
  addon.Logger:Info(
    "Pet Journal scanned:",
    numPets
  )
  addon.EventBus:Fire(
    addon.Events.PET_JOURNAL_UPDATED,
    self.Cache
  )
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
    speciesID = speciesID,
    customName = customName,
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

  local petCount = C_PetJournal.GetNumPets()
  local bestPetGUID = nil
  local bestLevel = -1
  local bestQuality = -1

  for index = 1, petCount do
    local petGUID,
    currentSpeciesID,
    owned,
    customName,
    level = C_PetJournal.GetPetInfoByIndex(index)

    if owned and petGUID and currentSpeciesID == speciesID then
      local _, _, _, _, quality = C_PetJournal.GetPetStats(petGUID)

      level = level or 0
      quality = quality or 0

      if level > bestLevel or (level == bestLevel and quality > bestQuality) then
        bestPetGUID = petGUID
        bestLevel = level
        bestQuality = quality
      end
    end
  end

  return bestPetGUID
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
