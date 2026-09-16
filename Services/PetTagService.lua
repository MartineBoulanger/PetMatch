local _, addon = ...

addon.Services = addon.Services or {}

local L = addon.L

local PetTagService = {}

PetTagService.Tags = {
  {
    id = 1,
    name = L["TAG_STAR"],
  },
  {
    id = 2,
    name = L["TAG_CIRCLE"],
  },
  {
    id = 3,
    name = L["TAG_DIAMOND"],
  },
  {
    id = 4,
    name = L["TAG_TRIANGLE"],
  },
  {
    id = 5,
    name = L["TAG_MOON"],
  },
  {
    id = 6,
    name = L["TAG_SQUARE"],
  },
  {
    id = 7,
    name = L["TAG_CROSS"],
  },
  {
    id = 8,
    name = L["TAG_SKULL"],
  },
}

local function GetProfile()
  return addon.Profiles:GetCurrentProfile()
end

local function GetTagStorage()
  local profile = GetProfile()

  profile.tags = profile.tags or {}

  return profile.tags
end

function PetTagService:GetDefinitions()
  return self.Tags
end

function PetTagService:GetDefinition(tagID)
  tagID = tonumber(tagID)

  if not tagID then
    return nil
  end

  for _, definition in ipairs(self.Tags) do
    if definition.id == tagID then
      return definition
    end
  end

  return nil
end

function PetTagService:GetTag(petGUID)
  if type(petGUID) ~= "string"
      or petGUID == "" then
    return nil
  end

  local tags = GetTagStorage()
  local tagID = tonumber(tags[petGUID])

  if not self:GetDefinition(tagID) then
    return nil
  end

  return tagID
end

function PetTagService:GetTagDefinition(petGUID)
  local tagID = self:GetTag(petGUID)

  return self:GetDefinition(tagID)
end

function PetTagService:SetTag(petGUID, tagID)
  if type(petGUID) ~= "string" or petGUID == "" then
    return false, L["INVALID_GUID"]
  end

  tagID = tonumber(tagID)

  if not self:GetDefinition(tagID) then
    return false, L["INVALID_TAG"]
  end

  local tags = GetTagStorage()

  tags[petGUID] = tagID

  return true
end

function PetTagService:ClearTag(petGUID)
  if type(petGUID) ~= "string"
      or petGUID == "" then
    return false
  end

  local tags = GetTagStorage()

  tags[petGUID] = nil

  return true
end

function PetTagService:HasTag(
    petGUID,
    tagID
)
  return self:GetTag(petGUID)
      == tonumber(tagID)
end

addon.Services.PetTag = PetTagService
