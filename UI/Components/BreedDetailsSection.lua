local _, addon = ...

addon.UI.Components.PetTooltipSections =
    addon.UI.Components.PetTooltipSections
    or {}

local Sections =
    addon.UI.Components.PetTooltipSections

local LABEL_COLOR = {
  r = 1,
  g = 0.82,
  b = 0,
  a = 1,
}

local VALUE_COLOR = {
  r = 1,
  g = 1,
  b = 1,
  a = 1,
}

local function FormatStats(stats)
  if not stats then
    return nil
  end

  return string.format(
    "%s/%s/%s",
    tostring(stats.health),
    tostring(stats.power),
    tostring(stats.speed)
  )
end

local function FormatPossibleBreeds(details)
  if details.allBreedsPossible then
    return "All"
  end

  local names = {}

  for _, breedID
  in ipairs(details.possibleBreedIDs or {}) do
    local name =
        ({
          [3] = "B/B",
          [4] = "P/P",
          [5] = "S/S",
          [6] = "H/H",
          [7] = "H/P",
          [8] = "P/S",
          [9] = "H/S",
          [10] = "P/B",
          [11] = "S/B",
          [12] = "H/B",
        })[breedID]

    if name then
      names[#names + 1] = name
    end
  end

  if #names == 0 then
    return "Unknown"
  end

  return table.concat(names, ", ")
end

local function FormatCollected(collected)
  if not collected or #collected == 0 then
    return nil
  end

  local values = {}

  for _, pet in ipairs(collected) do
    values[#values + 1] = pet.text
  end

  return table.concat(values, ", ")
end

function Sections.AddBreedDetails(
    tooltip,
    details
)
  if not tooltip or not details then
    return
  end

  tooltip:AddSpacer(6)

  if details.currentBreedName then
    tooltip:AddDoubleLine(
      "Current Breed:",
      details.currentBreedName,
      LABEL_COLOR,
      VALUE_COLOR
    )
  end

  local collectedText =
      FormatCollected(
        details.collected
      )

  if collectedText then
    tooltip:AddDoubleLine(
      "Collected:",
      collectedText,
      LABEL_COLOR,
      VALUE_COLOR
    )
  end

  tooltip:AddDoubleLine(
    "Possible Breeds:",
    FormatPossibleBreeds(details),
    LABEL_COLOR,
    VALUE_COLOR
  )

  local baseStats =
      FormatStats(
        details.speciesBaseStats
      )

  if baseStats then
    tooltip:AddDoubleLine(
      "Base Stats:",
      baseStats,
      LABEL_COLOR,
      VALUE_COLOR
    )
  end
end
