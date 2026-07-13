local addonName, addon = ...

local Slash = {}

local function Print(...)
  addon.Logger:Info(...)
end

local commands = {}

commands.version = function()
  Print(
    "Version:",
    addon.Version
  )
end

commands.modules = function()
  Print(
    "Loaded modules:"
  )
  for _, module in ipairs(addon.Modules) do
    Print(
      "-",
      module.Name
    )
  end
end

commands.database = function()
  if addon.DB then
    Print(
      "Database version:",
      addon.DB.version
    )
  else
    Print(
      "Database unavailable"
    )
  end
end

commands.debug = function()
  Print(
    "Debug information"
  )
  Print(
    "Initialized:",
    addon.Initialized
  )
  Print(
    "Enabled:",
    addon.Enabled
  )
end

commands.settings = function()
  Print(
    "Theme:",
    addon.Settings:Get("theme")
  )
  Print(
    "Scale:",
    addon.Settings:Get("scale")
  )
end

-- testing models teams
commands.model = function()
  local team =
      addon.Models.Team:Create(
        "Test Team"
      )
  Print(
    "Created team:",
    team.name,
    team.id
  )
end

-- testing services teams
commands.team = function()
  local team =
      addon.Services.Team:Create(
        "Mijn eerste team"
      )
  Print(
    "Team created:",
    team.name,
    team.id
  )
end

commands.teams = function()
  local teams =
      addon.Services.Team:GetTeams()
  local count = 0
  for _, team in pairs(teams) do
    count = count + 1
    Print(
      team.name,
      team.id
    )
  end
  Print(
    "Total teams:",
    count
  )
end

commands.activeteam = function()
  local team =
      addon.Services.Team:GetActive()
  if team then
    Print(
      "Active:",
      team.name
    )
  else
    Print(
      "No active team"
    )
  end
end

commands.pets = function()
  local pets =
      addon.Services.PetJournal:GetAll()
  local count = 0
  for _, pet in pairs(pets) do
    count = count + 1

    Print(
      pet.name,
      "Level",
      pet.level
    )
  end
  Print(
    "Pets found:",
    count
  )
end

function Slash:Initialize()
  SLASH_PETMATCH1 = "/petmatch"
  SLASH_PETMATCH2 = "/pm"
  SlashCmdList.PETMATCH = function(message)
    local command = string.lower(
      message or ""
    )
    if commands[command] then
      commands[command]()
    else
      Print(
        "Commands:",
        "version, modules, database, debug"
      )
    end
  end
end

addon.Slash = Slash

addon.ModuleManager:Register(
  "Slash",
  Slash
)
