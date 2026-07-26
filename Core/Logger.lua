local _, addon = ...

addon.Logger = addon.Logger or {}
local Logger = {}

Logger.Levels = {
  DEBUG = 1,
  INFO = 2,
  WARN = 3,
  ERROR = 4,
}

Logger.CurrentLevel = Logger.Levels.INFO


local function Print(level, ...)
  if level < Logger.CurrentLevel then
    return
  end

  local prefix = addon.Constants.CHAT_PREFIX

  print(prefix, ...)
end


function Logger:SetLevel(level)
  self.CurrentLevel = level
end

function Logger:Debug(...)
  Print(self.Levels.DEBUG, ...)
end

function Logger:Info(...)
  Print(self.Levels.INFO, ...)
end

function Logger:Warn(...)
  Print(self.Levels.WARN, ...)
end

function Logger:Error(...)
  Print(self.Levels.ERROR, ...)
end

addon.Logger = Logger
