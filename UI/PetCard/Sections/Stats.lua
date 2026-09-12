local _, addon = ...

local Stats = {}
Stats.__index = Stats

local INFO_ROW_HEIGHT = 18
local STAT_ROW_HEIGHT = 16
local ROW_SPACING = 2
local SECTION_SPACING = 6
local ICON_SIZE = 14

local STAT_ICONS = {
  health = "Interface\\Icons\\Petbattle_Health",
  power = "Interface\\Icons\\Petbattle_Attack",
  speed = "Interface\\Icons\\Petbattle_Speed",
}

local PET_RARITY_COLORS = addon.Constants.PET_RARITY_COLORS

--------------------------------------------------
-- Helpers
--------------------------------------------------

local function GetQualityColor(quality)
  quality = tonumber(quality) or 0

  local color =
      PET_RARITY_COLORS[quality]

  if not color then
    return 1, 1, 1
  end

  return
      color.r or 1,
      color.g or 1,
      color.b or 1
end

local function CreateInfoRow(parent, font)
  local row =
      CreateFrame(
        "Frame",
        nil,
        parent
      )

  row:SetHeight(
    INFO_ROW_HEIGHT
  )

  row.Value =
      row:CreateFontString(
        nil,
        "OVERLAY",
        font or "GameFontHighlight"
      )

  row.Value:SetPoint(
    "LEFT",
    row,
    "LEFT",
    0,
    0
  )

  row.Value:SetPoint(
    "RIGHT",
    row,
    "RIGHT",
    0,
    0
  )

  row.Value:SetJustifyH("LEFT")
  row.Value:SetWordWrap(false)

  return row
end

local function CreateStatRow(
    parent,
    iconTexture
)
  local row =
      CreateFrame(
        "Frame",
        nil,
        parent
      )

  row:SetHeight(
    STAT_ROW_HEIGHT
  )

  row.Icon =
      row:CreateTexture(
        nil,
        "ARTWORK"
      )

  row.Icon:SetSize(
    ICON_SIZE,
    ICON_SIZE
  )

  row.Icon:SetPoint(
    "LEFT",
    row,
    "LEFT",
    0,
    0
  )

  row.Icon:SetTexture(
    iconTexture
  )

  row.Value =
      row:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlight"
      )

  row.Value:SetPoint(
    "LEFT",
    row.Icon,
    "RIGHT",
    3,
    0
  )

  row.Value:SetPoint(
    "RIGHT",
    row,
    "RIGHT",
    0,
    0
  )

  row.Value:SetJustifyH("LEFT")
  row.Value:SetWordWrap(false)

  return row
end

