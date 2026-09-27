local _, addon = ...

local HiddenPetService = {}

local function GetProfile()
  return addon.Profiles:GetCurrentProfile()
end

local function GetHiddenPetStorage()
  local profile = GetProfile()

  profile.hiddenPets = profile.hiddenPets or {}

  return profile.hiddenPets
end

local function GetHiddenSpeciesStorage()
  local profile = GetProfile()
  profile.hiddenSpecies = profile.hiddenSpecies or {}
  return profile.hiddenSpecies
end

function HiddenPetService:IsSpeciesHidden(speciesID)
  speciesID = tonumber(speciesID)

  if not speciesID then
    return false
  end

  local hiddenSpecies = GetHiddenSpeciesStorage()

  return hiddenSpecies[speciesID] == true
end

function HiddenPetService:HideSpecies(speciesID)
  speciesID = tonumber(speciesID)

  if not speciesID then
    return false
  end

  local hiddenSpecies = GetHiddenSpeciesStorage()

  hiddenSpecies[speciesID] = true

  return true
end

function HiddenPetService:UnhideSpecies(speciesID)
  speciesID = tonumber(speciesID)

  if not speciesID then
    return false
  end

  local hiddenSpecies = GetHiddenSpeciesStorage()

  hiddenSpecies[speciesID] = nil

  return true
end

function HiddenPetService:IsHidden(petGUID)
  if type(petGUID) ~= "string" or petGUID == "" then
    return false
  end

  local hiddenPets = GetHiddenPetStorage()

  return hiddenPets[petGUID] == true
end

function HiddenPetService:Hide(petGUID)
  if type(petGUID) ~= "string" or petGUID == "" then
    return false
  end

  local hiddenPets = GetHiddenPetStorage()

  hiddenPets[petGUID] = true

  return true
end

function HiddenPetService:Unhide(petGUID)
  if type(petGUID) ~= "string" or petGUID == "" then
    return false
  end

  local hiddenPets = GetHiddenPetStorage()

  hiddenPets[petGUID] = nil

  return true
end

function HiddenPetService:SetHidden(petGUID, hidden)
  if hidden then
    return self:Hide(petGUID)
  end

  return self:Unhide(petGUID)
end

addon.Services.HiddenPet = HiddenPetService
