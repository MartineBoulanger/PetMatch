local _, addon = ...

local TeamCompareService = {}

local function IsSpecialSlot(team, slot)
  return team
      and type(team.specialSlots) == "table"
      and type(team.specialSlots[slot]) == "table"
end

function TeamCompareService:Compare(
    team,
    currentSlots
)
  local changedSlots = {}

  if not team then
    return false, changedSlots
  end

  currentSlots =
      currentSlots
      or {}

  for slot = 1, 3 do
    if not IsSpecialSlot(team, slot) then
      local savedPetGUID =
          team.pets
          and team.pets[slot]
          or nil

      local currentPetGUID = currentSlots[slot]

      if savedPetGUID ~= currentPetGUID then
        changedSlots[slot] = true
      end
    end
  end

  return next(changedSlots) ~= nil, changedSlots
end

function TeamCompareService:CompareWithCurrentSlots(team)
  local changedSlots = {}

  if not team then
    return false, changedSlots
  end

  local currentLoadout = addon.Services.BattleSlot:GetCurrentLoadout()

  for slot = 1, 3 do
    if not IsSpecialSlot(team, slot) then
      local savedPet =
          team.pets
          and team.pets[slot]
          or nil

      local currentPet = currentLoadout.pets[slot]

      if savedPet ~= currentPet then
        changedSlots[slot] = true
      else
        local savedAbilities = team.abilities and team.abilities[slot]
        local currentAbilities = currentLoadout.abilities[slot]

        if savedAbilities then
          for abilitySlot = 1, 3 do
            local savedAbility = savedAbilities[abilitySlot]
            local currentAbility = currentAbilities and currentAbilities[abilitySlot]

            if savedAbility ~= currentAbility then
              changedSlots[slot] = true
              break
            end
          end
        end
      end
    end
  end

  return next(changedSlots) ~= nil, changedSlots
end

addon.Services.TeamCompare = TeamCompareService
