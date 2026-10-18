local _, addon = ...

local L = addon.L

local IconPicker = {}

local DIALOG_WIDTH = 420
local ICON_SIZE = 36
local ICON_SPACING = 6
local COLUMNS = 8
local VISIBLE_ROWS = 7

local dialogInstance
local icons = {}
local filteredIcons = {}
local iconButtons = {}

local CONTENT_PADDING = 14
local CONTENT_MARGIN = {
  left = -12,
  right = 12,
  top = 4,
  bottom = 8,
}

--------------------------------------------------
-- Load icons
--------------------------------------------------
function IconPicker:LoadIcons()
  wipe(icons)

  local seen = {}

  local function AddIcons(iconList)
    if type(iconList) ~= "table" then
      return
    end

    for _, icon in ipairs(iconList) do
      if icon and not seen[icon] then
        seen[icon] = true
        icons[#icons + 1] = icon
      end
    end
  end

  if C_Macro and C_Macro.GetMacroIcons then
    AddIcons(C_Macro.GetMacroIcons())
  elseif GetMacroIcons then
    local result = {}
    GetMacroIcons(result)
    AddIcons(result)
  end

  if C_Macro and C_Macro.GetMacroItemIcons then
    AddIcons(C_Macro.GetMacroItemIcons())
  elseif GetMacroItemIcons then
    local result = {}
    GetMacroItemIcons(result)
    AddIcons(result)
  end
end

--------------------------------------------------
-- Filter icons
--------------------------------------------------
function IconPicker:FilterIcons(searchText)
  searchText = string.lower(
    addon.Utils:Trim(searchText or "")
  )

  local searchIndex = addon.Data.IconSearchIndex or {}

  wipe(filteredIcons)

  for _, icon in ipairs(icons) do
    local iconID = tonumber(icon)
    local iconName = iconID and searchIndex[iconID] or ""

    if searchText == ""
        or string.find(tostring(icon), searchText, 1, true)
        or string.find(iconName, searchText, 1, true) then
      filteredIcons[#filteredIcons + 1] = icon
    end
  end

  self.ScrollOffset = 0

  local totalRows = math.ceil(#filteredIcons / COLUMNS)
  local maxOffset = math.max(0, totalRows - VISIBLE_ROWS)

  self.Scrollbar:SetMinMaxValues(0, maxOffset)
  self.Scrollbar:SetValue(0)

  self:RefreshIcons()
end

--------------------------------------------------
-- Refresh visible icons
--------------------------------------------------
function IconPicker:RefreshIcons()
  GameTooltip:Hide()
  local offset = self.ScrollOffset or 0

  for index, button in ipairs(iconButtons) do
    local iconIndex = offset * COLUMNS + index
    local icon = filteredIcons[iconIndex]

    if icon then
      button.Icon:SetTexture(icon)
      button.IconID = icon
      button:Show()
    else
      button.IconID = nil
      button:Hide()
    end
  end
end

--------------------------------------------------
-- Scroll
--------------------------------------------------
function IconPicker:SetScrollOffset(offset)
  local totalRows = math.ceil(#filteredIcons / COLUMNS)
  local maxOffset = math.max(0, totalRows - VISIBLE_ROWS)

  offset = math.max(
    0,
    math.min(maxOffset, math.floor(offset))
  )

  self.ScrollOffset = offset

  -- Synchronize scrollbar with mouse wheel scrolling
  if self.Scrollbar:GetValue() ~= offset then
    self.Scrollbar:SetValue(offset)
  end

  self:RefreshIcons()
end

--------------------------------------------------
-- Select icon
--------------------------------------------------
function IconPicker:SelectIcon(icon)
  local callback = self.OnSelect

  self.OnSelect = nil

  if dialogInstance then
    dialogInstance:Hide()
  end

  if callback then
    callback(icon)
  end
end

--------------------------------------------------
-- Create content
--------------------------------------------------
function IconPicker:CreateContent(dialog)
  local content = dialog:GetContentFrame()

  --------------------------------------------------
  -- Search input
  --------------------------------------------------
  self.SearchInput = CreateFrame(
    "EditBox",
    nil,
    content,
    "InputBoxTemplate"
  )

  self.SearchInput:SetHeight(28)
  self.SearchInput:SetAutoFocus(false)
  self.SearchInput:SetMaxLetters(100)

  self.SearchInput:SetPoint(
    "TOPLEFT",
    content,
    "TOPLEFT",
    4,
    0
  )

  self.SearchInput:SetPoint(
    "TOPRIGHT",
    content,
    "TOPRIGHT",
    -4,
    0
  )


  --------------------------------------------------
  -- Search placeholder
  --------------------------------------------------
  self.SearchPlaceholder = self.SearchInput:CreateFontString(
    nil,
    "OVERLAY",
    "GameFontDisable"
  )

  self.SearchPlaceholder:SetPoint(
    "LEFT",
    self.SearchInput,
    "LEFT",
    8,
    -1
  )

  self.SearchPlaceholder:SetText(
    L["SEARCH_ICONS"] or "Search icons..."
  )

  --------------------------------------------------
  -- Clear search button
  --------------------------------------------------
  self.ClearSearchButton = CreateFrame(
    "Button",
    nil,
    self.SearchInput
  )

  self.ClearSearchButton:SetFrameLevel(
    self.SearchInput:GetFrameLevel() + 10
  )

  self.ClearSearchButton:SetSize(18, 18)
  self.ClearSearchButton:SetPoint(
    "RIGHT",
    self.SearchInput,
    "RIGHT",
    -4,
    0
  )

  local clearText = self.ClearSearchButton:CreateFontString(
    nil,
    "OVERLAY",
    "GameFontNormal"
  )

  clearText:SetAllPoints()
  clearText:SetText("x")

  self.ClearSearchButton:SetScript("OnClick", function()
    self.SearchInput:SetText("")
    self.SearchInput:SetFocus()
  end)

  self.ClearSearchButton:Hide()

  self.SearchInput:SetScript("OnTextChanged", function(input)
    local text = input:GetText() or ""

    self.SearchPlaceholder:SetShown(text == "")
    self.ClearSearchButton:SetShown(text ~= "")

    self:FilterIcons(text)
  end)

  self.SearchInput:SetScript("OnEscapePressed", function(input)
    input:ClearFocus()
  end)

  self.SearchInput:SetScript("OnEnterPressed", function(input)
    input:ClearFocus()
  end)

  self.SearchInput.Instructions = self.SearchPlaceholder
  addon.SkinManager:ApplyEditBox(self.SearchInput)

  local grid = CreateFrame("Frame", nil, content)

  grid:SetSize(
    COLUMNS * (ICON_SIZE + ICON_SPACING),
    VISIBLE_ROWS * (ICON_SIZE + ICON_SPACING)
  )

  grid:SetPoint("TOPLEFT", self.SearchInput, "BOTTOMLEFT", -4, -16)

  self.Grid = grid

  --------------------------------------------------
  -- Icon buttons
  --------------------------------------------------
  for index = 1, COLUMNS * VISIBLE_ROWS do
    local button = CreateFrame("Button", nil, grid)

    button:SetSize(ICON_SIZE, ICON_SIZE)

    local column = (index - 1) % COLUMNS
    local row = math.floor((index - 1) / COLUMNS)

    button:SetPoint(
      "TOPLEFT",
      grid,
      "TOPLEFT",
      column * (ICON_SIZE + ICON_SPACING),
      -row * (ICON_SIZE + ICON_SPACING)
    )

    local texture = button:CreateTexture(nil, "ARTWORK")
    texture:SetAllPoints()
    button.Icon = texture

    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetColorTexture(1, 1, 1, 0.25)

    button:SetScript("OnClick", function(control)
      if control.IconID then
        self:SelectIcon(control.IconID)
      end
    end)


    button:SetScript("OnEnter", function(control)
      if not control.IconID then
        return
      end

      local iconID = tonumber(control.IconID)
      local searchIndex = addon.Data.IconSearchIndex or {}
      local iconName = iconID and searchIndex[iconID]

      GameTooltip:SetOwner(control, "ANCHOR_RIGHT")

      if iconName and iconName ~= "" then
        GameTooltip:AddLine(
          iconName,
          1, 0.82, 0
        )
      else
        GameTooltip:AddLine(
          L["UNKNOWN_ICON"] or "Unknown icon",
          1, 0.82, 0
        )
      end

      GameTooltip:AddLine(
        L["ICON_ID"] .. tostring(control.IconID),
        0.7, 0.7, 0.7
      )

      GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function()
      GameTooltip:Hide()
    end)

    addon.SkinManager:ApplyIconPickerButton(button)

    iconButtons[index] = button
  end

  --------------------------------------------------
  -- Mouse wheel
  --------------------------------------------------
  grid:EnableMouseWheel(true)

  grid:SetScript("OnMouseWheel", function(_, delta)
    self:SetScrollOffset(
      (self.ScrollOffset or 0) - delta
    )
  end)

  --------------------------------------------------
  -- Scrollbar
  --------------------------------------------------
  local scrollbar = CreateFrame(
    "Slider",
    nil,
    content,
    "UIPanelScrollBarTemplate"
  )

  scrollbar:SetPoint("TOPLEFT", grid, "TOPRIGHT", 8, -16)
  scrollbar:SetPoint("BOTTOMLEFT", grid, "BOTTOMRIGHT", 8, 16)

  scrollbar:SetMinMaxValues(0, 0)
  scrollbar:SetValueStep(1)
  scrollbar:SetObeyStepOnDrag(true)

  scrollbar:SetScript("OnValueChanged", function(_, value)
    self:SetScrollOffset(value)
  end)

  addon.SkinManager:ApplyScrollBar(scrollbar)

  self.Scrollbar = scrollbar
end

--------------------------------------------------
-- Create dialog
--------------------------------------------------
function IconPicker:Create()
  if dialogInstance then
    return dialogInstance
  end

  local dialog = addon.UI.Base.Dialog:Create({
    name = "PetMatchIconPicker",
    title = L["CHOOSE_ICON_TITLE"],
    width = DIALOG_WIDTH,
    contentMargin = CONTENT_MARGIN,
    padding = CONTENT_PADDING,
    bottomSpacing = 0,
    onCancel = function()
      self.OnSelect = nil
      return true
    end,
    onClose = function()
      self.OnSelect = nil
    end,
  })

  self:CreateContent(dialog)

  dialog:AddCancelButton({
    text = addon.L["CANCEL"] or "Cancel",
    width = 100,
  })

  dialogInstance = dialog
  self.Dialog = dialog

  dialog:RefreshLayout()

  return dialog
end

--------------------------------------------------
-- Show
--------------------------------------------------
function IconPicker:Show(onSelect)
  local dialog = self:Create()

  self.OnSelect = onSelect
  self.ScrollOffset = 0

  self:LoadIcons()

  self.SearchInput:SetText("")
  self:FilterIcons("")

  dialog:Show()
  dialog:RefreshLayout()
end

--------------------------------------------------
-- Register
--------------------------------------------------
addon.UI.Dialogs.IconPicker = IconPicker
