local _, addon = ...

addon.Profiles = addon.Profiles or {}

local Profiles = {}

local DEFAULT_PROFILE_NAME = "Default"

local DEFAULT_PROFILE = {
  name = DEFAULT_PROFILE_NAME,
  created = 0,
  teams = {},
  tags = {},
  favorites = {},
  settings = {},
  folders = {},
  activeTeam = nil,
  levellingQueue = {
    pets = {},
    knownPets = {},
    initialized = false,
  },
}

--------------------------------------------------
-- Helpers
--------------------------------------------------
local function GetCharacterKey()
  return UnitGUID("player")
end

local function GetProfilesTable()
  return addon.DB.profiles
end

local function CreateProfileData(name)
  local profile = addon.Utils:DeepCopy(DEFAULT_PROFILE)

  profile.name = name
  profile.created = time()

  return profile
end

local function EnsureDefaultProfile()
  local profiles = GetProfilesTable()

  if not profiles[DEFAULT_PROFILE_NAME] then
    profiles[DEFAULT_PROFILE_NAME] =
        CreateProfileData(DEFAULT_PROFILE_NAME)
  end

  return profiles[DEFAULT_PROFILE_NAME]
end

local function IsValidName(name)
  return type(name) == "string"
      and addon.Utils:Trim(name) ~= ""
end

--------------------------------------------------
-- Current profile
--------------------------------------------------
function Profiles:GetCurrentProfileName()
  EnsureDefaultProfile()

  local characterKey = GetCharacterKey()

  if not characterKey then
    return DEFAULT_PROFILE_NAME
  end

  local profileName = addon.DB.profileKeys[characterKey]

  if not profileName or not GetProfilesTable()[profileName] then
    profileName = DEFAULT_PROFILE_NAME
    addon.DB.profileKeys[characterKey] = profileName
  end

  return profileName
end

function Profiles:GetCurrentProfile()
  local profileName = self:GetCurrentProfileName()

  return GetProfilesTable()[profileName]
end

--------------------------------------------------
-- Get available profiles
--------------------------------------------------
function Profiles:GetProfiles()
  EnsureDefaultProfile()

  local profiles = {}

  for name in pairs(GetProfilesTable()) do
    profiles[#profiles + 1] = name
  end

  table.sort(profiles, function(a, b)
    if a == DEFAULT_PROFILE_NAME then
      return true
    end

    if b == DEFAULT_PROFILE_NAME then
      return false
    end

    return a:lower() < b:lower()
  end)

  return profiles
end

function Profiles:GetProfile(name)
  if not IsValidName(name) then
    return nil
  end

  return GetProfilesTable()[name]
end

--------------------------------------------------
-- Create profile
--------------------------------------------------
function Profiles:Create(name)
  if not IsValidName(name) then
    return false
  end

  name = addon.Utils:Trim(name)

  if GetProfilesTable()[name] then
    return false
  end

  GetProfilesTable()[name] = CreateProfileData(name)

  return true
end

--------------------------------------------------
-- Rename profile
--------------------------------------------------
function Profiles:Rename(oldName, newName)
  if not IsValidName(oldName) or not IsValidName(newName) then
    return false
  end

  newName = addon.Utils:Trim(newName)

  if oldName == DEFAULT_PROFILE_NAME then
    return false
  end

  local profiles = GetProfilesTable()
  local profile = profiles[oldName]

  if not profile or profiles[newName] then
    return false
  end

  if oldName == newName then
    return true
  end

  local currentProfileName = self:GetCurrentProfileName()
  local isCurrentProfile = currentProfileName == oldName

  -- Rename the profile without changing its data.
  profiles[newName] = profile
  profiles[oldName] = nil

  profile.name = newName

  -- Update all character references.
  for characterKey, profileName in pairs(addon.DB.profileKeys) do
    if profileName == oldName then
      addon.DB.profileKeys[characterKey] = newName
    end
  end

  -- Keep the loaded team associated with the renamed profile.
  local teamService = addon.Services.Team

  if teamService and teamService.LoadedTeam then
    if teamService.LoadedTeam.profileName == oldName then
      teamService.LoadedTeam.profileName = newName
    end
  end

  -- Notify other modules when the current profile was renamed.
  if isCurrentProfile then
    addon.EventBus:Fire(
      addon.Events.PROFILE_CHANGED,
      newName,
      oldName
    )
  end

  return true
end

--------------------------------------------------
-- Delete profile
--------------------------------------------------
function Profiles:Delete(name)
  if not IsValidName(name) or name == DEFAULT_PROFILE_NAME then
    return false
  end

  local profiles = GetProfilesTable()

  if not profiles[name] then
    return false
  end

  local currentProfileName = self:GetCurrentProfileName()
  local isCurrentProfile = currentProfileName == name

  -- Update all character references.
  for characterKey, profileName in pairs(addon.DB.profileKeys) do
    if profileName == name then
      addon.DB.profileKeys[characterKey] = DEFAULT_PROFILE_NAME
    end
  end

  -- Clear the loaded team reference if it belongs to this profile.
  local teamService = addon.Services.Team

  if teamService and teamService.LoadedTeam then
    if teamService.LoadedTeam.profileName == name then
      teamService.LoadedTeam = nil
    end
  end

  -- Remove the profile.
  profiles[name] = nil

  -- Notify other modules if the current profile was deleted.
  if isCurrentProfile then
    addon.EventBus:Fire(
      addon.Events.PROFILE_CHANGED,
      DEFAULT_PROFILE_NAME,
      name
    )
  end

  return true
end

--------------------------------------------------
-- Copy profile data
--------------------------------------------------
function Profiles:CopyFrom(sourceName, targetName)
  if not IsValidName(sourceName) or not IsValidName(targetName) then
    return false
  end

  if sourceName == targetName then
    return false
  end

  local profiles = GetProfilesTable()
  local source = profiles[sourceName]
  local target = profiles[targetName]

  if not source or not target then
    return false
  end

  -- Create an independent copy of the source data.
  local copied = addon.Utils:DeepCopy(source)

  -- Preserve the target profile identity.
  copied.name = targetName
  copied.created = target.created

  -- Do not retain the source profile's active team.
  copied.activeTeam = nil

  -- Replace all existing target data.
  profiles[targetName] = copied

  -- Clear runtime references to the overwritten profile.
  local teamService = addon.Services.Team

  if teamService and teamService.LoadedTeam
      and teamService.LoadedTeam.profileName == targetName then
    teamService.LoadedTeam = nil
  end

  -- Refresh modules if the target is the current profile.
  if self:GetCurrentProfileName() == targetName then
    addon.EventBus:Fire(
      addon.Events.PROFILE_CHANGED, targetName, targetName
    )
  end

  return true
end

--------------------------------------------------
-- Switch profile
--------------------------------------------------
function Profiles:SetCurrentProfile(name)
  if not IsValidName(name) then
    return false
  end

  local profiles = GetProfilesTable()

  if not profiles[name] then
    return false
  end

  local characterKey = GetCharacterKey()

  if not characterKey then
    return false
  end

  local oldProfileName = self:GetCurrentProfileName()

  if oldProfileName == name then
    return true
  end

  addon.DB.profileKeys[characterKey] = name

  addon.EventBus:Fire(
    addon.Events.PROFILE_CHANGED,
    name,
    oldProfileName
  )

  return true
end

addon.Profiles = Profiles

addon.ModuleManager:Register(
  "Profiles",
  Profiles
)
