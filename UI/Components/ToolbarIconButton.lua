local _, addon = ...

local ToolbarIconButton = {}
ToolbarIconButton.__index = ToolbarIconButton

local DEFAULT_SIZE = 28

local function CopyBorderStyle(targetButton, sourceButton)
  if not targetButton
      or not sourceButton
      or not sourceButton.Border then
    return
  end

  local sourceBorder = sourceButton.Border

  local border =
      targetButton:CreateTexture(
        nil,
        "OVERLAY",
        nil,
        7
      )

  local atlas = sourceBorder.GetAtlas and sourceBorder:GetAtlas()

  if atlas then
    border:SetAtlas(
      atlas,
      false
    )
  else
    local texture = sourceBorder:GetTexture()

    if not texture then
      return
    end

    border:SetTexture(texture)
    border:SetTexCoord(sourceBorder:GetTexCoord())
  end

  local sourceWidth = sourceButton:GetWidth()
  local sourceHeight = sourceButton:GetHeight()
  local borderWidth = sourceBorder:GetWidth()
  local borderHeight = sourceBorder:GetHeight()

  border:ClearAllPoints()

  if sourceWidth > 0
      and sourceHeight > 0
      and borderWidth > 0
      and borderHeight > 0 then
    border:SetSize(
      targetButton:GetWidth()
      * borderWidth
      / sourceWidth,

      targetButton:GetHeight()
      * borderHeight
      / sourceHeight
    )

    border:SetPoint(
      "CENTER",
      targetButton,
      "CENTER"
    )
  else
    border:SetAllPoints(targetButton)
  end

  border:SetVertexColor(sourceBorder:GetVertexColor())
  border:SetAlpha(sourceBorder:GetAlpha())

  border:Show()

  targetButton.Border = border
end

local function CopyHighlightStyle(targetButton, sourceButton)
  if not targetButton or not sourceButton then
    return
  end

  local sourceHighlight = sourceButton:GetHighlightTexture()

  if not sourceHighlight then
    return
  end

  local highlight = targetButton:GetHighlightTexture()

  if not highlight then
    highlight =
        targetButton:CreateTexture(
          nil,
          "HIGHLIGHT"
        )

    targetButton:SetHighlightTexture(highlight)
  end

  local atlas = sourceHighlight.GetAtlas and sourceHighlight:GetAtlas()

  if atlas then
    highlight:SetAtlas(atlas, false)
  else
    local texture = sourceHighlight:GetTexture()

    if texture then
      highlight:SetTexture(texture)
    end

    highlight:SetTexCoord(sourceHighlight:GetTexCoord())
  end

  highlight:ClearAllPoints()

  local sourceButtonWidth = sourceButton:GetWidth()
  local sourceButtonHeight = sourceButton:GetHeight()
  local sourceWidth = sourceHighlight:GetWidth()
  local sourceHeight = sourceHighlight:GetHeight()

  if sourceButtonWidth > 0
      and sourceButtonHeight > 0
      and sourceWidth > 0
      and sourceHeight > 0 then
    highlight:SetSize(
      targetButton:GetWidth()
      * sourceWidth
      / sourceButtonWidth,

      targetButton:GetHeight()
      * sourceHeight
      / sourceButtonHeight
    )

    highlight:SetPoint(
      "CENTER",
      targetButton,
      "CENTER"
    )
  else
    highlight:SetAllPoints(targetButton)
  end

  highlight:SetBlendMode(sourceHighlight:GetBlendMode())
  highlight:SetVertexColor(sourceHighlight:GetVertexColor())
  highlight:SetAlpha(sourceHighlight:GetAlpha())

  highlight:Show()
end

function ToolbarIconButton:ShowTooltip(button, title, description, itemID)
  GameTooltip:SetOwner(
    button,
    "ANCHOR_RIGHT"
  )

  if itemID then
    GameTooltip:SetItemByID(itemID)
  elseif title then
    GameTooltip:SetText(
      title,
      1,
      1,
      1
    )

    if description then
      GameTooltip:AddLine(
        description,
        nil,
        nil,
        nil,
        true
      )
    end
  end

  GameTooltip:Show()
end

function ToolbarIconButton:ApplyStyle(
    button,
    styleSource
)
  if not button
      or not styleSource then
    return
  end

  CopyBorderStyle(
    button,
    styleSource
  )

  CopyHighlightStyle(
    button,
    styleSource
  )
end

function ToolbarIconButton:Create(parent, options)
  options = options or {}

  local instance =
      setmetatable(
        {},
        ToolbarIconButton
      )

  local button =
      CreateFrame(
        "Button",
        options.name,
        parent,
        "IconButtonTemplate"
      )

  button:SetSize(
    options.width
    or options.size
    or DEFAULT_SIZE,

    options.height
    or options.size
    or DEFAULT_SIZE
  )

  button:RegisterForClicks("LeftButtonUp")

  instance.Frame = button
  instance.ItemID = options.itemID

  --------------------------------------------------
  -- Icon
  --------------------------------------------------
  if button.Icon then
    button.Icon:ClearAllPoints()
    button.Icon:SetAllPoints(button)

    local texture = options.texture

    if not texture and options.itemID then
      texture = C_Item.GetItemIconByID(options.itemID)
    end

    if texture then
      button.Icon:SetTexture(texture)
    end

    button.Icon:SetTexCoord(0, 1, 0, 1)
  end

  --------------------------------------------------
  -- Optional source styling
  --------------------------------------------------
  if options.styleSource then
    self:ApplyStyle(
      button,
      options.styleSource
    )
  end

  --------------------------------------------------
  -- Count
  --------------------------------------------------
  if options.showCount then
    instance.Count =
        button:CreateFontString(
          nil,
          "OVERLAY",
          "NumberFontNormalSmall"
        )

    instance.Count:SetPoint(
      "BOTTOMRIGHT",
      button,
      "BOTTOMRIGHT",
      -2,
      2
    )

    instance.Count:SetJustifyH("RIGHT")
  end

  --------------------------------------------------
  -- Tooltip
  --------------------------------------------------
  button:SetScript(
    "OnEnter",
    function()
      self:ShowTooltip(
        button,
        options.tooltipTitle,
        options.tooltipDescription,
        options.itemID
      )
    end
  )

  button:SetScript(
    "OnLeave",
    function()
      GameTooltip:Hide()
    end
  )

  --------------------------------------------------
  -- Click
  --------------------------------------------------
  button:SetScript(
    "OnClick",
    function()
      if not button:IsEnabled() then
        return
      end
      if options.onClick then
        options.onClick(instance)
      end
    end
  )

  return instance
end

function ToolbarIconButton:SetCount(count)
  count = tonumber(count) or 0

  if self.Count then
    self.Count:SetText(tostring(count))
  end
end

function ToolbarIconButton:SetEnabled(enabled)
  enabled = enabled == true

  self.Frame:SetEnabled(enabled)

  if self.Frame.Icon then
    self.Frame.Icon:SetDesaturated(not enabled)
    self.Frame.Icon:SetAlpha(enabled and 1 or 0.45)
  end

  if self.Count then
    self.Count:SetAlpha(enabled and 1 or 0.65)
  end
end

function ToolbarIconButton:GetFrame()
  return self.Frame
end

addon.UI.Components.ToolbarIconButton = ToolbarIconButton
