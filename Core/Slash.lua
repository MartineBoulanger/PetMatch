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

-- testing models teams
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

-- testing folders
commands.createfolder = function(...)
  local name = table.concat({ ... }, " ")

  local folder, errorMessage =
      addon.Services.Folder:Create(name)

  if not folder then
    Print(errorMessage or "Unable to create folder")
    return
  end

  Print(
    "Created folder:",
    folder.name,
    folder.id
  )
end

commands.folders = function()
  local folders =
      addon.Services.Folder:GetSortedFolders()

  Print("Folders:")

  for _, folder in ipairs(folders) do
    Print(
      "-",
      folder.name,
      folder.id
    )
  end
end

commands.moveteam = function(teamID, folderID)
  local team, errorMessage =
      addon.Services.Team:MoveToFolder(
        teamID,
        folderID
      )

  if not team then
    Print(errorMessage or "Unable to move team")
    return
  end

  Print(
    "Moved team:",
    team.name
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
        "version, modules, database, debug, settings, pets, listpets, slots"
      )
    end
  end
end

commands.export = function(teamID)
  local team =
      addon.Services.Team:Get(teamID)

  if not team then
    Print("Team not found")
    return
  end

  local value, errorMessage =
      addon.Services.ImportExport:
      ExportTeam(team)

  if not value then
    Print(errorMessage or "Export failed")
    return
  end

  print(value)
end

addon.Slash = Slash

addon.ModuleManager:Register(
  "Slash",
  Slash
)
