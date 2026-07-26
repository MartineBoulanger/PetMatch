local _, addon = ...

local AccordionHeader = {}

local DEFAULT_WIDTH = 238
local DEFAULT_HEIGHT = 26

local COLLAPSED_ATLAS = "Options_ListExpand_Right"
local EXPANDED_ATLAS = "Options_ListExpand_Down"

local function SetArrowAtlas(
    texture,
    expanded
)
  local atlas =
      expanded
      and EXPANDED_ATLAS
      or COLLAPSED_ATLAS

  local success =
      pcall(
        texture.SetAtlas,
        texture,
        atlas,
        true
      )

  if not success then
    texture:SetTexture(
      "Interface/Buttons/UI-SpellbookIcon-NextPage-Up"
    )

    texture:SetRotation(
      expanded
      and -math.pi / 2
      or 0
    )
  else
    texture:SetRotation(0)
  end
end

function AccordionHeader:Create(
    parent,
    options
)
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
    bgFile = "Interface/Buttons/WHITE8X8",
    edgeFile = "Interface/Buttons/WHITE8X8",
    edgeSize = 1,
  })

  button:SetBackdropColor(
    0.08,
    0.08,
    0.08,
    0.88
  )

  button:SetBackdropBorderColor(
    0.35,
    0.30,
    0.20,
    0.85
  )

  button.Highlight =
      button:CreateTexture(
        nil,
        "HIGHLIGHT"
      )

  button.Highlight:SetAllPoints()

  button.Highlight:SetColorTexture(0.1, 0.7, 1, 0.08)

  button.Accent =
      button:CreateTexture(
        nil,
        "ARTWORK"
      )

  button.Accent:SetPoint(
    "TOPLEFT",
    button,
    "TOPLEFT",
    0,
    0
  )

  button.Accent:SetPoint(
    "BOTTOMLEFT",
    button,
    "BOTTOMLEFT",
    0,
    0
  )

  button.Accent:SetWidth(3)

  button.Accent:SetColorTexture(
    0.25,
    0.55,
    1,
    1
  )

  button.Arrow =
      button:CreateTexture(
        nil,
        "ARTWORK"
      )

  button.Arrow:SetSize(
    14,
    14
  )

  button.Arrow:SetPoint(
    "LEFT",
    button,
    "LEFT",
    0,
    0
  )

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
    8,
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

    SetArrowAtlas(
      self.Arrow,
      self.Expanded
    )

    if self.Expanded then
      self.Accent:Show()
      self.Label:SetTextColor(
        1,
        0.82,
        0
      )
    else
      self.Accent:Hide()
      self.Label:SetTextColor(
        0.9,
        0.9,
        0.9
      )
    end
  end

  button:SetScript(
    "OnMouseDown",
    function(self)
      self.Label:SetPoint(
        "LEFT",
        self.Arrow,
        "RIGHT",
        6,
        -1
      )
    end
  )

  button:SetScript(
    "OnMouseUp",
    function(self)
      self.Label:SetPoint(
        "LEFT",
        self.Arrow,
        "RIGHT",
        5,
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
