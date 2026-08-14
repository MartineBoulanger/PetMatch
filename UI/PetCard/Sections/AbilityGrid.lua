local _, addon = ...

local AbilityCell =
    addon.UI.PetCard.AbilityCell

local AbilityGrid = {}
AbilityGrid.__index = AbilityGrid

local SLOT_COUNT = 3
local CHOICE_COUNT = 2

local CELL_HEIGHT = 44

function AbilityGrid:Create(parent)
  local self =
      setmetatable(
        {},
        AbilityGrid
      )

  self.Frame =
      CreateFrame(
        "Frame",
        nil,
        parent
      )

  self.Cells = {}

  --------------------------------------------------
  -- 3 rows × 2 columns
  --------------------------------------------------
  for slot = 1, SLOT_COUNT do
    self.Cells[slot] = {}

    for choice = 1, CHOICE_COUNT do
      self.Cells[slot][choice] =
          AbilityCell:Create(
            self.Frame
          )
    end
  end

  self.Frame:SetHeight(
    SLOT_COUNT * CELL_HEIGHT
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

  if not width
      or width <= 0 then
    return
  end

  local columnWidth = width / CHOICE_COUNT

  --------------------------------------------------
  -- 3 rows × 2 columns
  --------------------------------------------------
  for slot = 1, SLOT_COUNT do
    for choice = 1, CHOICE_COUNT do
      local cell =
          self.Cells[slot]
          and self.Cells[slot][choice]

      if cell then
        local cellFrame = cell:GetFrame()

        cellFrame:ClearAllPoints()

        local x =
            (choice - 1)
            * columnWidth

        local y =
            (slot - 1)
            * CELL_HEIGHT

        cellFrame:SetPoint(
          "TOPLEFT",
          self.Frame,
          "TOPLEFT",
          x,
          -y
        )

        cell:SetWidth(
          columnWidth
        )

        cell:SetHeight(
          CELL_HEIGHT
        )
      end
    end
  end

  --------------------------------------------------
  -- Total height
  --------------------------------------------------
  self.Frame:SetHeight(
    SLOT_COUNT
    * CELL_HEIGHT
  )
end

function AbilityGrid:SetAbilities(slots)
  for slot = 1, SLOT_COUNT do
    local abilities =
        slots[slot] or {}

    table.sort(
      abilities,
      function(a, b)
        return
            (a.choice or 1)
            <
            (b.choice or 1)
      end
    )

    for choice = 1, CHOICE_COUNT do
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

  for _, ability in ipairs(
    pet.abilities
  ) do
    local slot =
        tonumber(
          ability.slot
        )

    if slot
        and slots[slot] then
      local abilityData = {
        abilityID =
            ability.abilityID
            or ability.id,

        id =
            ability.id
            or ability.abilityID,
        name = ability.name,
        icon = ability.icon,
        slot = slot,
        choice = ability.choice,
        requiredLevel =
            ability.requiredLevel
            or ability.level,

        additionalText =
            ability.additionalText,

        --------------------------------------------------
        -- Ability family
        --------------------------------------------------
        speciesID =
            pet.speciesID,

        petGUID =
            pet.petGUID
            or pet.petID
            or pet.guid,

        petID =
            pet.petGUID
            or pet.petID
            or pet.guid,

        pet = pet,
      }

      table.insert(
        slots[slot],
        abilityData
      )
    end
  end

  self:SetAbilities(
    slots
  )

  self:Show()

  return true
end

function AbilityGrid:Clear()
  for slot = 1, SLOT_COUNT do
    for choice = 1, CHOICE_COUNT do
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
