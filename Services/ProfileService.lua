local _, addon = ...

local ProfileService = {}

function ProfileService:GetCurrent()
  return addon.Profiles:GetCurrentProfile()
end

function ProfileService:GetSetting(key)
  local profile = self:GetCurrent()
  return profile.settings[key]
end

function ProfileService:SetSetting(key, value)
  local profile = self:GetCurrent()
  profile.settings[key] = value
  addon.EventBus:Fire(
    addon.Events.SETTINGS_CHANGED,
    key,
    value
  )
end

addon.Services.Profile = ProfileService
