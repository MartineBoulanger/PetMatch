local _, addon = ...

local L = addon.L
local Dialog = {}
Dialog.__index = Dialog

local DEFAULT_WIDTH = 360
local DEFAULT_HEIGHT = 100
local DEFAULT_FOOTER_HEIGHT = 48
local DEFAULT_PADDING = 14
local DEFAULT_BUTTON_SPACING = 8

local CONTENT_OUTER_MARGIN = 12
local CONTENT_TOP_SPACING = 16
local CONTENT_BOTTOM_SPACING = 8

local function CreateButton(
    parent,
    text,
    width,
    onClick
)
  local button

  if addon.UI.Base
      and addon.UI.Base.Button
      and type(
        addon.UI.Base.Button.Create
      ) == "function" then
    button =
        addon.UI.Base.Button:Create(
          parent,
          {
            text = text or "",
            width = width or 90,
            onClick = onClick,
          }
        )
  else
    button =
        CreateFrame(
          "Button",
          nil,
          parent,
          "UIPanelButtonTemplate"
        )

    button:SetSize(
      width or 90,
      24
    )

    button:SetText(
      text or ""
    )

    button:SetScript(
      "OnClick",
      onClick
    )
  end

  return button
end

local function NormalizeSpacing(
    value,
    defaultValue
)
  if type(value) == "number" then
    return {
      left = value,
      right = value,
      top = value,
      bottom = value,
    }
  end

  value =
      type(value) == "table"
      and value
      or {}

  return {
    left =
        tonumber(value.left)
        or defaultValue,

    right =
        tonumber(value.right)
        or defaultValue,

    top =
        tonumber(value.top)
        or defaultValue,

    bottom =
        tonumber(value.bottom)
        or defaultValue,
  }
end

function Dialog:Create(options)
  options = options or {}

  local instance =
      setmetatable(
        {},
        Dialog
      )

  instance.Width = options.width or DEFAULT_WIDTH
  instance.Height = options.height or DEFAULT_HEIGHT
  instance.Padding = options.padding or DEFAULT_PADDING
  instance.ContentMargin =
      NormalizeSpacing(
        options.contentMargin
        or options.margin,
        CONTENT_OUTER_MARGIN
      )
  instance.TopSpacing =
      tonumber(
        options.topSpacing
      )
      or CONTENT_TOP_SPACING
  instance.BottomSpacing =
      tonumber(
        options.bottomSpacing
      )
      or CONTENT_BOTTOM_SPACING
  instance.ShowFooter = options.showFooter ~= false
  instance.FooterHeight = options.footerHeight or DEFAULT_FOOTER_HEIGHT
  instance.ShowCloseButton = options.showCloseButton ~= false
  instance.CloseOnEscape = options.closeOnEscape ~= false
  instance.CloseOnAccept = options.closeOnAccept ~= false
  instance.AutoHeight = options.autoHeight ~= false
  instance.OnAccept = options.onAccept
  instance.OnCancel = options.onCancel
  instance.OnClose = options.onClose
  instance.OnExtraAccept = options.onExtraAccept

  instance:CreateFrame(options)
  instance:CreateContent()

  if instance.ShowFooter then
    instance:CreateFooter()
  end

  instance:CreateCloseButton(options)

  instance.Frame:Hide()

  return instance
end

function Dialog:CreateFrame(options)
  local parent =
      options.parent
      or UIParent

  local frame =
      CreateFrame(
        "Frame",
        options.name,
        parent,
        "DefaultPanelTemplate"
      )

  frame:SetSize(
    self.Width,
    self.Height
  )

  frame:SetFrameStrata(
    options.frameStrata
    or "DIALOG"
  )

  frame:SetClampedToScreen(true)
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")

  --------------------------------------------------
  -- Blizzard title
  --------------------------------------------------
  if frame.TitleContainer
      and frame.TitleContainer.TitleText then
    frame.TitleContainer.TitleText:SetText(
      options.title
      or ""
    )
  elseif type(frame.SetTitle) == "function" then
    frame:SetTitle(
      options.title
      or ""
    )
  end

  --------------------------------------------------
  -- Dragging
  --------------------------------------------------
  frame:SetScript(
    "OnDragStart",

    function(control)
      control:StartMoving()
    end
  )

  frame:SetScript(
    "OnDragStop",

    function(control)
      control:StopMovingOrSizing()
    end
  )

  --------------------------------------------------
  -- Position
  --------------------------------------------------
  frame:SetPoint(
    options.point
    or "CENTER",

    options.relativeTo
    or UIParent,

    options.relativePoint
    or "CENTER",

    options.offsetX
    or 0,

    options.offsetY
    or 0
  )

  --------------------------------------------------
  -- Escape
  --------------------------------------------------
  if self.CloseOnEscape then
    frame:EnableKeyboard(
      true
    )

    frame:SetPropagateKeyboardInput(
      true
    )

    frame:SetScript(
      "OnKeyDown",

      function(_, key)
        if key == "ESCAPE" then
          self:Cancel()
        end
      end
    )
  end

  self.Frame = frame
