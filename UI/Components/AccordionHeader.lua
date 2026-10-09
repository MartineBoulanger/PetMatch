local _, addon = ...

local AccordionHeader = {}

local DEFAULT_WIDTH = 238
local DEFAULT_HEIGHT = 26

local function CreateArrow(parent)
  local arrow = CreateFrame("Frame", nil, parent)
  arrow:SetSize(8, 8)
  arrow:SetPoint("LEFT", parent, "LEFT", 10, 0)

  arrow.Lines = {}

  for index = 1, 2 do
    local line = arrow:CreateTexture(nil, "ARTWORK")
    line:SetColorTexture(1, 0.82, 0, 1)
    line:SetSize(7, 2)
    arrow.Lines[index] = line
  end

  return arrow
end

local function SetArrowExpanded(arrow, expanded)
  local first = arrow.Lines[1]
  local second = arrow.Lines[2]

  first:ClearAllPoints()
  second:ClearAllPoints()

  if expanded then
    -- Chevron down
    first:SetPoint("CENTER", arrow, "CENTER", -2, 0)
    first:SetRotation(math.rad(-45))

    second:SetPoint("CENTER", arrow, "CENTER", 2, 0)
    second:SetRotation(math.rad(45))
  else
    -- Chevron right
    first:SetPoint("CENTER", arrow, "CENTER", 0, 2)
    first:SetRotation(math.rad(-45))

    second:SetPoint("CENTER", arrow, "CENTER", 0, -2)
    second:SetRotation(math.rad(45))
  end
end

function AccordionHeader:Create(parent, options)
  options = options or {}

  local button =
      CreateFrame(
        "Button",
        nil,
        parent,
        "BackdropTemplate"
      )

  button:SetSize(
    options.width or DEFAULT_WIDTH,
    options.height or DEFAULT_HEIGHT
  )

  button:RegisterForClicks(
    "LeftButtonUp",
    "RightButtonUp"
  )

  button:SetBackdrop({
    bgFile = "Interface\\FrameGeneral\\UI-Background-Marble",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 128,
    edgeSize = 8,
    insets = {
      left = 3,
      right = 3,
      top = 3,
      bottom = 3,
    },
  })

  button:SetBackdropBorderColor(0.35, 0.35, 0.35, 1)

  button.BackgroundGradient = button:CreateTexture(
    nil,
    "BACKGROUND",
    nil,
    1
  )

  button.BackgroundGradient:SetPoint("TOPLEFT", 1, -1)
  button.BackgroundGradient:SetPoint("BOTTOMRIGHT", -1, 1)

  button.BackgroundGradient:SetColorTexture(1, 1, 1, 1)

  button.BackgroundGradient:SetGradient(
    "VERTICAL",
    CreateColor(0.015, 0.015, 0.015, 0.95),
    CreateColor(0.13, 0.13, 0.13, 0.8)
  )

  button.Highlight =
      button:CreateTexture(
        nil,
        "HIGHLIGHT"
      )

  button.Highlight:SetAtlas(
    "PetList-ButtonHighlight",
    true
  )

  button.Highlight:SetPoint(
    "TOPLEFT",
    button,
    "TOPLEFT",
    0,
    0
  )

  button.Highlight:SetPoint(
    "BOTTOMRIGHT",
    button,
    "BOTTOMRIGHT",
    0,
    0
  )

  button.Highlight:SetBlendMode(
    "BLEND"
  )

  button:SetHighlightTexture(
    button.Highlight
  )

  button.Arrow = CreateArrow(button)

  button.Label =
      button:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontNormal"
      )

  button.Label:SetPoint(
    "LEFT",
    button.Arrow,
    "RIGHT",
    12,
    0
  )

  button.Label:SetPoint(
    "RIGHT",
    button,
    "RIGHT",
    -34,
    0
  )

  button.Label:SetJustifyH("LEFT")
  button.Label:SetWordWrap(false)

  button.Count =
      button:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontDisableSmall"
      )

  button.Count:SetPoint(
    "RIGHT",
    button,
    "RIGHT",
    -8,
    0
  )

  function button:SetLabel(label)
    self.Label:SetText(
      label or ""
    )
  end

  function button:SetCount(count)
    if count == nil then
      self.Count:SetText("")
      self.Count:Hide()

      self.Label:SetPoint(
        "RIGHT",
        self,
        "RIGHT",
        -8,
        0
      )

      return
    end

    self.Count:SetText(
      tostring(count)
    )

    self.Count:Show()

    self.Label:SetPoint(
      "RIGHT",
      self,
      "RIGHT",
      -34,
      0
    )
  end

  function button:SetExpanded(expanded)
    self.Expanded = expanded == true

    SetArrowExpanded(self.Arrow, self.Expanded)

    if self.Expanded then
      self:SetBackdropBorderColor(0.20, 0.70, 1.00, 1.00)
      self.Label:SetTextColor(1, 0.82, 0)
    else
      self:SetBackdropBorderColor(0.35, 0.30, 0.20, 0.85)
      self.Label:SetTextColor(0.9, 0.9, 0.9)
    end
  end

  button:SetScript(
    "OnMouseDown",
    function(self)
      self.Label:ClearAllPoints()

      self.Label:SetPoint(
        "LEFT",
        self.Arrow,
        "RIGHT",
        12,
        0
      )

      self.Label:SetPoint(
        "RIGHT",
        self,
        "RIGHT",
        self.Count:IsShown()
        and -34
        or -8,
        0
      )
    end
  )

  button:SetScript(
    "OnMouseUp",
    function(self)
      self.Label:ClearAllPoints()

      self.Label:SetPoint(
        "LEFT",
        self.Arrow,
        "RIGHT",
        12,
        0
      )

      self.Label:SetPoint(
        "RIGHT",
        self,
        "RIGHT",
        self.Count:IsShown()
        and -34
        or -8,
        0
      )
    end
  )

  button:SetScript(
    "OnClick",
    function(self, mouseButton)
      if mouseButton == "RightButton" then
        if options.onRightClick then
          options.onRightClick(
            self
          )
        end

        return
      end

      if mouseButton == "LeftButton"
          and options.onClick then
        options.onClick(
          self
        )
      end
    end
  )

  button:SetLabel(
    options.label
  )

  button:SetCount(
    options.count
  )

  button:SetExpanded(
    options.expanded
  )

  return button
end

addon.UI.Components.AccordionHeader = AccordionHeader
