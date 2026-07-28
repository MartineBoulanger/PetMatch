local _, addon = ...

addon.UI.Components.PetTooltipSections =
    addon.UI.Components.PetTooltipSections
    or {}

local Sections =
    addon.UI.Components.PetTooltipSections

local RARE_COLOR = {
  r = 0,
  g = 0.44,
  b = 0.87,
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
    "%d/%d/%d",
    stats.health,
    stats.power,
    stats.speed
  )
end

function Sections.AddBreedLevel25Stats(
    tooltip,
    details
)
  if not tooltip
      or not details
      or not details.level25Stats then
    return
  end

  tooltip:AddSpacer(4)

  for _, breed
  in ipairs(details.level25Stats) do
    if breed.stats then
      local marker =
          breed.isCurrent
          and "*"
          or ""

      tooltip:AddDoubleLine(
        breed.breedName
        .. marker
        .. " at 25:",

        FormatStats(
          breed.stats
        ),

        RARE_COLOR,
        VALUE_COLOR
      )
    end
  end
end
