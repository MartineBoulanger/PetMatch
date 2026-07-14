local addonName, addon = ...

local Label = {}

function Label:Create(parent, options)
  options = options or {}

  local font =
      options.font
      or addon.UI.Theme.Fonts.Normal

  local text =
      parent:CreateFontString(
        nil,
        "OVERLAY",
        font
      )

  text:SetText(options.text or "")

  if options.width then
    text:SetWidth(options.width)
  end

  if options.justify then
    text:SetJustifyH(options.justify)
  end

  return text
end

addon.UI.Components.Label = Label
