local addonName, addon = ...

local BattleSlotService = {}

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

addon.Services = addon.Services or {}

addon.Services.BattleSlot = BattleSlotService
