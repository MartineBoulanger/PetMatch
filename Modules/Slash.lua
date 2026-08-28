local _, addon = ...

addon.Slash = addon.Slash or {}
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

commands.queue = function()
  -- local export,
  -- errorMessage =
  --     addon.Services.ImportExport:
  --     ExportLevellingQueue()

  -- if export then
  --   print(export)
  -- else
  --   print(
  --     "PetMatch:",
  --     errorMessage
  --   )
  -- end
  local importText = [[
  PMQ1
  species=1125;breed=3;level=7;rarity=4;type=7
  species=1125;breed=3;level=18;rarity=4;type=7
  species=1125;breed=3;level=1;rarity=4;type=7
  ]]

  local preview,
  errorMessage =
      addon.Services.ImportExport:
      PrepareLevellingQueueImport(
        importText
      )

  if not preview then
    print(
      "Import error:",
      errorMessage
    )
    return
  end

  print(
    "Total:",
    preview.total,
    "Addable:",
    preview.addable,
    "Unavailable:",
    preview.unavailable,
    "Invalid:",
    preview.invalid
  )

  for index, item in ipairs(
    preview.pets
  ) do
    print(
      index,
      item.status,
      item.petGUID or "nil",
      item.pet and item.pet.level or "nil",
      item.pet and item.pet.quality or "nil"
    )
  end
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
        "version, modules, database, debug, settings, pets, listpets"
      )
    end
  end
end

addon.Slash = Slash

addon.ModuleManager:Register(
  "Slash",
  Slash
)
