local _, addon = ...

addon.UI.PetCard = addon.UI.PetCard or {}

local AbilityCell = {}
AbilityCell.__index = AbilityCell

local ICON_SIZE = 35
local FAMILY_ICON_SIZE = 50

local CURSOR_OFFSET_X = 8
local CURSOR_OFFSET_Y = 8

local DEFAULT_BORDER_COLOR = { 0.32, 0.32, 0.32, 1, }

local function PositionTooltipAtCursor(tooltip)
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

local function GetAbilityPetType(abilityID)
  abilityID = tonumber(abilityID)

  if not abilityID then
    return nil
  end

  if not C_PetJournal
      or type(C_PetJournal.GetPetAbilityInfo) ~= "function" then
    return nil
  end

  local _, _, petType = C_PetJournal.GetPetAbilityInfo(abilityID)

  petType = tonumber(petType)

  if not petType or petType < 1 or petType > 10 then
    return nil
  end

  return petType
end

function AbilityCell:Create(parent)
  local self = setmetatable({}, AbilityCell)
  self.Highlighted = false

  --------------------------------------------------
  -- Cell frame
  --------------------------------------------------
  self.Frame = CreateFrame("Frame", nil, parent)

  self.Frame:EnableMouse(true)

  --------------------------------------------------
  -- Blizzard Pet Journal slot background
  --------------------------------------------------
  self.Background = self.Frame:CreateTexture(nil, "BACKGROUND")

  self.Background:SetAllPoints()

  self.Background:SetAtlas("PetJournal-PetCard-BG")

  --------------------------------------------------
  -- Border
  --------------------------------------------------
  self.Border = CreateFrame("Frame", nil, self.Frame, "BackdropTemplate")

  self.Border:SetAllPoints()

  self.Border:SetBackdrop({
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 1,
    inset = {
      left = 2,
      right = 2,
      top = 2,
      bottom = 2
    }
  })

  self.Border:SetBackdropBorderColor(
    DEFAULT_BORDER_COLOR[1],
    DEFAULT_BORDER_COLOR[2],
    DEFAULT_BORDER_COLOR[3],
    DEFAULT_BORDER_COLOR[4]
  )

  self.Border:SetFrameLevel(self.Frame:GetFrameLevel() + 2)

  self.Border:EnableMouse(false)

  --------------------------------------------------
  -- Family background
  --------------------------------------------------
  self.FamilyBackground = self.Frame:CreateTexture(nil, "BACKGROUND", nil, 1)

  self.FamilyBackground:SetSize(FAMILY_ICON_SIZE, FAMILY_ICON_SIZE)

  self.FamilyBackground:SetPoint(
    "RIGHT",
    self.Frame,
    "RIGHT",
    0,
    0
  )

  self.FamilyBackground:SetAlpha(0.46)

  --------------------------------------------------
  -- Ability icon
  --------------------------------------------------
  self.Icon = self.Frame:CreateTexture(nil, "ARTWORK")

  self.Icon:SetSize(ICON_SIZE, ICON_SIZE)

  self.Icon:SetPoint(
    "LEFT",
    self.Frame,
    "LEFT",
    7,
    0
  )

  self.Icon:SetTexCoord(
    0.08,
    0.92,
    0.08,
    0.92
  )

  --------------------------------------------------
  -- Ability icon border
  --------------------------------------------------
  self.IconBorderFrame = CreateFrame("Frame", nil, self.Frame)

  self.IconBorderFrame:SetSize(
    ICON_SIZE + 4,
    ICON_SIZE + 4
  )

  self.IconBorderFrame:SetPoint(
    "CENTER",
    self.Icon,
    "CENTER",
    0,
    0
  )

  self.IconBorderFrame:SetFrameLevel(
    self.Frame:GetFrameLevel() + 20
  )

  self.IconBorderFrame:EnableMouse(false)

  --------------------------------------------------
  -- Normal icon border
  --------------------------------------------------
  self.NormalBorderFrame = CreateFrame("Frame", nil, self.Frame, "BackdropTemplate")

  self.NormalBorderFrame:SetSize(
    ICON_SIZE + 4,
    ICON_SIZE + 4
  )

  self.NormalBorderFrame:SetPoint(
    "CENTER",
    self.Icon,
    "CENTER",
    0,
    0
  )

  self.NormalBorderFrame:SetBackdrop({
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 8,
  })

  self.NormalBorderFrame:SetBackdropBorderColor(
    0.35,
    0.35,
    0.35,
    1
  )

  self.NormalBorderFrame:SetFrameLevel(
    self.Frame:GetFrameLevel() + 10
  )

  self.NormalBorderFrame:EnableMouse(false)

  --------------------------------------------------
  -- Selected / highlighted border
  --------------------------------------------------
  self.HighlightBorder =
      self.IconBorderFrame:CreateTexture(
        nil,
        "OVERLAY",
        nil,
        1
      )

  self.HighlightBorder:SetAllPoints()

  self.HighlightBorder:SetTexture(
    "Interface\\Buttons\\UI-Quickslot-Depress"
  )

  self.HighlightBorder:SetBlendMode("ADD")
  self.HighlightBorder:Hide()

  --------------------------------------------------
  -- Ability name
  --------------------------------------------------
  self.Name = self.Frame:CreateFontString(nil, "OVERLAY", "GameTooltipText")

  self.Name:SetPoint(
    "LEFT",
    self.Icon,
    "RIGHT",
    6,
    0
  )

  self.Name:SetPoint(
    "RIGHT",
    self.Frame,
    "RIGHT",
    -8,
    0
  )

  self.Name:SetJustifyH("LEFT")
  self.Name:SetJustifyV("MIDDLE")

  self.Name:SetWordWrap(true)
  self.Name:SetNonSpaceWrap(false)

  --------------------------------------------------
  -- Tooltip
  --------------------------------------------------
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

  --------------------------------------------------
  -- Ability icon
  --------------------------------------------------
  self.Icon:SetTexture(ability.icon)

  --------------------------------------------------
  -- Ability name
  --------------------------------------------------
  self.Name:SetText(ability.name or "")

  --------------------------------------------------
  -- Ability family
  --------------------------------------------------
  local abilityID = ability.abilityID or ability.id
  local petType = GetAbilityPetType(abilityID)
  local familyTexture = petType and addon.Constants.PET_FAMILY_ICONS[petType]

  if familyTexture then
    self.FamilyBackground:SetTexture(familyTexture)
    self.FamilyBackground:Show()
  else
    self.FamilyBackground:SetTexture(nil)
    self.FamilyBackground:Hide()
  end

  self.Frame:Show()
