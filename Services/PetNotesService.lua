local _, addon = ...

addon.Services = addon.Services or {}

local PetNotesService = {}

local function GetNotesStorage()
  local profile = addon.Profiles:GetCurrentProfile()

  if not profile then
    return nil
  end

  profile.petNotes = profile.petNotes or {}
  profile.petNotes.species = profile.petNotes.species or {}
  profile.petNotes.pets = profile.petNotes.pets or {}

  return profile.petNotes
end

local function IsValidPetGUID(petGUID)
  return type(petGUID) == "string" and petGUID ~= ""
end

local function NormalizeSpeciesID(speciesID)
  speciesID = tonumber(speciesID)

  if not speciesID or speciesID <= 0
      or speciesID % 1 ~= 0 then
    return nil
  end

  return speciesID
end

function PetNotesService:GetPetNote(petGUID)
  if not IsValidPetGUID(petGUID) then
    return nil
  end

  local storage = GetNotesStorage()

  return storage and storage.pets[petGUID] or nil
end

function PetNotesService:SetPetNote(petGUID, note)
  if not IsValidPetGUID(petGUID) or type(note) ~= "string" then
    return false
  end

  local storage = GetNotesStorage()

  if not storage then
    return false
  end

  storage.pets[petGUID] = note ~= "" and note or nil

  return true
end

function PetNotesService:DeletePetNote(petGUID)
  if not IsValidPetGUID(petGUID) then
    return false
  end

  local storage = GetNotesStorage()

  if not storage then
    return false
  end

  storage.pets[petGUID] = nil

  return true
end

function PetNotesService:HasPetNote(petGUID)
  local note = self:GetPetNote(petGUID)

  return type(note) == "string" and note ~= ""
end

function PetNotesService:GetSpeciesNote(speciesID)
  speciesID = NormalizeSpeciesID(speciesID)

  if not speciesID then
    return nil
  end

  local storage = GetNotesStorage()

  return storage and storage.species[speciesID] or nil
end

function PetNotesService:SetSpeciesNote(speciesID, note)
  speciesID = NormalizeSpeciesID(speciesID)

  if not speciesID or type(note) ~= "string" then
    return false
  end

  local storage = GetNotesStorage()

  if not storage then
    return false
  end

  storage.species[speciesID] = note ~= "" and note or nil

  return true
end

function PetNotesService:DeleteSpeciesNote(speciesID)
  speciesID = NormalizeSpeciesID(speciesID)

  if not speciesID then
    return false
  end

  local storage = GetNotesStorage()

  if not storage then
    return false
  end

  storage.species[speciesID] = nil

  return true
end

function PetNotesService:HasSpeciesNote(speciesID)
  local note = self:GetSpeciesNote(speciesID)

  return type(note) == "string" and note ~= ""
end

function PetNotesService:GetOwnedSpeciesCount(speciesID)
  speciesID = NormalizeSpeciesID(speciesID)

  if not speciesID then
    return 0
  end

  local petJournal = addon.Services.PetJournal

  if not petJournal then
    return 0
  end

  -- Ensure the pet cache is initialized.
  petJournal:EnsureIndex()

  local pets = petJournal:GetAll()

  if type(pets) ~= "table" then
    return 0
  end

  local count = 0

  for petGUID, pet in pairs(pets) do
    if type(petGUID) == "string"
        and petGUID ~= ""
        and type(pet) == "table"
        and tonumber(pet.speciesID) == speciesID then
      count = count + 1
    end
  end

  return count
end

function PetNotesService:HasDuplicates(speciesID)
  return self:GetOwnedSpeciesCount(speciesID) > 1
end

addon.Services.PetNotes = PetNotesService
