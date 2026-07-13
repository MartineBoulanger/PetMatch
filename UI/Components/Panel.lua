local addonName, addon = ...

local Panel = {}

function Panel:Create(parent, options)
  options = options or {}

  local frame =
      CreateFrame(
        "Frame",
        nil,
        parent,
        "BackdropTemplate"
      )

  frame:SetSize(
    options.width or addon.UI.Theme.Sizes.DefaultWidth,
    options.height or addon.UI.Theme.Sizes.DefaultHeight
  )

  frame:SetBackdrop({
    bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
    edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
    edgeSize = 16
  })

  local color = addon.UI.Theme.Colors.Background

  frame:SetBackdropColor(unpack(color))

  return frame
end

addon.UI.Components.Panel = Panel
