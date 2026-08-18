local _, addon = ...

local DragCursor = {}

function DragCursor:Start()
  if type(SetCursor) ~= "function" then
    return
  end
  SetCursor("HoldingHand.blp")
end

function DragCursor:Stop()
  if type(ResetCursor) ~= "function" then
    return
  end
  ResetCursor()
end

addon.UI.Components.DragCursor = DragCursor
