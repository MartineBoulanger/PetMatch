local _, addon = ...

local LevellingQueueService = {}
LevellingQueueService.Initialized = false

local MAX_PET_LEVEL = 25

--------------------------------------------------
-- Profile
--------------------------------------------------
local function GetProfile()
  return addon.Profiles:GetCurrentProfile()
end

local function EnsureData()
  local profile = GetProfile()

  if not profile then
    return nil
  end

  profile.levellingQueue = profile.levellingQueue or {}
  profile.levellingQueue.pets = profile.levellingQueue.pets or {}
  profile.levellingQueue.knownPets = profile.levellingQueue.knownPets or {}

  if profile.levellingQueue.initialized == nil then
    profile.levellingQueue.initialized = false
  end

  return profile.levellingQueue
end

--------------------------------------------------
-- Pet information
--------------------------------------------------
local function GetPetInfo(petGUID)
  if type(petGUID) ~= "string"
      or petGUID == "" then
    return nil
  end

  local petService =
      addon.Services.PetJournal

  if not petService then
    return nil
  end

  local pet = petService:GetPet(petGUID)

  if not pet then
    return nil
  end

  return pet
end

local function CanBeLevelled(pet)
  if type(pet) ~= "table" then
    return false
  end

  if pet.canBattle ~= true then
    return false
  end

  local level = tonumber(pet.level)

  if not level then
    return false
  end

  return level < MAX_PET_LEVEL
end

--------------------------------------------------
-- Events
--------------------------------------------------
local function FireChanged()
  addon.EventBus:Fire(
    addon.Events.LEVELLING_QUEUE_CHANGED
  )
end

--------------------------------------------------
-- Get queue
--------------------------------------------------
function LevellingQueueService:GetAll()
  local data = EnsureData()

  if not data then
    return {}
  end

  return data.pets
end

function LevellingQueueService:GetCount()
  return #self:GetAll()
end

function LevellingQueueService:RemoveCompletedPets()
  local queue = self:GetAll()
  local changed = false

  for index = #queue, 1, -1 do
    local petGUID = queue[index]

    local pet = GetPetInfo(petGUID)

    if pet then
      local level =
          tonumber(
            pet.level
          )

      if level
          and level >= MAX_PET_LEVEL then
        table.remove(
          queue,
          index
        )

        addon.EventBus:Fire(
          addon.Events.LEVELLING_QUEUE_PET_REMOVED,
          petGUID,
          index
        )

        changed = true
      end
    end
  end

  if changed then
    FireChanged()
  end

  return changed
end

--------------------------------------------------
-- Find
--------------------------------------------------
function LevellingQueueService:GetIndex(petGUID)
  if not petGUID then
    return nil
  end

  for index, queuedGUID in ipairs(
    self:GetAll()
  ) do
    if queuedGUID == petGUID then
      return index
    end
  end

  return nil
end

function LevellingQueueService:Contains(petGUID)
  return self:GetIndex(petGUID) ~= nil
end

--------------------------------------------------
-- Validation
--------------------------------------------------
function LevellingQueueService:CanAdd(petGUID)
  if not petGUID then
    return false, "No pet was provided."
  end

  if self:Contains(petGUID) then
    return false, "This pet is already in the levelling queue."
  end

  local pet = GetPetInfo(petGUID)

  if not pet then
    return false, "The pet could not be found."
  end

  if pet.canBattle ~= true then
    return false, "This pet cannot battle."
  end

  local level = tonumber(pet.level)

  if not level then
    return false, "The pet level could not be determined."
  end

  if level >= MAX_PET_LEVEL then
    return false, "Only pets below level 25 can be added."
  end

  return true
end

