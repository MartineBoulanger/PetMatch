local _, addon = ...

local FilterExtension = {}

local Filters = {
  petTypes = {},
  sources = {},
  expansions = {},
  rarities = {},
  levels = {},
  breeds = {},
  tags = {}
}

local PET_TYPES = {}
local PET_SOURCES = {}

local ItemPool = {}

local ActiveItems = {}
local BuildItems = {}
local LastNativeSearchText = nil

local applyFiltersTimer = nil
local refreshRequired = false
local currentFilterBarShown = nil
local applyFiltersQueued = false

local APPLY_FILTERS_DELAY = 0.4

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

local EXPANSION_SEARCH_IDS = {
  classic = 0,
  vanilla = 0,

  tbc = 1,
  burningcrusade = 1,

  wotlk = 2,
  wrath = 2,
  wrathofthelichking = 2,

  cataclysm = 3,
  cata = 3,

  mop = 4,
  mistsofpandaria = 4,

  wod = 5,
  warlordsofdraenor = 5,

  legion = 6,

  bfa = 7,
  battleforazeroth = 7,

  shadowlands = 8,
  sl = 8,

  dragonflight = 9,
  df = 9,

  thewarwithin = 10,
  tww = 10,

  midnight = 11,
  mid = 11
}

local PET_TYPE_SEARCH_NAMES = {
  [1] = "humanoid",
  [2] = "dragonkin",
  [3] = "flying",
  [4] = "undead",
  [5] = "critter",
  [6] = "magic",
  [7] = "elemental",
  [8] = "beast",
  [9] = "aquatic",
  [10] = "mechanical",
}

local PET_TYPE_SEARCH_ALIASES = {
  dragon = "dragonkin",
  magical = "magic",
  water = "aquatic",
  mech = "mechanical",
}

