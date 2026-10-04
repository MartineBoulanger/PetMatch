local _, addon = ...

local L = addon.L
local BattleSlotService = {}
BattleSlotService.LoadGeneration = 0
BattleSlotService.IsLoadingTeam = false

local MAX_ABILITY_ATTEMPTS = 6
local ABILITY_RETRY_DELAY = 0.08

local function AbilitiesMatch(expectedAbilities)
  if type(expectedAbilities) ~= "table" then
    return true
  end

  for teamSlot = 1, 3 do
    local expected =
        expectedAbilities[teamSlot]

    if type(expected) == "table" then
      local _,
      currentAbility1,
      currentAbility2,
      currentAbility3 =
          C_PetJournal.GetPetLoadOutInfo(
            teamSlot
          )

      local current = {
        currentAbility1,
        currentAbility2,
        currentAbility3,
      }

      for abilitySlot = 1, 3 do
        if expected[abilitySlot]
            and current[abilitySlot]
            ~= expected[abilitySlot] then
          return false
        end
      end
    end
  end

  return true
end

local function ApplyAbilities(pets, abilities)
  if type(abilities) ~= "table" then
    return
  end

  for teamSlot = 1, 3 do
    local petGUID = pets[teamSlot]
    local slotAbilities =
        abilities[teamSlot]

    if petGUID
        and type(slotAbilities) == "table" then
      for abilitySlot = 1, 3 do
        local abilityID =
            slotAbilities[abilitySlot]

        if abilityID then
          C_PetJournal.SetAbility(
            teamSlot,
            abilitySlot,
            abilityID
          )
        end
      end
    end
  end
end

local function ApplyAbilitiesWithRetry(pets, abilities, attempt, generation)
  attempt = attempt or 1
  if generation ~= BattleSlotService.LoadGeneration then
    return
  end

  ApplyAbilities(
    pets,
    abilities
  )

  C_Timer.After(
    ABILITY_RETRY_DELAY,

    function()
      if generation ~= BattleSlotService.LoadGeneration then
        return
      end

      if AbilitiesMatch(abilities) then
        if type(PetJournal_UpdatePetLoadOut) == "function" then
          PetJournal_UpdatePetLoadOut()
        end

        if addon.Services.LoadoutMonitor then
          addon.Services.LoadoutMonitor:Resume()
        end

        return
      end

      if attempt < MAX_ABILITY_ATTEMPTS then
        ApplyAbilitiesWithRetry(
          pets,
          abilities,
          attempt + 1,
          generation
        )

        return
      end

      if generation ~= BattleSlotService.LoadGeneration then
        return
      end

      if addon.Services.LoadoutMonitor then
        addon.Services.LoadoutMonitor:Resume()
      end

      addon.Logger:Warn(
        L["ABILITIES_ERROR"]
      )
    end
  )
end

local function GetFirstAbilityIDs(petGUID)
  local pet =
      addon.Services.PetJournal:GetPet(
        petGUID
      )

  if not pet or not pet.speciesID then
    return {}
  end

  local abilityIDs = {}
  local abilityLevels = {}

  C_PetJournal.GetPetAbilityList(
    pet.speciesID,
    abilityIDs,
    abilityLevels
  )

  return {
    abilityIDs[1],
    abilityIDs[2],
    abilityIDs[3],
  }
end

function BattleSlotService:GetSlot(slot)
  if slot < 1 or slot > 3 then
    return nil
  end

  local petGUID = C_PetJournal.GetPetLoadOutInfo(slot)

  return petGUID
end

function BattleSlotService:GetCurrentSlots()
  local slots = {}

  for i = 1, 3 do
    slots[i] = self:GetSlot(i)
  end

  return slots
end

function BattleSlotService:SetSlot(slot, petGUID)
  if slot < 1 or slot > 3 then
    return false
  end

  if not petGUID then
    return false
  end

  C_PetJournal.SetPetLoadOutInfo(
    slot,
    petGUID
  )

  return true
end

