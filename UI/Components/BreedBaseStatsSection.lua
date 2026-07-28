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

local function FormatNumber(value)
  if value == nil then
    return "0"
  end

  if value % 1 == 0 then
    return tostring(
      math.floor(value)
    )
  end

  return tostring(value)
end

local function FormatStats(stats)
  if not stats then
    return nil
  end

  return string.format(
    "%s/%s/%s",
    FormatNumber(stats.health),
    FormatNumber(stats.power),
    FormatNumber(stats.speed)
  )
end

function Sections.AddBreedBaseStats(
    tooltip,
    details
)
  if not tooltip
      or not details
      or not details.breedBaseStats then
    return
  end

  for _, breed
  in ipairs(details.breedBaseStats) do
    if breed.stats then
      local marker =
          breed.isCurrent
          and "*"
          or ""

      tooltip:AddDoubleLine(
        "Breed "
        .. breed.breedName
        .. marker
        .. ":",

        FormatStats(
          breed.stats
        ),

        LABEL_COLOR,
        VALUE_COLOR
      )
    end
  end
end
