local _, addon = ...

local AbilityCell = {}
AbilityCell.__index = AbilityCell

local ICON_SIZE = 32

function AbilityCell:Create(parent)
  local self = setmetatable({}, AbilityCell)

  self.Frame = CreateFrame("Frame", nil, parent)
  self.Frame:SetSize(100, 82)

  self.Icon = self.Frame:CreateTexture(nil, "ARTWORK")
  self.Icon:SetSize(ICON_SIZE, ICON_SIZE)

  self.Icon:SetPoint(
    "TOP",
    self.Frame,
    "TOP",
    0,
    0
  )

  self.Icon:SetTexCoord(
    0.08,
    0.92,
    0.08,
    0.92
  )

  self.Name = self.Frame:CreateFontString(
    nil,
    "OVERLAY",
    "GameTooltipText"
  )

  self.Name:SetPoint(
    "TOP",
    self.Icon,
    "BOTTOM",
    0,
    -4
  )

  self.Name:SetWidth(90)
  self.Name:SetJustifyH("CENTER")
  self.Name:SetWordWrap(true)

  self.Level = self.Frame:CreateFontString(
    nil,
    "OVERLAY",
    "GameTooltipTextSmall"
  )

  self.Level:SetPoint(
    "TOP",
    self.Name,
    "BOTTOM",
    0,
    -2
  )

  self.Level:SetJustifyH("CENTER")

  return self
end

function AbilityCell:SetAbility(ability)
  if not ability then
    self:Hide()
    return
  end

  self.Icon:SetTexture(ability.icon)

  self.Name:SetText(
    ability.name or ""
  )

  self.Level:SetText(
    string.format(
      "Lvl %d",
      ability.requiredLevel or 1
    )
  )

  self.Frame:Show()
end

function AbilityCell:Clear()
  self.Icon:SetTexture(nil)
  self.Name:SetText("")
  self.Level:SetText("")
end

function AbilityCell:Show()
  self.Frame:Show()
end

function AbilityCell:Hide()
  self.Frame:Hide()
end

function AbilityCell:SetPoint(...)
  self.Frame:SetPoint(...)
end

function AbilityCell:SetWidth(width)
  self.Frame:SetWidth(width)

  self.Name:SetWidth(width - 10)
end

function AbilityCell:SetHeight(height)
  self.Frame:SetHeight(height)
end

function AbilityCell:SetEnabled(enabled)
  local alpha = enabled and 1 or 0.4

  self.Icon:SetAlpha(alpha)
  self.Name:SetAlpha(alpha)
  self.Level:SetAlpha(alpha)
end

addon.UI.Base.AbilityCell = AbilityCell
