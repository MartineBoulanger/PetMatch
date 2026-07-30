local _, addon = ...

local PetTooltip = {}

-- Setting the correct names for the pet families
local PET_TYPE_SUFFIX = {
  [1]  = "Humanoid",
  [2]  = "Dragonkin",
  [3]  = "Flying",
  [4]  = "Undead",
  [5]  = "Critter",
  [6]  = "Magic",
  [7]  = "Elemental",
  [8]  = "Beast",
  [9]  = "Aquatic",
  [10] = "Mechanical"
}

-- setting the correct rarity color per pet
local PET_RARITY_COLORS = {
  [1] = ITEM_QUALITY_COLORS[0],
  [2] = ITEM_QUALITY_COLORS[1],
  [3] = ITEM_QUALITY_COLORS[2],
  [4] = ITEM_QUALITY_COLORS[3],
  [5] = ITEM_QUALITY_COLORS[4],
  [6] = ITEM_QUALITY_COLORS[5]
}

local TEXT_COLOR = {
  r = 1,
  g = 1,
  b = 1,
}

local MUTED_COLOR = {
  r = 0.72,
  g = 0.72,
  b = 0.72,
}

local VALUE_COLOR = {
  r = 1,
  g = 0.82,
  b = 0,
}

local DESCRIPTION_COLOR = {
  r = 0.9,
  g = 0.9,
  b = 0.9,
}

local function GetQualityColor(
    quality
)
  quality = tonumber(quality) or 0

  local color =
      PET_RARITY_COLORS
      and PET_RARITY_COLORS[quality]

  if not color then
    return TEXT_COLOR
  end

  return {
    r = color.r or 1,
    g = color.g or 1,
    b = color.b or 1,
    a = 1,
  }
end

local function GetPetTypeName(
    petType
)
  petType = tonumber(petType)

  if not petType then
    return nil
  end

  if PET_TYPE_SUFFIX then
    return PET_TYPE_SUFFIX[petType]
  end

  return nil
end

local function AddIdentitySection(
    tooltip,
    pet
)
  tooltip:SetTitle(
    pet.name,
    GetQualityColor(
      pet.quality
    )
  )

  if pet.customName
      and pet.speciesName
      and pet.customName
      ~= pet.speciesName then
    tooltip:AddLine(
      pet.speciesName,
      MUTED_COLOR
    )
  end

  tooltip:AddDoubleLine(
    "Level",
    tostring(
      pet.level or 0
    ),
    MUTED_COLOR,
    VALUE_COLOR
  )

  local petTypeName = GetPetTypeName(pet.petType)

  if petTypeName then
    tooltip:AddDoubleLine(
      "Family",
      petTypeName,
      MUTED_COLOR,
      VALUE_COLOR
    )
  end
end

local function AddStatsSection(
    tooltip,
    pet
)
  if not pet.canBattle
      and pet.health == 0
      and pet.power == 0
      and pet.speed == 0 then
    return
  end

  tooltip:AddSpacer(7)

  tooltip:AddDoubleLine(
    "Health",
    tostring(
      pet.maxHealth
      or pet.health
      or 0
    ),
    MUTED_COLOR,
    TEXT_COLOR
  )

  tooltip:AddDoubleLine(
    "Power",
    tostring(
      pet.power or 0
    ),
    MUTED_COLOR,
    TEXT_COLOR
  )

  tooltip:AddDoubleLine(
    "Speed",
    tostring(
      pet.speed or 0
    ),
    MUTED_COLOR,
    TEXT_COLOR
  )
end

local function AddBreedSection(
    tooltip,
    pet
)
  if pet.breedName then
    tooltip:AddDoubleLine(
      "Breed",
      pet.breedName,
      MUTED_COLOR,
      VALUE_COLOR
    )
  end
end

local function AddExpansionSection(
    tooltip,
    pet
)
  if not pet.expansionName then
    return
  end

  tooltip:AddDoubleLine(
    "Expansion",
    pet.expansionName,
    MUTED_COLOR,
    VALUE_COLOR
  )
end

local function AddDescriptionSection(
    tooltip,
    pet
)
  if type(pet.description)
      ~= "string"
      or pet.description == "" then
    return
  end

  tooltip:AddSpacer(8)

  tooltip:AddLine(
    pet.description,
    DESCRIPTION_COLOR
  )
end

