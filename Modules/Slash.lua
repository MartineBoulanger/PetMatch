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
    addon.Settings:GetUI("theme")
  )
  Print(
    "Scale:",
    addon.Settings:Get("scale")
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
      Print("Command unknown")
    end
  end
end

addon.Slash = Slash

addon.ModuleManager:Register(
  "Slash",
  Slash
)
