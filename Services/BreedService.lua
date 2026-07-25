local _, addon = ...

local BreedService = {}

BreedService.Cache = {}

local INVALID_BREEDS = {
  ["???"] = true,
  ["NEW"] = true,
  ["ERR-PID"] = true,
}

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

function BreedService:IsAvailable()
  return type(_G.GetBreedID_Journal) == "function"
end

function BreedService:GetJournalBreed(petGUID)
  if type(petGUID) ~= "string"
      or petGUID == "" then
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

  if not success
      or IsInvalidBreed(breed) then
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

function BreedService:SetJournalNameDisplayEnabled(
    enabled
)
  if not self:IsAvailable() then
    return false
  end

  if type(_G.BPBID_Options) ~= "table" then
    return false
  end

  _G.BPBID_Options.Names =
      _G.BPBID_Options.Names or {}

  _G.BPBID_Options.Names.HSFUpdate =
      enabled == true

  return true
end

addon.Services.Breed = BreedService
