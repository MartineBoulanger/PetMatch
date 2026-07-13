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
  folder.name =
      name or "New Folder"
  folder.parentID = nil
  folder.order = 0
  return folder
end

addon.Models.Folder = Folder