end

function Dialog:CreateContent()
  local contentFrame =
      CreateFrame(
        "Frame",
        nil,
        self.Frame,
        "BackdropTemplate"
      )

  local margin = self.ContentMargin

  --------------------------------------------------
  -- Content position
  --------------------------------------------------
  contentFrame:SetPoint(
    "TOPLEFT",
    self.Frame.TitleContainer,
    "BOTTOMLEFT",
    margin.left,
    -(
      self.TopSpacing
      + margin.top
    )
  )

  contentFrame:SetPoint(
    "TOPRIGHT",
    self.Frame,
    "TOPRIGHT",
    -margin.right,
    0
  )

  --------------------------------------------------
  -- Marble background
  --------------------------------------------------
  contentFrame:SetBackdrop({
    bgFile = "Interface\\FrameGeneral\\UI-Background-Marble",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 128,
    edgeSize = 12,
    insets = {
      left = 3,
      right = 3,
      top = 3,
      bottom = 3,
    },
  })

  contentFrame:SetBackdropColor(
    0.63,
    0.63,
    0.63,
    0.85
  )

  contentFrame:SetBackdropBorderColor(
    0.35,
    0.35,
    0.35,
    1
  )

  --------------------------------------------------
  -- Inner content with padding
  --------------------------------------------------
  local content =
      CreateFrame(
        "Frame",
        nil,
        contentFrame
      )

  content:SetPoint(
    "TOPLEFT",
    contentFrame,
    "TOPLEFT",
    self.Padding,
    -self.Padding
  )

  content:SetPoint(
    "TOPRIGHT",
    contentFrame,
    "TOPRIGHT",
    -self.Padding,
    -self.Padding
  )

  content:SetHeight(1)

  contentFrame:SetHeight(
    (self.Padding * 2) + 1
  )

  self.ContentFrame =
      contentFrame

  self.Content =
      content
end

function Dialog:CreateFooter()
  local footer =
      CreateFrame(
        "Frame",
        nil,
        self.Frame
      )

  footer:SetPoint(
    "BOTTOMLEFT",
    self.Frame,
    "BOTTOMLEFT",
    12,
    8
  )

  footer:SetPoint(
    "BOTTOMRIGHT",
    self.Frame,
    "BOTTOMRIGHT",
    -3,
    8
  )

  footer:SetHeight(
    self.FooterHeight
  )

  self.Footer = footer
  self.FooterButtons = {}
end

function Dialog:CreateCloseButton(options)
  if options.showCloseButton == false then
    return
  end

  local button =
      CreateFrame(
        "Button",
        nil,
        self.Frame,
        "UIPanelCloseButton"
      )

  button:SetPoint(
    "TOPRIGHT",
    self.Frame,
    "TOPRIGHT",
    0,
    0
  )

  button:SetScript(
    "OnClick",

    function()
      self:Cancel()
    end
  )

  self.CloseButton = button
end

function Dialog:GetContentHeight()
  if not self.Content then
    return 1
  end

  local contentTop = self.Content:GetTop()

  if not contentTop then
    return 1
  end

  local lowestBottom = contentTop

  local children = {
    self.Content:GetChildren()
  }

  for _, child in ipairs(children) do
    if child:IsShown() then
      local bottom =
          child:GetBottom()

      if bottom
          and bottom < lowestBottom then
        lowestBottom = bottom
      end
    end
  end

  local regions = {
    self.Content:GetRegions()
  }

  for _, region in ipairs(regions) do
    if region:IsShown() then
      local bottom =
          region:GetBottom()

      if bottom
          and bottom < lowestBottom then
        lowestBottom =
            bottom
      end
    end
  end

  return math.max(
    1,
    math.ceil(
      contentTop
      - lowestBottom
    )
  )
end

function Dialog:UpdateHeight()
  if not self.AutoHeight then
    return
  end

  local contentHeight = self:GetContentHeight()

  --------------------------------------------------
  -- Inner content
  --------------------------------------------------
  self.Content:SetHeight(
    contentHeight
  )

  --------------------------------------------------
  -- Background/content frame
  --------------------------------------------------
  local contentFrameHeight =
      contentHeight
      + (self.Padding * 2)

  self.ContentFrame:SetHeight(
    contentFrameHeight
  )

  --------------------------------------------------
  -- Top section
  --------------------------------------------------
  local frameTop = self.Frame:GetTop()
  local contentTop = self.ContentFrame:GetTop()
  local topHeight = 0

  if frameTop
      and contentTop then
    topHeight =
        frameTop
        - contentTop
  end

  --------------------------------------------------
  -- Footer
  --------------------------------------------------
  local footerHeight = 0

  if self.ShowFooter then
    footerHeight = self.FooterHeight
  end

  --------------------------------------------------
  -- Total dialog height
  --------------------------------------------------
  local margin = self.ContentMargin

  local totalHeight =
      topHeight
      + contentFrameHeight
      + margin.bottom
      + self.BottomSpacing
      + footerHeight

  totalHeight =
      math.max(
        totalHeight,
        1
      )

  self.Height =
      math.ceil(
        math.max(
          totalHeight,
          1
        )
      )

  self.Frame:SetHeight(
    self.Height
  )
