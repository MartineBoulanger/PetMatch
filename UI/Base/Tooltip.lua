local _, addon = ...

local Tooltip = {}

local DEFAULT_WIDTH = 300
local MIN_HEIGHT = 40

local PADDING_LEFT = 12
local PADDING_RIGHT = 12
local PADDING_TOP = 12
local PADDING_BOTTOM = 12

local TITLE_SPACING = 8
local LINE_SPACING = 3

local function GetTooltipFrame()
  if Tooltip.Frame then
    return Tooltip.Frame
  end

  local frame = CreateFrame(
    "Frame",
    "PetMatchTooltip",
    UIParent,
    "BackdropTemplate"
  )

  frame:SetFrameStrata("TOOLTIP")
  frame:SetClampedToScreen(true)
  frame:SetSize(
    DEFAULT_WIDTH,
    MIN_HEIGHT
  )

  frame:SetBackdrop({
    bgFile =
    "Interface/Tooltips/UI-Tooltip-Background",

    edgeFile =
    "Interface/Tooltips/UI-Tooltip-Border",

    tile = true,
    tileSize = 16,
    edgeSize = 16,

    insets = {
      left = 4,
      right = 4,
      top = 4,
      bottom = 4,
    },
  })

  frame:SetBackdropColor(
    0.05,
    0.05,
    0.05,
    0.95
  )

  frame:SetBackdropBorderColor(
    0.65,
    0.65,
    0.65,
    1
  )

  frame:EnableMouse(false)
  frame:Hide()

  frame.Rows = {}
  frame.ActiveRowCount = 0

  local title =
      frame:CreateFontString(
        nil,
        "OVERLAY",
        "GameTooltipHeaderText"
      )

  title:SetPoint(
    "TOPLEFT",
    frame,
    "TOPLEFT",
    PADDING_LEFT,
    -PADDING_TOP
  )

  title:SetPoint(
    "RIGHT",
    frame,
    "RIGHT",
    -PADDING_RIGHT,
    0
  )

  title:SetJustifyH("LEFT")
  title:SetJustifyV("TOP")
  title:SetWordWrap(true)

  frame.Title = title

  Tooltip.Frame = frame

  return frame
end

local function CreateRow(frame)
  local row = CreateFrame(
    "Frame",
    nil,
    frame
  )

  row:SetHeight(14)

  local leftText =
      row:CreateFontString(
        nil,
        "OVERLAY",
        "GameTooltipText"
      )

  leftText:SetPoint(
    "TOPLEFT",
    row,
    "TOPLEFT",
    0,
    0
  )

  leftText:SetJustifyH("LEFT")
  leftText:SetJustifyV("TOP")
  leftText:SetWordWrap(true)

  local rightText =
      row:CreateFontString(
        nil,
        "OVERLAY",
        "GameTooltipText"
      )

  rightText:SetPoint(
    "TOPRIGHT",
    row,
    "TOPRIGHT",
    0,
    0
  )

  rightText:SetJustifyH("RIGHT")
  rightText:SetJustifyV("TOP")
  rightText:SetWordWrap(false)

  row.LeftText = leftText
  row.RightText = rightText

  return row
end

local function AcquireRow()
  local frame = GetTooltipFrame()

  frame.ActiveRowCount =
      frame.ActiveRowCount + 1

  local index = frame.ActiveRowCount
  local row = frame.Rows[index]

  if not row then
    row = CreateRow(frame)
    frame.Rows[index] = row
  end

  row:Show()

  row.LeftText:SetText("")
  row.RightText:SetText("")

  row.LeftText:SetTextColor(
    1,
    1,
    1,
    1
  )

  row.RightText:SetTextColor(
    1,
    1,
    1,
    1
  )

  return row
end

local function ReleaseRows()
  local frame = GetTooltipFrame()

  for _, row in ipairs(frame.Rows) do
    row:Hide()
    row:ClearAllPoints()

    row.LeftText:SetText("")
    row.RightText:SetText("")
  end

  frame.ActiveRowCount = 0
end

local function ApplyColor(
    fontString,
    color
)
  if not color then
    return
  end

  fontString:SetTextColor(
    color.r or 1,
    color.g or 1,
    color.b or 1,
    color.a or 1
  )
end

function Tooltip:GetFrame()
  return GetTooltipFrame()
end

function Tooltip:SetWidth(width)
  local frame = GetTooltipFrame()

  frame:SetWidth(
    width or DEFAULT_WIDTH
  )
end

function Tooltip:SetTitle(
    text,
    color
)
  local frame = GetTooltipFrame()

  frame.Title:SetText(text or "")

  frame.Title:SetTextColor(
    1,
    0.82,
    0,
    1
  )

  ApplyColor(
    frame.Title,
    color
  )
end

function Tooltip:AddLine(
    text,
    color
)
  local row = AcquireRow()

  row.LeftText:SetText(
    text or ""
  )

  row.RightText:SetText("")

  row.LeftText:ClearAllPoints()

  row.LeftText:SetPoint(
    "TOPLEFT",
    row,
    "TOPLEFT",
    0,
    0
  )

  row.LeftText:SetPoint(
    "RIGHT",
    row,
    "RIGHT",
    0,
    0
  )

  row.LeftText:SetJustifyH("LEFT")
  row.LeftText:SetWordWrap(true)

  ApplyColor(
    row.LeftText,
    color
  )

  return row
