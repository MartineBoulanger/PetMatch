local _, addon = ...

local Frame = {}

function Frame:Create(parent)
  local frame =
      CreateFrame(
        "Frame",
        nil,
        parent
      )
  return frame
end

addon.UI.Base.Frame = Frame
