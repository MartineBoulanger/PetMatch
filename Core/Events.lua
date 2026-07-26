local _, addon = ...

addon.EventBus = addon.EventBus or {}
local EventBus = {}
EventBus.Registered = {}

function EventBus:Register(event, callback)
  if not event then
    addon.Logger:Error(
      "Cannot register empty event"
    )
    return
  end
  if type(callback) ~= "function" then
    addon.Logger:Error(
      "Invalid callback for event",
      event
    )
    return
  end
  if not self.Registered[event] then
    self.Registered[event] = {}
  end
  table.insert(
    self.Registered[event],
    callback
  )
end

function EventBus:Fire(event, ...)
  if not event then
    return
  end
  local callbacks = self.Registered[event]
  if not callbacks then
    return
  end

  for _, callback in ipairs(callbacks) do
    local success, err = pcall(
      callback,
      ...
    )
    if not success then
      addon.Logger:Error(
        "Error in event:",
        event,
        err
      )
    end
  end
end

function EventBus:Unregister(event, callback)
  local callbacks = self.Registered[event]
  if not callbacks then
    return
  end
  for index, registered in ipairs(callbacks) do
    if registered == callback then
      table.remove(
        callbacks,
        index
      )
      return
    end
  end
end

addon.EventBus = EventBus
