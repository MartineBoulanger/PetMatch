local addonName, addon = ...

local Tag = {}

setmetatable(
  Tag,
  {
    __index = addon.Models.Base
  }
)

function Tag:Create(name)
  local tag =
      addon.Models.Base:New()
  tag.name = name
  tag.color = nil
  tag.icon = nil
  return tag
end

addon.Models.Tag = Tag
