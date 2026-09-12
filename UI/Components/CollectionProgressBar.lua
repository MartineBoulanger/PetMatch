local _, addon = ...

local CollectionProgressBar = {}

local DEFAULT_HEIGHT = 20

--------------------------------------------------
-- Helpers
--------------------------------------------------
local function GetColorValue(color, key, fallback)
  if type(color) ~= "table" then
    return fallback
  end

  return tonumber(color[key]) or fallback
end

local function SetTooltip(control, segment)
  if not segment then
    return
  end

  local title = segment.tooltipTitle or segment.label

  if not title then
    return
  end

  GameTooltip:SetOwner(
    control,
    "ANCHOR_RIGHT"
  )

  GameTooltip:SetText(
    tostring(title)
  )

  if type(segment.tooltipLines) == "table" then
    for _, line in ipairs(segment.tooltipLines) do
      if type(line) == "string" then
        GameTooltip:AddLine(
          line,
          1,
          1,
          1,
          true
        )
      elseif type(line) == "table" then
        GameTooltip:AddLine(
          tostring(line.text or ""),
          line.r or 1,
          line.g or 1,
          line.b or 1,
          line.wrap ~= false
        )
      end
    end
  end

  GameTooltip:Show()
end

--------------------------------------------------
-- Create
--------------------------------------------------
function CollectionProgressBar:Create(parent, options)
  options = options or {}

  local instance = {}

  setmetatable(
    instance,
    {
      __index = CollectionProgressBar,
    }
  )

  local frame =
      CreateFrame(
        "Frame",
        nil,
        parent,
        "BackdropTemplate"
      )

  frame:SetHeight(
    options.height or DEFAULT_HEIGHT
  )

  frame:SetBackdrop({
    bgFile = "Interface\\TargetingFrame\\UI-TargetingFrame-BarFill",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 9,
    insets = {
      left = 3,
      right = 3,
      top = 3,
      bottom = 3,
    },
  })

  local colors = addon.UI.Theme.Colors

  local background =
      colors.Background
      or {
        r = 0.05,
        g = 0.05,
        b = 0.05,
        a = 0.9,
      }

  local border =
      colors.Border
      or {
        r = 0.3,
        g = 0.3,
        b = 0.3,
        a = 1,
      }

  frame:SetBackdropColor(
    background.r or 0.05,
    background.g or 0.05,
    background.b or 0.05,
    background.a or 0.9
  )

  frame:SetBackdropBorderColor(
    border.r or 0.3,
    border.g or 0.3,
    border.b or 0.3,
    border.a or 1
  )

  ------------------------------------------------
  -- Fill area
  ------------------------------------------------
  instance.Fill =
      CreateFrame(
        "Frame",
        nil,
        frame
      )

  instance.Fill:SetPoint(
    "TOPLEFT",
    frame,
    "TOPLEFT",
    2,
    -2
  )

  instance.Fill:SetPoint(
    "BOTTOMRIGHT",
    frame,
    "BOTTOMRIGHT",
    -2,
    2
  )

  instance.Fill.Background =
      instance.Fill:CreateTexture(
        nil,
        "BACKGROUND"
      )

  instance.Fill.Background:SetAllPoints()

  instance.Fill.Background:SetTexture(
    "Interface\\TargetingFrame\\UI-TargetingFrame-BarFill"
  )

  instance.Fill.Background:SetVertexColor(
    background.r or 0.05,
    background.g or 0.05,
    background.b or 0.05,
    background.a or 0.9
  )

  ------------------------------------------------
  -- Center text
  ------------------------------------------------
  instance.Text =
      addon.UI.Base.Label:Create(
        frame,
        {
          text = "",
          justify = "CENTER",
          color = colors.Text,
        }
      )

  instance.Text:SetPoint(
    "CENTER",
    frame,
    "CENTER",
    0,
    0
  )

  ------------------------------------------------
  -- State
  ------------------------------------------------
  instance.Frame = frame
  instance.SegmentFrames = {}
  instance.Data = nil

  frame:SetScript(
    "OnSizeChanged",
    function()
      instance:Refresh()
    end
  )

  return instance
end

--------------------------------------------------
-- Clear segments
--------------------------------------------------
function CollectionProgressBar:ClearSegments()
  for _, segmentFrame in ipairs(self.SegmentFrames or {}) do
    segmentFrame:Hide()
    segmentFrame:SetParent(nil)
  end

  self.SegmentFrames = {}
end

--------------------------------------------------
-- Create segment
--------------------------------------------------
function CollectionProgressBar:CreateSegment(segment, xOffset, width)
  if width <= 0 then
    return
  end

  local control =
      CreateFrame(
        "Frame",
        nil,
        self.Fill
      )

  control:SetPoint(
    "TOPLEFT",
    self.Fill,
    "TOPLEFT",
    xOffset,
    0
  )

  control:SetPoint(
    "BOTTOMLEFT",
    self.Fill,
    "BOTTOMLEFT",
    xOffset,
    0
  )

  control:SetWidth(width)

  local texture =
      control:CreateTexture(
        nil,
        "ARTWORK"
      )

  texture:SetAllPoints()

  local color = segment.color or {}

  texture:SetTexture(
    "Interface\\TargetingFrame\\UI-TargetingFrame-BarFill"
  )

  texture:SetVertexColor(
    GetColorValue(
      color,
      "r",
      1
    ),
    GetColorValue(
      color,
      "g",
      1
    ),
    GetColorValue(
      color,
      "b",
      1
    ),
    GetColorValue(
      color,
      "a",
      1
    )
  )

  control.Texture = texture
  control.Segment = segment

  ------------------------------------------------
  -- Tooltip
  ------------------------------------------------
  control:EnableMouse(true)

  control:SetScript(
    "OnEnter",
    function(frame)
      SetTooltip(
        frame,
        frame.Segment
      )
    end
  )

  control:SetScript(
    "OnLeave",
    function()
      GameTooltip:Hide()
    end
  )

  self.SegmentFrames[#self.SegmentFrames + 1] = control
end

--------------------------------------------------
-- Refresh
--------------------------------------------------
function CollectionProgressBar:Refresh()
  if not self.Frame or not self.Fill
      or not self.Data then
    return
  end

  self:ClearSegments()

  local maximum = tonumber(self.Data.maximum) or 0

  if maximum <= 0 then
    self.Text:SetText(self.Data.text or "")
    return
  end

  local barWidth = self.Fill:GetWidth()

  if not barWidth or barWidth <= 0 then
    return
  end

  local xOffset = 0

  for _, segment in ipairs(self.Data.segments or {}) do
    local value = math.max(0, tonumber(segment.value) or 0)
    local width = barWidth * math.min(value / maximum, 1)

    if xOffset + width > barWidth then
      width = math.max(0, barWidth - xOffset)
    end

    self:CreateSegment(
      segment,
      xOffset,
      width
    )

    xOffset = xOffset + width

    if xOffset >= barWidth then
      break
    end
  end

  self.Text:SetText(
    self.Data.text
    or ""
  )
end

--------------------------------------------------
-- Set data
--------------------------------------------------
function CollectionProgressBar:SetData(data)
  self.Data = data or {}
  self:Refresh()
end

--------------------------------------------------
-- Get frame
--------------------------------------------------
function CollectionProgressBar:GetFrame()
  return self.Frame
end

--------------------------------------------------
-- Register
--------------------------------------------------
addon.UI.Components.CollectionProgressBar = CollectionProgressBar
