local _, addon = ...

addon.Settings = addon.Settings or {}
local Settings = {}

local DEFAULT_SETTINGS = {
  theme = "Dark",
  scale = 1,
  debug = false,
  showTooltips = true,
  animations = true,

  -- options panel list options
  duplicateTeamMode = "replace",
  showPetListBreed = true,
  petListBreedPosition = "right",
  compactPetListRows = false,
  teamCardHeightMode = "normal",
  petCardInteractionMode = "hover",
  petCardPetListEnabled = true,
  petCardTeamsEnabled = true,
  petCardLevellingQueueEnabled = true,
  levellingQueueAutoAddMode = "disabled",
  petTypeFilterDisplayMode = "both",
  summonedPetMode = "keep",
  restorePreviousSummonedPet = false,

  ui = {
    selectedFolderKey = "__ALL__",
    selectedTeamID = nil,
    teamSortMode = "name",
    teamCardMode = "comfortable",
  },
}

local function ApplyDefaults(defaults, target)
  for key, defaultValue in pairs(defaults) do
    if type(defaultValue) == "table" then
      if type(target[key]) ~= "table" then
        target[key] = {}
      end

      ApplyDefaults(
        defaultValue,
        target[key]
      )
    elseif target[key] == nil then
      target[key] = defaultValue
    end
  end
end

function Settings:Initialize()
  local profile =
      addon.Profiles:GetCurrentProfile()

  profile.settings =
      profile.settings or {}

  ApplyDefaults(
    DEFAULT_SETTINGS,
    profile.settings
  )
end

function Settings:Get(key)
  local profile =
      addon.Profiles:GetCurrentProfile()

  profile.settings =
      profile.settings or {}

  ApplyDefaults(
    DEFAULT_SETTINGS,
    profile.settings
  )

  return profile.settings[key]
end

function Settings:Set(key, value)
  local profile =
      addon.Profiles:GetCurrentProfile()

  profile.settings =
      profile.settings or {}

  profile.settings[key] = value

  addon.EventBus:Fire(
    addon.Events.SETTINGS_CHANGED,
    key,
    value
  )
end

function Settings:GetUI(key)
  local profile =
      addon.Profiles:GetCurrentProfile()

  profile.settings =
      profile.settings or {}

  profile.settings.ui =
      profile.settings.ui or {}

  ApplyDefaults(
    DEFAULT_SETTINGS.ui,
    profile.settings.ui
  )

  return profile.settings.ui[key]
end

function Settings:SetUI(key, value)
  local profile =
      addon.Profiles:GetCurrentProfile()

  profile.settings =
      profile.settings or {}

  profile.settings.ui =
      profile.settings.ui or {}

  profile.settings.ui[key] = value

  addon.EventBus:Fire(
    addon.Events.SETTINGS_CHANGED,
    "ui." .. key,
    value
  )
end

addon.Settings = Settings

addon.ModuleManager:Register(
  "Settings",
  Settings
)
