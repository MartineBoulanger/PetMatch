local _, addon = ...

local L = addon.L

addon.Constants = {
  ADDON_NAME = "PetMatch",
  VERSION = "0.1.0",
  DATABASE_VERSION = 1,
  CHAT_PREFIX = "|cff00ccff[PetMatch]|r",

  -- pet breed variables
  BREEDS_FOR_FILTERS = {
    "B/B",
    "P/P",
    "S/S",
    "H/H",
    "H/P",
    "P/S",
    "H/S",
    "P/B",
    "S/B",
    "H/B",
  },
  BREED_NAME_TO_ID = {
    ["B/B"] = 3,
    ["P/P"] = 4,
    ["S/S"] = 5,
    ["H/H"] = 6,
    ["H/P"] = 7,
    ["P/S"] = 8,
    ["H/S"] = 9,
    ["P/B"] = 10,
    ["S/B"] = 11,
    ["H/B"] = 12,
  },
  PET_BREED_NAMES = {
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
  },
  PET_BREED_COLORS = {
    [3] = { r = 1.000, g = 0.627, b = 0.478 },  -- B/B #FFA07A
    [4] = { r = 0.306, g = 0.804, b = 0.769 },  -- P/P #4ECDC4
    [5] = { r = 1.000, g = 0.420, b = 0.420 },  -- S/S #FF6B6B
    [6] = { r = 0.271, g = 0.718, b = 0.820 },  -- H/H #45B7D1
    [7] = { r = 0.729, g = 0.408, b = 0.784 },  -- H/P #BA68C8
    [8] = { r = 0.596, g = 0.847, b = 0.784 },  -- P/S #98D8C8
    [9] = { r = 0.392, g = 0.710, b = 0.965 },  -- H/S #64B5F6
    [10] = { r = 0.506, g = 0.780, b = 0.518 }, -- P/B #81C784
    [11] = { r = 0.941, g = 0.384, b = 0.573 }, -- S/B #F06292
    [12] = { r = 1.000, g = 0.835, b = 0.310 }, -- H/B #FFD54F
  },

  -- pet rarity variables
  PET_RARITY_COLORS = {
    [1] = ITEM_QUALITY_COLORS[0], -- poor
    [2] = ITEM_QUALITY_COLORS[1], -- common
    [3] = ITEM_QUALITY_COLORS[2], -- uncommon
    [4] = ITEM_QUALITY_COLORS[3], -- rare
    [5] = ITEM_QUALITY_COLORS[4], -- epic
    [6] = ITEM_QUALITY_COLORS[5], -- legendary
  },
  PET_RARITY_NAMES = {
    [1] = L["POOR"],
    [2] = L["COMMON"],
    [3] = L["UNCOMMON"],
    [4] = L["RARE"],
  },

  -- pet type variables
  PET_FAMILY_ICONS = {
    [1]  = "Interface\\Icons\\Pet_Type_Humanoid",
    [2]  = "Interface\\Icons\\Pet_Type_Dragon",
    [3]  = "Interface\\Icons\\Pet_Type_Flying",
    [4]  = "Interface\\Icons\\Pet_Type_Undead",
    [5]  = "Interface\\Icons\\Pet_Type_Critter",
    [6]  = "Interface\\Icons\\Pet_Type_Magical",
    [7]  = "Interface\\Icons\\Pet_Type_Elemental",
    [8]  = "Interface\\Icons\\Pet_Type_Beast",
    [9]  = "Interface\\Icons\\Pet_Type_Water",
    [10] = "Interface\\Icons\\Pet_Type_Mechanical",
  },
  PET_FAMILY_COLORS = {
    [1] = { r = 0.067, g = 0.655, b = 0.961 },  -- Humanoid   #11a7f5
    [2] = { r = 0.267, g = 0.647, b = 0.067 },  -- Dragonkin  #44a511
    [3] = { r = 0.867, g = 0.812, b = 0.325 },  -- Flying     #ddcf53
    [4] = { r = 0.659, g = 0.463, b = 0.482 },  -- Undead     #a8767b
    [5] = { r = 0.475, g = 0.341, b = 0.271 },  -- Critter    #795745
    [6] = { r = 0.698, g = 0.471, b = 1.000 },  -- Magic      #b278ff
    [7] = { r = 0.996, g = 0.808, b = 0.008 },  -- Elemental  #fece02
    [8] = { r = 0.918, g = 0.176, b = 0.129 },  -- Beast      #ea2d21
    [9] = { r = 0.067, g = 0.647, b = 0.710 },  -- Aquatic    #11a5b5
    [10] = { r = 0.467, g = 0.455, b = 0.400 }, -- Mechanical #777466
  },
  PET_FAMILY_NAMES = {
    [1] = _G.BATTLE_PET_NAME_1 or L["FAM_HUM"],
    [2] = _G.BATTLE_PET_NAME_2 or L["FAM_DRA"],
    [3] = _G.BATTLE_PET_NAME_3 or L["FAM_FLY"],
    [4] = _G.BATTLE_PET_NAME_4 or L["FAM_UND"],
    [5] = _G.BATTLE_PET_NAME_5 or L["FAM_CRI"],
    [6] = _G.BATTLE_PET_NAME_6 or L["FAM_MAG"],
    [7] = _G.BATTLE_PET_NAME_7 or L["FAM_ELE"],
    [8] = _G.BATTLE_PET_NAME_8 or L["FAM_BEA"],
    [9] = _G.BATTLE_PET_NAME_9 or L["FAM_AQU"],
    [10] = _G.BATTLE_PET_NAME_10 or L["FAM_MEC"],
  },

  -- pet sources variables
  PET_SOURCE_ICONS = {
    [1] = "Interface\\Icons\\INV_Misc_Bag_10",                -- Drop
    [2] = "Interface\\GossipFrame\\AvailableQuestIcon",       -- Quest
    [3] = "Interface\\Icons\\INV_Misc_Coin_01",               -- Vendor
    [4] = "Interface\\Icons\\Trade_Engineering",              -- Profession
    [5] = "Interface\\Icons\\Tracking_Wildpet",               -- Pet Battle
    [6] = "Interface\\Icons\\Achievement_General",            -- Achievement
    [7] = "Interface\\Icons\\INV_Thanksgiving_Turkey_act",    -- World Event
    [8] = "Interface\\Icons\\UI_Shop_BCV",                    -- Promotion
    [9] = "Interface\\Icons\\INV_Misc_Ticket_Tarot_Stack_01", -- Trading Card Game
    [10] = "Interface\\Icons\\WoW_Token01",                   -- In-Game Shop
    [11] = "Interface\\Icons\\INV_Box_PetCarrier_01",         -- Discovery
    [12] = "Interface\\Icons\\TradingPostCurrency",           -- Trading Post
  },
  PET_SOURCE_COLORS = {
    [1] = { r = 0.506, g = 0.780, b = 0.518 },  -- #81C784
    [2] = { r = 0.647, g = 0.427, b = 0.992 },  -- #a56dfd
    [3] = { r = 1.000, g = 0.502, b = 0.259 },  -- #FF8042
    [4] = { r = 0.306, g = 0.804, b = 0.769 },  -- #4ECDC4
    [5] = { r = 1.000, g = 0.627, b = 0.478 },  -- #FFA07A
    [6] = { r = 1.000, g = 0.835, b = 0.310 },  -- #FFD54F
    [7] = { r = 0.941, g = 0.384, b = 0.573 },  -- #F06292
    [8] = { r = 0.063, g = 0.671, b = 0.698 },  -- #10abb2
    [9] = { r = 0.875, g = 0.812, b = 0.357 },  -- #dfcf5b
    [10] = { r = 0.176, g = 0.576, b = 0.094 }, -- #2d9318
    [11] = { r = 0.067, g = 0.655, b = 0.965 }, -- #11a7f6
    [12] = { r = 1.000, g = 0.420, b = 0.420 }, -- #FF6B6B
  },

  -- pet expansion variables
  PET_EXPANSION_ICONS = {
    [0] = "Interface\\Glues\\Common\\Glues-Wow-Logo",                 -- Classic
    [1] = "Interface\\Glues\\Common\\Glues-Wow-BcLogo",               -- TBC
    [2] = "Interface\\Glues\\Common\\Glues-Wow-WotlkLogo",            -- WotLK
    [3] = "Interface\\Glues\\Common\\Glues-Wow-CcLogo",               -- Cata
    [4] = "Interface\\Glues\\Common\\Glues-Wow-MpLogo",               -- MoP
    [5] = "Interface\\Glues\\Common\\Glues-Wow-WodLogo",              -- WoD
    [6] = "Interface\\Glues\\Common\\Glues-Wow-LegionLogo",           -- Legion
    [7] = "Interface\\Glues\\Common\\Glues-Wow-BattleForAzerothLogo", -- BfA
    [8] = "Interface\\Glues\\Common\\Glues-Wow-ShadowlandsLogo",      -- SL
    [9] = "Interface\\Glues\\Common\\Glues-Wow-DragonFlightLogo",     -- DF
    [10] = "Interface\\Glues\\Common\\Glues-Wow-TheWarWithinLogo",    -- TWW
    [11] = "Interface\\Glues\\Common\\Glues-Wow-MidnightLogo",        -- Midnight
  },
  PET_EXPANSION_COLORS = {
    [0] = { r = 0.839, g = 0.671, b = 0.490 },  -- Classic  #D6AB7D
    [1] = { r = 0.894, g = 0.243, b = 0.353 },  -- TBC      #E43E5A
    [2] = { r = 0.247, g = 0.780, b = 0.922 },  -- WotLK    #3FC7EB
    [3] = { r = 1.000, g = 0.486, b = 0.039 },  -- Cata     #FF7C0A
    [4] = { r = 0.000, g = 0.937, b = 0.533 },  -- MoP      #00EF88
    [5] = { r = 0.957, g = 0.549, b = 0.729 },  -- WoD      #F48CBA
    [6] = { r = 0.667, g = 0.827, b = 0.447 },  -- Legion   #AAD372
    [7] = { r = 1.000, g = 0.957, b = 0.408 },  -- BfA      #FFF468
    [8] = { r = 0.592, g = 0.596, b = 0.996 },  -- SL       #9798FE
    [9] = { r = 0.325, g = 0.702, b = 0.624 },  -- DF       #53B39F
    [10] = { r = 0.565, g = 0.800, b = 0.867 }, -- TWW      #90CCDD
    [11] = { r = 0.427, g = 0.247, b = 0.753 }, -- Midnight #6D3FC0
  },
  EXPANSION_NAMES = {
    EXPANSION_NAME0,
    EXPANSION_NAME1,
    EXPANSION_NAME2,
    EXPANSION_NAME3,
    EXPANSION_NAME4,
    EXPANSION_NAME5,
    EXPANSION_NAME6,
    EXPANSION_NAME7,
    EXPANSION_NAME8,
    EXPANSION_NAME9,
    EXPANSION_NAME10,
    EXPANSION_NAME11,
  },

  -- sorting and filtering
  SORT_LABELS = {
    name = L["NAME"],
    modified = L["RECENT"],
    favorites = L["FAVORITES"],
  },
}

