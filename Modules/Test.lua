local _, addon = ...

local L = addon.L
local Test = {}

function Test:Initialize()
  addon.EventBus:Register(
    addon.Events.DATABASE_READY,
    function()
      addon.Logger:Info(
        L["TEST"]
      )
    end
  )
end

addon.ModuleManager:Register(
  "Test",
  Test
)