local function AddSourceSection(
    tooltip,
    pet
)
  if type(pet.sourceText)
      ~= "string"
      or pet.sourceText == "" then
    return
  end

  tooltip:AddSpacer(8)

  tooltip:AddLine(
    pet.sourceText,
    MUTED_COLOR
  )
end

local function AddAbilitiesSection(tooltip, pet)
  if not pet.abilities or #pet.abilities == 0 then
    return
  end

  tooltip:AddSpacer(8)

  tooltip:AddLine(
    "Abilities",
    VALUE_COLOR
  )

  local slots = {
    [1] = {},
    [2] = {},
    [3] = {}
  }

  for _, ability in ipairs(pet.abilities) do
    table.insert(
      slots[ability.slot],
      ability
    )
  end

  tooltip:AddAbilityGrid(slots)
end

function PetTooltip:Show(
    owner,
    pet,
    anchor
)
  if not owner or not pet then
    return
  end

  local tooltip = addon.UI.Base.Tooltip

  if not tooltip then
    return
  end

  tooltip:Clear()
  tooltip:SetWidth(390)

  tooltip:SetOwner(
    owner,
    anchor or "ANCHOR_RIGHT"
  )

  AddIdentitySection(
    tooltip,
    pet
  )

  AddStatsSection(
    tooltip,
    pet
  )

  AddBreedSection(
    tooltip,
    pet
  )

  AddExpansionSection(
    tooltip,
    pet
  )

  AddDescriptionSection(
    tooltip,
    pet
  )

  AddSourceSection(
    tooltip,
    pet
  )

  local breedTooltipService =
      addon.Services.BreedTooltip

  local breedSections =
      addon.UI.Components
      and addon.UI.Components
      .PetTooltipSections

  if breedTooltipService
      and breedSections then
    local details =
        breedTooltipService:GetDetails(
          pet
        )

    if details then
      breedSections.AddBreedDetails(
        tooltip,
        details
      )

      breedSections.AddBreedBaseStats(
        tooltip,
        details
      )

      breedSections.AddBreedLevel25Stats(
        tooltip,
        details
      )
    end
  end

  AddAbilitiesSection(
    tooltip,
    pet
  )

  tooltip:Show()
end

function PetTooltip:ShowByPetGUID(
    owner,
    petGUID,
    anchor
)
  local service = addon.Services.PetTooltip

  if not service then
    return
  end

  local pet =
      service:CreatePet(
        petGUID
      )

  if not pet then
    return
  end

  self:Show(
    owner,
    pet,
    anchor
  )
end

function PetTooltip:Hide(owner)
  local tooltip = addon.UI.Base.Tooltip

  if not tooltip then
    return
  end

  tooltip:Hide(owner)
end

function PetTooltip:Attach(
    frame,
    provider,
    anchor
)
  if not frame then
    return
  end

  if type(provider) ~= "function" then
    error("PetTooltip: Attach requires a provider function.")
  end

  frame.__PetMatchTooltipProvider = provider
  frame.__PetMatchTooltipAnchor = anchor or "ANCHOR_RIGHT"
  if frame.__PetMatchTooltipAttached then
    return
  end
  frame.__PetMatchTooltipAttached = true

  frame:HookScript(
    "OnEnter",
    function(control)
      local currentProvider =
          control.__PetMatchTooltipProvider

      if type(currentProvider) ~= "function" then
        return
      end

      local first, second = currentProvider(control)

      local valueType
      local value

      if first == "petGUID"
          or first == "speciesID"
          or first == "pet" then
        valueType = first
        value = second
      else
        value = first

        if type(value) == "string" then
          valueType = "petGUID"
        elseif type(value) == "number" then
          valueType = "speciesID"
        elseif type(value) == "table" then
          valueType = "pet"
        end
      end

      if value == nil then
        return
      end

      local pet

      if valueType == "petGUID" then
        if type(value) ~= "string" or value == "" then
          return
        end
        pet = addon.Services.PetTooltip:CreatePet(value)
      elseif valueType == "speciesID" then
        pet = addon.Services.PetTooltip:GetBySpeciesID(value)
      elseif valueType == "pet" then
        pet = value
      end

      if not pet then
        return
      end

      PetTooltip:Show(
        control,
        pet,
        control.__PetMatchTooltipAnchor
      )
    end
  )

  frame:HookScript(
    "OnLeave",
    function(control)
      PetTooltip:Hide(control)
    end
  )
end

addon.UI.Components.PetTooltip = PetTooltip
