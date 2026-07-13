local addonName, addon = ...

local Settings = {}

local DEFAULT_SETTINGS = {
  theme = "Dark",
  scale = 1,
  debug = false,
  showTooltips = true,
  animations = true,
}

function Settings:Initialize()
  local profile =
      addon.Profiles:GetCurrentProfile()
  for key, value in pairs(DEFAULT_SETTINGS) do
    if profile.settings[key] == nil then
      profile.settings[key] = value
    end
  end
end

function Settings:Get(key)
  local profile =
      addon.Profiles:GetCurrentProfile()
  return profile.settings[key]
end

function Settings:Set(key, value)
  local profile =
      addon.Profiles:GetCurrentProfile()
  profile.settings[key] = value
  addon.EventBus:Fire(
    addon.Events.SETTINGS_CHANGED,
    key,
    value
  )
end

addon.Settings = Settings

addon.ModuleManager:Register(
  "Settings",
  Settings
)

addon.Logger:Info(
  "Settings initialized"
)