--------------------------------------------------
-- Add
--------------------------------------------------
function LevellingQueueService:Add(petGUID)
  local allowed, errorMessage = self:CanAdd(petGUID)

  if not allowed then
    return false, errorMessage
  end

  local queue = self:GetAll()

  queue[#queue + 1] = petGUID

  addon.EventBus:Fire(
    addon.Events.LEVELLING_QUEUE_PET_ADDED,
    petGUID,
    #queue
  )

  FireChanged()

  return true
end

--------------------------------------------------
-- Remove
--------------------------------------------------
function LevellingQueueService:Remove(petGUID)
  local index = self:GetIndex(petGUID)

  if not index then
    return false
  end

  local queue = self:GetAll()

  table.remove(
    queue,
    index
  )

  addon.EventBus:Fire(
    addon.Events.LEVELLING_QUEUE_PET_REMOVED,
    petGUID,
    index
  )

  FireChanged()

  return true
end

--------------------------------------------------
-- Move
--------------------------------------------------
function LevellingQueueService:Move(petGUID, targetIndex)
  local queue = self:GetAll()
  local currentIndex = self:GetIndex(petGUID)

  if not currentIndex then
    return false
  end

  targetIndex =
      tonumber(
        targetIndex
      )

  if not targetIndex then
    return false
  end

  targetIndex = math.floor(targetIndex)
  targetIndex =
      math.max(
        1,
        math.min(
          #queue,
          targetIndex
        )
      )

  if currentIndex == targetIndex then
    return true
  end

  table.remove(
    queue,
    currentIndex
  )

  table.insert(
    queue,
    targetIndex,
    petGUID
  )

  addon.EventBus:Fire(
    addon.Events.LEVELLING_QUEUE_ORDER_CHANGED,
    petGUID,
    currentIndex,
    targetIndex
  )

  FireChanged()

  return true
end

function LevellingQueueService:MoveUp(petGUID)
  local index = self:GetIndex(petGUID)

  if not index or index <= 1 then
    return false
  end

  return self:Move(
    petGUID,
    index - 1
  )
end

function LevellingQueueService:MoveDown(petGUID)
  local queue = self:GetAll()
  local index = self:GetIndex(petGUID)

  if not index or index >= #queue then
    return false
  end

  return self:Move(
    petGUID,
    index + 1
  )
end

--------------------------------------------------
-- Next pet
--------------------------------------------------
function LevellingQueueService:GetNext()
  local queue = self:GetAll()
  return queue[1]
end

--------------------------------------------------
-- Get queue pets
--------------------------------------------------
function LevellingQueueService:GetPets()
  local result = {}

  for index, petGUID in ipairs(
    self:GetAll()
  ) do
    local pet = GetPetInfo(petGUID)

    if pet then
      result[#result + 1] = {
        index = index,
        petGUID = petGUID,
        pet = pet,
      }
    end
  end

  return result
end

--------------------------------------------------
-- Pet Journal updated
--------------------------------------------------
function LevellingQueueService:HandlePetJournalUpdated(cache)
  local data = EnsureData()

  if not data then
    return
  end

  cache = type(cache) == "table" and cache or addon.Services.PetJournal:GetAll()

  if type(cache) ~= "table" then
    return
  end

  --------------------------------------------------
  -- First scan:
  -- remember all existing pets, but do NOT add them.
  --------------------------------------------------

  if data.initialized ~= true then
    for petGUID in pairs(cache) do
      data.knownPets[petGUID] = true
    end
    data.initialized = true
    return
  end

  --------------------------------------------------
  -- Later scans:
  -- detect genuinely new pets.
  --------------------------------------------------

  local autoAdd = addon.Settings:Get("levellingQueueAutoAddMode") == "enabled"

  for petGUID, pet in pairs(cache) do
    local isNew = data.knownPets[petGUID] ~= true

    --------------------------------------------------
    -- Always mark it as known.
    --
    -- This is intentional even when auto-add
    -- is disabled.
    --------------------------------------------------

    data.knownPets[petGUID] = true

    if isNew
        and autoAdd
        and type(pet) == "table"
        and CanBeLevelled(pet)
        and not self:Contains(petGUID) then
      self:Add(petGUID)
    end
  end
end

--------------------------------------------------
-- Initialize
--------------------------------------------------
function LevellingQueueService:Initialize()
  if self.Initialized then
    return
  end

  self.Initialized = true

  addon.EventBus:Register(
    addon.Events.PET_JOURNAL_UPDATED,
    function(cache)
      self:RemoveCompletedPets()
      self:HandlePetJournalUpdated(cache)
    end
  )
end

--------------------------------------------------
-- Register
--------------------------------------------------
addon.Services.LevellingQueue = LevellingQueueService
