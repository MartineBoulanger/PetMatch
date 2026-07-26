local _, addon = ...

local PetTooltipService = {}

function PetTooltipService:GetPetStats(
    petGUID
)
  if type(petGUID) ~= "string"
      or petGUID == "" then
    return {
      health = 0,
      maxHealth = 0,
      power = 0,
      speed = 0,
      quality = 0,
    }
  end

  local health,
  maxHealth,
  power,
  speed,
  quality =
      C_PetJournal.GetPetStats(
        petGUID
      )

  return {
    health = health or 0,
    maxHealth =
        maxHealth
        or health
        or 0,

    power = power or 0,
    speed = speed or 0,
    quality = quality or 0,
  }
end

function PetTooltipService:GetAbilities(
    speciesID
)
  speciesID = tonumber(speciesID)

  if not speciesID then
    return {}
  end

  local abilityIDs = {}
  local abilityLevels = {}

  C_PetJournal.GetPetAbilityList(
    speciesID,
    abilityIDs,
    abilityLevels
  )

  local abilities = {}

  for index, abilityID in ipairs(
    abilityIDs
  ) do
    if abilityID then
      local name,
      icon,
      petType,
      noStrongWeakHints =
          C_PetBattles.GetAbilityInfoByID(
            abilityID
          )

      table.insert(
        abilities,
        {
          abilityID = abilityID,
          name = name or "Unknown",
          icon = icon,
          petType = petType,

          noStrongWeakHints =
              noStrongWeakHints == true,

          requiredLevel =
              abilityLevels[index]
              or 0,

          slot =
              ((index - 1) % 3)
              + 1,

          choice =
              index <= 3
              and 1
              or 2,
        }
      )
    end
  end

  return abilities
end

function PetTooltipService:CreatePet(
    petGUID
)
  if type(petGUID) ~= "string"
      or petGUID == "" then
    return nil, "Invalid pet GUID"
  end

  local journalService = addon.Services.PetJournal

  if not journalService then
    return nil,
        "Pet Journal service is unavailable"
  end

  local journalPet =
      journalService:GetPet(
        petGUID
      )

  if not journalPet then
    return nil, "Pet not found"
  end

  local stats =
      self:GetPetStats(
        petGUID
      )

  local pet =
      addon.Models.Pet:Create({
        petGUID = petGUID,
        speciesID = journalPet.speciesID,
        name = journalPet.name,
        customName = journalPet.customName,
        speciesName = journalPet.speciesName,
        icon = journalPet.icon,
        level = journalPet.level,
        quality = stats.quality,
        favorite = journalPet.favorite,
        petType = journalPet.petType,
        creatureID = journalPet.creatureID,
        displayID = journalPet.displayID,
        description = journalPet.description,
        sourceText = journalPet.sourceText,
        health = stats.health,
        maxHealth = stats.maxHealth,
        power = stats.power,
        speed = stats.speed,
        abilities =
            self:GetAbilities(
              journalPet.speciesID
            ),
      })

  self:ApplyBreedData(pet)
  self:ApplyExpansionData(pet)
  self:ApplyPassiveData(pet)

  return pet
end

function PetTooltipService:ApplyBreedData(
    pet
)
  if not pet then
    return
  end

  local breedService = addon.Services.Breed

  if not breedService then
    return
  end
end

function PetTooltipService:ApplyExpansionData(
    pet
)
  if not pet then
    return
  end

  -- Expansion-resolutie voegen we toe
  -- zodra de basis-tooltip werkt.
end

function PetTooltipService:ApplyPassiveData(
    pet
)
  if not pet
      or not pet.petType then
    return
  end

  pet.passive = {
    petType = pet.petType,
  }
end

function PetTooltipService:GetBySpeciesID(
    speciesID
)
  speciesID = tonumber(speciesID)

  if not speciesID then
    return nil, "Invalid species ID"
  end

  local journalService = addon.Services.PetJournal

  if not journalService then
    return nil,
        "Pet Journal service is unavailable"
  end

  local petGUID =
      journalService:
      FindOwnedPetBySpeciesID(
        speciesID
      )

  if not petGUID then
    return nil,
        "No owned pet found for species"
  end

  return self:CreatePet(
    petGUID
  )
end

addon.Services.PetTooltip = PetTooltipService
