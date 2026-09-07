local _, addon = ...

addon.Services = addon.Services or {}

local BreedService = {}

BreedService.Cache = {}

local INVALID_BREEDS = {
  ["???"] = true,
  ["NEW"] = true,
  ["ERR-PID"] = true,
}

local BREED_NAMES = {
  [3] = "B/B",
  [4] = "P/P",
  [5] = "S/S",
  [6] = "H/H",
  [7] = "H/P",
  [8] = "P/S",
  [9] = "H/S",
  [10] = "P/B",
  [11] = "S/B",
  [12] = "H/B",
}

local BREED_IDS = {}
for breedID, breedName in pairs(BREED_NAMES) do
  BREED_IDS[breedName] = breedID
end

local function IsInvalidBreed(breed)
  if breed == nil then
    return true
  end

  breed = tostring(breed)

  if INVALID_BREEDS[breed] then
    return true
  end

  return string.sub(breed, 1, 3) == "ERR"
end

function BreedService:GetBreedID(breedName)
  if type(breedName) ~= "string" or breedName == "" then
    return nil
  end

  return BREED_IDS[breedName]
end

function BreedService:GetJournalBreedID(petGUID)
  local breedName = self:GetJournalBreed(petGUID)

  if not breedName then
    return nil
  end

  return self:GetBreedID(breedName)
end

function BreedService:GetBreedName(breedID)
  return BREED_NAMES[tonumber(breedID)]
end

function BreedService:GetPossibleBreeds(
    speciesID
)
  speciesID = tonumber(speciesID)

  if not speciesID then
    return {}
  end

  local arrays = _G.BPBID_Arrays

  if type(arrays) ~= "table" then
    return {}
  end

  if not arrays.BreedsPerSpecies
      and type(arrays.InitializeArrays)
      == "function" then
    pcall(
      arrays.InitializeArrays
    )
  end

  local breedIDs =
      arrays.BreedsPerSpecies
      and arrays.BreedsPerSpecies[
      speciesID
      ]

  if type(breedIDs) ~= "table" then
    return {}
  end

  local breeds = {}

  for _, breedID in ipairs(breedIDs) do
    local name =
        self:GetBreedName(
          breedID
        )

    if name then
      breeds[#breeds + 1] = {
        id = breedID,
        name = name,
      }
    end
  end

  return breeds
end

function BreedService:IsAvailable()
  return type(_G.GetBreedID_Journal) == "function"
end

function BreedService:GetJournalBreed(petGUID)
  if type(petGUID) ~= "string" or petGUID == "" then
    return nil
  end

  if not self:IsAvailable() then
    return nil
  end

  if self.Cache[petGUID] ~= nil then
    return self.Cache[petGUID] or nil
  end

  local success, breed = pcall(
    _G.GetBreedID_Journal,
    petGUID
  )

  if not success or IsInvalidBreed(breed) then
    self.Cache[petGUID] = false
    return nil
  end

  breed = tostring(breed)

  self.Cache[petGUID] = breed

  return breed
end

function BreedService:ClearCache()
  wipe(self.Cache)
end

function BreedService:SetJournalNameDisplayEnabled(enabled)
  if not self:IsAvailable() then
    return false
  end

  if type(_G.BPBID_Options) ~= "table" then
    return false
  end

  _G.BPBID_Options.Names = _G.BPBID_Options.Names or {}
  _G.BPBID_Options.Names.HSFUpdate = enabled == true

  return true
end

addon.Services.Breed = BreedService
