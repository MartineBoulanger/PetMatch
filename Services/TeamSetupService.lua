local _, addon = ...

local TeamSetupService = {}

TeamSetupService.Active = false
TeamSetupService.Slots = {}
TeamSetupService.TargetNPCIDs = {}

local function AreSlotsEqual(left, right)
  local leftIsSpecial = type(left) == "table"
  local rightIsSpecial = type(right) == "table"

  if left == false and right == nil then
    return true
  end

  if left == nil and right == false then
    return true
  end

  if not leftIsSpecial and not rightIsSpecial then
    return true
  end

  if leftIsSpecial ~= rightIsSpecial then
    return false
  end

  return left.type == right.type
      and tonumber(left.petType or 0)
      == tonumber(right.petType or 0)
      and left.rawPetTag == right.rawPetTag
      and tonumber(left.level or 0)
      == tonumber(right.level or 0)
      and tonumber(left.rarity or 0)
      == tonumber(right.rarity or 0)
      and tonumber(left.minimumLevel or 0)
      == tonumber(right.minimumLevel or 0)
      and tonumber(left.maximumLevel or 0)
      == tonumber(right.maximumLevel or 0)
      and tonumber(left.minimumHealth or 0)
      == tonumber(right.minimumHealth or 0)
end

function TeamSetupService:AreSlotsDifferent(savedSpecialSlots)
  savedSpecialSlots = type(savedSpecialSlots) == "table"
      and savedSpecialSlots or {}

  for slot = 1, 3 do
    local current = self.Slots[slot]
    local saved = savedSpecialSlots[slot]

    if not AreSlotsEqual(current, saved) then
      return true
    end
  end

  return false
end

function TeamSetupService:IsActive()
  return self.Active == true
end

function TeamSetupService:Enter()
  if self:IsActive() then
    return false
  end

  self.Active = true

  addon.EventBus:Fire(
    addon.Events.TEAM_SETUP_CHANGED,
    true
  )

  return true
end

function TeamSetupService:Exit()
  if not self:IsActive() then
    return false
  end

  self.Active = false

  addon.EventBus:Fire(
    addon.Events.TEAM_SETUP_CHANGED,
    false
  )

  return true
end

function TeamSetupService:Toggle()
  if self:IsActive() then
    self:Exit()
  else
    self:Enter()
  end

  return self:IsActive()
end

function TeamSetupService:SetSlots(specialSlots)
  wipe(self.Slots)

  if type(specialSlots) ~= "table" then
    return
  end

  for slot = 1, 3 do
    local specialSlot = specialSlots[slot]

    if type(specialSlot) == "table" then
      self.Slots[slot] = {
        type = specialSlot.type,
        petType = specialSlot.petType,
        rawPetTag = specialSlot.rawPetTag,
        level = specialSlot.level,
        rarity = specialSlot.rarity,
        minimumLevel = specialSlot.minimumLevel,
        maximumLevel = specialSlot.maximumLevel,
        minimumHealth = specialSlot.minimumHealth,
      }
    end
  end
end

function TeamSetupService:SetNormalSlot(slot)
  slot = tonumber(slot)

  if not slot or slot < 1 or slot > 3 then
    return false
  end

  --------------------------------------------------
  -- false means:
  -- explicitly use the current physical pet.
  --------------------------------------------------
  self.Slots[slot] = false

  addon.EventBus:Fire(
    addon.Events.TEAM_SETUP_SLOT_CHANGED,
    slot
  )

  return true
end

function TeamSetupService:SetSpecialSlot(slot, specialSlot)
  slot = tonumber(slot)

  if not slot or slot < 1 or slot > 3 then
    return false
  end

  if type(specialSlot) ~= "table" then
    return false
  end

  self.Slots[slot] = {
    type = specialSlot.type,
    petType = specialSlot.petType,
    rawPetTag = specialSlot.rawPetTag,
    level = specialSlot.level,
    rarity = specialSlot.rarity,
    minimumLevel = specialSlot.minimumLevel,
    maximumLevel = specialSlot.maximumLevel,
    minimumHealth = specialSlot.minimumHealth,
  }

  addon.EventBus:Fire(
    addon.Events.TEAM_SETUP_SLOT_CHANGED,
    slot
  )

  return true
end

function TeamSetupService:GetSlot(slot)
  slot = tonumber(slot)

  if not slot
      or slot < 1
      or slot > 3 then
    return nil
  end

  return self.Slots[slot]
end

function TeamSetupService:GetSlots()
  return self.Slots
end

function TeamSetupService:ClearSlot(slot)
  slot = tonumber(slot)

  if not slot
      or slot < 1
      or slot > 3 then
    return false
  end

  self.Slots[slot] = nil

  return true
end

function TeamSetupService:ClearSlots()
  wipe(self.Slots)
end

function TeamSetupService:SetTargetNPC(npcID)
  wipe(self.TargetNPCIDs)

  npcID = tonumber(npcID)

  if not npcID then
    return false
  end

  self.TargetNPCIDs[1] = npcID

  addon.EventBus:Fire(
    addon.Events.TEAM_SETUP_TARGET_CHANGED
  )


  return true
end

function TeamSetupService:SetTargetNPCIDs(npcIDs)
  wipe(self.TargetNPCIDs)

  if type(npcIDs) == "table" then
    for _, npcID in ipairs(npcIDs) do
      npcID = tonumber(npcID)

      if npcID then
        self.TargetNPCIDs[#self.TargetNPCIDs + 1] = npcID
      end
    end
  end

  addon.EventBus:Fire(
    addon.Events.TEAM_SETUP_TARGET_CHANGED
  )
end

function TeamSetupService:GetTargetNPCID()
  return self.TargetNPCIDs[1]
end

function TeamSetupService:GetTargetNPCIDs()
  return self.TargetNPCIDs
end

function TeamSetupService:ClearTargetNPC()
  wipe(self.TargetNPCIDs)
  addon.EventBus:Fire(
    addon.Events.TEAM_SETUP_TARGET_CHANGED
  )
end

function TeamSetupService:IsTargetDifferent(targetNPCIDs)
  targetNPCIDs = type(targetNPCIDs) == "table"
      and targetNPCIDs or {}

  if #self.TargetNPCIDs ~= #targetNPCIDs then
    return true
  end

  for index, npcID in ipairs(self.TargetNPCIDs) do
    if npcID ~= tonumber(targetNPCIDs[index]) then
      return true
    end
  end

  return false
end

addon.Services.TeamSetup = TeamSetupService
