local _, addon = ...

local Description = {}
Description.__index = Description

function Description:Create(parent)
  local self = setmetatable({}, Description)

  self.Frame = CreateFrame("Frame", nil, parent)
  self.Frame:SetPoint("TOPLEFT")
  self.Frame:SetPoint("TOPRIGHT")
  self.Frame:SetHeight(120)

  self.Text = self.Frame:CreateFontString(
    nil,
    "OVERLAY",
    "GameFontNormalSmall"
  )

  self.Text:SetPoint("TOPLEFT", self.Frame, "TOPLEFT", 0, 0)
  self.Text:SetPoint("TOPRIGHT", self.Frame, "TOPRIGHT", 0, 0)

  self.Text:SetJustifyH("CENTER")
  self.Text:SetJustifyV("TOP")
  self.Text:SetWordWrap(true)
  self.Text:SetSpacing(2)

  return self
end

function Description:SetPet(pet)
  local description = pet and pet.description

  if type(description) ~= "string"
      or description == "" then
    description =
    "No description available."
  end

  self.Text:SetText(description)
end

function Description:UpdateHeight()
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
      14,
      textHeight + 4
    )
  )
end

function Description:GetFrame()
  return self.Frame
end

addon.UI.PetCard.Description = Description
