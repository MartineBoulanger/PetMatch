local _, addon = ...

local Pet = {}

setmetatable(
  Pet,
  {
    __index = addon.Models.Base
  }
)

function Pet:Create(data)
  local pet = addon.Models.Base:New(data)
  pet.speciesID = data.speciesID
  pet.petGUID = data.petGUID
  pet.level = data.level or 1
  pet.quality = data.quality or 0
  pet.breedID = data.breedID
  pet.breedName = data.breedName
  pet.abilities = data.abilities or {}
  pet.name = data.name or "Unknown"
  pet.customName = data.customName
  pet.speciesName = data.speciesName
  pet.icon = data.icon
  pet.favorite = data.favorite == true
  pet.canBattle = data.canBattle == true
  pet.petType = data.petType
  pet.creatureID = data.creatureID
  pet.displayID = data.displayID
  pet.description = data.description
  pet.sourceText = data.sourceText
  pet.expansionID = data.expansionID
  pet.expansionName = data.expansionName
  pet.health = data.health or 0
  pet.maxHealth = data.maxHealth or data.health
  pet.power = data.power or 0
  pet.speed = data.speed or 0
  pet.passive = data.passive
  return pet
end

addon.Models.Pet = Pet
