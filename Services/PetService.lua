local _, addon = ...

local PetService = {}

function PetService:Create(data)
  return addon.Models.Pet:Create(data)
end

function PetService:GetProfilePets()
  local profile = addon.Profiles:GetCurrentProfile()
  if not profile.pets then
    profile.pets = {}
  end
  return profile.pets
end

function PetService:Add(pet)
  local pets = self:GetProfilePets()
  table.insert(
    pets,
    pet
  )
  addon.EventBus:Fire(
    addon.Events.PET_SELECTED,
    pet
  )
end

addon.Services.Pet = PetService
