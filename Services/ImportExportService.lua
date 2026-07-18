local addonName, addon = ...

local ImportExportService = {}

local PM_VERSION = "PM1"
local BASE32_ALPHABET = "0123456789ABCDEFGHIJKLMNOPQRSTUV"

local function Trim(value)
  return addon.Utils:Trim(value or "")
end

local function NormalizeNewlines(value)
  value = tostring(value or "")
  value = value:gsub("\r\n", "\n")
  value = value:gsub("\r", "\n")
  return value
end

local function SplitPreservingEmpty(value, separator)
  local result = {}
  local startIndex = 1

  while true do
    local separatorStart, separatorEnd =
        string.find(
          value,
          separator,
          startIndex,
          true
        )

    if not separatorStart then
      result[#result + 1] = string.sub(value, startIndex)
      break
    end

    result[#result + 1] =
        string.sub(
          value,
          startIndex,
          separatorStart - 1
        )

    startIndex = separatorEnd + 1
  end

  return result
end

local function DecodeBase32(value)
  value = string.upper(Trim(value))

  if value == "" then
    return nil
  end

  local result = 0

  for index = 1, #value do
    local character = value:sub(index, index)
    local position = BASE32_ALPHABET:find(character, 1, true)

    if not position then
      return nil
    end

    result = (result * 32) + (position - 1)
  end

  return result
end

local function ParseNPCIDs(value)
  local npcIDs = {}

  if not value or value == "" then
    return npcIDs
  end

  for encodedID in value:gmatch("[^,]+") do
    local npcID = DecodeBase32(encodedID)

    if npcID then
      npcIDs[#npcIDs + 1] =
          npcID
    end
  end

  return npcIDs
end

local function Escape(value)
  value = tostring(value or "")

  return value:gsub(
    "([^%w%-%._ ])",
    function(character)
      return string.format(
        "%%%02X",
        string.byte(character)
      )
    end
  ):gsub(" ", "%%20")
end

local function Unescape(value)
  value = tostring(value or "")

  return value:gsub(
    "%%(%x%x)",
    function(hex)
      return string.char(
        tonumber(hex, 16)
      )
    end
  )
end

local function Split(value, separator)
  local result = {}

  for part in string.gmatch(
    value,
    "([^" .. separator .. "]+)"
  ) do
    result[#result + 1] = part
  end

  return result
end

local function GetAbilityIDs(
    speciesID,
    choices
)
  local abilityIDs =
      C_PetJournal.GetPetAbilityList(
        speciesID
      )

  if type(abilityIDs) ~= "table" then
    return {}
  end

  local selectedAbilities = {}

  for abilitySlot = 1, 3 do
    local choice =
        tonumber(
          choices:sub(
            abilitySlot,
            abilitySlot
          )
        ) or 1

    if choice ~= 2 then
      choice = 1
    end

    local abilityIndex =
        abilitySlot
        + (
          choice == 2
          and 3
          or 0
        )

    selectedAbilities[abilitySlot] =
        abilityIDs[abilityIndex]
  end

  return selectedAbilities
end

local function IsLegacyGroupHeader(line)
  return line:match("^__%s*.-%s*__$") ~= nil
      and not line:find(":", 1, true)
end

local function GetLines(value)
  local lines = {}

  value = NormalizeNewlines(value)

  if value:sub(-1) ~= "\n" then
    value = value .. "\n"
  end

  for line in value:gmatch("(.-)\n") do
    lines[#lines + 1] = line
  end

  return lines
end

local function GetSpeciesID(petGUID)
  if not petGUID then
    return nil
  end

  local pet =
      addon.Services.PetJournal:GetPet(
        petGUID
      )

  return pet and pet.speciesID or nil
end

local function IsBlank(value)
  return addon.Utils:Trim(value or "") == ""
end

local function IsGroupHeader(line)
  return line:match("^__%s*.-%s*__$") ~= nil
end

local function StartsWith(value, prefix)
  return value:sub(1, #prefix) == prefix
end

function ImportExportService:ExportTeam(team)
  if not team then
    return nil, "Team not found"
  end

  local parts = {
    PM_VERSION,
    "name=" .. Escape(
      team.name or "Imported Team"
    ),
    "favorite="
    .. (
      team.favorite
      and "1"
      or "0"
    ),
  }

  if team.folderID then
    local folder =
        addon.Services.Folder:Get(
          team.folderID
        )

    if folder then
      parts[#parts + 1] =
          "folder="
          .. Escape(folder.name)
    end
  end

  for slot = 1, 3 do
    local speciesID =
        GetSpeciesID(
          team.pets
          and team.pets[slot]
        )

    local abilities =
        team.abilities
        and team.abilities[slot]
        or {}

    parts[#parts + 1] =
        string.format(
          "slot%d=%s,%s,%s,%s",
          slot,
          tostring(speciesID or 0),
          tostring(abilities[1] or 0),
          tostring(abilities[2] or 0),
          tostring(abilities[3] or 0)
        )
  end

  return table.concat(parts, "|")
end

function ImportExportService:ParsePetMatch(value)
  value = Trim(value)

  if value:sub(1, 4) ~= "PM1|" then
    return nil, "Not a PetMatch PM1 string"
  end

  local fields = Split(value, "|")

  local result = {
    format = "petmatch",
    name = "Imported Team",
    favorite = false,
    folderName = nil,
    slots = {},
  }

  for index = 2, #fields do
    local key, rawValue =
        fields[index]:match(
          "^([^=]+)=(.*)$"
        )

    if key then
      if key == "name" then
        result.name =
            Unescape(rawValue)
      elseif key == "folder" then
        result.folderName =
            Unescape(rawValue)
      elseif key == "favorite" then
        result.favorite =
            rawValue == "1"
      else
        local slot =
            tonumber(
              key:match("^slot([123])$")
            )

        if slot then
          local values =
              Split(rawValue, ",")

          result.slots[slot] = {
            speciesID =
                tonumber(values[1]),

            abilities = {
              tonumber(values[2]),
              tonumber(values[3]),
              tonumber(values[4]),
            },
          }
        end
      end
    end
  end

  return result
end

function ImportExportService:Parse(value)
  value = Trim(value)

  if value == "" then
    return nil, "Paste a team string"
  end

  if value:sub(1, 4) == "PM1|" then
    return self:ParsePetMatch(value)
  end

  if value:find("::", 1, true) then
    return self:ParseRematch(value)
  end

  return nil, "Unknown team format"
end

function ImportExportService:Import(value)
  value = Trim(value)

  local format = self:DetectFormat(value)

  if format == "rematch" then
    return self:ImportRematch(value)
  end

  if format == "petmatch" then
    if not self.ImportPetMatch then
      return nil,
          "PetMatch-import wordt nog niet ondersteund."
    end

    return self:ImportPetMatch(value)
  end

  return nil,
      "Het importformaat kon niet worden herkend."
end

function ImportExportService:GetAbilityIDsFromChoices(
    speciesID,
    choices
)
  local abilityIDs = C_PetJournal.GetPetAbilityList(speciesID)

  if type(abilityIDs) ~= "table" then
    return {}
  end

  local selected = {}

  for abilitySlot = 1, 3 do
    local choice = choices[abilitySlot] or 0

    if choice == 1 then
      selected[abilitySlot] = abilityIDs[abilitySlot]
    elseif choice == 2 then
      selected[abilitySlot] = abilityIDs[abilitySlot + 3]
    else
      -- 0 betekent dat Rematch geen voorkeur opslaat.
      selected[abilitySlot] = nil
    end
  end

  return selected
end

function ImportExportService:ImportRematchDocument(
    document,
    conflictMode
)
  conflictMode = conflictMode or "copy"

  local result = {
    teams = {},
    folders = {},
    warnings = {},
    failed = {},
  }

  for _, groupData in ipairs(document.groups or {}) do
    local folderID =
        addon.Services.Folder:GetSelectedStorageFolderID()

    if groupData.name then
      local folder =
          addon.Services.Folder:FindByName(
            groupData.name
          )

      if not folder then
        folder =
            addon.Services.Folder:Create(
              groupData.name
            )
      end

      if folder then
        folderID = folder.id
        result.folders[#result.folders + 1] = folder
      else
        result.warnings[#result.warnings + 1] =
            "Unable to create folder: "
            .. groupData.name
      end
    end

    for _, teamData in ipairs(groupData.teams or {}) do
      teamData.folderID = folderID

      local team, errorMessage, warnings =
          self:ImportRematchTeamData(
            teamData,
            conflictMode
          )

      if team then
        result.teams[#result.teams + 1] = team
      else
        result.failed[#result.failed + 1] = {
          name = teamData.name,
          error = errorMessage,
        }
      end

      for _, warning in ipairs(warnings or {}) do
        result.warnings[#result.warnings + 1] =
            warning
      end
    end
  end

  return result
end

function ImportExportService:DecodeRematchPetTag(token)
  token = string.upper(Trim(token))

  if token == "" then
    return nil, "Empty Rematch pet tag"
  end

  -- Speciale Rematch-slots.
  if token == "ZL" then
    return {
      type = "leveling",
      special = true,
      rawPetTag = token,
    }
  end

  if token == "ZI" then
    return {
      type = "ignored",
      special = true,
      rawPetTag = token,
    }
  end

  if token == "ZU" then
    return {
      type = "unknown",
      special = true,
      rawPetTag = token,
    }
  end

  local randomTypeCode = token:match("^ZR([0-9A-V])$")

  if randomTypeCode then
    return {
      type = "random",
      special = true,
      petType = DecodeBase32(randomTypeCode),
      rawPetTag = token,
    }
  end

  if token:sub(1, 1) == "Q" then
    if #token < 3 then
      return nil, "Invalid leveling queue tag: " .. token
    end

    local level = DecodeBase32(token:sub(2, 2))
    local rarity = DecodeBase32(token:sub(3, 3))

    if not level or not rarity then
      return nil, "Invalid leveling queue tag: " .. token
    end

    return {
      type = "levelingQueue",
      special = true,
      level = level,
      rarity = rarity,
      rawPetTag = token,
    }
  end

  if #token < 5 then
    return nil, "Invalid Rematch pet tag: " .. token
  end

  local choices = {
    DecodeBase32(token:sub(1, 1)),
    DecodeBase32(token:sub(2, 2)),
    DecodeBase32(token:sub(3, 3)),
  }

  for abilitySlot = 1, 3 do
    local choice = choices[abilitySlot]

    if choice ~= 0
        and choice ~= 1
        and choice ~= 2 then
      return nil,
          "Invalid Rematch ability choice"
    end
  end

  local breedID = DecodeBase32(token:sub(4, 4))
  local speciesID = DecodeBase32(token:sub(5))

  if not speciesID then
    return nil, "Invalid Rematch species code"
  end

  return {
    type = "pet",
    special = false,
    speciesID = speciesID,
    breedID = breedID or 0,
    abilityChoices = choices,
    abilities =
        self:GetAbilityIDsFromChoices(
          speciesID,
          choices
        ),
    rawPetTag = token,
  }
end

function ImportExportService:ParseRematchTeam(line)
  line = Trim(line)

  local fields = SplitPreservingEmpty(line, ":")

  if #fields < 6 then
    return nil, "Incomplete Rematch team string"
  end

  local name = Trim(fields[1])

  if name == "" then
    return nil, "Rematch team has no name"
  end

  local result = {
    format = "rematch",
    name = name,
    npcIDs = ParseNPCIDs(fields[2]),
    slots = {},
    preferences = nil,
    notes = "",
    warnings = {},
  }

  for slot = 1, 3 do
    local token = fields[slot + 2]

    if token and token ~= "" then
      local slotData, errorMessage =
          self:DecodeRematchPetTag(
            token
          )

      if slotData then
        result.slots[slot] = slotData
      else
        result.warnings[#result.warnings + 1] = errorMessage
      end
    end
  end

  local index = 6

  while index <= #fields do
    local marker = fields[index]

    if marker == "P" then
      result.preferences = {
        minHP = tonumber(fields[index + 1]),
        allowMM = tonumber(fields[index + 2]),
        expectedDD = tonumber(fields[index + 3]),
        minXP = tonumber(fields[index + 4]),
        maxXP = tonumber(fields[index + 5]),
      }

      index = index + 6
    elseif marker == "N" then
      local noteParts = {}

      for noteIndex = index + 1, #fields do
        noteParts[#noteParts + 1] = fields[noteIndex]
      end

      result.notes = table.concat(noteParts, ":"):gsub("\\n", "\n")

      break
    else
      index = index + 1
    end
  end

  return result
end

function ImportExportService:ParseRematchGroupHeader(line)
  local inner = Trim(line:match("^__%s*(.-)%s*__$"))

  if not inner or inner == "" then
    return nil, "Rematch group has no name"
  end

  if not inner:find(":", 1, true) then
    return {
      name = inner,
      teams = {},
    }
  end

  local fields = SplitPreservingEmpty(inner, ":")

  return {
    name = Trim(fields[1]),
    sort = tonumber(fields[2]),
    icon = fields[3] ~= "" and fields[3] or nil,
    color = fields[4] ~= "" and fields[4] or nil,
    teams = {},
  }
end

function ImportExportService:ParseRematchDocument(value)
  value = NormalizeNewlines(value)

  if IsBlank(value) then
    return nil, "Paste a Rematch team or group export"
  end

  local document = {
    format = "rematch",
    groups = {},
    warnings = {},
  }

  local ungrouped = {
    name = nil,
    teams = {},
  }

  local currentGroup = ungrouped

  for rawLine in value:gmatch("([^\n]*)\n?") do
    local line = addon.Utils:Trim(rawLine)

    if line ~= "" then
      if IsGroupHeader(line) then
        local group, errorMessage =
            self:ParseRematchGroupHeader(line)

        if not group then
          document.warnings[#document.warnings + 1] =
              errorMessage
        else
          document.groups[#document.groups + 1] =
              group

          currentGroup = group
        end
      else
        local team, errorMessage =
            self:ParseRematchTeam(line)

        if team then
          currentGroup.teams[#currentGroup.teams + 1] =
              team
        else
          document.warnings[#document.warnings + 1] =
              errorMessage
              or ("Unable to parse line: " .. line)
        end
      end
    end
  end

  if #ungrouped.teams > 0 then
    table.insert(document.groups, 1, ungrouped)
  end

  local teamCount = 0

  for _, group in ipairs(document.groups) do
    teamCount = teamCount + #group.teams
  end

  if teamCount == 0 then
    return nil, "No valid Rematch teams were found"
  end

  return document
end

function ImportExportService:ImportRematch(value)
  local document, errorMessage =
      self:ParseRematchDocument(value)

  if not document then
    return nil, errorMessage
  end

  local result = {
    teams = {},
    folders = {},
    missingSpecies = {},
    warnings = document.warnings or {},
  }

  for _, groupData in ipairs(document.groups) do
    local folderID =
        addon.Services.Folder:
        GetSelectedStorageFolderID()

    if groupData.name then
      local folder =
          addon.Services.Folder:
          FindByName(
            groupData.name
          )

      if not folder then
        folder =
            addon.Services.Folder:
            Create(
              groupData.name
            )
      end

      if folder then
        folderID = folder.id
        result.folders[#result.folders + 1] = folder
      end
    end

    for _, teamData in ipairs(
      groupData.teams
    ) do
      teamData.folderID = folderID

      local team,
      importError,
      missingSpecies = addon.Services.Team:CreateFromImport(teamData)

      if team then
        result.teams[#result.teams + 1] = team
      elseif importError then
        result.warnings[#result.warnings + 1] = importError
      end

      for _, speciesID in ipairs(
        missingSpecies or {}
      ) do
        result.missingSpecies[#result.missingSpecies + 1] = speciesID
      end
    end
  end

  return result
end

function ImportExportService:DetectFormat(value)
  value = Trim(value)

  if value == "" then
    return nil
  end

  if StartsWith(value, "PM1") then
    return "petmatch"
  end

  if value:match("^__%s*.-%s*__$") then
    return "rematch"
  end

  local firstLine =
      value:match("([^\r\n]+)")

  if firstLine then
    local fields =
        SplitPreservingEmpty(
          firstLine,
          ":"
        )

    if #fields >= 6 then
      return "rematch"
    end
  end

  return nil
end

addon.Services.ImportExport = ImportExportService
