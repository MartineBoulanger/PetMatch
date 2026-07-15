local addonName, addon = ...

local BattleSlotService = {}

local function RefreshBlizzardLoadout()
  if type(PetJournal_UpdatePetLoadOut) == "function" then
    PetJournal_UpdatePetLoadOut()
  end
end

-------------------------------------------------
-- Get pet GUID from Blizzard battle slot
-------------------------------------------------
function BattleSlotService:GetSlot(slot)
  if slot < 1 or slot > 3 then
    return nil
  end

  local petGUID = C_PetJournal.GetPetLoadOutInfo(slot)

  return petGUID
end

-------------------------------------------------
-- Get all current battle slots
-------------------------------------------------
function BattleSlotService:GetCurrentSlots()
  local slots = {}

  for i = 1, 3 do
    slots[i] = self:GetSlot(i)
  end

  return slots
end

-------------------------------------------------
-- Put a pet into Blizzard battle slot
-------------------------------------------------
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

-------------------------------------------------
-- Debug
-------------------------------------------------
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

function BattleSlotService:LoadPets(pets)
  if type(pets) ~= "table" then
    return false, "Invalid pet list"
  end

  if C_PetBattles.IsInBattle() then
    return false, "Cannot load a team during a pet battle"
  end

  if InCombatLockdown() then
    return false, "Cannot load a team during combat"
  end

  local changedSlots = 0

  for slot = 1, 3 do
    local petGUID = pets[slot]

    if petGUID then
      local pet =
          addon.Services.PetJournal:GetPet(petGUID)

      if not pet then
        return false, string.format(
          "Pet in slot %d is unavailable",
          slot
        )
      end

      local _, _, _, _, locked =
          C_PetJournal.GetPetLoadOutInfo(slot)

      if locked then
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
    return false, "The team contains no pets"
  end

  -- Laat Blizzard de originele Battle Pet Slots opnieuw tekenen.
  RefreshBlizzardLoadout()

  return true
end

addon.Services = addon.Services or {}

addon.Services.BattleSlot = BattleSlotService
