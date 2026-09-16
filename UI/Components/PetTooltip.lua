local _, addon = ...

local L = addon.L
local PetTooltip = {}
local Card

PetTooltip.Pinned = false
PetTooltip.PinnedType = nil
PetTooltip.PinnedValue = nil
PetTooltip.PinnedOwner = nil
PetTooltip.PinnedHighlightedAbilities = nil

local VALID_MODES = {
  hover = true,
  click = true,
  both = true,
}

local VALID_SOURCES = {
  petList = true,
  teams = true,
  queue = true,
}

local function GetInteractionMode()
  local mode = addon.Settings:Get("petCardInteractionMode")

  if not VALID_MODES[mode] then
    return "hover"
  end

  return mode
end

local function AllowsHover()
  local mode = GetInteractionMode()
  return mode == "hover" or mode == "both"
end

local function AllowsClick()
  local mode = GetInteractionMode()
  return mode == "click" or mode == "both"
end

local function AllowsSource(source)
  if not VALID_SOURCES[source] then
    return true
  end

  if source == "petList" then
    return addon.Settings:Get(
      "petCardPetListEnabled"
    ) ~= false
  end

  if source == "teams" then
    return addon.Settings:Get(
      "petCardTeamsEnabled"
    ) ~= false
  end

  if source == "queue" then
    return addon.Settings:Get(
      "petCardLevellingQueueEnabled"
    ) ~= false
  end

  return true
end

local function GetPetCard()
  if Card then
    return Card
  end

  local component = addon.UI.PetCard and addon.UI.PetCard.Card

  if not component then
    error(L["NO_PET_CARD"])
  end

  Card = component:Create(UIParent)

  Card:SetCloseHandler(
    function()
      PetTooltip:Unpin()
    end
  )

  return Card
end

local function ResolveProviderValue(provider, control)
  if type(provider) ~= "function" then
    return nil, nil
  end

  local first, second = provider(control)
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

local function ResolveHighlightedAbilities(provider, control)
  if type(provider) ~= "function" then
    return nil
  end

  local abilityIDs = provider(control)

  if type(abilityIDs) ~= "table" then
    return nil
  end

  return abilityIDs
end

local function CreatePet(valueType, value)
  if value == nil then
    return nil
  end

  local service = addon.Services.PetTooltip

  if not service then
    return nil
  end

  if valueType == "petGUID" then
    if type(value) ~= "string" or value == "" then
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

    return service:GetBySpeciesID(value)
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

local function ValuesMatch(firstType, firstValue, secondType, secondValue)
  if firstType ~= secondType then
    return false
  end

  if firstType == "pet" then
    local firstGUID = firstValue and firstValue.petGUID
    local secondGUID = secondValue and secondValue.petGUID

    if firstGUID or secondGUID then
      return firstGUID == secondGUID
    end

    local firstSpeciesID = firstValue and firstValue.speciesID
    local secondSpeciesID = secondValue and secondValue.speciesID

    return firstSpeciesID == secondSpeciesID
  end

  return firstValue == secondValue
end

function PetTooltip:Show(owner, pet, anchor, pinned, highlightedAbilities)
  if not owner or not pet then
    return
  end

  local card = GetPetCard()

  card:SetOwner(owner, anchor or "ANCHOR_RIGHT")
  card:SetPet(pet)

  if type(highlightedAbilities) == "table" then
    card:SetHighlightedAbilities(highlightedAbilities)
  else
    card:ClearHighlightedAbilities()
  end

  card:SetPinned(pinned == true)
  card:Show()
end

function PetTooltip:ShowValue(owner, valueType, value, anchor, pinned, highlightedAbilities)
  local pet = CreatePet(valueType, value)

  if not pet then
    return false
  end

  self:Show(owner, pet, anchor, pinned, highlightedAbilities)

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

function PetTooltip:ShowByPetGUID(owner, petGUID, anchor)
  self:ShowValue(
    owner,
    "petGUID",
    petGUID,
    anchor,
    false
  )
end

function PetTooltip:Pin(owner, valueType, value, anchor, highlightedAbilities)
  if not owner or not valueType or value == nil then
    return false
  end

  local shown =
      self:ShowValue(
        owner,
        valueType,
        value,
        anchor,
        true,
        highlightedAbilities
      )

  if not shown then
    return false
  end

  self.Pinned = true
  self.PinnedType = valueType
  self.PinnedValue = value
  self.PinnedOwner = owner
  self.PinnedHighlightedAbilities = highlightedAbilities

  return true
end

function PetTooltip:Unpin()
  self.Pinned = false
  self.PinnedType = nil
  self.PinnedValue = nil
  self.PinnedOwner = nil
  self.PinnedHighlightedAbilities = nil

  if not Card then
    return
  end

  Card:SetPinned(false)
  Card:Hide()
end

function PetTooltip:TogglePin(owner, valueType, value, anchor, highlightedAbilities)
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
    anchor,
    highlightedAbilities
  )
end

function PetTooltip:IsPinned()
  return self.Pinned == true
end

function PetTooltip:SetClickBlocker(frame, blocker)
  if not frame then
    return
  end

  if blocker ~= nil and type(blocker) ~= "function" then
    error(L["PET_TOOLTIP_ERROR"])
  end

  frame.__PetMatchTooltipClickBlocker = blocker
end

function PetTooltip:Attach(frame, provider, anchor, source, highlightProvider)
  if not frame then
    return
  end

  if type(provider) ~= "function" then
    error(L["NO_PROVIDER"])
  end

  frame.__PetMatchTooltipProvider = provider
  frame.__PetMatchTooltipAnchor = anchor or "ANCHOR_RIGHT"
  frame.__PetMatchTooltipSource = source
  frame.__PetMatchTooltipHighlightProvider = highlightProvider

  if frame.__PetMatchTooltipAttached then
    return
  end

  frame.__PetMatchTooltipAttached = true

  frame:HookScript(
    "OnEnter",

    function(control)
      if not AllowsSource(control.__PetMatchTooltipSource) then
        return
      end

      if not AllowsHover() then
        return
      end

      if PetTooltip:IsPinned() then
        return
      end

      local currentProvider = control.__PetMatchTooltipProvider
      local valueType, value = ResolveProviderValue(currentProvider, control)

      if not valueType or value == nil then
        return
      end

      local highlightedAbilities = ResolveHighlightedAbilities(control.__PetMatchTooltipHighlightProvider, control)

      PetTooltip:ShowValue(
        control,
        valueType,
        value,
        control.__PetMatchTooltipAnchor,
        false,
        highlightedAbilities
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

      local clickBlocker = control.__PetMatchTooltipClickBlocker

      if type(clickBlocker) == "function" and clickBlocker(control) then
        return
      end

      if not AllowsSource(control.__PetMatchTooltipSource) then
        return
      end

      if not AllowsClick() then
        return
      end

      local currentProvider = control.__PetMatchTooltipProvider
      local valueType, value = ResolveProviderValue(currentProvider, control)

      if not valueType or value == nil then
        return
      end

      local highlightedAbilities = ResolveHighlightedAbilities(control.__PetMatchTooltipHighlightProvider, control)

      PetTooltip:TogglePin(
        control,
        valueType,
        value,
        control.__PetMatchTooltipAnchor,
        highlightedAbilities
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
