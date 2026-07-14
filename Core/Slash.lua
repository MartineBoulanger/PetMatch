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
  addon.Services.Team:SetActive(
    team.id
  )
  Print(
    "Team created and selected:",
    team.name,
    team.id
  )
end

commands.teams = function()
  local teams = addon.Services.Team:GetTeams()
  print(
    "[PetMatch] Teams:"
  )
  for id, team in pairs(teams) do
    print(
      "-",
      team.name
    )
  end
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

commands.teaminfo = function()
  local team = addon.Services.Team:GetActive()
  if not team then
    Print(
      "No active team"
    )
    return
  end
  Print(
    "Team:",
    team.name
  )
  for slot = 1, 3 do
    local guid =
        team.pets[slot]
    if guid then
      local pet =
          addon.Services.PetJournal:GetPet(
            guid
          )
      if pet then
        Print(
          slot,
          pet.name
        )
      end
    else
      Print(
        slot,
        "Empty"
      )
    end
  end
end

commands.select = function(id)
  local success =
      addon.Services.Team:SetActive(
        id
      )
  if success then
    Print(
      "Team selected"
    )
  else
    Print(
      "Team not found"
    )
  end
end

commands.addpet = function(
    slot,
    guid
)
  local team =
      addon.Services.Team:GetActive()
  if not team then
    Print(
      "No active team"
    )
    return
  end
  local success =
      addon.Services.Team:AddPet(
        team.id,
        tonumber(slot),
        guid
      )
  if success then
    Print(
      "Pet added to slot",
      slot
    )
  else
    Print(
      "Could not add pet"
    )
  end
end

commands.listpets = function()
  local pets =
      addon.Services.PetJournal:GetAll()
  local count = 0
  for guid, pet in pairs(pets) do
    count = count + 1
    if count <= 10 then
      Print(
        pet.name,
        guid
      )
    end
  end
  Print(
    "Showing first 10 pets"
  )
end

commands.slots = function()
  addon.Services.BattleSlot:Debug()
end

commands.savecurrent = function(name)
  if not name then
    Print(
      "Usage: /pm savecurrent TeamName"
    )
    return
  end
  local team =
      addon.Services.Team:CreateFromBattleSlots(
        name
      )
  if team then
    Print(
      "Saved team:",
      team.name
    )
  else
    Print(
      "Failed saving team"
    )
  end
end

commands.testui = function()
  if not addon.Initialized then
    print(
      "[PetMatch] Not initialized yet"
    )
    return
  end

  local frame =
      CreateFrame(
        "Frame",
        "PetMatchTeamListTest",
        UIParent
      )

  frame:SetSize(
    400,
    500
  )

  frame:SetPoint(
    "CENTER"
  )

  local list =
      addon.UI.Components.TeamList:Create(
        frame
      )

  list:SetPoint(
    "CENTER"
  )
end

function Slash:Initialize()
  SLASH_PETMATCH1 = "/petmatch"
  SLASH_PETMATCH2 = "/pm"
  SlashCmdList.PETMATCH = function(message)
    local args =
        addon.Utils:Split(
          message or ""
        )
    local command =
        string.lower(
          args[1] or ""
        )
    table.remove(
      args,
      1
    )
    if commands[command] then
      commands[command](
        unpack(args)
      )
    else
      Print(
        "Commands:",
        "version, modules, database, debug, team, teams, select, activeteam, teaminfo"
      )
    end
  end
end

addon.Slash = Slash

addon.ModuleManager:Register(
  "Slash",
  Slash
)
