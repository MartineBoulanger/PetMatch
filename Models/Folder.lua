local addonName, addon = ...

local Folder = {}

setmetatable(
  Folder,
  {
    __index = addon.Models.Base
  }
)

function Folder:Create(name)
  local folder =
      addon.Models.Base:New()
  folder.name = name
  folder.parent = nil
  folder.children = {}
  folder.teams = {}
  return folder
end

addon.Models.Folder = Folder
