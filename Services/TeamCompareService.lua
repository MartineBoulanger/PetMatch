local addonName, addon = ...

local TeamCompareService = {}

function TeamCompareService:Compare(team, currentSlots)
  local changedSlots = {}

  if not team then
    return false, changedSlots
  end

  currentSlots = currentSlots or {}

  for slot = 1, 3 do
    local savedPetGUID =
        team.pets
        and team.pets[slot]
        or nil

    local currentPetGUID =
        currentSlots[slot]

    if savedPetGUID ~= currentPetGUID then
      changedSlots[slot] = true
    end
  end

  return next(changedSlots) ~= nil, changedSlots
end

function TeamCompareService:CompareWithCurrentSlots(team)
  local currentSlots =
      addon.Services.BattleSlot:GetCurrentSlots()

  return self:Compare(
    team,
    currentSlots
  )
end

addon.Services.TeamCompare = TeamCompareService
