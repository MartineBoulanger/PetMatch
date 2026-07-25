local _, addon = ...

local Profiles = {}

local DEFAULT_PROFILE = {
  name = "Default",
  created = 0,
  teams = {},
  tags = {},
  favorites = {},
  settings = {},
  folders = {},
  activeTeam = nil,
}

function Profiles:GetCurrentProfile()
  local profileName =
      addon.DB.profileKeys[UnitGUID("player")]
  if not profileName then
    profileName = "Default"
    addon.DB.profileKeys[
    UnitGUID("player")
    ] = profileName
  end
  if not addon.DB.profiles[profileName] then
    addon.DB.profiles[profileName] =
        addon.Utils:DeepCopy(
          DEFAULT_PROFILE
        )
    addon.DB.profiles[profileName].created =
        time()
  end
  return addon.DB.profiles[profileName]
end

function Profiles:Create(name)
  if addon.DB.profiles[name] then
    return false
  end
  addon.DB.profiles[name] =
      addon.Utils:DeepCopy(
        DEFAULT_PROFILE
      )
  addon.DB.profiles[name].name =
      name
  addon.Events:Fire(
    addon.Events.PROFILE_CHANGED,
    name
  )
  return true
end

function Profiles:Delete(name)
  if name == "Default" then
    return false
  end
  addon.DB.profiles[name] = nil
  return true
end

addon.Profiles = Profiles

addon.ModuleManager:Register(
  "Profiles",
  Profiles
)
