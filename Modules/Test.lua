local _, addon = ...

local Test = {}

function Test:Initialize()
  addon.EventBus:Register(
    addon.Events.DATABASE_READY,
    function()
      addon.Logger:Info(
        "EventBus test module successful"
      )
    end
  )
end

addon.Modules:Register(
  "Test",
  Test
)
