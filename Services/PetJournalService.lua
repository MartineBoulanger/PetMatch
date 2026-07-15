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

addon.Services.PetJournal = PetJournalService