end

function AbilityCell:SetHighlighted(highlighted)
  self.Highlighted = highlighted == true

  if self.NormalIconBorder then
    self.NormalIconBorder:SetShown(not self.Highlighted)
  end

  if self.HighlightBorder then
    self.HighlightBorder:SetShown(self.Highlighted)
  end
end

function AbilityCell:ShowTooltip()
  local ability = self.Ability

  if not ability then
    return
  end

  local abilityID = tonumber(ability.abilityID or ability.id)

  if not abilityID then
    return
  end

  local speciesID = tonumber(ability.speciesID
    or (ability.pet and ability.pet.speciesID)
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

  if type(_G.PetJournal_ShowAbilityTooltip) ~= "function" then
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

  if not tooltip then
    return
  end

  tooltip:SetFrameStrata("TOOLTIP")

  local cardFrame = self.Frame:GetParent()

  while cardFrame and cardFrame:GetParent() do
    if cardFrame:GetWidth() == 360 then
      break
    end

    cardFrame = cardFrame:GetParent()
  end

  local minimumLevel = 200

  if cardFrame then
    minimumLevel = math.max(minimumLevel, cardFrame:GetFrameLevel() + 50)
  end

  tooltip:SetFrameLevel(minimumLevel)

  PositionTooltipAtCursor(tooltip)

  tooltip.anchoredTo = self.Frame

  tooltip:Show()
end

function AbilityCell:HideTooltip()
  local tooltip = _G.PetJournalPrimaryAbilityTooltip

  if not tooltip then
    return
  end

  if tooltip.anchoredTo and tooltip.anchoredTo ~= self.Frame then
    return
  end

  tooltip:Hide()
  tooltip.anchoredTo = nil
end

function AbilityCell:Clear()
  self:HideTooltip()

  self.Ability = nil

  self:SetHighlighted(false)

  self.Icon:SetTexture(nil)
  self.Name:SetText("")

  self.FamilyBackground:SetTexture(nil)
  self.FamilyBackground:Hide()
end

function AbilityCell:Show()
  self.Frame:Show()
end

function AbilityCell:Hide()
  self:HideTooltip()
  self.Frame:Hide()
end

function AbilityCell:SetWidth(width)
  self.Frame:SetWidth(width)
end

function AbilityCell:SetHeight(height)
  self.Frame:SetHeight(height)
end

function AbilityCell:SetEnabled(enabled)
  self.Enabled = enabled ~= false

  local alpha = self.Enabled and 1 or 0.4

  self.Icon:SetAlpha(alpha)
  self.Name:SetAlpha(alpha)

  self.FamilyBackground:SetAlpha(
    self.Enabled
    and 0.12
    or 0.05
  )
end

function AbilityCell:GetFrame()
  return self.Frame
end

addon.UI.PetCard.AbilityCell = AbilityCell
