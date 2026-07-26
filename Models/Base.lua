local _, addon = ...

addon.Models = addon.Models or {}
local Base = {}

function Base:New(data)
  local object = {}
  setmetatable(
    object,
    {
      __index = self
    }
  )
  object.id = addon.Utils:GenerateID()
  object.created = time()
  object.modified = time()
  if data then
    for key, value in pairs(data) do
      object[key] = value
    end
  end
  return object
end

function Base:Touch()
  self.modified = time()
end

addon.Models.Base = Base