--------------------------------------------------
-- Create
--------------------------------------------------
function Stats:Create(parent)
  local instance =
      setmetatable(
        {},
        Stats
      )

  instance.Frame =
      CreateFrame(
        "Frame",
        nil,
        parent
      )

  --------------------------------------------------
  -- Level
  --------------------------------------------------

  instance.Level =
      CreateInfoRow(
        instance.Frame,
        "GameFontNormal"
      )

  instance.Level:SetPoint(
    "TOPLEFT",
    instance.Frame,
    "TOPLEFT",
    0,
    0
  )

  instance.Level:SetPoint(
    "TOPRIGHT",
    instance.Frame,
    "TOPRIGHT",
    0,
    0
  )

  --------------------------------------------------
  -- Expansion
  --------------------------------------------------

  instance.Expansion =
      CreateInfoRow(
        instance.Frame,
        "GameFontHighlight"
      )

  instance.Expansion:SetPoint(
    "TOPLEFT",
    instance.Level,
    "BOTTOMLEFT",
    0,
    -ROW_SPACING
  )

  instance.Expansion:SetPoint(
    "TOPRIGHT",
    instance.Level,
    "BOTTOMRIGHT",
    0,
    -ROW_SPACING
  )

  --------------------------------------------------
  -- Health
  --------------------------------------------------

  instance.Health =
      CreateStatRow(
        instance.Frame,
        STAT_ICONS.health
      )

  instance.Health:SetPoint(
    "TOPLEFT",
    instance.Expansion,
    "BOTTOMLEFT",
    0,
    -SECTION_SPACING
  )

  instance.Health:SetPoint(
    "TOPRIGHT",
    instance.Expansion,
    "BOTTOMRIGHT",
    0,
    -SECTION_SPACING
  )

  --------------------------------------------------
  -- Power
  --------------------------------------------------

  instance.Power =
      CreateStatRow(
        instance.Frame,
        STAT_ICONS.power
      )

  instance.Power:SetPoint(
    "TOPLEFT",
    instance.Health,
    "BOTTOMLEFT",
    0,
    -ROW_SPACING
  )

  instance.Power:SetPoint(
    "TOPRIGHT",
    instance.Health,
    "BOTTOMRIGHT",
    0,
    -ROW_SPACING
  )

  --------------------------------------------------
  -- Speed
  --------------------------------------------------

  instance.Speed =
      CreateStatRow(
        instance.Frame,
        STAT_ICONS.speed
      )

  instance.Speed:SetPoint(
    "TOPLEFT",
    instance.Power,
    "BOTTOMLEFT",
    0,
    -ROW_SPACING
  )

  instance.Speed:SetPoint(
    "TOPRIGHT",
    instance.Power,
    "BOTTOMRIGHT",
    0,
    -ROW_SPACING
  )

  --------------------------------------------------
  -- Height
  --------------------------------------------------

  local totalHeight =
      (INFO_ROW_HEIGHT * 2)
      + (STAT_ROW_HEIGHT * 3)
      + ROW_SPACING
      + SECTION_SPACING
      + (ROW_SPACING * 2)

  instance.Frame:SetHeight(
    totalHeight
  )

  return instance
end

--------------------------------------------------
-- Set pet
--------------------------------------------------
function Stats:SetPet(pet)
  if not pet then
    self.Frame:Hide()
    return false
  end

  self.Frame:Show()

  --------------------------------------------------
  -- Quality
  --------------------------------------------------

  local r, g, b =
      GetQualityColor(
        pet.quality
      )

  --------------------------------------------------
  -- Level
  --------------------------------------------------

  if pet.level
      and pet.level > 0 then
    self.Level.Value:SetFormattedText(
      "Level %d",
      pet.level
    )
  else
    self.Level.Value:SetText(
      "Not Collected"
    )
  end

  self.Level.Value:SetTextColor(
    r,
    g,
    b,
    1
  )

  --------------------------------------------------
  -- Expansion
  --------------------------------------------------

  if pet.expansionName
      and pet.expansionName ~= "" then
    self.Expansion.Value:SetText(
      pet.expansionName
    )

    self.Expansion:Show()
  else
    self.Expansion.Value:SetText("")
    self.Expansion:Hide()
  end

  --------------------------------------------------
  -- Stats
  --------------------------------------------------

  local hasStats =
      pet.petGUID
      and (
        pet.health ~= nil
        or pet.power ~= nil
        or pet.speed ~= nil
      )

  if hasStats then
    self.Health.Value:SetFormattedText(
      "%s",
      tostring(
        pet.maxHealth
        or pet.health
        or "0"
      )
    )

    self.Power.Value:SetFormattedText(
      "%s",
      tostring(
        pet.power
        or "0"
      )
    )

    self.Speed.Value:SetFormattedText(
      "%s",
      tostring(
        pet.speed
        or "0"
      )
    )

    self.Health:Show()
    self.Power:Show()
    self.Speed:Show()
  else
    self.Health:Hide()
    self.Power:Hide()
    self.Speed:Hide()
  end

  return true
end

--------------------------------------------------
-- Accessors
--------------------------------------------------
function Stats:GetFrame()
  return self.Frame
end

addon.UI.PetCard.Stats = Stats
