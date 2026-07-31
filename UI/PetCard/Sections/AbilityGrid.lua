local _, addon = ...

local AbilityCell = addon.UI.PetCard.AbilityCell

local AbilityGrid = {}
AbilityGrid.__index = AbilityGrid

local COLUMN_COUNT = 3
local ROW_COUNT = 2

local HEADER_HEIGHT = 18
local CELL_HEIGHT = 72
local ROW_SPACING = 0
local HEADER_SPACING = 4

function AbilityGrid:Create(parent)
  local self = setmetatable({}, AbilityGrid)

  self.Frame = CreateFrame("Frame", nil, parent)

  self.Headers = {}
  self.Cells = {}

  for slot = 1, COLUMN_COUNT do
    local header = self.Frame:CreateFontString(
      nil,
      "OVERLAY",
      "GameTooltipText"
    )

    header:SetText(("Slot %d"):format(slot))
    header:SetJustifyH("CENTER")

    self.Headers[slot] = header

    self.Cells[slot] = {}

    for choice = 1, ROW_COUNT do
      self.Cells[slot][choice] =
          AbilityCell:Create(self.Frame)
    end
  end

  self.Frame:SetHeight(
    HEADER_HEIGHT +
    HEADER_SPACING +
    (CELL_HEIGHT * ROW_COUNT)
  )

  self.Frame:SetScript(
    "OnSizeChanged",
    function()
      self:Layout()
    end
  )

  return self
end

function AbilityGrid:Layout()
  local width = self.Frame:GetWidth()

  local columnWidth = width / COLUMN_COUNT

  for slot = 1, COLUMN_COUNT do
    local center =
        ((slot - 1) * columnWidth) +
        (columnWidth / 2)

    local header = self.Headers[slot]

    header:ClearAllPoints()

    header:SetPoint(
      "TOP",
      self.Frame,
      "TOPLEFT",
      center,
      0
    )

    for choice = 1, ROW_COUNT do
      local cell = self.Cells[slot][choice]

      cell:SetWidth(columnWidth)

      cell:ClearAllPoints()

      local y =
          HEADER_HEIGHT +
          HEADER_SPACING +
          ((choice - 1) * (CELL_HEIGHT + ROW_SPACING))

      cell:SetPoint(
        "TOP",
        self.Frame,
        "TOPLEFT",
        center,
        -y
      )
    end
  end
end

function AbilityCell:ClearAllPoints()
  self.Frame:ClearAllPoints()
end

function AbilityGrid:SetAbilities(slots)
  for slot = 1, COLUMN_COUNT do
    local abilities = slots[slot] or {}

    table.sort(
      abilities,
      function(a, b)
        return (a.choice or 1) <
            (b.choice or 1)
      end
    )

    for choice = 1, ROW_COUNT do
      self.Cells[slot][choice]:SetAbility(
        abilities[choice]
      )
    end
  end
end

function AbilityGrid:SetPet(pet)
  if not pet
      or pet.canBattle ~= true
      or type(pet.abilities) ~= "table"
      or #pet.abilities == 0 then
    self:Clear()
    self:Hide()

    return false
  end

  local slots = {
    [1] = {},
    [2] = {},
    [3] = {},
  }

  for _, ability in ipairs(pet.abilities) do
    local slot = tonumber(ability.slot)

    if slot and slots[slot] then
      table.insert(
        slots[slot],
        ability
      )
    end
  end

  self:SetAbilities(slots)
  self:Show()

  return true
end

function AbilityGrid:Clear()
  for slot = 1, COLUMN_COUNT do
    for choice = 1, ROW_COUNT do
      self.Cells[slot][choice]:Clear()
      self.Cells[slot][choice]:Hide()
    end
  end
end

function AbilityGrid:GetFrame()
  return self.Frame
end

function AbilityGrid:Show()
  self.Frame:Show()
end

function AbilityGrid:Hide()
  self.Frame:Hide()
end

addon.UI.PetCard.AbilityGrid = AbilityGrid
