local _, addon = ...

addon.Database = addon.Database or {}
local Database = {}

local DEFAULT_DATABASE = {
  version = 1,
  global = {
    settings = {},
  },
  profiles = {
    Default = {
      teams = {},
      tags = {},
      favorites = {},
      settings = {},
    },
  },
  profileKeys = {},
  characters = {},
  cache = {},
}

local function CopyDefaults(source, target)
  for key, value in pairs(source) do
    if type(value) == "table" then
      if type(target[key]) ~= "table" then
        target[key] = {}
      end
      CopyDefaults(
        value,
        target[key]
      )
    elseif target[key] == nil then
      target[key] = value
    end
  end
end

function Database:Initialize()
  if not PetMatchDB then
    PetMatchDB = {}
  end
  CopyDefaults(
    DEFAULT_DATABASE,
    PetMatchDB
  )
  addon.DB = PetMatchDB
end

function Database:GetProfile()
  return addon.DB.profiles.Default
end

addon.Database = Database
