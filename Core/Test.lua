local addonName, addon = ...

local Test = {}

function Test:Initialize()
  addon.EventBus:Register(
    addon.Events.DATABASE_READY,
    function()
      addon.Logger:Info(
        "EventBus test successful"
      )
    end
  )
end

addon.ModuleManager:Register(
  "Test",
  Test
)
