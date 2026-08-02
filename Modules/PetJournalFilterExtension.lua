local _, addon = ...

local FilterExtension = {}

local Filters = {
  petTypes = {},
  sources = {},
  expansions = {},
  rarities = {},
  levels = {},
  breeds = {},
}

local PET_TYPES = {}
local PET_SOURCES = {}

local PetCache = {}

local EXPANSIONS = {
  "Classic",
  "Burning Crusade",
  "Wrath of the Lich King",
  "Cataclysm",
  "Mists of Pandaria",
  "Warlords of Draenor",
  "Legion",
  "Battle for Azeroth",
  "Shadowlands",
  "Dragonflight",
  "The War Within",
  "Midnight",
}

local RARITIES = {
  "Poor",
  "Common",
  "Uncommon",
  "Rare",
}

local RARITY_NAMES = {
  [1] = "Poor",
  [2] = "Common",
  [3] = "Uncommon",
  [4] = "Rare",
}

local BREEDS = {
  "B/B",
  "H/B",
  "P/B",
  "S/B",
  "H/H",
  "P/P",
  "S/S",
  "H/P",
  "H/S",
  "P/S",
}

local LEVEL_RANGES = {
  {
    key = "1-4",
    label = "1 - 4",
    min = 1,
    max = 4,
  },
  {
    key = "5-9",
    label = "5 - 9",
    min = 5,
    max = 9,
  },
  {
    key = "10-14",
    label = "10 - 14",
    min = 10,
    max = 14,
  },
  {
    key = "15-19",
    label = "15 - 19",
    min = 15,
    max = 19,
  },
  {
    key = "20-24",
    label = "20 - 24",
    min = 20,
    max = 24,
  },
  {
    key = "25",
    label = "25",
    min = 25,
    max = 25,
  },
}