end

function Tooltip:AddDoubleLine(
    leftText,
    rightText,
    leftColor,
    rightColor
)
  local row = AcquireRow()

  row.LeftText:SetText(
    leftText or ""
  )

  row.RightText:SetText(
    rightText or ""
  )

  row.LeftText:ClearAllPoints()

  row.LeftText:SetPoint(
    "TOPLEFT",
    row,
    "TOPLEFT",
    0,
    0
  )

  row.LeftText:SetPoint(
    "RIGHT",
    row.RightText,
    "LEFT",
    -10,
    0
  )

  row.LeftText:SetJustifyH("LEFT")
  row.LeftText:SetWordWrap(true)

  ApplyColor(
    row.LeftText,
    leftColor
  )

  ApplyColor(
    row.RightText,
    rightColor
  )

  return row
end

function Tooltip:AddSpacer(height)
  local row = AcquireRow()

  row.LeftText:SetText("")
  row.RightText:SetText("")

  row.SpacerHeight = height or 6

  return row
end

function Tooltip:Clear()
  local frame = GetTooltipFrame()

  frame.Title:SetText("")
  frame.Owner = nil

  ReleaseRows()
end

function Tooltip:SetOwner(
    owner,
    anchor
)
  local frame = GetTooltipFrame()

  frame.Owner = owner

  frame:ClearAllPoints()

  anchor = anchor or "ANCHOR_RIGHT"

  if anchor == "ANCHOR_LEFT" then
    frame:SetPoint(
      "RIGHT",
      owner,
      "LEFT",
      -8,
      0
    )
  elseif anchor == "ANCHOR_TOP" then
    frame:SetPoint(
      "BOTTOM",
      owner,
      "TOP",
      0,
      8
    )
  elseif anchor == "ANCHOR_BOTTOM" then
    frame:SetPoint(
      "TOP",
      owner,
      "BOTTOM",
      0,
      -8
    )
  elseif anchor == "ANCHOR_CURSOR" then
    local scale = UIParent:GetEffectiveScale()
    local x, y = GetCursorPosition()

    x = x / scale
    y = y / scale

    frame:SetPoint(
      "BOTTOMLEFT",
      UIParent,
      "BOTTOMLEFT",
      x + 16,
      y + 16
    )
  else
    frame:SetPoint(
      "LEFT",
      owner,
      "RIGHT",
      8,
      0
    )
  end
end

function Tooltip:Layout()
  local frame = GetTooltipFrame()

  local currentAnchor = frame.Title
  local totalHeight = PADDING_TOP

  local titleHeight =
      frame.Title:GetStringHeight()

  if frame.Title:GetText() ~= "" then
    totalHeight =
        totalHeight
        + titleHeight
        + TITLE_SPACING
  end

  for index = 1, frame.ActiveRowCount do
    local row = frame.Rows[index]

    row:ClearAllPoints()

    if index == 1 then
      if frame.Title:GetText() ~= "" then
        row:SetPoint(
          "TOPLEFT",
          frame.Title,
          "BOTTOMLEFT",
          0,
          -TITLE_SPACING
        )

        row:SetPoint(
          "TOPRIGHT",
          frame.Title,
          "BOTTOMRIGHT",
          0,
          -TITLE_SPACING
        )
      else
        row:SetPoint(
          "TOPLEFT",
          frame,
          "TOPLEFT",
          PADDING_LEFT,
          -PADDING_TOP
        )

        row:SetPoint(
          "TOPRIGHT",
          frame,
          "TOPRIGHT",
          -PADDING_RIGHT,
          -PADDING_TOP
        )
      end
    else
      row:SetPoint(
        "TOPLEFT",
        currentAnchor,
        "BOTTOMLEFT",
        0,
        -LINE_SPACING
      )

      row:SetPoint(
        "TOPRIGHT",
        currentAnchor,
        "BOTTOMRIGHT",
        0,
        -LINE_SPACING
      )

      totalHeight =
          totalHeight
          + LINE_SPACING
    end

    local rowHeight

    if row.SpacerHeight then
      rowHeight = row.SpacerHeight
      row.SpacerHeight = nil
    else
      rowHeight = math.max(
        row.LeftText:GetStringHeight(),
        row.RightText:GetStringHeight(),
        14
      )
    end

    row:SetHeight(rowHeight)

    totalHeight =
        totalHeight + rowHeight

    currentAnchor = row
  end

  totalHeight =
      totalHeight + PADDING_BOTTOM

  frame:SetHeight(
    math.max(
      MIN_HEIGHT,
      totalHeight
    )
  )
end

function Tooltip:Show()
  local frame = GetTooltipFrame()

  self:Layout()
  frame:Show()
end

function Tooltip:Hide(owner)
  local frame = GetTooltipFrame()

  if owner
      and frame.Owner
      and frame.Owner ~= owner then
    return
  end

  frame:Hide()
  frame.Owner = nil
end

function Tooltip:IsOwnedBy(owner)
  local frame = GetTooltipFrame()
  return frame.Owner == owner
end

addon.UI.Base.Tooltip = Tooltip