function BattleSlotService:Debug()
  for i = 1, 3 do
    local guid = self:GetSlot(i)

    if guid then
      addon.Logger:INFO(
        L["INFO_SLOT"],
        i,
        guid
      )
    else
      addon.Logger:INFO(
        L["INFO_SLOT"],
        i,
        L["EMPTY"]
      )
    end
  end
end

function BattleSlotService:ResolveSpecialSlot(specialSlot, slot, usedPetGUIDs)
  if type(specialSlot) ~= "table" then
    return nil, string.format(
      L["INVALID_SPECIAL_SLOT"] .. ": %d",
      slot
    )
  end

  usedPetGUIDs = usedPetGUIDs or {}
  local slotType = specialSlot.type

  --------------------------------------------------
  -- Ignored / unowned
  --------------------------------------------------
  if slotType == "ignored"
      or slotType == "unowned" then
    return nil
  end

  --------------------------------------------------
  -- Levelling Queue
  --------------------------------------------------
  if slotType == "leveling" or slotType == "levelingQueue" then
    local queueService = addon.Services.LevellingQueue

    if not queueService then
      return nil, L["INVALID_QUEUE"]
    end

    local queue = queueService:GetAll()

    local minimumLevel =
        tonumber(
          specialSlot.minimumLevel
          or specialSlot.level
        )
        or 1

    local maximumLevel =
        tonumber(
          specialSlot.maximumLevel
        )
        or 24

    local minimumHealth =
        tonumber(
          specialSlot.minimumHealth
        )

    ------------------------------------------------
    -- Queue order is priority order.
    ------------------------------------------------
    if type(queue) == "table" then
      for _, petGUID in ipairs(queue) do
        if not usedPetGUIDs[petGUID] then
          local pet = addon.Services.PetJournal:GetPet(petGUID)

          if pet and pet.canBattle == true then
            local level = tonumber(pet.level) or 0

            local correctLevel =
                level >= minimumLevel
                and level <= maximumLevel

            local correctHealth = true

            if correctLevel and minimumHealth then
              local _, maximumHealth =
                  C_PetJournal.GetPetStats(petGUID)

              correctHealth = (maximumHealth or 0) >= minimumHealth
            end

            if correctLevel and correctHealth then
              return petGUID
            end
          end
        end
      end
    end

    ------------------------------------------------
    -- No eligible queue pet.
    --
    -- Fall back to a random unused level 25 pet.
    ------------------------------------------------
    local pets = addon.Services.PetJournal:GetAll()

    if type(pets) ~= "table" then
      return nil, L["JOURNAL_ERROR"]
    end

    local candidates = {}

    for petGUID, pet in pairs(pets) do
      if petGUID
          and type(pet) == "table"
          and pet.canBattle == true
          and not usedPetGUIDs[petGUID]
          and tonumber(pet.level) == 25 then
        candidates[
        #candidates + 1
        ] = petGUID
      end
    end

    if #candidates == 0 then
      return nil, string.format(
        L["INVALID_LEVEL_25"] .. L["INVALID_LEVEL_25_PART4"],
        slot
      )
    end

    return candidates[
    math.random(1, #candidates)
    ]
  end

  --------------------------------------------------
  -- Random pet
  --------------------------------------------------
  if slotType ~= "random" then
    return nil, string.format(
      L["UNSUPPORTED_SLOT"] .. " '%s'",
      tostring(slotType)
    )
  end

  local pets = addon.Services.PetJournal:GetAll()

  if type(pets) ~= "table" then
    return nil, L["JOURNAL_ERROR"]
  end

  local candidates = {}

  for petGUID, pet in pairs(pets) do
    if petGUID
        and type(pet) == "table"
        and pet.canBattle ~= false
        and not usedPetGUIDs[petGUID] then
      local level =
          tonumber(
            pet.level
          )
          or 0

      local requiredPetType =
          tonumber(
            specialSlot.petType
          )
          or 0

      local correctFamily =
          requiredPetType == 0
          or pet.petType
          == requiredPetType

      if level == 25 and correctFamily then
        candidates[
        #candidates + 1
        ] = {
          petGUID =
              petGUID,

          level =
              level,
        }
      end
    end
  end

  --------------------------------------------------
  -- No random candidates
  --------------------------------------------------
  if #candidates == 0 then
    local petType =
        tonumber(
          specialSlot.petType
        )
        or 0

    if petType > 0 then
      return nil, string.format(
        L["INVALID_LEVEL_25"] .. L["INVALID_LEVEL_25_PART2"] .. L["INVALID_LEVEL_25_PART3"],
        petType,
        slot
      )
    end

    return nil, string.format(
      L["INVALID_LEVEL_25"] .. L["INVALID_LEVEL_25_PART3"],
      slot
    )
  end

  --------------------------------------------------
  -- Random candidate
  --------------------------------------------------
  local candidate =
      candidates[
      math.random(
        1,
        #candidates
      )
      ]

  return candidate.petGUID
end

function BattleSlotService:RefreshLevellingSlots()
  if C_PetBattles.IsInBattle()
      or InCombatLockdown() then
    return false
  end

  local usedPetGUIDs = {}
  local changed = false

  for slot = 1, 3 do
    local specialSlot = addon.Services.TeamSetup:GetSlot(slot)

    local isLevellingSlot =
        type(specialSlot) == "table"
        and (
          specialSlot.type == "leveling"
          or specialSlot.type == "levelingQueue"
        )

    if not isLevellingSlot then
      local petGUID =
          self:GetSlot(slot)

      if petGUID then
        usedPetGUIDs[petGUID] = true
      end
    end
  end

  --------------------------------------------------
  -- Resolve levelling slots again from the queue.
  --------------------------------------------------
  for slot = 1, 3 do
    local specialSlot = addon.Services.TeamSetup:GetSlot(slot)

    local isLevellingSlot =
        type(specialSlot) == "table"
        and (
          specialSlot.type == "leveling"
          or specialSlot.type == "levelingQueue"
        )

    if isLevellingSlot then
      local petGUID =
          self:ResolveSpecialSlot(
            specialSlot,
            slot,
            usedPetGUIDs
          )

      if petGUID then
        local currentPetGUID =
            self:GetSlot(slot)

        if currentPetGUID ~= petGUID then
          C_PetJournal.SetPetLoadOutInfo(
            slot,
            petGUID
          )

          changed = true
        end

        usedPetGUIDs[petGUID] = true
      end
    end
  end

  if changed
      and type(PetJournal_UpdatePetLoadOut)
      == "function" then
    PetJournal_UpdatePetLoadOut()
  end

  return changed
end

local function ResolveHealthyDuplicate(savedPetGUID, slot, usedPetGUIDs, preserveCurrentDuplicate)
  if not savedPetGUID then
    return nil
  end

  --------------------------------------------------
  -- Saved team pet determines the species
  --------------------------------------------------

  local savedPet =
      addon.Services.PetJournal:
      GetPet(savedPetGUID)

  if not savedPet
      or not savedPet.speciesID then
    return savedPetGUID
  end

  local speciesID =
      savedPet.speciesID

  --------------------------------------------------
  -- Prefer the currently loaded pet when it is
  -- already a duplicate of the saved team pet.
  --------------------------------------------------

  local currentPetGUID =
      C_PetJournal.GetPetLoadOutInfo(
        slot
      )

  local currentPet

  if currentPetGUID then
    currentPet =
        addon.Services.PetJournal:
        GetPet(currentPetGUID)
  end

  local currentIsSameSpecies =
      currentPet
      and currentPet.speciesID
      == speciesID

  --------------------------------------------------
  -- Do not keep a pet that is reserved for another
  -- normal team slot.
  --
  -- The saved pet for this slot is allowed because
  -- it is also present in usedPetGUIDs.
  --------------------------------------------------

  local currentIsAvailable =
      currentPetGUID == savedPetGUID
      or not usedPetGUIDs[
      currentPetGUID
      ]

  local petGUID

  if preserveCurrentDuplicate
      and currentIsSameSpecies
      and currentIsAvailable then
    petGUID = currentPetGUID
  else
    petGUID = savedPetGUID
  end

  --------------------------------------------------
  -- Determine the health state of the pet we
  -- would normally keep.
  --
  -- 3 = Full health
  -- 2 = Damaged
  -- 1 = Dead
  --------------------------------------------------
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

  local currentHealthState

  if health <= 0 then
    currentHealthState = 1
  elseif maxHealth > 0
      and health >= maxHealth then
    currentHealthState = 3
  else
    currentHealthState = 2
  end

  --------------------------------------------------
  -- Full health is already the best possible
  -- state, so keep the preferred pet.
  --------------------------------------------------
  if currentHealthState == 3 then
    return petGUID
  end

  --------------------------------------------------
  -- Look for an available duplicate of the same
  -- species with a better health state.
  --------------------------------------------------
  local pets =
      addon.Services.PetJournal:
      GetAll()

  if type(pets) ~= "table" then
    return petGUID
  end

  local bestPetGUID =
      petGUID

  local bestHealthState =
      currentHealthState

  for candidateGUID, candidate
  in pairs(pets) do
    local candidateIsAvailable =
        candidateGUID == savedPetGUID
        or not usedPetGUIDs[
        candidateGUID
        ]

    if candidateGUID ~= petGUID
        and candidateIsAvailable
        and type(candidate) == "table"
        and candidate.speciesID
        == speciesID
        and candidate.canBattle ~= false
        and tonumber(candidate.level) == 25 then
      local candidateHealth,
      candidateMaxHealth =
          C_PetJournal.GetPetStats(
            candidateGUID
          )

      candidateHealth =
          tonumber(
            candidateHealth
          ) or 0

      candidateMaxHealth =
          tonumber(
            candidateMaxHealth
          ) or 0

      local candidateHealthState

      if candidateHealth <= 0 then
        candidateHealthState = 1
      elseif candidateMaxHealth > 0
          and candidateHealth
          >= candidateMaxHealth then
        candidateHealthState = 3
      else
        candidateHealthState = 2
      end

      ------------------------------------------------
      -- Only replace the preferred pet when the
      -- duplicate has a strictly better health
      -- state.
      ------------------------------------------------
      if candidateHealthState
          > bestHealthState then
        bestPetGUID =
            candidateGUID

        bestHealthState =
            candidateHealthState
      end
    end
  end

  return bestPetGUID
end

function BattleSlotService:LoadPets(pets, abilities, specialSlots, preserveCurrentDuplicates)
  self.LoadGeneration = self.LoadGeneration + 1
  local generation = self.LoadGeneration

  if type(pets) ~= "table" then
    return false, L["INVALID_PET_LIST"]
  end

  specialSlots = specialSlots or {}

  if C_PetBattles.IsInBattle() then
    return false, L["LOAD_ERROR"]
  end

  if InCombatLockdown() then
    return false, L["LOAD_COMBAT_ERROR"]
  end

  --------------------------------------------------
  -- Preflight: validate all battle pet slots
  -- before changing anything
  --------------------------------------------------
  for slot = 1, 3 do
    local _, _, _, _, locked = C_PetJournal.GetPetLoadOutInfo(slot)

    if locked then
      return false, string.format(
        "Battle pet slot %d is locked",
        slot
      )
    end
  end

  --------------------------------------------------
  -- Resolve loadout
  --------------------------------------------------
  local changedSlots = 0
  local resolvedPets = {}
  local usedPetGUIDs = {}
  local resolvedAbilities = {}

  --------------------------------------------------
  -- Reserve normal team pets so special slots
  -- cannot resolve to the same pet
  --------------------------------------------------
  for slot = 1, 3 do
    if not specialSlots[slot] and pets[slot] then
      usedPetGUIDs[pets[slot]] = true
    end
  end

  --------------------------------------------------
  -- Suspend loadout monitoring while we apply team
  --------------------------------------------------
  if addon.Services.LoadoutMonitor then
    addon.Services.LoadoutMonitor:Suspend()
  end

  local previousSummonedPetGUID = C_PetJournal.GetSummonedPetGUID()

  self.IsLoadingTeam = true

  --------------------------------------------------
  -- Resolve and load pets
  --------------------------------------------------
  for slot = 1, 3 do
    local specialSlot = specialSlots[slot]
    local petGUID
    local resolveError

    if specialSlot then
      petGUID, resolveError =
          self:ResolveSpecialSlot(
            specialSlot,
            slot,
            usedPetGUIDs
          )

      if resolveError then
        if addon.Services.LoadoutMonitor then
          addon.Services.LoadoutMonitor:Resume()
        end

        return false, resolveError
      end
    else
      petGUID =
          ResolveHealthyDuplicate(
            pets[slot],
            slot,
            usedPetGUIDs,
            preserveCurrentDuplicates
          )
    end


    resolvedPets[slot] = petGUID

    ------------------------------------------------
    -- Resolve abilities
    ------------------------------------------------
    if not petGUID then
      resolvedAbilities[slot] = nil
    elseif specialSlot
        and (
          specialSlot.type == "random"
          or specialSlot.type == "leveling"
          or specialSlot.type == "levelingQueue"
        ) then
      resolvedAbilities[slot] = GetFirstAbilityIDs(petGUID)
    else
      resolvedAbilities[slot] =
          abilities
          and abilities[slot]
          or {}
    end

    ------------------------------------------------
    -- Validate and apply pet
    ------------------------------------------------
    if petGUID then
      usedPetGUIDs[petGUID] = true

      local pet = addon.Services.PetJournal:GetPet(petGUID)

      if not pet then
        if addon.Services.LoadoutMonitor then
          addon.Services.LoadoutMonitor:Resume()
        end

        return false, string.format(
          "Pet in slot %d is unavailable",
          slot
        )
      end

      C_PetJournal.SetPetLoadOutInfo(
        slot,
        petGUID
      )

      changedSlots = changedSlots + 1
    end
  end

  self.IsLoadingTeam = false

  --------------------------------------------------
  -- Auto dismiss summoned pet
  --------------------------------------------------
  if changedSlots > 0
      and resolvedPets[1]
      and addon.UI
      and addon.UI.Actions
      and addon.UI.Actions.PetJournalToolbar
      and addon.UI.Actions.PetJournalToolbar.AutoDismissPet then
    addon.UI.Actions.PetJournalToolbar:
        AutoDismissPet(resolvedPets[1], 1, generation, previousSummonedPetGUID)
  end

  --------------------------------------------------
  -- Nothing loaded
  --------------------------------------------------
  if changedSlots == 0 then
    if addon.Services.LoadoutMonitor then
      addon.Services.LoadoutMonitor:Resume()
    end

    return false, L["NO_PETS_ERROR"]
  end

  --------------------------------------------------
  -- Refresh Blizzard loadout UI
  --------------------------------------------------
  if type(PetJournal_UpdatePetLoadOut) == "function" then
    PetJournal_UpdatePetLoadOut()
  end

  --------------------------------------------------
  -- Apply abilities after pets have settled
  --------------------------------------------------
  C_Timer.After(
    0.08,
    function()
      if generation ~= self.LoadGeneration then
        return
      end

      ApplyAbilitiesWithRetry(
        resolvedPets,
        resolvedAbilities,
        1,
        generation
      )
    end
  )

  return true
end

function BattleSlotService:GetSlotLoadout(slot)
  if type(slot) ~= "number"
      or slot < 1
      or slot > 3 then
    return nil
  end

  local petGUID,
  ability1,
  ability2,
  ability3,
  locked =
      C_PetJournal.GetPetLoadOutInfo(slot)

  return {
    petGUID = petGUID,

    abilities = {
      [1] = ability1,
      [2] = ability2,
      [3] = ability3,
    },

    locked = locked == true,
  }
end

function BattleSlotService:GetCurrentLoadout()
  local loadout = {
    pets = {},
    abilities = {},
  }

  for slot = 1, 3 do
    local slotInfo =
        self:GetSlotLoadout(slot)

    if slotInfo then
      loadout.pets[slot] =
          slotInfo.petGUID

      loadout.abilities[slot] = {
        [1] = slotInfo.abilities[1],
        [2] = slotInfo.abilities[2],
        [3] = slotInfo.abilities[3],
      }
    end
  end

  return loadout
end

addon.Services.BattleSlot = BattleSlotService
