local addonName, addon = ...

local Team = {}

setmetatable(
  Team,
  {
    __index = addon.Models.Base
  }
)

function Team:Create(name)
  local team = addon.Models.Base:New()
  team.name = name or "New Team"
  team.description = ""
  team.icon = nil
  team.folderID = nil
  team.tags = {}
  team.pets = {
    [1] = nil,
    [2] = nil,
    [3] = nil,
  }
  team.abilities = {
    [1] = nil,
    [2] = nil,
    [3] = nil,
  }
  team.breeds = {}
  team.specialSlots = {}
  team.targetNPCIDs = {}
  team.createdBy = "PetMatch"
  team.strategy = ""
  team.difficulty = nil
  team.favorite = false
  team.notes = ""
  team.scripts = ""
  team.importSource = nil
  return team
end

function Team:AddPet(pet)
  if #self.pets >= 3 then
    return false
  end
  table.insert(
    self.pets,
    pet
  )
  self:Touch()
  return true
end

function Team:SetName(name)
  self.name = name
  self:Touch()
end

addon.Models.Team = Team