addon.Events = {
  DATABASE_READY = "DATABASE_READY",
  PROFILE_CHANGED = "PROFILE_CHANGED",
  SETTINGS_CHANGED = "SETTINGS_CHANGED",

  TAG_CREATED = "TAG_CREATED",
  TAG_UPDATED = "TAG_UPDATED",
  TAG_DELETED = "TAG_DELETED",
  TEAM_TAGS_CHANGED = "TEAM_TAGS_CHANGED",

  TEAM_LOADED = "TEAM_LOADED",
  TEAM_CREATED = "TEAM_CREATED",
  TEAM_UPDATED = "TEAM_UPDATED",
  TEAM_DELETED = "TEAM_DELETED",
  TEAM_SELECTED = "TEAM_SELECTED",
  TEAM_IMPORTED = "TEAM_IMPORTED",
  TEAMS_CHANGED = "TEAMS_CHANGED",
  TEAM_SETUP_CHANGED = "TEAM_SETUP_CHANGED",
  TEAM_SETUP_SLOT_CHANGED = "TEAM_SETUP_SLOT_CHANGED",
  TEAM_SETUP_TARGET_CHANGED = "TEAM_SETUP_TARGET_CHANGED",

  SEARCH_CHANGED = "SEARCH_CHANGED",
  TEAM_SORT_CHANGED = "TEAM_SORT_CHANGED",
  TEAM_FAVORITE_CHANGED = "TEAM_FAVORITE_CHANGED",
  CURRENT_TEAM_DIRTY_CHANGED = "CURRENT_TEAM_DIRTY_CHANGED",
  PET_TYPE_FILTER_CHANGED = "PET_TYPE_FILTER_CHANGED",

  PET_SELECTED = "PET_SELECTED",
  PET_JOURNAL_UPDATED = "PET_JOURNAL_UPDATED",
  PET_ADDED_TO_TEAM = "PET_ADDED_TO_TEAM",
  PET_REMOVED_FROM_TEAM = "PET_REMOVED_FROM_TEAM",

  LEVELLING_QUEUE_CHANGED = "LEVELLING_QUEUE_CHANGED",
  LEVELLING_QUEUE_PET_ADDED = "LEVELLING_QUEUE_PET_ADDED",
  LEVELLING_QUEUE_PET_REMOVED = "LEVELLING_QUEUE_PET_REMOVED",
  LEVELLING_QUEUE_ORDER_CHANGED = "LEVELLING_QUEUE_ORDER_CHANGED",
  PET_BATTLE_LEVEL_CHANGED = "PET_BATTLE_LEVEL_CHANGED",

  PET_BATTLE_STARTED = "PET_BATTLE_STARTED",
  PET_BATTLE_ENDED = "PET_BATTLE_ENDED",

  FOLDER_CREATED = "FOLDER_CREATED",
  FOLDER_UPDATED = "FOLDER_UPDATED",
  FOLDER_DELETED = "FOLDER_DELETED",
  FOLDER_SELECTED = "FOLDER_SELECTED",
}
