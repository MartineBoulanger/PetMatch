local _, addon = ...

local SuggestedTeamService = {}

--------------------------------------------------
-- Get enemy pet type
--------------------------------------------------
local function GetEnemyPetType(speciesID)
  speciesID = tonumber(speciesID)

  if not speciesID then
    return nil
  end

  local _, _, petType =
      C_PetJournal.GetPetInfoBySpeciesID(speciesID)

  return tonumber(petType)
end

local function GetEnemyLevel(enemyPet)
  if type(enemyPet) ~= "table" then
    return 25
  end

  return tonumber(enemyPet.level) or 25
end

local function GetDefensiveScore(pet, enemyPet)
  if type(pet) ~= "table"
      or not pet.petType or type(enemyPet) ~= "table"
      or not enemyPet.speciesID then
    return 0
  end

  local petTypeFilter = addon.Services.PetTypeFilter

  if not petTypeFilter then
    return 0
  end

  local enemyAbilityTypes =
      petTypeFilter:GetAbilityTypes(enemyPet.speciesID, GetEnemyLevel(enemyPet))

  local score = 0

  for abilityType in pairs(enemyAbilityTypes) do
    local matchup = petTypeFilter:GetMatchup(abilityType)

    if matchup then
      ------------------------------------------------
      -- Enemy ability is strong against our family.
      ------------------------------------------------
      if matchup.strongVs == pet.petType then
        score = score - 1
      end

      ------------------------------------------------
      -- Enemy ability is weak against our family.
      ------------------------------------------------
      if matchup.weakVs == pet.petType then
        score = score + 1
      end
    end
  end

  return score
end

local function CountStrongAbilitySlots(speciesID, strongAbilities)
  if not speciesID or type(strongAbilities) ~= "table" then
    return 0
  end

  local abilityIDs = {}
  local abilityLevels = {}

  C_PetJournal.GetPetAbilityList(
    speciesID, abilityIDs, abilityLevels
  )

  local count = 0

  for abilitySlot = 1, 3 do
    local firstAbility = abilityIDs[abilitySlot]
    local secondAbility = abilityIDs[abilitySlot + 3]

    if (firstAbility and strongAbilities[firstAbility]) or (
          secondAbility and strongAbilities[secondAbility]) then
      count = count + 1
    end
  end

  return count
end

local function GetHealthState(petGUID)
  if not petGUID then
    return 0
  end

  local health,
  maxHealth = C_PetJournal.GetPetStats(petGUID)

  health = tonumber(health) or 0
  maxHealth = tonumber(maxHealth) or 0

  if health <= 0 then
    return 1
  end

  if maxHealth > 0 and health >= maxHealth then
    return 3
  end

  return 2
end

local function GetPetStats(petGUID)
  if not petGUID then
    return 0, 0, 0
  end

  local _, maxHealth, power, speed =
      C_PetJournal.GetPetStats(petGUID)

  return tonumber(power) or 0,
      tonumber(speed) or 0, tonumber(maxHealth) or 0
end

