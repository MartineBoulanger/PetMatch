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

  local color =
      options.color
      or addon.UI.Theme.Colors.Text

  text:SetTextColor(
    color[1] or 1,
    color[2] or 1,
    color[3] or 1,
    color[4] or 1
  )

  if options.width then
    text:SetWidth(options.width)
  end

  if options.justify then
    text:SetJustifyH(options.justify)
  end

  return text
end

addon.UI.Components.Label = Label
