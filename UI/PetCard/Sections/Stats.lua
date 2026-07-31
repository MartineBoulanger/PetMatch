local _, addon = ...

local Stats = {}
Stats.__index = Stats

local ROW_HEIGHT = 16
local ROW_SPACING = 2
local ICON_SIZE = 14

local STAT_ICONS = {
  health = "Interface\\Icons\\Petbattle_Health",
  power = "Interface\\Icons\\Petbattle_Attack",
  speed = "Interface\\Icons\\Petbattle_Speed",
}

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
    ROW_HEIGHT
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

  instance.Health =
      CreateStatRow(
        instance.Frame,
        STAT_ICONS.health
      )

  instance.Power =
      CreateStatRow(
        instance.Frame,
        STAT_ICONS.power
      )

  instance.Speed =
      CreateStatRow(
        instance.Frame,
        STAT_ICONS.speed
      )

  local rows = {
    instance.Health,
    instance.Power,
    instance.Speed,
    instance.SpeciesID,
  }

  for index, row in ipairs(rows) do
    row:SetPoint(
      "LEFT",
      instance.Frame,
      "LEFT",
      0,
      0
    )

    row:SetPoint(
      "RIGHT",
      instance.Frame,
      "RIGHT",
      0,
      0
    )

    if index == 1 then
      row:SetPoint(
        "TOP",
        instance.Frame,
        "TOP",
        0,
        0
      )
    else
      row:SetPoint(
        "TOP",
        rows[index - 1],
        "BOTTOM",
        0,
        -ROW_SPACING
      )
    end
  end

  local totalHeight =
      (#rows * ROW_HEIGHT)
      + (
        (#rows - 1)
        * ROW_SPACING
      )

  instance.Frame:SetHeight(
    totalHeight
  )

  return instance
end

function Stats:SetPet(pet)
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
      pet.power or "0"
    )
  )

  self.Speed.Value:SetFormattedText(
    "%s",
    tostring(
      pet.speed or "0"
    )
  )
end

function Stats:GetFrame()
  return self.Frame
end

addon.UI.PetCard.Stats = Stats
