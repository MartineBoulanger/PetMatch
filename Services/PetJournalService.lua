local addonName, addon = ...

local PetJournalService = {}

PetJournalService.Cache = {}

function PetJournalService:Scan()
  wipe(self.Cache)
  local numPets =
      C_PetJournal.GetNumPets()
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
    unique =
        C_PetJournal.GetPetInfoByIndex(
          index
        )
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

function PetJournalService:GetPet(guid)
  return self.Cache[guid]
end

function PetJournalService:GetAll()
  return self.Cache
end

function PetJournalService:GetPetName(guid)
  local speciesID,
  customName,
  level,
  xp,
  maxXP,
  displayID,
  isFavorite,
  name
  = C_PetJournal.GetPetInfoByPetID(
    guid
  )
  return customName or name
end

addon.Services.PetJournal = PetJournalService
