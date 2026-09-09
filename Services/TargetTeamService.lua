local _, addon = ...

local TargetTeamService = {}

--------------------------------------------------
-- Normalize NPC ID
--------------------------------------------------
local function NormalizeNPCID(npcID)
  npcID = tonumber(npcID)

  if not npcID or npcID <= 0 then
    return nil
  end

  return math.floor(npcID)
end

--------------------------------------------------
-- Get NPC IDs assigned to a team
--------------------------------------------------
function TargetTeamService:GetTeamNPCIDs(team)
  if type(team) ~= "table"
      or type(team.targetNPCIDs) ~= "table" then
    return {}
  end

  return team.targetNPCIDs
end

--------------------------------------------------
-- Check whether a team belongs to an NPC
--------------------------------------------------
function TargetTeamService:TeamHasNPC(team, npcID)
  npcID = NormalizeNPCID(npcID)

  if not npcID then
    return false
  end

  local npcIDs = self:GetTeamNPCIDs(team)

  for _, teamNPCID in ipairs(npcIDs) do
    if NormalizeNPCID(teamNPCID) == npcID then
      return true
    end
  end

  return false
end

--------------------------------------------------
-- Get all teams assigned to an NPC
--------------------------------------------------
function TargetTeamService:GetTeamsForNPC(npcID)
  npcID = NormalizeNPCID(npcID)

  if not npcID then
    return {}
  end

  local teamService = addon.Services.Team

  if not teamService then
    return {}
  end

  local teams = teamService:GetAllTeams()

  if type(teams) ~= "table" then
    return {}
  end

  local result = {}

  for _, team in pairs(teams) do
    if self:TeamHasNPC(team, npcID) then
      result[#result + 1] = team
    end
  end

  table.sort(
    result,
    function(left, right)
      return string.lower(left.name or "")
          < string.lower(right.name or "")
    end
  )

  return result
end

--------------------------------------------------
-- Set NPC targets for a team
--------------------------------------------------
function TargetTeamService:SetTeamNPCIDs(teamID, npcIDs)
  local teamService = addon.Services.Team

  if not teamService then
    return nil, "The Team service is unavailable"
  end

  local team = teamService:Get(teamID)

  if not team then
    return nil, "Team not found"
  end

  local normalized = {}
  local seen = {}

  if type(npcIDs) == "table" then
    for _, npcID in ipairs(npcIDs) do
      npcID = NormalizeNPCID(npcID)

      if npcID and not seen[npcID] then
        normalized[#normalized + 1] = npcID
        seen[npcID] = true
      end
    end
  end

  team.targetNPCIDs = normalized
  team.modified = time()

  addon.EventBus:Fire(
    addon.Events.TEAM_UPDATED,
    team
  )

  return team
end

--------------------------------------------------
-- Add NPC target to a team
--------------------------------------------------
function TargetTeamService:AddTeamNPC(teamID, npcID)
  npcID = NormalizeNPCID(npcID)

  if not npcID then
    return nil, "Invalid NPC ID"
  end

  local teamService = addon.Services.Team

  if not teamService then
    return nil, "The Team service is unavailable"
  end

  local team = teamService:Get(teamID)

  if not team then
    return nil, "Team not found"
  end

  if self:TeamHasNPC(team, npcID) then
    return team
  end

  local npcIDs = {}

  for _, existingNPCID in ipairs(self:GetTeamNPCIDs(team)) do
    npcIDs[#npcIDs + 1] = existingNPCID
  end

  npcIDs[#npcIDs + 1] = npcID

  return self:SetTeamNPCIDs(
    teamID,
    npcIDs
  )
end

--------------------------------------------------
-- Remove NPC target from a team
--------------------------------------------------
function TargetTeamService:RemoveTeamNPC(teamID, npcID)
  npcID = NormalizeNPCID(npcID)

  if not npcID then
    return nil, "Invalid NPC ID"
  end

  local teamService = addon.Services.Team

  if not teamService then
    return nil, "The Team service is unavailable"
  end

  local team = teamService:Get(teamID)

  if not team then
    return nil, "Team not found"
  end

  local npcIDs = {}

  for _, existingNPCID in ipairs(self:GetTeamNPCIDs(team)) do
    if NormalizeNPCID(existingNPCID) ~= npcID then
      npcIDs[#npcIDs + 1] = existingNPCID
    end
  end

  return self:SetTeamNPCIDs(
    teamID,
    npcIDs
  )
end

--------------------------------------------------
-- Get NPC ID from unit
--------------------------------------------------
function TargetTeamService:GetNPCIDFromUnit(unitToken)
  unitToken = unitToken or "target"

  if not UnitExists(unitToken) then
    return nil
  end

  ------------------------------------------------
  -- Unit identity can be secret in Midnight.
  --
  -- Some modern targets expose secret identity
  -- data. Target-based team loading is only
  -- needed for older pet battle NPCs anyway.
  ------------------------------------------------
  if C_Secrets
      and C_Secrets.ShouldUnitIdentityBeSecret
      and C_Secrets.ShouldUnitIdentityBeSecret(
        unitToken
      ) then
    return nil
  end

  local guid = UnitGUID(unitToken)

  if type(guid) ~= "string" or guid == "" then
    return nil
  end

  ------------------------------------------------
  -- Creature / Vehicle GUID:
  --
  -- Type-0-Server-Instance-Zone-NPCID-SpawnID
  ------------------------------------------------
  local unitType,
  npcID = guid:match(
    "^([^-]+)%-[^-]+%-[^-]+%-[^-]+%-[^-]+%-([^-]+)%-"
  )

  if unitType ~= "Creature" and unitType ~= "Vehicle" then
    return nil
  end

  return NormalizeNPCID(npcID)
end

--------------------------------------------------
-- Get current target NPC ID
--------------------------------------------------
function TargetTeamService:GetCurrentTargetNPCID()
  return self:GetNPCIDFromUnit("target")
end

--------------------------------------------------
-- Handle target change
--------------------------------------------------
function TargetTeamService:HandleTargetChanged()
  local npcID = self:GetCurrentTargetNPCID()

  self.CurrentNPCID = npcID

  if not npcID then
    return nil, {}
  end

  local teams = self:GetTeamsForNPC(npcID)

  return npcID, teams
end

--------------------------------------------------
-- Resolve target team state
--------------------------------------------------
function TargetTeamService:ResolveTeams(teams)
  if type(teams) ~= "table" or #teams == 0 then
    return {
      type = "none",
      team = nil,
      teams = {},
    }
  end

  if #teams == 1 then
    return {
      type = "single",
      team = teams[1],
      teams = teams,
    }
  end

  return {
    type = "multiple",
    team = nil,
    teams = teams,
  }
end

--------------------------------------------------
-- Resolve current target
--------------------------------------------------
function TargetTeamService:ResolveCurrentTarget()
  local npcID,
  teams = self:HandleTargetChanged()
  local result = self:ResolveTeams(teams)
  result.npcID = npcID
  return result
end

--------------------------------------------------
-- Handle resolved target
--------------------------------------------------
function TargetTeamService:HandleResolvedTarget(result)
  if type(result) ~= "table" then
    return
  end

  ------------------------------------------------
  -- Always hide any previous target button first
  ------------------------------------------------
  local loadButton =
      addon.UI
      and addon.UI.Actions
      and addon.UI.Actions.TargetTeamLoadButton

  if loadButton then
    loadButton:Hide()
  end

  ------------------------------------------------
  -- Get target team load mode
  ------------------------------------------------
  local mode =
      addon.Settings:Get("targetTeamLoadMode")
      or "off"

  ------------------------------------------------
  -- Target team handling disabled
  ------------------------------------------------
  if mode == "off" then
    return
  end

  ------------------------------------------------
  -- No matching teams
  ------------------------------------------------
  if result.type == "none" then
    return
  end

  ------------------------------------------------
  -- Multiple teams
  ------------------------------------------------
  if result.type == "multiple" then
    local dialog =
        addon.UI
        and addon.UI.Dialogs
        and addon.UI.Dialogs.TargetTeamSelectDialog

    if dialog then
      dialog:Show(
        result.teams,
        result.npcID
      )
    end

    return
  end

  ------------------------------------------------
  -- Single team
  ------------------------------------------------
  if result.type ~= "single" or not result.team then
    return
  end

  ------------------------------------------------
  -- Show load button
  ------------------------------------------------
  if mode == "button" then
    if loadButton then
      loadButton:SetTeam(
        result.team,
        result.npcID
      )
    end

    return
  end

  --------------------------------------------------
  -- Confirm before loading
  --------------------------------------------------
  if mode == "confirm" then
    local dialog =
        addon.UI
        and addon.UI.Dialogs
        and addon.UI.Dialogs.TargetTeamConfirmDialog

    if dialog then
      dialog:Show(
        result.team,
        result.npcID
      )
    end

    return
  end

  --------------------------------------------------
  -- Automatic loading
  --------------------------------------------------
  if mode ~= "auto" then
    return
  end

  local teamService = addon.Services.Team

  if not teamService then
    return
  end

  teamService:Load(result.team.id)
end

addon.Services.TargetTeam = TargetTeamService