end

function Dialog:RefreshLayout()
  if not self.AutoHeight then
    return
  end

  C_Timer.After(
    0,

    function()
      if not self.Frame then
        return
      end

      self:UpdateHeight()
    end
  )
end

function Dialog:AddFooterButton(options)
  if not self.ShowFooter
      or not self.Footer then
    error(
      L["FOOTER_ERROR"]
    )
  end

  options = options or {}

  local button

  button =
      CreateButton(
        self.Footer,
        options.text,
        options.width,

        function()
          if options.onClick then
            options.onClick(
              self,
              button
            )
          end
        end
      )

  local previous =
      self.FooterButtons[
      #self.FooterButtons
      ]

  if previous then
    button:SetPoint(
      "RIGHT",
      previous,
      "LEFT",
      -DEFAULT_BUTTON_SPACING,
      0
    )
  else
    button:SetPoint(
      "RIGHT",
      self.Footer,
      "RIGHT",
      -8,
      -6
    )
  end

  table.insert(
    self.FooterButtons,
    button
  )

  return button
end

function Dialog:AddAcceptButton(options)
  options = options or {}

  local button =
      self:AddFooterButton({
        text =
            options.text
            or L["ACCEPT"],

        width =
            options.width
            or 90,

        onClick =
            function()
              self:Accept()
            end,
      })

  self.AcceptButton =
      button

  return button
end

function Dialog:AddExtraButton(options)
  options = options or {}

  local button =
      self:AddFooterButton({
        text =
            options.text
            or L["EXTRA"],

        width =
            options.width
            or 90,

        onClick =
            function()
              self:ExtraAction()
            end,
      })

  self.ExtraButton =
      button

  return button
end

function Dialog:AddCancelButton(options)
  options = options or {}

  local button =
      self:AddFooterButton({
        text =
            options.text
            or L["CANCEL"],

        width =
            options.width
            or 90,

        onClick =
            function()
              self:Cancel()
            end,
      })

  self.CancelButton =
      button

  return button
end

function Dialog:SetTitle(title)
  if self.Frame
      and self.Frame.TitleContainer
      and self.Frame.TitleContainer.TitleText then
    self.Frame.TitleContainer.TitleText:SetText(
      title or ""
    )

    return
  end

  if self.Frame
      and type(self.Frame.SetTitle)
      == "function" then
    self.Frame:SetTitle(
      title or ""
    )
  end
end

function Dialog:GetFrame()
  return self.Frame
end

function Dialog:GetContentFrame()
  return self.Content
end

function Dialog:GetContentBackgroundFrame()
  return self.ContentFrame
end

function Dialog:GetFooterFrame()
  return self.Footer
end

function Dialog:SetSize(
    width,
    height
)
  if width then
    self.Width = width

    self.Frame:SetWidth(
      width
    )
  end

  if height
      and not self.AutoHeight then
    self.Height = height

    self.Frame:SetHeight(
      height
    )
  end

  if self.AutoHeight then
    self:RefreshLayout()
  end
end

function Dialog:Show()
  self.Frame:Show()
  self.Frame:Raise()

  self:RefreshLayout()
end

function Dialog:Hide()
  self.Frame:Hide()

  if self.OnClose then
    self.OnClose(
      self
    )
  end
end

function Dialog:Accept()
  local shouldClose = true

  if self.OnAccept then
    local result =
        self.OnAccept(
          self
        )

    if result == false then
      shouldClose = false
    end
  end

  if shouldClose
      and self.CloseOnAccept then
    self:Hide()
  end
end

function Dialog:ExtraAction()
  local shouldClose = true

  if self.OnExtraAccept then
    local result =
        self.OnExtraAccept(
          self
        )

    if result == false then
      shouldClose = false
    end
  end

  if shouldClose
      and self.CloseOnAccept then
    self:Hide()
  end
end

function Dialog:Cancel()
  local shouldClose = true

  if self.OnCancel then
    local result =
        self.OnCancel(
          self
        )

    if result == false then
      shouldClose = false
    end
  end

  if shouldClose then
    self:Hide()
  end
end

function Dialog:SetAcceptEnabled(enabled)
  if self.AcceptButton then
    self.AcceptButton:SetEnabled(
      enabled == true
    )
  end
end

addon.UI.Base.Dialog = Dialog
