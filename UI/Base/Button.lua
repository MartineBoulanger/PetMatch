local _, addon = ...

local L = addon.L
local Button = {}

function Button:Create(parent, options)
  options = options or {}

  local button =
      CreateFrame(
        "Button",
        nil,
        parent,
        "UIPanelButtonTemplate"
      )

  button:SetSize(
    options.width
    or 120,
    options.height
    or addon.UI.Theme.Sizes.ButtonHeight
  )

  button:SetText(
    options.text
    or L["BUTTON"]
  )

  if options.onClick then
    button:SetScript(
      "OnClick",
      options.onClick
    )
  end

  return button
end

addon.UI.Base.Button = Button
