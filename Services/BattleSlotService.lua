local _, addon = ...

local BattleSlotService = {}

local MAX_ABILITY_ATTEMPTS = 6
local ABILITY_RETRY_DELAY = 0.08

local function AbilitiesMatch(
    expectedAbilities
)
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

local function ApplyAbilities(
    pets,
    abilities
)
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

local function ApplyAbilitiesWithRetry(
    pets,
    abilities,
    attempt
)
  attempt = attempt or 1

  ApplyAbilities(
    pets,
    abilities
  )

  C_Timer.After(
    ABILITY_RETRY_DELAY,
    function()
      if AbilitiesMatch(abilities) then
        if type(PetJournal_UpdatePetLoadOut)
            == "function" then
          PetJournal_UpdatePetLoadOut()
        end

        if addon.Services.LoadoutMonitor then
          addon.Services.LoadoutMonitor:
              Resume()
        end

        return
      end

      if attempt < MAX_ABILITY_ATTEMPTS then
        ApplyAbilitiesWithRetry(
          pets,
          abilities,
          attempt + 1
        )

        return
      end

      if addon.Services.LoadoutMonitor then
        addon.Services.LoadoutMonitor:
            Resume()
      end

      addon.Logger:Warn(
        "Some pet abilities could not be applied"
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
      print(
        "[PetMatch] Battle Slot",
        i,
        guid
      )
    else
      print(
        "[PetMatch] Battle Slot",
        i,
        "Empty"
      )
    end
  end
end

function BattleSlotService:ResolveSpecialSlot(
    specialSlot,
    slot,
    usedPetGUIDs
)
  if type(specialSlot) ~= "table" then
    return nil, string.format(
      "Invalid special pet slot %d",
      slot
    )
  end

  usedPetGUIDs = usedPetGUIDs or {}

  local slotType = specialSlot.type

  -- Een ignored of unowned slot wordt niet aangepast.
  if slotType == "ignored"
      or slotType == "unowned" then
    return nil
  end

  local pets =
      addon.Services.PetJournal:GetAll()

  if type(pets) ~= "table" then
    return nil,
        "The Pet Journal cache is unavailable"
  end

  local candidates = {}

  for petGUID, pet in pairs(pets) do
    if petGUID
        and type(pet) == "table"
        and pet.canBattle ~= false
        and not usedPetGUIDs[petGUID] then
      local level = tonumber(pet.level) or 0

      if slotType == "random" then
        local requiredPetType =
            tonumber(specialSlot.petType) or 0

        local correctFamily =
            requiredPetType == 0
            or pet.petType == requiredPetType

        if level == 25 and correctFamily then
          candidates[#candidates + 1] = {
            petGUID = petGUID,
            level = level,
          }
        end
      elseif slotType == "leveling"
          or slotType == "levelingQueue" then
        local minimumLevel =
            tonumber(
              specialSlot.minimumLevel
              or specialSlot.level
            ) or 1

        local maximumLevel =
            tonumber(
              specialSlot.maximumLevel
            ) or 24

        local correctLevel =
            level >= minimumLevel
            and level <= maximumLevel

        local correctHealth = true
        local minimumHealth =
            tonumber(specialSlot.minimumHealth)

        if correctLevel and minimumHealth then
          local _, maximumHealth =
              C_PetJournal.GetPetStats(
                petGUID
              )

          correctHealth =
              (maximumHealth or 0)
              >= minimumHealth
        end

        if correctLevel and correctHealth then
          candidates[#candidates + 1] = {
            petGUID = petGUID,
            level = level,
          }
        end
      end
    end
  end

  if #candidates == 0 then
    if slotType == "random" then
      local petType =
          tonumber(specialSlot.petType) or 0

      if petType > 0 then
        return nil, string.format(
          "No available level 25 pet of family %d for slot %d",
          petType,
          slot
        )
      end

      return nil, string.format(
        "No available level 25 pet for slot %d",
        slot
      )
    end

    if slotType == "leveling"
        or slotType == "levelingQueue" then
      return nil, string.format(
        "No available leveling pet for slot %d",
        slot
      )
    end

    return nil, string.format(
      "Unsupported special slot type '%s'",
      tostring(slotType)
    )
  end

  if slotType == "random" then
    local candidate =
        candidates[
        math.random(1, #candidates)
        ]

    return candidate.petGUID
  end

  table.sort(
    candidates,
    function(left, right)
      if left.level ~= right.level then
        return left.level < right.level
      end

      return left.petGUID < right.petGUID
    end
  )

  return candidates[1].petGUID
end

function BattleSlotService:LoadPets(
    pets,
    abilities,
    specialSlots
)
  if type(pets) ~= "table" then
    return false, "Invalid pet list"
  end

  specialSlots = specialSlots or {}

  if C_PetBattles.IsInBattle() then
    return false,
        "Cannot load a team during a pet battle"
  end

  if InCombatLockdown() then
    return false,
        "Cannot load a team during combat"
  end

  local changedSlots = 0
  local resolvedPets = {}
  local usedPetGUIDs = {}
  local resolvedAbilities = {}

  for slot = 1, 3 do
    if not specialSlots[slot]
        and pets[slot] then
      usedPetGUIDs[pets[slot]] = true
    end
  end

  if addon.Services.LoadoutMonitor then
    addon.Services.LoadoutMonitor:Suspend()
  end

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
      petGUID = pets[slot]
    end

    resolvedPets[slot] = petGUID

    if specialSlot
        and specialSlot.type == "random"
        and petGUID then
      resolvedAbilities[slot] =
          GetFirstAbilityIDs(
            petGUID
          )
    else
      resolvedAbilities[slot] =
          abilities
          and abilities[slot]
          or {}
    end

    if petGUID then
      usedPetGUIDs[petGUID] = true

      local pet =
          addon.Services.PetJournal:GetPet(
            petGUID
          )

      if not pet then
        if addon.Services.LoadoutMonitor then
          addon.Services.LoadoutMonitor:Resume()
        end

        return false, string.format(
          "Pet in slot %d is unavailable",
          slot
        )
      end

      local _, _, _, _, locked =
          C_PetJournal.GetPetLoadOutInfo(slot)

      if locked then
        if addon.Services.LoadoutMonitor then
          addon.Services.LoadoutMonitor:Resume()
        end

        return false, string.format(
          "Battle pet slot %d is locked",
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

  if changedSlots == 0 then
    if addon.Services.LoadoutMonitor then
      addon.Services.LoadoutMonitor:Resume()
    end

    return false,
        "The team contains no pets"
  end

  if type(PetJournal_UpdatePetLoadOut)
      == "function" then
    PetJournal_UpdatePetLoadOut()
  end

  C_Timer.After(
    0.08,
    function()
      ApplyAbilitiesWithRetry(
        resolvedPets,
        resolvedAbilities,
        1
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
