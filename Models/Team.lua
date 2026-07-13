local addonName, addon = ...

local Team = {}

setmetatable(
  Team,
  {
    __index = addon.Models.Base
  }
)

function Team:Create(name)
  local team =
      addon.Models.Base:New()
  team.name = name
  team.description = ""
  team.icon = nil
  team.folder = nil
  team.tags = {}
  team.pets = {}
  team.favorite = false
  team.notes = ""
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
