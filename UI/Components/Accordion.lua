local _, addon = ...

local Accordion = {}

local DEFAULT_WIDTH = 238
local DEFAULT_HEADER_HEIGHT = 26
local DEFAULT_CONTENT_HEIGHT = 0
local DEFAULT_CONTENT_PADDING = 8

function Accordion:Create(parent, options)
  options = options or {}

  local accordion =
      CreateFrame(
        "Frame",
        nil,
        parent
      )

  accordion.HeaderHeight =
      options.headerHeight
      or DEFAULT_HEADER_HEIGHT

  accordion.ContentHeight =
      options.contentHeight
      or DEFAULT_CONTENT_HEIGHT

  accordion.ContentPadding =
      options.contentPadding

  if accordion.ContentPadding == nil then
    accordion.ContentPadding =
        DEFAULT_CONTENT_PADDING
  end

  accordion.Expanded =
      options.expanded ~= false

  accordion:SetWidth(
    options.width
    or DEFAULT_WIDTH
  )

  accordion.Header =
      addon.UI.Components
      .AccordionHeader:Create(
        accordion,
        {
          label =
              options.title
              or options.label,

          count = options.count,

          expanded =
              accordion.Expanded,

          height =
              accordion.HeaderHeight,

          onClick = function()
            accordion:Toggle()
          end,

          onRightClick =
              options.onRightClick,
        }
      )

  accordion.Header:ClearAllPoints()

  accordion.Header:SetPoint(
    "TOPLEFT",
    accordion,
    "TOPLEFT",
    0,
    0
  )

  accordion.Header:SetPoint(
    "TOPRIGHT",
    accordion,
    "TOPRIGHT",
    0,
    0
  )

  accordion.Header:SetHeight(
    accordion.HeaderHeight
  )

  accordion.Content =
      CreateFrame(
        "Frame",
        nil,
        accordion
      )

  accordion.Content:SetPoint(
    "TOPLEFT",
    accordion.Header,
    "BOTTOMLEFT",
    accordion.ContentPadding,
    -accordion.ContentPadding
  )

  accordion.Content:SetPoint(
    "TOPRIGHT",
    accordion.Header,
    "BOTTOMRIGHT",
    -accordion.ContentPadding,
    -accordion.ContentPadding
  )

  function accordion:SetTitle(title)
    self.Header:SetLabel(title)
  end

  function accordion:GetTitle()
    return self.Header.Label:GetText()
  end

  function accordion:SetCount(count)
    self.Header:SetCount(count)
  end

  function accordion:GetContentFrame()
    return self.Content
  end

  function accordion:SetContentHeight(height)
    self.ContentHeight =
        math.max(
          0,
          tonumber(height) or 0
        )

    self:UpdateLayout()
  end

  function accordion:GetContentHeight()
    return self.ContentHeight
  end

  function accordion:IsExpanded()
    return self.Expanded == true
  end

  function accordion:SetExpanded(
      expanded,
      silent
  )
    expanded = expanded == true

    local changed =
        self.Expanded ~= expanded

    self.Expanded = expanded

    self.Header:SetExpanded(
      self.Expanded
    )

    self:UpdateLayout()

    if changed
        and not silent
        and options.onToggle then
      options.onToggle(
        self,
        self.Expanded
      )
    end
  end

  function accordion:Toggle()
    self:SetExpanded(
      not self.Expanded
    )
  end

  function accordion:UpdateLayout()
    local height =
        self.HeaderHeight

    if self.Expanded then
      self.Content:Show()

      self.Content:SetHeight(
        self.ContentHeight
      )

      if self.ContentHeight > 0 then
        height =
            height
            + self.ContentPadding
            + self.ContentHeight
      end
    else
      self.Content:Hide()
    end

    self:SetHeight(height)

    if options.onHeightChanged then
      options.onHeightChanged(
        self,
        height
      )
    end
  end

  accordion:SetExpanded(
    accordion.Expanded,
    true
  )

  return accordion
end

addon.UI.Components.Accordion = Accordion
