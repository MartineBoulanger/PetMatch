local addonName, addon = ...

local ScrollBox = {}

function ScrollBox:Create(parent, options)
  options = options or {}
  local frame = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
  frame:SetSize(options.width or 300, options.height or 300)
  local content = CreateFrame("Frame", nil, frame)
  content:SetSize(options.width or 300, 1)
  frame:SetScrollChild(content)
  frame.Content = content
  return frame
end

addon.UI.Components.ScrollBox = ScrollBox
