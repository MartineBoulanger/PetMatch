local _, addon = ...

local Source = {}
Source.__index = Source

local MIN_HEIGHT = 14
local BOTTOM_PADDING = 4

function Source:Create(parent)
  local instance =
      setmetatable(
        {},
        Source
      )

  instance.Frame =
      CreateFrame(
        "Frame",
        nil,
        parent
      )

  instance.Frame:SetHeight(
    MIN_HEIGHT
  )

  instance.Text =
      instance.Frame:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlightSmall"
      )

  instance.Text:SetPoint(
    "TOPLEFT",
    instance.Frame,
    "TOPLEFT",
    0,
    0
  )

  instance.Text:SetPoint(
    "TOPRIGHT",
    instance.Frame,
    "TOPRIGHT",
    0,
    0
  )

  instance.Text:SetJustifyH("LEFT")
  instance.Text:SetJustifyV("TOP")
  instance.Text:SetWordWrap(true)
  instance.Text:SetSpacing(1)

  return instance
end

function Source:SetPet(pet)
  local sourceText = pet and pet.sourceText

  if type(sourceText) ~= "string"
      or sourceText == "" then
    sourceText = "Unknown"
  end

  self.Text:SetText(
    sourceText
  )
end

function Source:UpdateHeight()
  local width =
      self.Frame:GetWidth()

  if not width
      or width <= 0 then
    return
  end

  self.Text:SetWidth(width)

  local textHeight =
      math.ceil(
        self.Text:GetStringHeight()
        or 0
      )

  self.Frame:SetHeight(
    math.max(
      MIN_HEIGHT,
      textHeight + BOTTOM_PADDING
    )
  )
end

function Source:GetFrame()
  return self.Frame
end

addon.UI.PetCard.Source = Source
