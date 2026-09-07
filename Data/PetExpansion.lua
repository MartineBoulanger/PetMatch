local _, addon = ...

addon.Data = addon.Data or {}

local PetExpansion = {}

local EXPANSION_RANGES = {
  [0] = { 39, 128 },     -- Classic
  [1] = { 130, 186 },    -- TBC
  [2] = { 187, 258 },    -- WotLK
  [3] = { 259, 343 },    -- Cata
  [4] = { 346, 1365 },   -- MoP
  [5] = { 1384, 1693 },  -- WoD
  [6] = { 1699, 2163 },  -- Legion
  [7] = { 2165, 2872 },  -- BfA
  [8] = { 2878, 3247 },  -- SL
  [9] = { 3248, 4437 },  -- DF
  [10] = { 4450, 4862 }, -- TWW
  [11] = { 4874, 9999 }  -- Midnight
}

local EXPANSION_OUTLIERS = {
  [1563] = 0,
  [191] = 1,
  [1073] = 1,
  [1351] = 2,
  [220] = 3,
  [255] = 3,
  [231] = 4,
  [1386] = 4,
  [1943] = 4,
  [115] = 5,
  [1725] = 5,
  [1730] = 5,
  [1740] = 5,
  [1741] = 5,
  [1761] = 5,
  [1764] = 5,
  [1765] = 5,
  [1766] = 5,
  [1828] = 5,
  [382] = 6,
  [2143] = 7,
  [2157] = 7,
  [2622] = 8,
  [2780] = 8,
  [2798] = 8,
  [2890] = 9,
  [3175] = 9,
  [3177] = 9,
  [3188] = 9,
  [3236] = 9,
  [3242] = 9,
  [3243] = 9,
  [3244] = 9,
  [4436] = 9,
  [4437] = 9,
  [4548] = 9,
  [4565] = 9,
  [4566] = 9,
  [4579] = 9,
  [4580] = 9,
  [1751] = 10,
  [2541] = 10,
  [3245] = 10,
  [3361] = 10,
  [3362] = 10,
  [3518] = 10,
  [3525] = 10,
  [3543] = 10,
  [4264] = 10,
  [4900] = 10,
  [4901] = 10,
  [4903] = 10,
  [4907] = 10,
  [4908] = 10,
  [3277] = 11,
  [3364] = 11,
  [4497] = 11,
  [4790] = 11,
  [4795] = 11,
  [4803] = 11,
  [4811] = 11,
  [4812] = 11,
  [4816] = 11
}

local function FindExpansion(
    speciesID,
    expansionID
)
  local range =
      EXPANSION_RANGES[expansionID]

  if not range then
    return nil
  end

  local firstSpeciesID = range[1]
  local lastSpeciesID = range[2]

  if speciesID < firstSpeciesID then
    return FindExpansion(
      speciesID,
      expansionID - 1
    )
  end

  if speciesID > lastSpeciesID then
    return FindExpansion(
      speciesID,
      expansionID + 1
    )
  end

  return expansionID
end

function PetExpansion:GetExpansionID(
    speciesID
)
  speciesID = tonumber(speciesID)

  if not speciesID
      or speciesID <= 0 then
    return nil
  end

  local outlierExpansion =
      EXPANSION_OUTLIERS[speciesID]

  if outlierExpansion ~= nil then
    return outlierExpansion
  end

  return FindExpansion(
    speciesID,
    4
  )
end

function PetExpansion:GetExpansionNameByID(
    expansionID
)
  expansionID = tonumber(expansionID)

  if expansionID == nil then
    return nil
  end

  local name =
      _G[
      "EXPANSION_NAME"
      .. expansionID
      ]

  if type(name) ~= "string"
      or name == "" then
    return nil
  end

  return name
end

function PetExpansion:GetExpansionName(
    speciesID
)
  local expansionID =
      self:GetExpansionID(
        speciesID
      )

  if expansionID == nil then
    return nil
  end

  local expansionName =
      _G[
      "EXPANSION_NAME"
      .. expansionID
      ]

  if type(expansionName) ~= "string"
      or expansionName == "" then
    return nil
  end

  return expansionName
end

addon.Data.PetExpansion = PetExpansion
