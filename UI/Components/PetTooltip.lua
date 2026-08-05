local _, addon = ...

local PetTooltip = {}
local Card

PetTooltip.Pinned = false
PetTooltip.PinnedType = nil
PetTooltip.PinnedValue = nil
PetTooltip.PinnedOwner = nil

local VALID_MODES = {
  hover = true,
  click = true,
  both = true,
}

local function GetInteractionMode()
  local mode =
      addon.Settings:Get(
        "petCardInteractionMode"
      )

  if not VALID_MODES[mode] then
    return "hover"
  end

  return mode
end

local function AllowsHover()
  local mode =
      GetInteractionMode()

  return mode == "hover"
      or mode == "both"
end

local function AllowsClick()
  local mode =
      GetInteractionMode()

  return mode == "click"
      or mode == "both"
end

local function GetPetCard()
  if Card then
    return Card
  end

  local component =
      addon.UI.PetCard
      and addon.UI.PetCard.Card

  if not component then
    error(
      "PetMatch: PetCard component is not loaded."
    )
  end

  Card = component:Create(UIParent)

  Card:SetCloseHandler(
    function()
      PetTooltip:Unpin()
    end
  )

  return Card
end

local function ResolveProviderValue(
    provider,
    control
)
  if type(provider) ~= "function" then
    return nil, nil
  end

  local first, second =
      provider(control)

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

  return valueType, value
end

local function CreatePet(
    valueType,
    value
)
  if value == nil then
    return nil
  end

  local service =
      addon.Services.PetTooltip

  if not service then
    return nil
  end

  if valueType == "petGUID" then
    if type(value) ~= "string"
        or value == "" then
      return nil
    end

    return service:CreatePet(
      value
    )
  end

  if valueType == "speciesID" then
    value = tonumber(value)

    if not value then
      return nil
    end

    return service:GetBySpeciesID(
      value
    )
  end

  if valueType == "pet" then
    if type(value) ~= "table" then
      return nil
    end

    if value.petGUID then
      return service:CreatePet(
        value.petGUID
      )
    end

    return value
  end

  return nil
end

local function ValuesMatch(
    firstType,
    firstValue,
    secondType,
    secondValue
)
  if firstType ~= secondType then
    return false
  end

  if firstType == "pet" then
    local firstGUID =
        firstValue
        and firstValue.petGUID

    local secondGUID =
        secondValue
        and secondValue.petGUID

    if firstGUID or secondGUID then
      return firstGUID == secondGUID
    end

    local firstSpeciesID =
        firstValue
        and firstValue.speciesID

    local secondSpeciesID =
        secondValue
        and secondValue.speciesID

    return firstSpeciesID
        == secondSpeciesID
  end

  return firstValue == secondValue
end

function PetTooltip:Show(
    owner,
    pet,
    anchor,
    pinned
)
  if not owner or not pet then
    return
  end

  local card = GetPetCard()

  card:SetOwner(
    owner,
    anchor or "ANCHOR_RIGHT"
  )

  card:SetPet(pet)

  card:SetPinned(
    pinned == true
  )

  card:Show()
end

function PetTooltip:ShowValue(
    owner,
    valueType,
    value,
    anchor,
    pinned
)
  local pet =
      CreatePet(
        valueType,
        value
      )

  if not pet then
    return false
  end

  self:Show(
    owner,
    pet,
    anchor,
    pinned
  )

  return true
end

function PetTooltip:Hide(owner)
  if self.Pinned then
    return
  end

  if not Card then
    return
  end

  Card:Hide(owner)
end

function PetTooltip:ShowByPetGUID(
    owner,
    petGUID,
    anchor
)
  self:ShowValue(
    owner,
    "petGUID",
    petGUID,
    anchor,
    false
  )
end

function PetTooltip:Pin(
    owner,
    valueType,
    value,
    anchor
)
  if not owner
      or not valueType
      or value == nil then
    return false
  end

  local shown =
      self:ShowValue(
        owner,
        valueType,
        value,
        anchor,
        true
      )

  if not shown then
    return false
  end

  self.Pinned = true
  self.PinnedType = valueType
  self.PinnedValue = value
  self.PinnedOwner = owner

  return true
end

function PetTooltip:Unpin()
  self.Pinned = false
  self.PinnedType = nil
  self.PinnedValue = nil
  self.PinnedOwner = nil

  if not Card then
    return
  end

  Card:SetPinned(false)
  Card:Hide()
end

function PetTooltip:TogglePin(
    owner,
    valueType,
    value,
    anchor
)
  if self.Pinned
      and ValuesMatch(
        self.PinnedType,
        self.PinnedValue,
        valueType,
        value
      ) then
    self:Unpin()
    return false
  end

  return self:Pin(
    owner,
    valueType,
    value,
    anchor
  )
end

function PetTooltip:IsPinned()
  return self.Pinned == true
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
    error(
      "PetTooltip: Attach requires a provider function."
    )
  end

  frame.__PetMatchTooltipProvider =
      provider

  frame.__PetMatchTooltipAnchor =
      anchor or "ANCHOR_RIGHT"

  if frame.__PetMatchTooltipAttached then
    return
  end

  frame.__PetMatchTooltipAttached = true

  frame:HookScript(
    "OnEnter",

    function(control)
      if not AllowsHover() then
        return
      end

      -- Een gepinde card wordt niet door hover vervangen.
      if PetTooltip:IsPinned() then
        return
      end

      local currentProvider =
          control.__PetMatchTooltipProvider

      local valueType, value =
          ResolveProviderValue(
            currentProvider,
            control
          )

      if not valueType
          or value == nil then
        return
      end

      PetTooltip:ShowValue(
        control,
        valueType,
        value,
        control.__PetMatchTooltipAnchor,
        false
      )
    end
  )

  frame:HookScript(
    "OnLeave",

    function(control)
      PetTooltip:Hide(
        control
      )
    end
  )

  frame:HookScript(
    "OnMouseUp",

    function(control, mouseButton)
      if mouseButton ~= "LeftButton" then
        return
      end

      if not AllowsClick() then
        return
      end

      local currentProvider =
          control.__PetMatchTooltipProvider

      local valueType, value =
          ResolveProviderValue(
            currentProvider,
            control
          )

      if not valueType
          or value == nil then
        return
      end

      PetTooltip:TogglePin(
        control,
        valueType,
        value,
        control.__PetMatchTooltipAnchor
      )
    end
  )
end

function PetTooltip:OnSettingChanged(key)
  if key ~= "petCardInteractionMode" then
    return
  end
  self:Unpin()
end

addon.EventBus:Register(
  addon.Events.SETTINGS_CHANGED,

  function(key)
    PetTooltip:OnSettingChanged(
      key
    )
  end
)

addon.UI.Components.PetTooltip = PetTooltip
