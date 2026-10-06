local _, addon = ...

local PetBattleTargetService = {}

local HEADER_ID = 1
local NPC_ID = 2
local MAP_ID = 3
local EXPANSION_ID = 4
local QUEST_ID = 5
local FIRST_PET = 6
local LAST_PET = 8

PetBattleTargetService.ByNPCID = {}
PetBattleTargetService.NameCache = {}
PetBattleTargetService.PetNameCache = {}

function PetBattleTargetService:Initialize()
  wipe(self.ByNPCID)

  for _, target in ipairs(addon.Data.PetBattleTargets) do
    local npcID = target[NPC_ID]

    if npcID then
      self.ByNPCID[npcID] = target
    end
  end
end

function PetBattleTargetService:GetTargets()
  return addon.Data.PetBattleTargets
end

function PetBattleTargetService:GetHeaderID(target)
  return target and target[HEADER_ID]
end

function PetBattleTargetService:GetNPCID(target)
  return target and target[NPC_ID]
end

function PetBattleTargetService:GetMapID(target)
  return target and target[MAP_ID]
end

function PetBattleTargetService:GetExpansionID(target)
  return target and target[EXPANSION_ID]
end

function PetBattleTargetService:GetQuestID(target)
  return target and target[QUEST_ID]
end

function PetBattleTargetService:GetPets(target)
  if type(target) ~= "table" then
    return {}
  end

  local pets = {}

  for index = FIRST_PET, LAST_PET do
    local pet = self:ParsePet(target[index])

    if pet then
      pets[#pets + 1] = pet
    end
  end

  return pets
end

function PetBattleTargetService:ResolveNPCID(npcID)
  npcID = tonumber(npcID)

  if not npcID then
    return nil
  end

  local redirects = addon.Data.PetBattleTargetRedirects

  return redirects[npcID] or npcID
end

function PetBattleTargetService:GetByNPCID(npcID)
  npcID = self:ResolveNPCID(npcID)

  if not npcID then
    return nil
  end

  return self.ByNPCID[npcID]
end

function PetBattleTargetService:ParsePet(petData)
  if type(petData) == "number" then
    return { speciesID = petData }
  end

  if type(petData) ~= "string" then
    return nil
  end

  local speciesID, level, rarity, health, power, speed =
      petData:match(
        "^battlepet:(%d+):(%d+):(%d+):(%d+):(%d+):(%d+)$"
      )

  speciesID = tonumber(speciesID)

  if not speciesID then
    return nil
  end

  return {
    speciesID = speciesID,
    level = tonumber(level),
    rarity = tonumber(rarity),
    health = tonumber(health),
    power = tonumber(power),
    speed = tonumber(speed),
  }
end

function PetBattleTargetService:GetName(npcID)
  npcID = tonumber(npcID)

  if not npcID then
    return nil
  end

  if self.NameCache[npcID] then
    return self.NameCache[npcID]
  end

  local hyperlink =
      string.format(
        "unit:Creature-0-0-0-0-%d-0000000000",
        npcID
      )

  local data = C_TooltipInfo.GetHyperlink(hyperlink)

  if not data or not data.lines then
    return nil
  end

  for _, line in ipairs(data.lines) do
    if line.type == Enum.TooltipDataLineType.UnitName
        and line.leftText and line.leftText ~= "" then
      self.NameCache[npcID] = line.leftText

      return line.leftText
    end
  end

  return nil
end

function PetBattleTargetService:GetPetIcon(speciesID)
  speciesID = tonumber(speciesID)

  if not speciesID then
    return nil
  end

  local _, icon = C_PetJournal.GetPetInfoBySpeciesID(speciesID)

  return icon
end

function PetBattleTargetService:GetTargetsByExpansion()
  local groups = {}

  for _, target in ipairs(addon.Data.PetBattleTargets) do
    local expansionID = self:GetExpansionID(target)

    if expansionID ~= nil then
      groups[expansionID] = groups[expansionID] or {}
      groups[expansionID][#groups[expansionID] + 1] = target
    end
  end

  return groups
end

function PetBattleTargetService:GetTargetsForExpansion(expansionID)
  expansionID = tonumber(expansionID)

  if expansionID == nil then
    return {}
  end

  local groups = self:GetTargetsByExpansion()

  return groups[expansionID] or {}
end

function PetBattleTargetService:GetExpansionName(expansionID)
  expansionID = tonumber(expansionID)

  if expansionID == nil then
    return nil
  end

  local globalName = _G["EXPANSION_NAME" .. expansionID]

  if globalName and globalName ~= "" then
    return globalName
  end

  return tostring(expansionID)
end

function PetBattleTargetService:GetTargetsByMap(targets)
  local groups = {}

  if type(targets) ~= "table" then
    return groups
  end

  for _, target in ipairs(targets) do
    local mapID = self:GetMapID(target)

    if mapID then
      groups[mapID] = groups[mapID] or {}
      groups[mapID][#groups[mapID] + 1] = target
    end
  end

  return groups
end

function PetBattleTargetService:GetMapName(mapID)
  mapID = tonumber(mapID)

  if not mapID then
    return nil
  end

  local mapInfo = C_Map.GetMapInfo(mapID)

  if mapInfo and mapInfo.name
      and mapInfo.name ~= "" then
    return mapInfo.name
  end

  return tostring(mapID)
end

function PetBattleTargetService:GetPetName(speciesID)
  speciesID = tonumber(speciesID)

  if not speciesID then
    return nil
  end

  if self.PetNameCache[speciesID] then
    return self.PetNameCache[speciesID]
  end

  local name = C_PetJournal.GetPetInfoBySpeciesID(speciesID)

  if name and name ~= "" then
    self.PetNameCache[speciesID] = name
    return name
  end

  return nil
end

function PetBattleTargetService:GetDisplayName(npcID)
  local name = self:GetName(npcID)

  if not name then
    return nil
  end

  local subnames = addon.Data.PetBattleTargetSubnames
  local subname = subnames and subnames[npcID]

  if subname and subname ~= "" then
    return string.format("%s (%s)", name, subname)
  end

  return name
end

function PetBattleTargetService:GetTargetDisplayName(target)
  if type(target) ~= "table" then
    return nil
  end

  local npcID = self:GetNPCID(target)
  local name = self:GetDisplayName(npcID)

  if not name then
    return nil
  end

  local pets = self:GetPets(target)

  local petNames = {}

  for _, pet in ipairs(pets) do
    local petName = self:GetPetName(pet.speciesID)

    if petName then
      petNames[#petNames + 1] = petName
    end
  end

  if #petNames == 1 and petNames[1] == name then
    return name
  end

  if #petNames > 0 then
    return string.format(
      "%s (%s)", name, table.concat(petNames, ", ")
    )
  end

  return name
end

addon.Services.PetBattleTarget = PetBattleTargetService
