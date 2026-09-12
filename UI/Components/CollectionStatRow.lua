local _, addon = ...

local CollectionStatRow = {}

local DEFAULT_HEIGHT = 24
local DEFAULT_ICON_SIZE = 20
local DEFAULT_BAR_HEIGHT = 18

function CollectionStatRow:Create(parent, options)
  options = options or {}

  local instance = {}

  setmetatable(
    instance,
    {
      __index = CollectionStatRow,
    }
  )

  local frame =
      CreateFrame(
        "Frame",
        nil,
        parent
      )

  frame:SetHeight(
    options.height or DEFAULT_HEIGHT
  )

  ------------------------------------------------
  -- Icon button
  ------------------------------------------------
  instance.IconButton =
      CreateFrame(
        "Button",
        nil,
        frame
      )

  local iconSize = options.iconSize or DEFAULT_ICON_SIZE

  instance.IconButton:SetSize(
    iconSize,
    iconSize
  )

  instance.IconButton:SetPoint(
    "LEFT",
    frame,
    "LEFT",
    0,
    0
  )

  instance.Icon =
      instance.IconButton:CreateTexture(
        nil,
        "ARTWORK"
      )

  instance.Icon:SetAllPoints()

  ------------------------------------------------
  -- Left label
  ------------------------------------------------
  instance.LeftLabel = addon.UI.Base.Label:Create(
    frame,
    {
      text = "",
      justify = "CENTER",
      color = addon.UI.Theme.Colors.Text,
    }
  )

  instance.LeftLabel:SetWidth(iconSize)

  instance.LeftLabel:SetPoint(
    "CENTER",
    instance.IconButton,
    "CENTER",
    0,
    0
  )

  instance.LeftLabel:Hide()

  ------------------------------------------------
  -- Progress bar
  ------------------------------------------------
  instance.Progress =
      addon.UI.Components.CollectionProgressBar:Create(
        frame,
        {
          height = options.barHeight or DEFAULT_BAR_HEIGHT,
        }
      )

  local progressFrame = instance.Progress:GetFrame()

  progressFrame:SetPoint(
    "LEFT",
    instance.IconButton,
    "RIGHT",
    8,
    0
  )

  progressFrame:SetPoint(
    "RIGHT",
    frame,
    "RIGHT",
    -140,
    0
  )

  ------------------------------------------------
  -- Count
  ------------------------------------------------
  instance.Count = addon.UI.Base.Label:Create(
    frame,
    {
      text = "",
      justify = "RIGHT",
      color = addon.UI.Theme.Colors.Text,
    }
  )

  instance.Count:SetPoint(
    "RIGHT",
    frame,
    "RIGHT",
    -58,
    0
  )

  ------------------------------------------------
  -- Percentage
  ------------------------------------------------
  instance.Percentage = addon.UI.Base.Label:Create(
    frame,
    {
      text = "",
      justify = "RIGHT",
      color = addon.UI.Theme.Colors.Text,
    }
  )

  instance.Percentage:SetPoint(
    "RIGHT",
    frame,
    "RIGHT",
    0,
    0
  )

  ------------------------------------------------
  -- State
  ------------------------------------------------
  instance.Frame = frame
  instance.Data = nil

  ------------------------------------------------
  -- Icon tooltip
  ------------------------------------------------
  instance.IconButton:SetScript(
    "OnEnter",
    function()
      local data = instance.Data

      if not data or not data.tooltipTitle then
        return
      end

      GameTooltip:SetOwner(
        instance.IconButton,
        "ANCHOR_RIGHT"
      )

      GameTooltip:SetText(
        data.tooltipTitle
      )

      for _, line in ipairs(data.tooltipLines or {}) do
        GameTooltip:AddLine(
          tostring(line),
          1,
          1,
          1,
          true
        )
      end

      GameTooltip:Show()
    end
  )

  instance.IconButton:SetScript(
    "OnLeave",
    function()
      GameTooltip:Hide()
    end
  )

  return instance
end

function CollectionStatRow:SetData(data)
  self.Data = data or {}

  ------------------------------------------------
  -- Icon / left label
  ------------------------------------------------
  if self.Data.icon then
    self.Icon:SetTexture(self.Data.icon)
    self.Icon:Show()
    self.LeftLabel:Hide()
    self.IconButton:Show()
  elseif self.Data.label then
    self.Icon:Hide()
    self.LeftLabel:SetText(self.Data.label)
    self.LeftLabel:Show()
    self.IconButton:Show()
  else
    self.Icon:Hide()
    self.LeftLabel:Hide()
    self.IconButton:Hide()
  end

  ------------------------------------------------
  -- Count
  ------------------------------------------------
  self.Count:SetText(
    string.format(
      "%d / %d",
      self.Data.owned or 0,
      self.Data.maximum or 0
    )
  )

  ------------------------------------------------
  -- Percentage
  ------------------------------------------------
  self.Percentage:SetText(
    string.format(
      "%.1f%%",
      self.Data.percentage or 0
    )
  )

  ------------------------------------------------
  -- Progress
  ------------------------------------------------
  self.Progress:SetData({
    maximum = self.Data.maximum or 0,
    segments = {
      {
        value = self.Data.owned or 0,
        color = self.Data.color,
        tooltipTitle = self.Data.tooltipTitle,
        tooltipLines = self.Data.tooltipLines,
      },
    },
  })
end

function CollectionStatRow:GetFrame()
  return self.Frame
end

addon.UI.Components.CollectionStatRow = CollectionStatRow
