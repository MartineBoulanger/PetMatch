local _, addon = ...

local AbilitySearch = {}

local DescriptionCache = {}

function AbilitySearch:GetDescription(abilityID)
  abilityID = tonumber(abilityID)

  if not abilityID then
    return ""
  end

  if DescriptionCache[abilityID] ~= nil then
    return DescriptionCache[abilityID]
  end

  local _, _, _, _, description =
      C_PetBattles.GetAbilityInfoByID(abilityID)

  description = type(description) == "string"
      and string.lower(description) or ""

  DescriptionCache[abilityID] = description

  return description
end

function AbilitySearch:Matches(abilityID, searchText)
  abilityID = tonumber(abilityID)

  if not abilityID or type(searchText) ~= "string" then
    return false
  end

  searchText = string.lower(searchText)

  if searchText == "" then
    return false
  end

  local abilityName =
      C_PetJournal.GetPetAbilityInfo(abilityID)

  if type(abilityName) == "string"
      and string.find(string.lower(abilityName), searchText, 1, true) then
    return true
  end

  return string.find(self:GetDescription(abilityID), searchText, 1, true) ~= nil
end

function AbilitySearch:MatchesSpecies(speciesID, searchText)
  speciesID = tonumber(speciesID)

  if not speciesID or type(searchText) ~= "string"
      or searchText == "" then
    return false
  end

  local abilityIDs = {}
  local abilityLevels = {}

  C_PetJournal.GetPetAbilityList(
    speciesID, abilityIDs, abilityLevels
  )

  for _, abilityID in ipairs(abilityIDs) do
    if self:Matches(abilityID, searchText) then
      return true
    end
  end

  return false
end

addon.AbilitySearch = AbilitySearch
addon.ModuleManager:Register(
  "AbilitySearch",
  AbilitySearch
)