local LEVEL_RANGE_KEYS = {}
for _, range in ipairs(LEVEL_RANGES) do
  LEVEL_RANGE_KEYS[#LEVEL_RANGE_KEYS + 1] =
      range.key
end

local FILTER_BAR_HEIGHT = 24
local PET_LIST_NORMAL_TOP_OFFSET = -36
local PET_LIST_FILTERED_TOP_OFFSET = -64

local OtherFilters = {
  leveling = nil,
  tradable = nil,
  battle = nil,
  team = nil,
}

-- sorting
local ActiveSort = {
  type = "blizzard",
  value = nil,
}
local SortOptions = {
  favoritesFirst = false,
  reverse = false,
}
local SORT_OPTIONS = {
  {
    key = "expansion",
    label = "Expansion",
  },
  {
    key = "breed",
    label = "Breed",
  },
  {
    key = "health",
    label = "Health",
  },
  {
    key = "power",
    label = "Power",
  },
  {
    key = "speed",
    label = "Speed",
  },
  {
    key = "teams",
    label = "Teams",
  },
}

local function InitializeNativeOptions()
  wipe(PET_TYPES)
  wipe(PET_SOURCES)

  for petType = 1,
  C_PetJournal.GetNumPetTypes() do
    PET_TYPES[#PET_TYPES + 1] =
        petType
  end

  for source = 1,
  C_PetJournal.GetNumPetSources() do
    PET_SOURCES[#PET_SOURCES + 1] =
        source
  end
end

local function InitializeFilter(
    filter,
    options
)
  for _, option in ipairs(options) do
    if filter[option] == nil then
      filter[option] = false
    end
  end
end

local function InitializeFilters()
  InitializeNativeOptions()

  InitializeFilter(
    Filters.petTypes,
    PET_TYPES
  )

  InitializeFilter(
    Filters.sources,
    PET_SOURCES
  )

  InitializeFilter(
    Filters.expansions,
    EXPANSIONS
  )

  InitializeFilter(
    Filters.rarities,
    RARITIES
  )

  InitializeFilter(
    Filters.levels,
    LEVEL_RANGE_KEYS
  )

  InitializeFilter(
    Filters.breeds,
    BREEDS
  )
end

local function SetAll(
    filter,
    options,
    checked
)
  for _, option in ipairs(options) do
    filter[option] = checked == true
  end
end

local function IsAllChecked(
    filter,
    options
)
  for _, option in ipairs(options) do
    if filter[option] ~= true then
      return false
    end
  end

  return true
end

local function IsNoneChecked(
    filter,
    options
)
  for _, option in ipairs(options) do
    if filter[option] == true then
      return false
    end
  end

  return true
end

local function ClearCache()
  wipe(PetCache)
end

local function IsOtherFilterChecked(
    group,
    value
)
  return OtherFilters[group] == value
end

local function HasOtherFilters()
  return OtherFilters.leveling ~= nil
      or OtherFilters.tradable ~= nil
      or OtherFilters.battle ~= nil
      or OtherFilters.team ~= nil
end

local function ResetOtherFilters()
  OtherFilters.leveling = nil
  OtherFilters.tradable = nil
  OtherFilters.battle = nil
  OtherFilters.team = nil

  ClearCache()
  FilterExtension:ApplyFilters()
end

local function SetOtherFilter(
    group,
    value
)
  if OtherFilters[group] == value then
    OtherFilters[group] = nil
  else
    OtherFilters[group] = value
  end

  ClearCache()
  FilterExtension:ApplyFilters()
end

local function HasSelection(
    filter,
    options
)
  for _, option in ipairs(options) do
    if filter[option] == true then
      return true
    end
  end

  return false
end

local function MatchesFilter(
    filter,
    options,
    value
)
  if not HasSelection(
        filter,
        options
      ) then
    return true
  end

  if value == nil then
    return false
  end

  return filter[value] == true
end

local function Toggle(
    filter,
    key,
    onChanged
)
  filter[key] = filter[key] ~= true

  if onChanged then
    onChanged()
  else
    ClearCache()
    FilterExtension:ApplyFilters()
  end
end

local function AddCheckAllButtons(
    submenu,
    filter,
    options,
    onChanged
)
  local checkAllButton =
      submenu:CreateButton(
        CHECK_ALL
      )

  checkAllButton:SetResponder(
    function()
      SetAll(
        filter,
        options,
        true
      )

      if onChanged then
        onChanged()
      else
        ClearCache()
        FilterExtension:ApplyFilters()
      end

      return MenuResponse.Refresh
    end
  )

  local uncheckAllButton =
      submenu:CreateButton(
        UNCHECK_ALL
      )

  uncheckAllButton:SetResponder(
    function()
      SetAll(
        filter,
        options,
        false
      )

      if onChanged then
        onChanged()
      else
        ClearCache()
        FilterExtension:ApplyFilters()
      end

      return MenuResponse.Refresh
    end
  )
end

local function SyncNativePetTypes()
  if HasSelection(
        Filters.petTypes,
        PET_TYPES
      ) then
    PetJournalFilterDropdown_SetAllPetTypes(
      false
    )

    for _, petType in ipairs(
      PET_TYPES
    ) do
      if Filters.petTypes[petType] then
        C_PetJournal.SetPetTypeFilter(
          petType,
          true
        )
      end
    end
  else
    PetJournalFilterDropdown_SetAllPetTypes(
      true
    )
  end
end

local function SyncNativeSources()
  if HasSelection(
        Filters.sources,
        PET_SOURCES
      ) then
    PetJournalFilterDropdown_SetAllPetSources(
      false
    )

    for _, sourceIndex in ipairs(
      PET_SOURCES
    ) do
      if Filters.sources[sourceIndex] then
        C_PetJournal.SetPetSourceChecked(
          sourceIndex,
          true
        )
      end
    end
  else
    PetJournalFilterDropdown_SetAllPetSources(
      true
    )
  end
end

local function SyncNativeFilters()
  SyncNativePetTypes()
  SyncNativeSources()

  ClearCache()
  FilterExtension:ApplyFilters()
end

local function GetExtendedPet(
    petID,
    speciesID
)
  local cacheKey =
      petID
      or (
        "species:"
        .. tostring(speciesID)
      )

  if PetCache[cacheKey] ~= nil then
    local cached =
        PetCache[cacheKey]

    return cached ~= false
        and cached
        or nil
  end

  local service =
      addon.Services
      and addon.Services.PetTooltip

  local pet

  if service then
    if petID
        and type(service.CreatePet)
        == "function" then
      pet =
          service:CreatePet(
            petID
          )
    elseif speciesID
        and type(service.CreateSpeciesPet)
        == "function" then
      pet =
          service:CreateSpeciesPet(
            speciesID
          )
    elseif speciesID
        and type(service.GetBySpeciesID)
        == "function" then
      pet =
          service:GetBySpeciesID(
            speciesID
          )
    end
  end

  PetCache[cacheKey] =
      pet or false

  return pet
end

local function GetExpansionName(
    petID,
    speciesID
)
  local pet =
      GetExtendedPet(
        petID,
        speciesID
      )

  if not pet then
    return nil
  end

  return pet.expansionName or pet.expansion
end

local function GetBreedName(
    petID,
    speciesID
)
  if not petID then
    return nil
  end

  local pet =
      GetExtendedPet(
        petID,
        speciesID
      )

  if not pet then
    return nil
  end

  if pet.breedName then
    return pet.breedName
  end

  if pet.breedID
      and addon.Services
      and addon.Services.Breed
      and type(
        addon.Services.Breed.GetBreedName
      ) == "function" then
    return addon.Services.Breed:
    GetBreedName(
      pet.breedID
    )
  end

  return nil
end

local function GetLevelRangeKey(level)
  level = tonumber(level)

  if not level then
    return nil
  end

  for _, range in ipairs(
    LEVEL_RANGES
  ) do
    if level >= range.min
        and level <= range.max then
      return range.key
    end
  end

  return nil
end

local function CreateExpansionMenu(
    owner,
    root
)
  local submenu =
      root:CreateButton(
        "Expansion"
      )

  AddCheckAllButtons(
    submenu,
    Filters.expansions,
    EXPANSIONS
  )

  for _, expansion in ipairs(
    EXPANSIONS
  ) do
    submenu:CreateCheckbox(
      expansion,

      function()
        return Filters.expansions[
        expansion
        ] == true
      end,

      function()
        Toggle(
          Filters.expansions,
          expansion
        )
      end
    )
  end
end

local function CreateRarityMenu(
    owner,
    root
)
  local submenu =
      root:CreateButton(
        "Rarity"
      )

  AddCheckAllButtons(
    submenu,
    Filters.rarities,
    RARITIES
  )

  for _, rarity in ipairs(
    RARITIES
  ) do
    submenu:CreateCheckbox(
      rarity,

      function()
        return Filters.rarities[
        rarity
        ] == true
      end,

      function()
        Toggle(
          Filters.rarities,
          rarity
        )
      end
    )
  end
end

local function CreateLevelMenu(
    owner,
    root
)
  local submenu =
      root:CreateButton(
        "Level"
      )

  AddCheckAllButtons(
    submenu,
    Filters.levels,
    LEVEL_RANGE_KEYS
  )

  for _, range in ipairs(
    LEVEL_RANGES
  ) do
    local rangeKey =
        range.key

    submenu:CreateCheckbox(
      range.label,

      function()
        return Filters.levels[
        rangeKey
        ] == true
      end,

      function()
        Toggle(
          Filters.levels,
          rangeKey
        )
      end
    )
  end
end

local function CreateBreedMenu(
    owner,
    root
)
  local submenu =
      root:CreateButton(
        "Breed"
      )

  AddCheckAllButtons(
    submenu,
    Filters.breeds,
    BREEDS
  )

  for _, breed in ipairs(
    BREEDS
  ) do
    submenu:CreateCheckbox(
      breed,

      function()
        return Filters.breeds[
        breed
        ] == true
      end,

      function()
        Toggle(
          Filters.breeds,
          breed
        )
      end
    )
  end
end

local function CreateOtherMenu(
    owner,
    root
)
  local submenu =
      root:CreateButton(
        "Other"
      )

  --------------------------------------------------
  -- Leveling
  --------------------------------------------------

  submenu:CreateCheckbox(
    "Leveling",

    function()
      return IsOtherFilterChecked(
        "leveling",
        "leveling"
      )
    end,

    function()
      SetOtherFilter(
        "leveling",
        "leveling"
      )

      return MenuResponse.Refresh
    end
  )

  submenu:CreateCheckbox(
    "Not Leveling",

    function()
      return IsOtherFilterChecked(
        "leveling",
        "notLeveling"
      )
    end,

    function()
      SetOtherFilter(
        "leveling",
        "notLeveling"
      )

      return MenuResponse.Refresh
    end
  )

  submenu:CreateDivider()

  --------------------------------------------------
  -- Tradable
  --------------------------------------------------

  submenu:CreateCheckbox(
    "Tradable",

    function()
      return IsOtherFilterChecked(
        "tradable",
        "tradable"
      )
    end,

    function()
      SetOtherFilter(
        "tradable",
        "tradable"
      )

      return MenuResponse.Refresh
    end
  )

  submenu:CreateCheckbox(
    "Not Tradable",

    function()
      return IsOtherFilterChecked(
        "tradable",
        "notTradable"
      )
    end,

    function()
      SetOtherFilter(
        "tradable",
        "notTradable"
      )

      return MenuResponse.Refresh
    end
  )

  submenu:CreateDivider()

  --------------------------------------------------
  -- Battle
  --------------------------------------------------

  submenu:CreateCheckbox(
    "Can Battle",

    function()
      return IsOtherFilterChecked(
        "battle",
        "canBattle"
      )
    end,

    function()
      SetOtherFilter(
        "battle",
        "canBattle"
      )

      return MenuResponse.Refresh
    end
  )

  submenu:CreateCheckbox(
    "Can't Battle",

    function()
      return IsOtherFilterChecked(
        "battle",
        "cannotBattle"
      )
    end,

    function()
      SetOtherFilter(
        "battle",
        "cannotBattle"
      )

      return MenuResponse.Refresh
    end
  )

  submenu:CreateDivider()

  --------------------------------------------------
  -- Teams
  --------------------------------------------------

  submenu:CreateCheckbox(
    "In A Team",

    function()
      return IsOtherFilterChecked(
        "team",
        "inTeam"
      )
    end,

    function()
      SetOtherFilter(
        "team",
        "inTeam"
      )

      return MenuResponse.Refresh
    end
  )

  submenu:CreateCheckbox(
    "Not In A Team",

    function()
      return IsOtherFilterChecked(
        "team",
        "notInTeam"
      )
    end,

    function()
      SetOtherFilter(
        "team",
        "notInTeam"
      )

      return MenuResponse.Refresh
    end
  )

  submenu:CreateDivider()

  local resetButton =
      submenu:CreateButton(
        "Reset"
      )

  resetButton:SetResponder(
    function()
      ResetOtherFilters()

      return MenuResponse.Refresh
    end
  )
end

local function CreatePetFamiliesMenu(
    owner,
    root
)
  local submenu =
      root:CreateButton(
        PET_FAMILIES
      )

  AddCheckAllButtons(
    submenu,
    Filters.petTypes,
    PET_TYPES,
    SyncNativePetTypes
  )

  for _, petType in ipairs(
    PET_TYPES
  ) do
    local currentPetType =
        petType

    submenu:CreateCheckbox(
      _G[
      "BATTLE_PET_NAME_"
      .. currentPetType
      ],

      function()
        return Filters.petTypes[
        currentPetType
        ] == true
      end,

      function()
        Toggle(
          Filters.petTypes,
          currentPetType,
          SyncNativePetTypes
        )

        return MenuResponse.Refresh
      end
    )
  end
end

local function CreateSourcesMenu(
    owner,
    root
)
  local submenu =
      root:CreateButton(
        SOURCES
      )

  AddCheckAllButtons(
    submenu,
    Filters.sources,
    PET_SOURCES,
    SyncNativeSources
  )

  for _, sourceIndex in ipairs(
    PET_SOURCES
  ) do
    local currentSource =
        sourceIndex

    submenu:CreateCheckbox(
      _G[
      "BATTLE_PET_SOURCE_"
      .. currentSource
      ],

      function()
        return Filters.sources[
        currentSource
        ] == true
      end,

      function()
        Toggle(
          Filters.sources,
          currentSource,
          SyncNativeSources
        )

        return MenuResponse.Refresh
      end
    )
  end
end

local function HasCustomFilter(
    filter,
    options
)
  return HasSelection(
    filter,
    options
  )
end

local function HasCollectedFilter()
  if type(
        PetJournalFilterDropdown_GetCollectedFilter
      ) ~= "function"
      or type(
        PetJournalFilterDropdown_GetNotCollectedFilter
      ) ~= "function" then
    return false
  end

  return not PetJournalFilterDropdown_GetCollectedFilter()
      or not PetJournalFilterDropdown_GetNotCollectedFilter()
end

local function GetExpansionOrder(
    expansionName
)
  if not expansionName then
    return 0
  end

  for index, name in ipairs(
    EXPANSIONS
  ) do
    if name == expansionName then
      return index
    end
  end

  return 0
end

local function GetBreedOrder(
    breedName
)
  if not breedName then
    return math.huge
  end

  for index, name in ipairs(
    BREEDS
  ) do
    if name == breedName then
      return index
    end
  end

  return math.huge
end

local function GetPetStatsForSorting(
    petID
)
  if not petID then
    return 0, 0, 0
  end

  local health,
  _maxHealth,
  power,
  speed =
      C_PetJournal.GetPetStats(
        petID
      )

  return tonumber(health) or 0,
      tonumber(power) or 0,
      tonumber(speed) or 0
end

local function IsPetInAnyTeam(
    petID,
    speciesID
)
  --------------------------------------------------
  -- Koppel hier jouw bestaande teamservice.
  --------------------------------------------------

  local teamService =
      addon.Services
      and addon.Services.Team

  if teamService
      and type(
        teamService.IsPetInAnyTeam
      ) == "function" then
    return teamService:
    IsPetInAnyTeam(
      petID,
      speciesID
    ) == true
  end

  return false
end

local function GetSortData(item)
  local pet =
      GetExtendedPet(
        item.petID,
        item.speciesID
      )

  local expansionName =
      pet
      and (
        pet.expansionName
        or pet.expansion
      )

  local breedName =
      GetBreedName(
        item.petID,
        item.speciesID
      )

  local health,
  power,
  speed =
      GetPetStatsForSorting(
        item.petID
      )

  local isFavorite = false

  if item.petID then
    isFavorite =
        C_PetJournal.PetIsFavorite(
          item.petID
        ) == true
  end

  return {
    expansionOrder =
        GetExpansionOrder(
          expansionName
        ),

    breedOrder =
        GetBreedOrder(
          breedName
        ),

    health = health,
    power = power,
    speed = speed,

    isFavorite = isFavorite,

    isInTeam =
        IsPetInAnyTeam(
          item.petID,
          item.speciesID
        ),

    name =
        pet
        and pet.name
        or "",
  }
end

local function CompareValues(
    a,
    b
)
  if a == b then
    return 0
  end

  if a < b then
    return -1
  end

  return 1
end

local function SortItems(items)
  local customSort =
      ActiveSort.type == "custom"
      and ActiveSort.value
      or nil

  local needsManualSort =
      customSort ~= nil
      or SortOptions.favoritesFirst
      or SortOptions.reverse

  if not needsManualSort then
    return
  end

  for _, item in ipairs(items) do
    item.sortData =
        GetSortData(item)
  end

  table.sort(
    items,

    function(a, b)
      local aData = a.sortData
      local bData = b.sortData

      ------------------------------------------------
      -- Favorites blijven altijd eerst staan.
      -- Reverse Sort draait dit niet om.
      ------------------------------------------------

      if SortOptions.favoritesFirst
          and aData.isFavorite
          ~= bData.isFavorite then
        return aData.isFavorite == true
      end

      local comparison = 0

      ------------------------------------------------
      -- PetMatch-sorteringen
      ------------------------------------------------

      if customSort == "expansion" then
        -- Standaard: nieuwste expansion eerst.
        comparison =
            CompareValues(
              bData.expansionOrder,
              aData.expansionOrder
            )
      elseif customSort == "breed" then
        -- Volgorde zoals BREEDS is gedefinieerd.
        comparison =
            CompareValues(
              aData.breedOrder,
              bData.breedOrder
            )
      elseif customSort == "health" then
        -- Standaard: hoogste eerst.
        comparison =
            CompareValues(
              bData.health,
              aData.health
            )
      elseif customSort == "power" then
        comparison =
            CompareValues(
              bData.power,
              aData.power
            )
      elseif customSort == "speed" then
        comparison =
            CompareValues(
              bData.speed,
              aData.speed
            )
      elseif customSort == "teams" then
        if aData.isInTeam
            ~= bData.isInTeam then
          comparison =
              aData.isInTeam
              and -1
              or 1
        end
      end

      ------------------------------------------------
      -- Blizzard-sortering met modifiers
      ------------------------------------------------

      if not customSort then
        local sortParameter =
            ActiveSort.value

        if sortParameter
            == LE_SORT_BY_NAME then
          comparison =
              CompareValues(
                string.lower(
                  aData.name or ""
                ),
                string.lower(
                  bData.name or ""
                )
              )
        elseif sortParameter
            == LE_SORT_BY_LEVEL then
          comparison =
              CompareValues(
                tonumber(b.level) or 0,
                tonumber(a.level) or 0
              )
        elseif sortParameter
            == LE_SORT_BY_RARITY then
          comparison =
              CompareValues(
                tonumber(b.rarity) or 0,
                tonumber(a.rarity) or 0
              )
        elseif sortParameter
            == LE_SORT_BY_PETTYPE then
          comparison =
              CompareValues(
                tonumber(a.petType) or 0,
                tonumber(b.petType) or 0
              )
        end
      end

      ------------------------------------------------
      -- Secundaire sortering op naam
      ------------------------------------------------

      if comparison == 0 then
        comparison =
            CompareValues(
              string.lower(
                aData.name or ""
              ),
              string.lower(
                bData.name or ""
              )
            )
      end

      if SortOptions.reverse then
        comparison = -comparison
      end

      return comparison < 0
    end
  )
end

local function SelectBlizzardSort(
    sortParameter
)
  ActiveSort.type = "blizzard"
  ActiveSort.value = sortParameter

  C_PetJournal.SetPetSortParameter(
    sortParameter
  )

  ClearCache()
  FilterExtension:ApplyFilters()
end

local function SelectCustomSort(
    sortKey
)
  ActiveSort.type = "custom"
  ActiveSort.value = sortKey

  ClearCache()
  FilterExtension:ApplyFilters()
end

local function CreateUnifiedSortMenu(
    root
)
  local submenu =
      root:CreateButton(
        RAID_FRAME_SORT_LABEL
      )

  local blizzardSorts = {
    {
      label = NAME,
      value = LE_SORT_BY_NAME,
    },
    {
      label = LEVEL,
      value = LE_SORT_BY_LEVEL,
    },
    {
      label = RARITY,
      value = LE_SORT_BY_RARITY,
    },
    {
      label = TYPE,
      value = LE_SORT_BY_PETTYPE,
    },
  }

  for _, option in ipairs(
    blizzardSorts
  ) do
    local sortParameter =
        option.value

    submenu:CreateRadio(
      option.label,

      function(parameter)
        return ActiveSort.type
            == "blizzard"
            and ActiveSort.value
            == parameter
      end,

      function(parameter)
        SelectBlizzardSort(
          parameter
        )

        return MenuResponse.Refresh
      end,

      sortParameter
    )
  end

  for _, option in ipairs(
    SORT_OPTIONS
  ) do
    local sortKey =
        option.key

    submenu:CreateRadio(
      option.label,

      function(key)
        return ActiveSort.type
            == "custom"
            and ActiveSort.value
            == key
      end,

      function(key)
        SelectCustomSort(
          key
        )

        return MenuResponse.Refresh
      end,

      sortKey
    )
  end

  submenu:CreateDivider()

  submenu:CreateCheckbox(
    "Favorites First",

    function()
      return SortOptions.favoritesFirst
          == true
    end,

    function()
      SortOptions.favoritesFirst =
          not SortOptions.favoritesFirst

      ClearCache()
      FilterExtension:ApplyFilters()

      return MenuResponse.Refresh
    end
  )

  submenu:CreateCheckbox(
    "Reverse Sort",

    function()
      return SortOptions.reverse
          == true
    end,

    function()
      SortOptions.reverse =
          not SortOptions.reverse

      ClearCache()
      FilterExtension:ApplyFilters()

      return MenuResponse.Refresh
    end
  )

  submenu:CreateDivider()

  local resetButton =
      submenu:CreateButton(
        RESET
      )

  resetButton:SetResponder(
    function()
      -----------------------------------------
      -- Blizzard sort
      -----------------------------------------

      ActiveSort.type = "blizzard"
      ActiveSort.value = LE_SORT_BY_NAME

      C_PetJournal.SetPetSortParameter(
        LE_SORT_BY_NAME
      )

      -----------------------------------------
      -- PetMatch sort options
      -----------------------------------------

      SortOptions.favoritesFirst = false
      SortOptions.reverse = false

      -----------------------------------------
      -- Refresh
      -----------------------------------------

      ClearCache()
      FilterExtension:ApplyFilters()

      return MenuResponse.Refresh
    end
  )
end

function FilterExtension:SetupFilterDropdown()
  if not PetJournal
      or not PetJournal.FilterDropdown then
    return
  end

  local dropdown =
      PetJournal.FilterDropdown

  dropdown:SetWidth(90)

  dropdown:SetIsDefaultCallback(
    function()
      -- PetMatch gebruikt de eigen filterbalk.
      -- Daardoor blijft Blizzard's rode resetknop verborgen.
      return true
    end
  )

  dropdown:SetDefaultCallback(
    function()
      FilterExtension:
          ResetAllFilters()
    end
  )

  dropdown:SetupMenu(
    function(_dropdown, root)
      root:SetTag(
        "MENU_PET_COLLECTION_FILTER"
      )

      root:CreateCheckbox(
        COLLECTED,
        PetJournalFilterDropdown_GetCollectedFilter,
        function()
          PetJournalFilterDropdown_SetCollectedFilter(
            not PetJournalFilterDropdown_GetCollectedFilter()
          )
        end
      )

      root:CreateCheckbox(
        NOT_COLLECTED,
        PetJournalFilterDropdown_GetNotCollectedFilter,
        function()
          PetJournalFilterDropdown_SetNotCollectedFilter(
            not PetJournalFilterDropdown_GetNotCollectedFilter()
          )
        end
      )

      root:CreateDivider()

      CreatePetFamiliesMenu(
        _dropdown,
        root
      )

      CreateSourcesMenu(
        _dropdown,
        root
      )

      CreateExpansionMenu(
        _dropdown,
        root
      )

      CreateRarityMenu(
        _dropdown,
        root
      )

      CreateLevelMenu(
        _dropdown,
        root
      )

      CreateBreedMenu(
        _dropdown,
        root
      )

      CreateOtherMenu(
        _dropdown,
        root
      )

      CreateUnifiedSortMenu(
        root
      )
    end
  )
end

function FilterExtension:HideBlizzardResetButton()
  if not PetJournal
      or not PetJournal.FilterDropdown then
    return
  end

  local dropdown = PetJournal.FilterDropdown

  if dropdown.ResetButton then
    dropdown.ResetButton:Hide()
    dropdown.ResetButton:SetAlpha(0)
    dropdown.ResetButton:EnableMouse(false)

    dropdown.ResetButton:HookScript(
      "OnShow",
      function(button)
        button:Hide()
        button:SetAlpha(0)
        button:EnableMouse(false)
      end
    )
  end
end

function FilterExtension:GetActiveFilterNames()
  local names = {}

  if HasCollectedFilter() then
    names[#names + 1] = "Collected"
  end

  if HasCustomFilter(
        Filters.petTypes,
        PET_TYPES
      ) then
    names[#names + 1] =
    "Pet Families"
  end

  if HasCustomFilter(
        Filters.sources,
        PET_SOURCES
      ) then
    names[#names + 1] = "Sources"
  end

  if HasCustomFilter(
        Filters.expansions,
        EXPANSIONS
      ) then
    names[#names + 1] = "Expansion"
  end

  if HasCustomFilter(
        Filters.rarities,
        RARITIES
      ) then
    names[#names + 1] = "Rarity"
  end

  if HasCustomFilter(
        Filters.levels,
        LEVEL_RANGE_KEYS
      ) then
    names[#names + 1] = "Level"
  end

  if HasCustomFilter(
        Filters.breeds,
        BREEDS
      ) then
    names[#names + 1] = "Breed"
  end

  if HasOtherFilters() then
    names[#names + 1] = "Other"
  end

  return names
end

function FilterExtension:LayoutPetList(
    filterBarShown
)
  if not PetJournal
      or not PetJournal.ScrollBox
      or not PetJournal.LeftInset then
    return
  end

  local scrollBox =
      PetJournal.ScrollBox

  scrollBox:ClearAllPoints()

  scrollBox:SetPoint(
    "TOPLEFT",
    PetJournal.LeftInset,
    "TOPLEFT",
    3,
    filterBarShown
    and PET_LIST_FILTERED_TOP_OFFSET
    or PET_LIST_NORMAL_TOP_OFFSET
  )

  scrollBox:SetPoint(
    "BOTTOMRIGHT",
    PetJournal.LeftInset,
    "BOTTOMRIGHT",
    -2,
    3
  )
end

function FilterExtension:CreateFilterBar()
  if self.FilterBar
      or not PetJournal
      or not PetJournal.LeftInset then
    return
  end

  local bar =
      CreateFrame(
        "Frame",
        nil,
        PetJournal.LeftInset,
        "BackdropTemplate"
      )

  bar:SetHeight(
    FILTER_BAR_HEIGHT
  )

  bar:SetPoint(
    "TOPLEFT",
    PetJournal.LeftInset,
    "TOPLEFT",
    5,
    -35
  )

  bar:SetPoint(
    "TOPRIGHT",
    PetJournal.LeftInset,
    "TOPRIGHT",
    -5,
    -35
  )

  bar:SetFrameStrata(
    PetJournal.LeftInset:GetFrameStrata()
  )

  bar:SetFrameLevel(
    PetJournal.ScrollBox:GetFrameLevel()
    + 20
  )

  bar:EnableMouse(true)

  bar:SetBackdrop({
    bgFile =
    "Interface\\Buttons\\WHITE8X8",

    edgeFile =
    "Interface\\Tooltips\\UI-Tooltip-Border",

    edgeSize = 10,

    insets = {
      left = 2,
      right = 2,
      top = 2,
      bottom = 2,
    },
  })

  bar:SetBackdropColor(
    0.03,
    0.03,
    0.03,
    0.92
  )

  bar:SetBackdropBorderColor(
    0.45,
    0.45,
    0.45,
    1
  )

  bar.Count =
      bar:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontNormalSmall"
      )

  bar.Count:SetPoint(
    "LEFT",
    bar,
    "LEFT",
    8,
    0
  )

  bar.Count:SetTextColor(
    1,
    0.82,
    0,
    1
  )

  bar.Filters =
      bar:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlightSmall"
      )

  bar.Filters:SetPoint(
    "LEFT",
    bar.Count,
    "RIGHT",
    5,
    0
  )

  bar.Filters:SetPoint(
    "RIGHT",
    bar,
    "RIGHT",
    -25,
    0
  )

  bar.Filters:SetJustifyH("LEFT")
  bar.Filters:SetWordWrap(false)

  bar.Close =
      CreateFrame(
        "Button",
        nil,
        bar,
        "UIPanelCloseButton"
      )

  bar.Close:SetSize(
    20,
    20
  )

  bar.Close:SetPoint(
    "RIGHT",
    bar,
    "RIGHT",
    -2,
    0
  )

  bar.Close:SetScript(
    "OnClick",
    function(button)
      button:GetParent():Hide()
      FilterExtension:ResetAllFilters()
    end
  )

  bar.Close:SetFrameLevel(
    bar:GetFrameLevel() + 1
  )

  bar.Close:EnableMouse(true)

  bar:Hide()

  self.FilterBar = bar
end

function FilterExtension:UpdateFilterBar(
    visiblePetCount
)
  self:CreateFilterBar()

  if not self.FilterBar then
    return
  end

  local activeFilters =
      self:GetActiveFilterNames()

  if #activeFilters == 0 then
    self.FilterBar:Hide()
    self:LayoutPetList(false)

    return
  end

  self.FilterBar.Count:SetFormattedText(
    "Pets: %d",
    tonumber(visiblePetCount) or 0
  )

  self.FilterBar.Filters:SetFormattedText(
    "Filters: %s",
    table.concat(
      activeFilters,
      ", "
    )
  )

  self.FilterBar:Show()
  self:LayoutPetList(true)
end

function FilterExtension:ResetAllFilters()
  --------------------------------------------------
  -- PetMatch multi-selectfilters
  --------------------------------------------------
  SetAll(
    Filters.petTypes,
    PET_TYPES,
    false
  )

  SetAll(
    Filters.sources,
    PET_SOURCES,
    false
  )

  SetAll(
    Filters.expansions,
    EXPANSIONS,
    false
  )

  SetAll(
    Filters.rarities,
    RARITIES,
    false
  )

  SetAll(
    Filters.levels,
    LEVEL_RANGE_KEYS,
    false
  )

  SetAll(
    Filters.breeds,
    BREEDS,
    false
  )

  --------------------------------------------------
  -- Other
  --------------------------------------------------

  OtherFilters.leveling = nil
  OtherFilters.tradable = nil
  OtherFilters.battle = nil
  OtherFilters.team = nil

  --------------------------------------------------
  -- Sorteermodifiers
  --------------------------------------------------

  SortOptions.favoritesFirst = false
  SortOptions.reverse = false

  --------------------------------------------------
  -- Standaardsortering
  --------------------------------------------------

  ActiveSort.type = "blizzard"
  ActiveSort.value = LE_SORT_BY_NAME

  C_PetJournal.SetPetSortParameter(
    LE_SORT_BY_NAME
  )

  --------------------------------------------------
  -- Blizzard-native filters
  --------------------------------------------------

  -- if C_PetJournal.SetDefaultFilters then
  --   C_PetJournal.SetDefaultFilters()
  -- end

  SyncNativePetTypes()
  SyncNativeSources()

  ClearCache()
  self:Refresh()
end

function FilterExtension:Refresh()
  ClearCache()

  if type(PetJournal_UpdatePetList)
      ~= "function" then
    return
  end

  if not PetJournal
      or not PetJournal.ScrollBox then
    return
  end

  PetJournal_UpdatePetList()
end

function FilterExtension:MatchesPet(
    petID,
    speciesID,
    isOwned,
    level,
    petType,
    canBattle,
    tradable
)
  --------------------------------------------------
  -- Expansion
  --------------------------------------------------
  if HasSelection(
        Filters.expansions,
        EXPANSIONS
      ) then
    local expansion =
        GetExpansionName(
          petID,
          speciesID
        )

    if not MatchesFilter(
          Filters.expansions,
          EXPANSIONS,
          expansion
        ) then
      return false
    end
  end

  --------------------------------------------------
  -- Rarity
  --------------------------------------------------
  if HasSelection(
        Filters.rarities,
        RARITIES
      ) then
    local rarityName

    if isOwned and petID then
      local _, _, _, _, rarity =
          C_PetJournal.GetPetStats(
            petID
          )

      rarityName =
          RARITY_NAMES[
          tonumber(rarity)
          ]
    end

    if not MatchesFilter(
          Filters.rarities,
          RARITIES,
          rarityName
        ) then
      return false
    end
  end

  --------------------------------------------------
  -- Level
  --------------------------------------------------
  if HasSelection(
        Filters.levels,
        LEVEL_RANGE_KEYS
      ) then
    local rangeKey

    if isOwned then
      rangeKey =
          GetLevelRangeKey(
            level
          )
    end

    if not MatchesFilter(
          Filters.levels,
          LEVEL_RANGE_KEYS,
          rangeKey
        ) then
      return false
    end
  end

  --------------------------------------------------
  -- Breed
  --------------------------------------------------
  if HasSelection(
        Filters.breeds,
        BREEDS
      ) then
    local breed =
        GetBreedName(
          petID,
          speciesID
        )

    if not MatchesFilter(
          Filters.breeds,
          BREEDS,
          breed
        ) then
      return false
    end
  end

  --------------------------------------------------
  -- Other: Leveling
  --------------------------------------------------

  if OtherFilters.leveling ~= nil then
    local isLeveling =
        isOwned == true
        and canBattle == true
        and tonumber(level) ~= nil
        and tonumber(level) < 25

    if OtherFilters.leveling == "leveling"
        and not isLeveling then
      return false
    end

    if OtherFilters.leveling == "notLeveling"
        and isLeveling then
      return false
    end
  end

  --------------------------------------------------
  -- Other: Tradable
  --------------------------------------------------

  if OtherFilters.tradable == "tradable"
      and tradable ~= true then
    return false
  end

  if OtherFilters.tradable == "notTradable"
      and tradable == true then
    return false
  end

  --------------------------------------------------
  -- Other: Can Battle
  --------------------------------------------------

  if OtherFilters.battle == "canBattle"
      and canBattle ~= true then
    return false
  end

  if OtherFilters.battle == "cannotBattle"
      and canBattle == true then
    return false
  end

  --------------------------------------------------
  -- Other: Team
  --------------------------------------------------

  if OtherFilters.team ~= nil then
    local isInTeam =
        IsPetInAnyTeam(
          petID,
          speciesID
        )

    if OtherFilters.team == "inTeam"
        and not isInTeam then
      return false
    end

    if OtherFilters.team == "notInTeam"
        and isInTeam then
      return false
    end
  end

  return true
end

function FilterExtension:ApplyFilters()
  if not PetJournal
      or not PetJournal.ScrollBox then
    return
  end

  local items = {}

  local petCount =
      C_PetJournal.GetNumPets()

  for index = 1, petCount do
    local petID,
    speciesID,
    isOwned,
    _customName,
    level,
    _favorite,
    _isRevoked,
    _name,
    _icon,
    petType,
    _creatureID,
    _sourceText,
    _description,
    _isHatchable,
    canBattle,
    tradable =
        C_PetJournal.GetPetInfoByIndex(
          index
        )

    if self:MatchesPet(
          petID,
          speciesID,
          isOwned,
          level,
          petType,
          canBattle == true,
          tradable == true
        ) then
      local rarity = 0

      if petID then
        rarity =
            select(
              5,
              C_PetJournal.GetPetStats(
                petID
              )
            ) or 0
      end

      items[#items + 1] = {
        index = index,
        petID = petID,
        speciesID = speciesID,
        isOwned = isOwned == true,
        level = tonumber(level) or 0,
        rarity = tonumber(rarity) or 0,
        petType = tonumber(petType) or 0,
      }
    end
  end

  SortItems(items)

  local dataProvider =
      CreateDataProvider()

  for _, item in ipairs(items) do
    dataProvider:Insert({
      index = item.index,
      petID = item.petID,
      speciesID = item.speciesID,
    })
  end

  PetJournal.ScrollBox:SetDataProvider(
    dataProvider,
    ScrollBoxConstants.RetainScrollPosition
  )

  self:UpdateFilterBar(
    #items
  )
end

function FilterExtension:HookPetJournal()
  if self.PetJournalHooked then
    return
  end

  if type(PetJournal_UpdatePetList)
      ~= "function" then
    return
  end

  self.PetJournalHooked = true

  hooksecurefunc(
    "PetJournal_UpdatePetList",

    function()
      FilterExtension:
          ApplyFilters()
    end
  )
end

function FilterExtension:Initialize()
  InitializeFilters()

  ActiveSort.type = "blizzard"
  ActiveSort.value = C_PetJournal.GetPetSortParameter()

  self.EventFrame =
      CreateFrame("Frame")

  self.EventFrame:RegisterEvent(
    "ADDON_LOADED"
  )

  self.EventFrame:RegisterEvent(
    "PET_JOURNAL_LIST_UPDATE"
  )

  self.EventFrame:SetScript(
    "OnEvent",

    function(_, event, loadedAddon)
      if event == "ADDON_LOADED" then
        if loadedAddon
            == "Blizzard_Collections" then
          FilterExtension:SetupFilterDropdown()
          FilterExtension:HookPetJournal()
          FilterExtension:CreateFilterBar()
          FilterExtension:HideBlizzardResetButton()
          SyncNativeFilters()
        end
      elseif event
          == "PET_JOURNAL_LIST_UPDATE" then
        ClearCache()

        FilterExtension:
            HookPetJournal()
      end
    end
  )

  self:HookPetJournal()
  self:SetupFilterDropdown()
  self:CreateFilterBar()
  self:HideBlizzardResetButton()

  if PetJournal
      and PetJournal.FilterDropdown then
    SyncNativeFilters()
  end
end

addon.PetJournalFilterExtension = FilterExtension
addon.ModuleManager:Register(
  "FilterExtension",
  FilterExtension
)
