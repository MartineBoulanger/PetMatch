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
-- Clear
--------------------------------------------------
function LevellingQueueService:Clear()
  local data = EnsureData()

  if not data then
    return 0
  end

  local queue = data.pets
  local removed = #queue

  if removed == 0 then
    return 0
  end

  --------------------------------------------------
  -- Report the pets from the back, so every index
  -- is still valid while the queue drains.
  --------------------------------------------------
  for index = removed, 1, -1 do
    local petGUID = queue[index]

    queue[index] = nil

    addon.EventBus:Fire(
      addon.Events.LEVELLING_QUEUE_PET_REMOVED,
      petGUID,
      index
    )
  end

  FireChanged()

  return removed
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
-- Sort
--------------------------------------------------
function LevellingQueueService:Sort(sortMode)
  local queue = self:GetAll()

  if #queue < 2 then
    return false
  end

  sortMode = sortMode or "levelHigh"

  --------------------------------------------------
  -- Cache pet information before sorting.
  --
  -- table.sort can call the comparator many times,
  -- so don't repeatedly query the Pet Journal.
  --------------------------------------------------
  local pets = {}
  local originalIndex = {}

  for index, petGUID in ipairs(queue) do
    pets[petGUID] = GetPetInfo(petGUID)
    originalIndex[petGUID] = index
  end

  local function GetValue(petGUID, field)
    local pet = pets[petGUID]

    if not pet then
      return 0
    end

    return tonumber(pet[field]) or 0
  end

  table.sort(
    queue,
    function(leftGUID, rightGUID)
      local leftValue
      local rightValue

      ------------------------------------------------
      -- Level
      ------------------------------------------------
      if sortMode == "levelHigh" then
        leftValue = GetValue(leftGUID, "level")
        rightValue = GetValue(rightGUID, "level")

        if leftValue ~= rightValue then
          return leftValue > rightValue
        end
      elseif sortMode == "levelLow" then
        leftValue = GetValue(leftGUID, "level")
        rightValue = GetValue(rightGUID, "level")

        if leftValue ~= rightValue then
          return leftValue < rightValue
        end

        ------------------------------------------------
        -- Rarity
        ------------------------------------------------
      elseif sortMode == "rarityHigh" then
        leftValue = GetValue(leftGUID, "quality")
        rightValue = GetValue(rightGUID, "quality")

        if leftValue ~= rightValue then
          return leftValue > rightValue
        end
      elseif sortMode == "rarityLow" then
        leftValue = GetValue(leftGUID, "quality")
        rightValue = GetValue(rightGUID, "quality")

        if leftValue ~= rightValue then
          return leftValue < rightValue
        end

        ------------------------------------------------
        -- Pet type
        ------------------------------------------------
      elseif sortMode == "petType" then
        leftValue = GetValue(leftGUID, "petType")
        rightValue = GetValue(rightGUID, "petType")

        if leftValue ~= rightValue then
          return leftValue < rightValue
        end
      end

      ------------------------------------------------
      -- Keep the existing relative order whenever
      -- the selected sort value is equal.
      ------------------------------------------------
      return
          (originalIndex[leftGUID] or 0) < (originalIndex[rightGUID] or 0)
    end
  )

  FireChanged()

  return true
end

--------------------------------------------------
-- Fill
--------------------------------------------------
local function GetLevellingProgress(pet)
  local level = tonumber(pet.level) or 0
  local xp = tonumber(pet.xp) or 0
  local maxXP = tonumber(pet.maxXP) or 0

  local fraction = 0

  if maxXP > 0 then
    fraction =
        math.max(
          0,
          math.min(
            1,
            xp / maxXP
          )
        )
  end

  return level + fraction
end

function LevellingQueueService:GetFillCandidates()
  local petService =
      addon.Services.PetJournal

  if not petService then
    return {}
  end

  petService:EnsureIndex()

  local cache = petService:GetAll()

  if type(cache) ~= "table" then
    return {}
  end

  --------------------------------------------------
  -- Look the queue up once instead of scanning it
  -- again for every owned pet.
  --------------------------------------------------
  local queued = {}

  for _, queuedGUID in ipairs(
    self:GetAll()
  ) do
    queued[queuedGUID] = true
  end

  local candidates = {}

  for petGUID, cachedPet in pairs(cache) do
    if type(cachedPet) == "table"
        and queued[petGUID] ~= true
        and CanBeLevelled(cachedPet) then
      --------------------------------------------------
      -- The cache has no experience, so read the
      -- full pet for the pets that qualify.
      --------------------------------------------------
      local pet = GetPetInfo(petGUID)

      if pet
          and CanBeLevelled(pet) then
        candidates[#candidates + 1] = {
          petGUID = petGUID,
          pet = pet,
          progress = GetLevellingProgress(pet),
          quality = tonumber(cachedPet.quality) or 0,
          name = pet.name or "",
        }
      end
    end
  end

  table.sort(
    candidates,

    function(left, right)
      if left.progress ~= right.progress then
        return left.progress > right.progress
      end

      if left.quality ~= right.quality then
        return left.quality > right.quality
      end

      if left.name ~= right.name then
        return left.name < right.name
      end

      --------------------------------------------------
      -- Keeps the order stable for identical pets.
      --------------------------------------------------
      return left.petGUID < right.petGUID
    end
  )

  return candidates
end

function LevellingQueueService:HasFillCandidates()
  local petService =
      addon.Services.PetJournal

  if not petService then
    return false
  end

  local cache = petService:GetAll()

  if type(cache) ~= "table" then
    return false
  end

  local queued = {}

  for _, queuedGUID in ipairs(
    self:GetAll()
  ) do
    queued[queuedGUID] = true
  end

  for petGUID, cachedPet in pairs(cache) do
    if type(cachedPet) == "table"
        and queued[petGUID] ~= true
        and CanBeLevelled(cachedPet) then
      return true
    end
  end

  return false
end

function LevellingQueueService:Fill(candidates)
  local data = EnsureData()

  if not data then
    return 0
  end

  candidates =
      type(candidates) == "table"
      and candidates
      or self:GetFillCandidates()

  if #candidates == 0 then
    return 0
  end

  local queue = data.pets
  local added = 0

  --------------------------------------------------
  -- The candidates may be a few seconds old, so
  -- check them against the queue and the cache
  -- one more time.
  --------------------------------------------------
  local queued = {}

  for _, queuedGUID in ipairs(queue) do
    queued[queuedGUID] = true
  end

  local cache =
      addon.Services.PetJournal
      and addon.Services.PetJournal:GetAll()

  local function IsStillEligible(candidate)
    local petGUID = candidate.petGUID

    if not petGUID
        or queued[petGUID] == true then
      return false
    end

    if type(cache) == "table" then
      return CanBeLevelled(
        cache[petGUID]
      )
    end

    return CanBeLevelled(
      candidate.pet
    )
  end

  for _, candidate in ipairs(candidates) do
    local petGUID = candidate.petGUID

    if IsStillEligible(candidate) then
      queued[petGUID] = true

      queue[#queue + 1] = petGUID
      added = added + 1

      addon.EventBus:Fire(
        addon.Events.LEVELLING_QUEUE_PET_ADDED,
        petGUID,
        #queue
      )
    end
  end

  if added > 0 then
    FireChanged()
  end

  return added
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