--------------------------------------------------
-- Find best counter for enemy pet
--------------------------------------------------
function SuggestedTeamService:FindCounter(enemyPet, usedPetGUIDs)
  if type(enemyPet) ~= "table" or not enemyPet.speciesID then
    return nil
  end

  local petJournal = addon.Services.PetJournal
  local petTypeFilter = addon.Services.PetTypeFilter

  if not petJournal or not petTypeFilter then
    return nil
  end

  local enemyPetType = GetEnemyPetType(enemyPet.speciesID)

  if not enemyPetType then
    return nil
  end

  petJournal:EnsureIndex()

  local pets = petJournal:GetAll()

  if type(pets) ~= "table" then
    return nil
  end

  usedPetGUIDs = usedPetGUIDs or {}

  local bestPet = nil
  local bestStrongAbilityCount = 0
  local bestDefensiveScore = 0
  local bestQuality = 0
  local bestHealthState = 0
  local bestPower = 0
  local bestSpeed = 0
  local bestMaxHealth = 0

  for petGUID, pet in pairs(pets) do
    if pet and pet.canBattle == true
        and tonumber(pet.level) == 25
        and not usedPetGUIDs[petGUID] then
      local strongAbilities =
          petTypeFilter:GetStrongAbilitiesAgainst(
            pet.speciesID, pet.level, enemyPetType
          )

      local strongAbilityCount = CountStrongAbilitySlots(
        pet.speciesID, strongAbilities
      )
      local defensiveScore = GetDefensiveScore(pet, enemyPet)
      local healthState = GetHealthState(petGUID)
      local power, speed, maxHealth = GetPetStats(petGUID)

      if strongAbilityCount > 0 then
        local quality = tonumber(pet.quality) or 0

        local sameCoreScore = strongAbilityCount == bestStrongAbilityCount
            and defensiveScore == bestDefensiveScore
            and quality == bestQuality
            and healthState == bestHealthState

        -- Compare pets based on the following criteria
        local isBetter = not bestPet or strongAbilityCount
            > bestStrongAbilityCount or (
              strongAbilityCount == bestStrongAbilityCount
              and defensiveScore > bestDefensiveScore)
            or (strongAbilityCount == bestStrongAbilityCount
              and defensiveScore == bestDefensiveScore
              and quality > bestQuality)
            or (strongAbilityCount == bestStrongAbilityCount
              and defensiveScore == bestDefensiveScore
              and quality == bestQuality
              and healthState > bestHealthState)
            or (sameCoreScore and power > bestPower)
            or (sameCoreScore and power == bestPower and speed > bestSpeed)
            or (sameCoreScore and power == bestPower
              and speed == bestSpeed and maxHealth > bestMaxHealth)
            or (sameCoreScore and power == bestPower
              and speed == bestSpeed and maxHealth == bestMaxHealth
              and bestPet and tostring(petGUID) < tostring(bestPet.petGUID))

        if isBetter then
          bestPet = pet
          bestStrongAbilityCount = strongAbilityCount
          bestDefensiveScore = defensiveScore
          bestQuality = quality
          bestHealthState = healthState
          bestPower = power
          bestSpeed = speed
          bestMaxHealth = maxHealth
        end
      end
    end
  end

  return bestPet
end

--------------------------------------------------
-- Build suggested team for target
--------------------------------------------------
function SuggestedTeamService:GetForTarget(npcID)
  local targetService = addon.Services.PetBattleTarget

  if not targetService then
    return {}
  end

  local target = targetService:GetByNPCID(npcID)

  if not target then
    return {}
  end

  local enemyPets = targetService:GetPets(target)

  local suggestedPets = {}
  local usedPetGUIDs = {}

  for slot = 1, 3 do
    local enemyPet = enemyPets[slot]

    local pet = self:FindCounter(enemyPet, usedPetGUIDs)

    if pet then
      pet.suggestedAbilities =
          self:GetAbilitiesForEnemy(pet, enemyPet)
      suggestedPets[slot] = pet
      usedPetGUIDs[pet.petGUID] = true
    end
  end

  return suggestedPets
end

function SuggestedTeamService:GetAbilitiesForEnemy(pet, enemyPet)
  if type(pet) ~= "table" or not pet.speciesID
      or type(enemyPet) ~= "table" or not enemyPet.speciesID then
    return {}
  end

  local petTypeFilter = addon.Services.PetTypeFilter

  if not petTypeFilter then
    return {}
  end

  local enemyPetType = GetEnemyPetType(enemyPet.speciesID)

  if not enemyPetType then
    return {}
  end

  local strongAbilities =
      petTypeFilter:GetStrongAbilitiesAgainst(
        pet.speciesID, pet.level, enemyPetType
      )

  local abilityIDs = {}
  local abilityLevels = {}

  C_PetJournal.GetPetAbilityList(
    pet.speciesID, abilityIDs, abilityLevels
  )

  local selectedAbilities = {}

  for abilitySlot = 1, 3 do
    local firstAbility = abilityIDs[abilitySlot]
    local secondAbility = abilityIDs[abilitySlot + 3]

    ------------------------------------------------
    -- Prefer the ability that is strong against
    -- the enemy pet family.
    ------------------------------------------------
    if secondAbility
        and strongAbilities[secondAbility] then
      selectedAbilities[abilitySlot] = secondAbility
    elseif firstAbility then
      selectedAbilities[abilitySlot] = firstAbility
    end
  end

  return selectedAbilities
end

addon.Services.SuggestedTeam = SuggestedTeamService
