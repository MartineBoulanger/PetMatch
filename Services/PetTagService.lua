local _, addon = ...

addon.Services = addon.Services or {}

local PetTagService = {}

PetTagService.Tags = {
  {
    id = 1,
    name = "Star",
  },
  {
    id = 2,
    name = "Circle",
  },
  {
    id = 3,
    name = "Diamond",
  },
  {
    id = 4,
    name = "Triangle",
  },
  {
    id = 5,
    name = "Moon",
  },
  {
    id = 6,
    name = "Square",
  },
  {
    id = 7,
    name = "Cross",
  },
  {
    id = 8,
    name = "Skull",
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

function PetTagService:SetTag(petGUID,tagID)
  if type(petGUID) ~= "string" or petGUID == "" then
    return false, "Invalid pet GUID"
  end

  tagID = tonumber(tagID)

  if not self:GetDefinition(tagID) then
    return false, "Invalid pet tag"
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
