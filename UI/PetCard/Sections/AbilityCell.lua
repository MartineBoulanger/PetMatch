local _, addon = ...

addon.UI.PetCard = addon.UI.PetCard or {}

local AbilityCell = {}
AbilityCell.__index = AbilityCell

local ICON_SIZE = 32
local CURSOR_OFFSET_X = 8
local CURSOR_OFFSET_Y = 8

local function PositionTooltipAtCursor(
    tooltip
)
  if not tooltip then
    return
  end

  local scale = UIParent:GetEffectiveScale()
  local cursorX, cursorY = GetCursorPosition()

  cursorX = cursorX / scale
  cursorY = cursorY / scale

  tooltip:ClearAllPoints()

  tooltip:SetPoint(
    "BOTTOMLEFT",
    UIParent,
    "BOTTOMLEFT",
    cursorX + CURSOR_OFFSET_X,
    cursorY + CURSOR_OFFSET_Y
  )
end

function AbilityCell:Create(parent)
  local self = setmetatable({}, AbilityCell)

  self.Frame = CreateFrame("Frame", nil, parent)
  self.Frame:SetSize(94, 76)

  self.Frame:EnableMouse(true)

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

  self.Frame:SetScript(
    "OnEnter",

    function()
      self:ShowTooltip()
    end
  )

  self.Frame:SetScript(
    "OnLeave",

    function()
      self:HideTooltip()
    end
  )

  return self
end

function AbilityCell:SetAbility(ability)
  if not ability then
    self:Clear()
    self:Hide()
    return
  end

  self.Ability = ability

  self.Icon:SetTexture(ability.icon)

  self.Name:SetText(
    ability.name or ""
  )

  self.Frame:Show()
end

function AbilityCell:ShowTooltip()
  local ability =
      self.Ability

  if not ability then
    return
  end

  local abilityID =
      tonumber(
        ability.abilityID
        or ability.id
      )

  if not abilityID then
    return
  end

  local speciesID =
      tonumber(
        ability.speciesID
        or (
          ability.pet
          and ability.pet.speciesID
        )
      )

  local petGUID =
      ability.petGUID
      or ability.petID
      or (
        ability.pet
        and (
          ability.pet.petGUID
          or ability.pet.petID
        )
      )

  if type(_G.PetJournal_ShowAbilityTooltip)
      ~= "function" then
    return
  end

  _G.PetJournal_ShowAbilityTooltip(
    self.Frame,
    abilityID,
    speciesID,
    petGUID,
    ability.additionalText
  )

  local tooltip = _G.PetJournalPrimaryAbilityTooltip

  if tooltip then
    tooltip:SetFrameStrata(
      "TOOLTIP"
    )

    local cardFrame = self.Frame:GetParent()

    while cardFrame
      and cardFrame:GetParent() do
      if cardFrame:GetWidth() == 360 then
        break
      end

      cardFrame = cardFrame:GetParent()
    end

    local minimumLevel = 200

    if cardFrame then
      minimumLevel =
          math.max(
            minimumLevel,
            cardFrame:GetFrameLevel() + 50
          )
    end

    tooltip:SetFrameLevel(minimumLevel)

    PositionTooltipAtCursor(tooltip)

    tooltip.anchoredTo = self.Frame

    tooltip:Show()
  end
end

function AbilityCell:HideTooltip()
  local tooltip =
      _G.PetJournalPrimaryAbilityTooltip

  if not tooltip then
    return
  end

  if tooltip.anchoredTo
      and tooltip.anchoredTo
      ~= self.Frame then
    return
  end

  tooltip:Hide()
  tooltip.anchoredTo = nil
end

function AbilityCell:Clear()
  self:HideTooltip()

  self.Ability = nil

  self.Icon:SetTexture(nil)
  self.Name:SetText("")
end

function AbilityCell:Show()
  self.Frame:Show()
end

function AbilityCell:Hide()
  self:HideTooltip()
  self.Frame:Hide()
end

-- function AbilityCell:SetPoint(...)
--   self.Frame:SetPoint(...)
-- end

function AbilityCell:SetWidth(width)
  self.Frame:SetWidth(width)

  self.Name:SetWidth(
    math.max(
      1,
      width - 10
    )
  )
end

function AbilityCell:SetHeight(height)
  self.Frame:SetHeight(height)
end

function AbilityCell:SetEnabled(enabled)
  self.Enabled = enabled ~= false

  local alpha = self.Enabled and 1 or 0.4

  self.Icon:SetAlpha(alpha)
  self.Name:SetAlpha(alpha)
end

function AbilityCell:GetFrame()
  return self.Frame
end

addon.UI.PetCard.AbilityCell = AbilityCell