local LEVEL_RANGE_KEYS = {}
for _, range in ipairs(LEVEL_RANGES) do
  LEVEL_RANGE_KEYS[#LEVEL_RANGE_KEYS + 1] =
      range.key
end

local TYPE_FILTER_BAR_HEIGHT = 56
local TYPE_FILTER_BAR_TOP_OFFSET = -32

local FILTER_BAR_HEIGHT = 24
local FILTER_BAR_SPACING = 4

local FILTER_BAR_TOP_OFFSET = TYPE_FILTER_BAR_TOP_OFFSET - TYPE_FILTER_BAR_HEIGHT - FILTER_BAR_SPACING
local PET_LIST_NORMAL_TOP_OFFSET = FILTER_BAR_TOP_OFFSET
local PET_LIST_FILTERED_TOP_OFFSET = FILTER_BAR_TOP_OFFSET - FILTER_BAR_HEIGHT + 2

local OtherFilters = {
  leveling = nil,
  tradable = nil,
  battle = nil,
  team = nil,
  duplicates = nil
}

local TAG_FILTER_OPTIONS = {
  1,
  2,
  3,
  4,
  5,
  6,
  7,
  8,
  "none",
}
local RAID_MARKER_TEXTURE_FORMAT = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_%d"

local MAX_SORT_LEVELS = 3

local SortLevels = {}
local SortOptions = {
  favoritesFirst = true,
  reverse = false,
}

local ALL_SORT_OPTIONS = {
  {
    key = "name",
    label = NAME,
  },
  {
    key = "level",
    label = LEVEL,
  },
  {
    key = "rarity",
    label = RARITY,
  },
  {
    key = "type",
    label = TYPE,
  },
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

local AdvancedSearch = {
  rawText = "",
  nativeText = "",
  filters = {},
}

local ADVANCED_SEARCH_FIELDS = {
  level = "number",
  health = "number",
  power = "number",
  speed = "number",

  rarity = "text",
  breed = "text",
  type = "text",
  expansion = "text",

  favorite = "boolean",
  canbattle = "boolean",
  tradable = "boolean",
  owned = "boolean",
}

local function QueueApplyFilters()
  --------------------------------------------------
  -- Blizzard kan tijdens het openen van de
  -- Pet Journal meerdere list updates vlak na
  -- elkaar sturen.
  --
  -- We wachten kort tot die reeks klaar is en
  -- voeren daarna slechts één volledige rebuild uit.
  --------------------------------------------------
  if not refreshRequired then
    return
  end

  if applyFiltersTimer then
    applyFiltersTimer:Cancel()
    applyFiltersTimer = nil
  end

  applyFiltersTimer =
      C_Timer.NewTimer(
        APPLY_FILTERS_DELAY,

        function()
          applyFiltersTimer = nil

          if not refreshRequired then
            return
          end

          refreshRequired = false

          FilterExtension:ApplyFilters()
        end
      )
end

local function CancelQueuedApplyFilters()
  if not applyFiltersTimer then
    return
  end

  applyFiltersTimer:Cancel()
  applyFiltersTimer = nil
end

local function QueueImmediateApplyFilters()
  if applyFiltersQueued then
    return
  end

  applyFiltersQueued = true

  C_Timer.After(
    0,
    function()
      applyFiltersQueued = false
      CancelQueuedApplyFilters()
      FilterExtension:ApplyFilters()
    end
  )
end

local function TokenizeSearch(text)
  local tokens = {}

  text = tostring(text or "")

  local index = 1
  local length = #text

  while index <= length do
    ------------------------------------------------
    -- Skip whitespace
    ------------------------------------------------
    while index <= length and text:sub(index, index):match("%s") do
      index = index + 1
    end

    if index > length then
      break
    end

    local startIndex = index
    local inQuotes = false

    while index <= length do
      local char = text:sub(index, index)

      if char == '"' then
        inQuotes = not inQuotes
      elseif char:match("%s") and not inQuotes then
        break
      end

      index = index + 1
    end

    local token = text:sub(startIndex, index - 1)

    if token ~= "" then
      tokens[#tokens + 1] = token
    end
  end

  return tokens
end

local function NormalizeExpansionSearch(value)
  value = string.lower(tostring(value or ""))

  --------------------------------------------------
  -- Remove spaces, apostrophes and dashes
  --------------------------------------------------
  value = value:gsub("[%s'%-]", "")

  return value
end

local function Unquote(value)
  value = tostring(value or "")

  if #value >= 2 and value:sub(1, 1) == '"' and value:sub(-1) == '"' then
    value = value:sub(2, -2)
  end

  return value
end

local function NormalizePetTypeSearch(value)
  value = string.lower(tostring(value or ""))
  return PET_TYPE_SEARCH_ALIASES[value] or value
end

local function GetSearchRarityName(rarity)
  local name = RARITY_NAMES[tonumber(rarity)]

  if not name then
    return nil
  end

  return string.lower(name)
end

local function ParseBoolean(value)
  value = string.lower(tostring(value or ""))

  if value == "true" or value == "yes" or value == "1" then
    return true
  end

  if value == "false" or value == "no" or value == "0" then
    return false
  end

  return nil
end

local function ParseAdvancedToken(token)
  local field
  local value
  local operator

  field, value = token:match("^([%a_]+)>=(.+)$")
  if field then
    operator = ">="
  end

  if not field then
    field, value = token:match("^([%a_]+)<=(.+)$")
    if field then
      operator = "<="
    end
  end

  if not field then
    field, value = token:match("^([%a_]+)>(.+)$")
    if field then
      operator = ">"
    end
  end

  if not field then
    field, value = token:match("^([%a_]+)<(.+)$")
    if field then
      operator = "<"
    end
  end

  if not field then
    field, value = token:match("^([%a_]+)=(.+)$")
    if field then
      operator = "="
    end
  end

  if not field then
    return nil
  end

  field = string.lower(field)
  value = Unquote(value)

  local fieldType = ADVANCED_SEARCH_FIELDS[field]

  if not fieldType then
    return nil
  end

  --------------------------------------------------
  -- Numeric
  --------------------------------------------------
  if fieldType == "number" then
    local number = tonumber(value)

    if number == nil then
      return nil
    end

    return {
      field = field,
      type = fieldType,
      operator = operator,
      value = number,
    }
  end

  --------------------------------------------------
  -- Boolean
  --------------------------------------------------
  if fieldType == "boolean" then
    if operator ~= "=" then
      return nil
    end

    local boolean = ParseBoolean(value)

    if boolean == nil then
      return nil
    end

    return {
      field = field,
      type = fieldType,
      operator = operator,
      value = boolean,
    }
  end

  --------------------------------------------------
  -- Text
  --------------------------------------------------
  if fieldType == "text" then
    if operator ~= "=" then
      return nil
    end

    value = string.lower(tostring(value or ""))

    if value == "" then
      return nil
    end

    return {
      field = field,
      type = fieldType,
      operator = operator,
      value = value,
    }
  end

  return nil
end

local function ParseAdvancedSearch(text)
  text = tostring(text or "")

  local nativeTerms = {}
  local filters = {}

  local tokens = TokenizeSearch(text)

  for _, token in ipairs(tokens) do
    local filter = ParseAdvancedToken(token)

    if filter then
      filters[#filters + 1] = filter
    else
      nativeTerms[#nativeTerms + 1] = token
    end
  end

  return {
    rawText = text,
    nativeText = table.concat(nativeTerms, " "),
    filters = filters,
  }
end

local function CompareSearchValue(actual, operator, expected)
  actual = tonumber(actual)
  expected = tonumber(expected)

  if actual == nil or expected == nil then
    return false
  end

  if operator == "=" then
    return actual == expected
  elseif operator == ">" then
    return actual > expected
  elseif operator == "<" then
    return actual < expected
  elseif operator == ">=" then
    return actual >= expected
  elseif operator == "<=" then
    return actual <= expected
  end

  return false
end

local function MatchesAdvancedSearch(
    petID,
    speciesID,
    isOwned,
    level,
    petType,
    favorite,
    canBattle,
    tradable
)
  local filters = AdvancedSearch.filters

  if type(filters) ~= "table"
      or #filters == 0 then
    return true
  end

  --------------------------------------------------
  -- Lazy stats
  --------------------------------------------------

  local statsLoaded = false

  local health = nil
  local power = nil
  local speed = nil
  local rarity = nil

  local function EnsureStats()
    if statsLoaded then
      return
    end

    statsLoaded = true

    if not petID then
      return
    end

    local currentHealth,
    _maxHealth,
    currentPower,
    currentSpeed,
    currentRarity =
        C_PetJournal.GetPetStats(
          petID
        )

    health =
        tonumber(currentHealth)

    power =
        tonumber(currentPower)

    speed =
        tonumber(currentSpeed)

    rarity =
        tonumber(currentRarity)
  end

  --------------------------------------------------
  -- Filters
  --------------------------------------------------

  for _, filter in ipairs(filters) do
    local field = filter.field

    ----------------------------------------------
    -- Numeric
    ----------------------------------------------
    if field == "level" then
      if not CompareSearchValue(
            level,
            filter.operator,
            filter.value
          ) then
        return false
      end
    elseif field == "health" then
      EnsureStats()

      if not CompareSearchValue(
            health,
            filter.operator,
            filter.value
          ) then
        return false
      end
    elseif field == "power" then
      EnsureStats()

      if not CompareSearchValue(
            power,
            filter.operator,
            filter.value
          ) then
        return false
      end
    elseif field == "speed" then
      EnsureStats()

      if not CompareSearchValue(
            speed,
            filter.operator,
            filter.value
          ) then
        return false
      end

      ----------------------------------------------
      -- Rarity
      ----------------------------------------------
    elseif field == "rarity" then
      EnsureStats()
      local actual = GetSearchRarityName(rarity)

      if actual ~= filter.value then
        return false
      end

      ----------------------------------------------
      -- Breed
      ----------------------------------------------
    elseif field == "breed" then
      local breed = GetBreedName(petID, speciesID)

      breed = breed and string.lower(breed)

      if breed ~= filter.value then
        return false
      end

      ----------------------------------------------
      -- Pet type
      ----------------------------------------------
    elseif field == "type" then
      local actual = PET_TYPE_SEARCH_NAMES[tonumber(petType)]
      local expected = NormalizePetTypeSearch(filter.value)

      if actual ~= expected then
        return false
      end

      ----------------------------------------------
      -- Expansion
      ----------------------------------------------
    elseif field == "expansion" then
      local expansionService = addon.Data and addon.Data.PetExpansion

      if not expansionService then
        return false
      end

      local searchValue = NormalizeExpansionSearch(filter.value)
      local expectedExpansionID = EXPANSION_SEARCH_IDS[searchValue]

      if expectedExpansionID == nil then
        return false
      end

      local actualExpansionID = expansionService:GetExpansionID(speciesID)

      if actualExpansionID ~= expectedExpansionID then
        return false
      end
      ----------------------------------------------
      -- Booleans
      ----------------------------------------------
    elseif field == "favorite" then
      if (favorite == true) ~= filter.value then
        return false
      end
    elseif field == "canbattle" then
      if (canBattle == true) ~= filter.value then
        return false
      end
    elseif field == "tradable" then
      if (tradable == true) ~= filter.value then
        return false
      end
    elseif field == "owned" then
      if (isOwned == true) ~= filter.value then
        return false
      end
    end
  end

  return true
end

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

local function InitializeFilter(filter, options)
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

  InitializeFilter(
    Filters.tags,
    TAG_FILTER_OPTIONS
  )
end

local function SetAll(filter, options, checked)
  for _, option in ipairs(options) do
    filter[option] = checked == true
  end
end

local function RefreshSorting()
  CancelQueuedApplyFilters()
  FilterExtension:ApplyFilters()
end

local function IsOtherFilterChecked(group, value)
  return OtherFilters[group] == value
end

local function HasOtherFilters()
  return OtherFilters.leveling ~= nil
      or OtherFilters.tradable ~= nil
      or OtherFilters.battle ~= nil
      or OtherFilters.team ~= nil
      or OtherFilters.duplicates ~= nil
end

local function ResetOtherFilters()
  OtherFilters.leveling = nil
  OtherFilters.tradable = nil
  OtherFilters.battle = nil
  OtherFilters.team = nil
  OtherFilters.duplicates = nil

  RefreshSorting()
end

local function SetOtherFilter(group, value)
  if OtherFilters[group] == value then
    OtherFilters[group] = nil
  else
    OtherFilters[group] = value
  end

  RefreshSorting()
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
    RefreshSorting()
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
        RefreshSorting()
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
        RefreshSorting()
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

  RefreshSorting()
end

local function GetExpansionName(_petID, speciesID)
  speciesID = tonumber(speciesID)

  if not speciesID then
    return nil
  end

  local petExpansion = addon.Data and addon.Data.PetExpansion

  if not petExpansion
      or type(petExpansion.GetExpansionName) ~= "function" then
    return nil
  end

  return petExpansion:GetExpansionName(speciesID)
end

local function GetBreedName(petID, _speciesID)
  if type(petID) ~= "string" or petID == "" then
    return nil
  end

  local breedService = addon.Services and addon.Services.Breed

  if not breedService
      or type(breedService.GetJournalBreed) ~= "function" then
    return nil
  end

  return breedService:GetJournalBreed(petID)
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

local function GetRaidMarkerTexture(tagID)
  tagID = tonumber(tagID)

  if not tagID
      or tagID < 1
      or tagID > 8 then
    return nil
  end

  return string.format(
    RAID_MARKER_TEXTURE_FORMAT,
    tagID
  )
end

local function BuildTagFilterLabel(
    definition
)
  if not definition then
    return "Unknown"
  end

  local texture =
      GetRaidMarkerTexture(
        definition.id
      )

  if not texture then
    return definition.name
        or "Unknown"
  end

  return string.format(
    "|T%s:14:14:0:0|t %s",
    texture,
    definition.name or "Unknown"
  )
end

local function GetPetTagFilterValue(
    petGUID
)
  if not petGUID then
    return "none"
  end

  local tagService =
      addon.Services
      and addon.Services.PetTag

  if not tagService then
    return "none"
  end

  local tagID =
      tagService:GetTag(
        petGUID
      )

  return tagID or "none"
end

local function HasDuplicatePet(speciesID)
  speciesID = tonumber(speciesID)

  if not speciesID then
    return false
  end

  local petJournalService = addon.Services and addon.Services.PetJournal

  if not petJournalService then
    return false
  end

  petJournalService:EnsureIndex()

  local pets = petJournalService.OwnedPetsBySpeciesID[speciesID]

  return type(pets) == "table" and #pets > 1
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

local function CreateTagMenu(
    owner,
    root
)
  local submenu =
      root:CreateButton(
        "Tag"
      )

  AddCheckAllButtons(
    submenu,
    Filters.tags,
    TAG_FILTER_OPTIONS
  )

  local tagService =
      addon.Services
      and addon.Services.PetTag

  if tagService then
    for _, definition in ipairs(
      tagService:GetDefinitions()
    ) do
      local tagID =
          definition.id

      submenu:CreateCheckbox(
        BuildTagFilterLabel(
          definition
        ),

        function()
          return Filters.tags[
          tagID
          ] == true
        end,

        function()
          Toggle(
            Filters.tags,
            tagID
          )

          return MenuResponse.Refresh
        end
      )
    end
  end

  submenu:CreateDivider()

  submenu:CreateCheckbox(
    "No Tag",

    function()
      return Filters.tags.none
          == true
    end,

    function()
      Toggle(
        Filters.tags,
        "none"
      )

      return MenuResponse.Refresh
    end
  )
end

local function CreateOtherMenu(owner, root)
  local submenu = root:CreateButton("Other")

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

  --------------------------------------------------
  -- Duplicates
  --------------------------------------------------
  submenu:CreateCheckbox(
    "Duplicates",
    function()
      return IsOtherFilterChecked(
        "duplicates",
        "duplicates"
      )
    end,
    function()
      SetOtherFilter(
        "duplicates",
        "duplicates"
      )

      return MenuResponse.Refresh
    end
  )

  submenu:CreateCheckbox(
    "No Duplicates",
    function()
      return IsOtherFilterChecked(
        "duplicates",
        "noDuplicates"
      )
    end,
    function()
      SetOtherFilter(
        "duplicates",
        "noDuplicates"
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

local function CreateSourcesMenu(owner, root)
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

local function GetSortLevelIndex(sortKey)
  for index, key in ipairs(SortLevels) do
    if key == sortKey then
      return index
    end
  end

  return nil
end

local function IsSortLevelSelected(sortKey)
  return GetSortLevelIndex(sortKey) ~= nil
end

local function ToggleSortLevel(sortKey)
  local index =
      GetSortLevelIndex(
        sortKey
      )

  if index then
    table.remove(
      SortLevels,
      index
    )
  else
    if #SortLevels
        >= MAX_SORT_LEVELS then
      return
    end

    SortLevels[
    #SortLevels + 1
    ] =
        sortKey
  end

  RefreshSorting()
end

local function PopulateSortData(item)
  --------------------------------------------------
  -- Favorites
  --------------------------------------------------
  if SortOptions.favoritesFirst then
    item.isFavorite =
        item.petID ~= nil
        and C_PetJournal.PetIsFavorite(
          item.petID
        ) == true
  else
    item.isFavorite = false
  end

  --------------------------------------------------
  -- Expansion
  --------------------------------------------------
  if IsSortLevelSelected(
        "expansion"
      ) then
    local expansionName =
        GetExpansionName(
          item.petID,
          item.speciesID
        )

    item.expansionOrder =
        GetExpansionOrder(
          expansionName
        )
  else
    item.expansionOrder = 0
  end

  --------------------------------------------------
  -- Breed
  --------------------------------------------------
  if IsSortLevelSelected(
        "breed"
      ) then
    local breedName =
        GetBreedName(
          item.petID,
          item.speciesID
        )

    item.breedOrder =
        GetBreedOrder(
          breedName
        )
  else
    item.breedOrder = 0
  end

  --------------------------------------------------
  -- Stats
  --
  -- Only call GetPetStats when one of these
  -- sort options actually needs the values.
  --------------------------------------------------
  local needsHealth =
      IsSortLevelSelected(
        "health"
      )

  local needsPower =
      IsSortLevelSelected(
        "power"
      )

  local needsSpeed =
      IsSortLevelSelected(
        "speed"
      )

  if needsHealth
      or needsPower
      or needsSpeed then
    local health,
    power,
    speed =
        GetPetStatsForSorting(
          item.petID
        )

    item.health = health
    item.power = power
    item.speed = speed
  else
    item.health = 0
    item.power = 0
    item.speed = 0
  end

  --------------------------------------------------
  -- Team usage
  --------------------------------------------------
  if IsSortLevelSelected(
        "teams"
      ) then
    item.isInTeam =
        IsPetInAnyTeam(
          item.petID,
          item.speciesID
        )
  else
    item.isInTeam = false
  end
end

local function CompareValues(a, b)
  if a == b then
    return 0
  end

  if a < b then
    return -1
  end

  return 1
end

local function CompareSortLevel(sortKey, a, b)
  if sortKey == "name" then
    return CompareValues(
      a.nameLower or "",
      b.nameLower or ""
    )
  end

  if sortKey == "level" then
    return CompareValues(
      b.level,
      a.level
    )
  end

  if sortKey == "rarity" then
    return CompareValues(
      b.rarity,
      a.rarity
    )
  end

  if sortKey == "type" then
    return CompareValues(
      a.petType,
      b.petType
    )
  end

  if sortKey == "expansion" then
    return CompareValues(
      b.expansionOrder,
      a.expansionOrder
    )
  end

  if sortKey == "breed" then
    return CompareValues(
      a.breedOrder,
      b.breedOrder
    )
  end

  if sortKey == "health" then
    return CompareValues(
      b.health,
      a.health
    )
  end

  if sortKey == "power" then
    return CompareValues(
      b.power,
      a.power
    )
  end

  if sortKey == "speed" then
    return CompareValues(
      b.speed,
      a.speed
    )
  end

  if sortKey == "teams" then
    if a.isInTeam == b.isInTeam then
      return 0
    end

    return a.isInTeam
        and -1
        or 1
  end

  return 0
end

local function SortItems(items)
  for _, item in ipairs(items) do
    PopulateSortData(item)
  end

  table.sort(
    items,

    function(a, b)
      ------------------------------------------------
      -- Collected pets always before uncollected.
      --
      -- Reverse Sort does NOT change this.
      ------------------------------------------------
      if a.isOwned ~= b.isOwned then
        return a.isOwned == true
      end

      ------------------------------------------------
      -- Favorites first
      ------------------------------------------------
      if SortOptions.favoritesFirst
          and a.isFavorite
          ~= b.isFavorite then
        return a.isFavorite == true
      end

      ------------------------------------------------
      -- Level 1 -> 2 -> 3
      ------------------------------------------------
      for _, sortKey in ipairs(
        SortLevels
      ) do
        local comparison =
            CompareSortLevel(
              sortKey,
              a,
              b
            )

        if comparison ~= 0 then
          if SortOptions.reverse then
            comparison = -comparison
          end

          return comparison < 0
        end
      end

      ------------------------------------------------
      -- Name fallback
      ------------------------------------------------
      local comparison =
          CompareValues(
            a.nameLower or "",
            b.nameLower or ""
          )

      if SortOptions.reverse then
        comparison = -comparison
      end

      if comparison ~= 0 then
        return comparison < 0
      end

      ------------------------------------------------
      -- Final deterministic fallback
      ------------------------------------------------
      return tostring(
        a.petID
        or a.speciesID
        or a.index
        or ""
      ) < tostring(
        b.petID
        or b.speciesID
        or b.index
        or ""
      )
    end
  )
end

local function CreateUnifiedSortMenu(root)
  local submenu = root:CreateButton(RAID_FRAME_SORT_LABEL)

  for _, option in ipairs(ALL_SORT_OPTIONS) do
    local sortKey = option.key
    local sortLabel = option.label

    local button =
        submenu:CreateCheckbox(
          sortLabel,

          function()
            return IsSortLevelSelected(
              sortKey
            )
          end,

          function()
            ToggleSortLevel(
              sortKey
            )

            return MenuResponse.Refresh
          end
        )

    button:AddInitializer(
      function(frame)
        local index =
            GetSortLevelIndex(
              sortKey
            )

        ------------------------------------------------
        -- Dynamic label
        ------------------------------------------------

        if frame.fontString then
          frame.fontString:SetText(
            index
            and string.format(
              "%d. %s",
              index,
              sortLabel
            )
            or sortLabel
          )
        end

        ------------------------------------------------
        -- Disable other options at max 3
        ------------------------------------------------

        frame:SetEnabled(
          index ~= nil
          or #SortLevels
          < MAX_SORT_LEVELS
        )
      end
    )
  end

  --------------------------------------------------
  -- Modifiers
  --------------------------------------------------
  submenu:CreateDivider()

  submenu:CreateCheckbox(
    "Favorites First",

    function()
      return SortOptions.favoritesFirst == true
    end,

    function()
      SortOptions.favoritesFirst = not SortOptions.favoritesFirst
      RefreshSorting()
      return MenuResponse.Refresh
    end
  )

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
    "Reverse Sort",

    function()
      return SortOptions.reverse == true
    end,

    function()
      SortOptions.reverse = not SortOptions.reverse
      RefreshSorting()
      return MenuResponse.Refresh
    end
  )

  --------------------------------------------------
  -- Reset
  --------------------------------------------------
  submenu:CreateDivider()

  local resetButton = submenu:CreateButton(RESET)

  resetButton:SetResponder(
    function()
      wipe(SortLevels)
      SortOptions.favoritesFirst = true
      SortOptions.reverse = false

      C_PetJournal.SetPetSortParameter(LE_SORT_BY_NAME)
      RefreshSorting()
      return MenuResponse.Refresh
    end
  )
end

local function AcquireItem()
  local item =
      table.remove(
        ItemPool
      )

  if not item then
    item = {}
  end

  return item
end

local function ReleaseItemList(
    list
)
  for index = 1, #list do
    local item =
        list[index]

    wipe(item)

    ItemPool[
    #ItemPool + 1
    ] =
        item

    list[index] = nil
  end
end

function FilterExtension:RequestRefresh()
  refreshRequired = true

  if type(PetJournal_UpdatePetList)
      ~= "function" then
    return
  end

  PetJournal_UpdatePetList()
end

function FilterExtension:SetupFilterDropdown()
  if not PetJournal or not PetJournal.FilterDropdown then
    return
  end

  local dropdown = PetJournal.FilterDropdown

  dropdown:SetWidth(90)

  dropdown:SetIsDefaultCallback(
    function()
      return true
    end
  )

  dropdown:SetDefaultCallback(
    function()
      FilterExtension:ResetAllFilters()
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

      CreateTagMenu(
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

  if HasCustomFilter(
        Filters.tags,
        TAG_FILTER_OPTIONS
      ) then
    names[#names + 1] =
    "Tag"
  end

  if HasOtherFilters() then
    names[#names + 1] = "Other"
  end

  if AdvancedSearch
      and type(AdvancedSearch.filters) == "table"
      and #AdvancedSearch.filters > 0 then
    names[#names + 1] = "Search"
  end

  local typeFilter = addon.Services.PetTypeFilter

  if typeFilter then
    local mode = typeFilter:GetMode()
    local selectedTypes = typeFilter:GetSelectedTypes(mode)

    if selectedTypes and next(selectedTypes) ~= nil then
      local modeLabels = {
        petType = "Pet Type",
        strongVs = "Strong Vs",
        weakVs = "Weak Vs",
        takesMoreFrom = "Takes More From",
        takesLessFrom = "Takes Less From",
      }

      names[#names + 1] = modeLabels[mode] or "Pet Type"
    end

    if typeFilter:IsLevel25Only() then
      names[#names + 1] = "Level 25"
    end
  end

  return names
end

local function GetSortLabel(sortKey)
  for _, option in ipairs(ALL_SORT_OPTIONS) do
    if option.key == sortKey then
      return option.label
    end
  end

  return sortKey
end

function FilterExtension:GetActiveSortNames()
  local names = {}

  for index, sortKey in ipairs(SortLevels) do
    names[#names + 1] =
        string.format(
          "%d. %s",
          index,
          GetSortLabel(sortKey)
        )
  end

  if SortOptions.reverse then
    names[#names + 1] = "Reverse"
  end

  return names
end

function FilterExtension:LayoutPetList(filterBarShown)
  if not PetJournal
      or not PetJournal.ScrollBox
      or not PetJournal.LeftInset then
    return
  end

  if currentFilterBarShown == filterBarShown then
    return
  end

  currentFilterBarShown = filterBarShown

  local scrollBox = PetJournal.ScrollBox

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

function FilterExtension:CreatePetTypeFilterBar()
  if self.PetTypeFilterBar
      or not PetJournal
      or not PetJournal.LeftInset then
    return
  end

  local component = addon.UI.Components.PetTypeFilterBar

  if not component then
    addon.Logger:Warn(
      "PetTypeFilterBar component is unavailable"
    )
    return
  end

  local bar = component:Create(PetJournal.LeftInset)

  if not bar then
    return
  end

  local frame = bar:GetFrame()

  frame:ClearAllPoints()

  frame:SetPoint(
    "TOPLEFT",
    PetJournal.LeftInset,
    "TOPLEFT",
    2,
    TYPE_FILTER_BAR_TOP_OFFSET
  )

  frame:SetPoint(
    "TOPRIGHT",
    PetJournal.LeftInset,
    "TOPRIGHT",
    -2,
    TYPE_FILTER_BAR_TOP_OFFSET
  )

  frame:SetHeight(
    TYPE_FILTER_BAR_HEIGHT
  )

  frame:SetFrameStrata(
    PetJournal.LeftInset:
    GetFrameStrata()
  )

  frame:SetFrameLevel(
    PetJournal.ScrollBox:
    GetFrameLevel()
    + 20
  )

  frame:Show()

  self.PetTypeFilterBar = bar
end

function FilterExtension:CreateFilterBar()
  if self.FilterBar or not PetJournal
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
    3,
    FILTER_BAR_TOP_OFFSET + 5
  )

  bar:SetPoint(
    "TOPRIGHT",
    PetJournal.LeftInset,
    "TOPRIGHT",
    -3,
    FILTER_BAR_TOP_OFFSET + 5
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
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",

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

function FilterExtension:UpdateFilterBar(visiblePetCount)
  self:CreateFilterBar()

  if not self.FilterBar then
    return
  end

  local activeFilters = self:GetActiveFilterNames()
  local activeSorts = self:GetActiveSortNames()

  if #activeFilters == 0 and #activeSorts == 0 then
    self.FilterBar:Hide()
    self:LayoutPetList(false)

    return
  end

  self.FilterBar.Count:SetFormattedText(
    "Pets: %d",
    tonumber(visiblePetCount) or 0
  )

  local parts = {}

  if #activeFilters > 0 then
    parts[#parts + 1] =
        "Filters: "
        .. table.concat(
          activeFilters,
          ", "
        )
  end

  if #activeSorts > 0 then
    parts[#parts + 1] =
        "Sort: "
        .. table.concat(
          activeSorts,
          ", "
        )
  end

  self.FilterBar.Filters:SetText(
    table.concat(
      parts,
      " | "
    )
  )

  self.FilterBar:Show()
  self:LayoutPetList(true)
end

function FilterExtension:ResetAllFilters()
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

  SetAll(
    Filters.tags,
    TAG_FILTER_OPTIONS,
    false
  )

  local typeFilter = addon.Services.PetTypeFilter

  if typeFilter then
    typeFilter:ClearAll()
  end

  if self.PetTypeFilterBar then
    self.PetTypeFilterBar:Refresh()
  end

  OtherFilters.leveling = nil
  OtherFilters.tradable = nil
  OtherFilters.battle = nil
  OtherFilters.team = nil

  SortOptions.favoritesFirst = true
  SortOptions.reverse = false

  wipe(SortLevels)

  C_PetJournal.SetPetSortParameter(
    LE_SORT_BY_NAME
  )

  SyncNativePetTypes()
  SyncNativeSources()

  RefreshSorting()

  if PetJournal
      and PetJournal.FilterDropdown
      and PetJournal.FilterDropdown.GenerateMenu then
    PetJournal.FilterDropdown:GenerateMenu()
  end

  self:Refresh()
end

function FilterExtension:Refresh()
  if not PetJournal
      or not PetJournal.ScrollBox then
    return
  end

  self:RequestRefresh()
end

function FilterExtension:MatchesPet(
    petID,
    speciesID,
    isOwned,
    level,
    petType,
    favorite,
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
  -- Tag
  --------------------------------------------------
  if HasSelection(
        Filters.tags,
        TAG_FILTER_OPTIONS
      ) then
    local tagValue =
        GetPetTagFilterValue(
          petID
        )

    if not MatchesFilter(
          Filters.tags,
          TAG_FILTER_OPTIONS,
          tagValue
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

  --------------------------------------------------
  -- Other: Duplicates
  --------------------------------------------------
  if OtherFilters.duplicates ~= nil then
    local hasDuplicate = isOwned == true and HasDuplicatePet(speciesID)

    if OtherFilters.duplicates == "duplicates" then
      if not hasDuplicate then
        return false
      end
    end

    if OtherFilters.duplicates == "noDuplicates" then
      if not isOwned or hasDuplicate then
        return false
      end
    end
  end

  --------------------------------------------------
  -- Advanced search
  --------------------------------------------------
  if not MatchesAdvancedSearch(
        petID,
        speciesID,
        isOwned,
        level,
        petType,
        favorite,
        canBattle,
        tradable
      ) then
    return false
  end


  return true
end

function FilterExtension:ApplyFilters()
  if not PetJournal or not PetJournal.ScrollBox then
    return
  end

  ReleaseItemList(BuildItems)

  local items = BuildItems
  local petCount = C_PetJournal.GetNumPets()
  local typeFilter = addon.Services.PetTypeFilter

  for index = 1, petCount do
    local petID,
    speciesID,
    isOwned,
    _customName,
    level,
    favorite,
    _isRevoked,
    name,
    _icon,
    petType,
    _creatureID,
    _sourceText,
    _description,
    _isHatchable,
    canBattle,
    tradable = C_PetJournal.GetPetInfoByIndex(index)

    local matchesPetMatchFilter =
        self:MatchesPet(
          petID,
          speciesID,
          isOwned,
          level,
          petType,
          favorite == true,
          canBattle == true,
          tradable == true
        )

    if matchesPetMatchFilter
        and typeFilter then
      matchesPetMatchFilter =
          typeFilter:DoesPetDataMatch(
            level,
            petType
          )
    end

    if matchesPetMatchFilter then
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

      local item = AcquireItem()

      item.index = index
      item.petID = petID
      item.speciesID = speciesID
      item.name = tostring(name or "")
      item.nameLower = string.lower(item.name)
      item.isOwned = isOwned == true
      item.level = tonumber(level) or 0
      item.rarity = tonumber(rarity) or 0
      item.petType = tonumber(petType) or 0

      items[#items + 1] = item
    end
  end

  --------------------------------------------------
  -- Populate extra sort data and sort
  --------------------------------------------------
  SortItems(items)

  --------------------------------------------------
  -- Build a fresh provider using the new buffer
  --------------------------------------------------
  local dataProvider = CreateDataProvider()

  for _, item in ipairs(items) do
    dataProvider:Insert(item)
  end

  --------------------------------------------------
  -- Install the new provider first.
  --
  -- Only after this point is the old provider no
  -- longer the active one for the ScrollBox.
  --------------------------------------------------
  PetJournal.ScrollBox:
      SetDataProvider(
        dataProvider,
        ScrollBoxConstants.RetainScrollPosition
      )

  --------------------------------------------------
  -- The old active item buffer can now be recycled
  --------------------------------------------------
  ReleaseItemList(ActiveItems)

  --------------------------------------------------
  -- Swap buffers
  --
  -- ActiveItems = what the current provider uses
  -- BuildItems  = empty buffer for next refresh
  --------------------------------------------------
  ActiveItems, BuildItems = BuildItems, ActiveItems

  --------------------------------------------------
  -- Update filter bar
  --------------------------------------------------
  self:UpdateFilterBar(#ActiveItems)
end

function FilterExtension:HookPetJournal()
  if self.PetJournalHooked then
    return
  end

  if type(PetJournal_UpdatePetList) ~= "function" then
    return
  end

  self.PetJournalHooked = true

  hooksecurefunc(
    "PetJournal_UpdatePetList",

    function()
      QueueImmediateApplyFilters()
    end
  )
end

function FilterExtension:HookSearchBox()
  if self.SearchHooked then
    return
  end

  if not PetJournal or not PetJournal.searchBox then
    return
  end

  self.SearchHooked = true

  local searchBox = PetJournal.searchBox

  searchBox:SetScript(
    "OnTextChanged",
    function(self)
      SearchBoxTemplate_OnTextChanged(self)

      local text = self:GetText() or ""
      local parsed = ParseAdvancedSearch(text)

      AdvancedSearch = parsed

      local nativeText = parsed.nativeText or ""

      if nativeText ~= LastNativeSearchText then
        LastNativeSearchText = nativeText
        C_PetJournal.SetSearchFilter(nativeText)
      else
        --------------------------------------------------
        -- Native Blizzard search did not change.
        -- Only our advanced filters changed.
        --------------------------------------------------
        QueueImmediateApplyFilters()
      end
    end
  )
end

function FilterExtension:Initialize()
  InitializeFilters()

  wipe(SortLevels)
  C_PetJournal.SetPetSortParameter(LE_SORT_BY_NAME)

  self.EventFrame = CreateFrame("Frame")
  self.EventFrame:RegisterEvent("ADDON_LOADED")
  self.EventFrame:RegisterEvent("PET_JOURNAL_LIST_UPDATE")

  self.EventFrame:SetScript(
    "OnEvent",

    function(_, event, loadedAddon)
      if event == "ADDON_LOADED" then
        if loadedAddon == "Blizzard_Collections" then
          FilterExtension:SetupFilterDropdown()
          FilterExtension:HookPetJournal()
          FilterExtension:HookSearchBox()
          FilterExtension:CreatePetTypeFilterBar()
          FilterExtension:CreateFilterBar()
          FilterExtension:HideBlizzardResetButton()
          SyncNativeFilters()
        end
      elseif event == "PET_JOURNAL_LIST_UPDATE" then
        FilterExtension:HookPetJournal()
        FilterExtension:HookSearchBox()
        QueueApplyFilters()
      end
    end
  )

  addon.EventBus:Register(
    addon.Events.PET_TYPE_FILTER_CHANGED,
    function()
      CancelQueuedApplyFilters()
      FilterExtension:ApplyFilters()

      if FilterExtension.PetTypeFilterBar then
        FilterExtension.PetTypeFilterBar:Refresh()
      end
    end
  )

  self:HookPetJournal()
  self:SetupFilterDropdown()
  self:HookSearchBox()
  self:CreatePetTypeFilterBar()
  self:CreateFilterBar()
  self:HideBlizzardResetButton()

  if PetJournal and PetJournal.FilterDropdown then
    SyncNativeFilters()
  end
end

addon.PetJournalFilterExtension = FilterExtension
addon.ModuleManager:Register(
  "FilterExtension",
  FilterExtension
)
