local addonName, addon = ...

local Pet = {}

setmetatable(
  Pet,
  {
    __index = addon.Models.Base
  }
)

function Pet:Create(data)
  local pet =
      addon.Models.Base:New(data)
  pet.speciesID = data.speciesID
  pet.petGUID = data.petGUID
  pet.level = data.level or 1
  pet.quality = data.quality
  pet.breed = data.breed
  pet.abilities = data.abilities or {}
  return pet
end

addon.Models.Pet = Pet
