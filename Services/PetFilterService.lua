local _, addon = ...

local PetFilterService = {}

local DEFAULT_FILTERS = {
  battlePetsOnly = false,
  tradableOnly = false,
  favoritesOnly = false,
  level25Only = false,

  qualities = {
    [0] = true,
    [1] = true,
    [2] = true,
    [3] = true,
    [4] = true,
  },
}

local function CopyDefaults(defaults, target)
  for key, value in pairs(defaults) do
    if type(value) == "table" then
      target[key] =
          type(target[key]) == "table"
          and target[key]
          or {}

      CopyDefaults(
        value,
        target[key]
      )
    elseif target[key] == nil then
      target[key] = value
    end
  end
end

function PetFilterService:GetState()
  local profile =
      addon.Profiles:GetCurrentProfile()

  profile.settings =
      profile.settings or {}

  profile.settings.petJournalFilters =
      profile.settings.petJournalFilters
      or {}

  CopyDefaults(
    DEFAULT_FILTERS,
    profile.settings.petJournalFilters
  )

  return profile.settings.petJournalFilters
end

function PetFilterService:Get(key)
  return self:GetState()[key]
end

function PetFilterService:Set(key, value)
  local state = self:GetState()

  state[key] = value

  self:RefreshJournal()
end

function PetFilterService:SetQuality(
    quality,
    enabled
)
  quality = tonumber(quality)

  if quality == nil then
    return
  end

  local state = self:GetState()

  state.qualities[quality] =
      enabled == true

  self:RefreshJournal()
end

function PetFilterService:IsQualityEnabled(
    quality
)
  quality = tonumber(quality)

  if quality == nil then
    return true
  end

  local enabled =
      self:GetState()
      .qualities[quality]

  return enabled ~= false
end

function PetFilterService:Reset()
  local profile =
      addon.Profiles:GetCurrentProfile()

  profile.settings.petJournalFilters = {}

  self:GetState()
  self:RefreshJournal()
end

function PetFilterService:MatchesPet(
    petGUID,
    speciesID,
    isOwned,
    level,
    favorite,
    canBattle,
    tradable
)
  local state = self:GetState()

  if state.battlePetsOnly
      and canBattle ~= true then
    return false
  end

  if state.tradableOnly
      and tradable ~= true then
    return false
  end

  if state.favoritesOnly
      and favorite ~= true then
    return false
  end

  if state.level25Only then
    if not isOwned
        or tonumber(level) ~= 25 then
      return false
    end
  end

  if isOwned and petGUID then
    local _, _, _, _, quality =
        C_PetJournal.GetPetStats(
          petGUID
        )

    if not self:IsQualityEnabled(
          quality
        ) then
      return false
    end
  end

  return true
end

function PetFilterService:RefreshJournal()
  if PetJournal
      and PetJournal.PetList
      and PetJournal.PetList.ScrollBox then
    if PetJournal.PetList.RefreshList then
      PetJournal.PetList:RefreshList()
    elseif PetJournal_UpdatePetList then
      PetJournal_UpdatePetList()
    end
  end
end

addon.Services.PetFilter = PetFilterService
