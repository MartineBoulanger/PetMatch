local _, addon = ...

local PetTooltip = {}
local Card

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

  return Card
end

function PetTooltip:Show(
    owner,
    pet,
    anchor
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
  card:Show()
end

function PetTooltip:Hide(owner)
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
        if value.petGUID
            and addon.Services.PetTooltip then
          pet =
              addon.Services.PetTooltip:
              CreatePet(
                value.petGUID
              )
        else
          pet = value
        end
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
