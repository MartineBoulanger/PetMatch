local addonName = ...

local PetMatch = _G.PetMatch
local PetBattleScripts = _G.PetBattleScripts

if not PetMatch or not PetMatch.API or not PetBattleScripts then
  return
end

local Plugin = PetBattleScripts:NewPlugin("PetMatch", "AceEvent-3.0")
local ScriptClass = PetBattleScripts:GetClass("Script")

local syncingFromPetMatch = false
local syncingToPetMatch = false

--------------------------------------------------
-- Helpers
--------------------------------------------------
local function NormalizeScript(script)
  script =
      tostring(
        script or ""
      )

  script =
      script:gsub(
        "\r\n",
        "\n"
      )

  script =
      script:gsub(
        "\r",
        "\n"
      )

  return script
end

local function IsBlank(script)
  return NormalizeScript(script):match("^%s*$") ~= nil
end

local function GetTeamName(team)
  if not team then
    return "PetMatch team"
  end

  local name = tostring(team.name or "")

  if name == "" then
    return "PetMatch team"
  end

  return name
end

local function EnsurePluginOrder()
  local db = PetBattleScripts.db

  if not db or not db.profile then
    return
  end

  db.profile.pluginOrders = db.profile.pluginOrders or {}

  for _, pluginName in ipairs(db.profile.pluginOrders) do
    if pluginName == "PetMatch" then
      return
    end
  end

  table.insert(
    db.profile.pluginOrders,
    "PetMatch"
  )
end

--------------------------------------------------
-- Initialization
--------------------------------------------------
function Plugin:OnInitialize()
  self:EnableWithAddon("PetMatch")

  self:SetPluginTitle(
    "PetMatch"
  )

  self:SetPluginNotes(
    "Uses scripts stored on PetMatch teams."
  )

  self:SetPluginIcon(
    [[Interface\Addons\PetMatch_PetBattleScripts\Media\PetMatch_Logo]]
  )

  EnsurePluginOrder()
end

--------------------------------------------------
-- Plugin metadata
--------------------------------------------------
function Plugin:GetCurrentKey()
  local team = PetMatch.API:GetCurrentTeam()
  return team and team.id or nil
end

function Plugin:GetTitleByKey(teamID)
  local team = PetMatch.API:GetTeam(teamID)

  return team and GetTeamName(team) or tostring(teamID)
end

function Plugin:OnTooltipFormatting(tooltip, teamID)
  local team = PetMatch.API:GetTeam(teamID)

  if not team then
    tooltip:AddLine(
      "PetMatch team not found",
      1,
      0.2,
      0.2
    )

    return
  end

  tooltip:AddLine(
    "PetMatch team: " .. GetTeamName(team),
    0.2,
    1,
    0.2
  )

  if IsBlank(team.script) then
    tooltip:AddLine(
      "No script stored",
      0.7,
      0.7,
      0.7
    )
  else
    tooltip:AddLine(
      "Script stored in PetMatch",
      0.8,
      0.8,
      0.8
    )
  end
end

--------------------------------------------------
-- PetMatch -> PetBattleScripts
--------------------------------------------------
function Plugin:ImportTeamScript(team)
  if not team or team.id == nil then
    return false, "Invalid PetMatch team"
  end

  local teamID = team.id
  local code = NormalizeScript(team.script)
  local existing = self:GetScript(teamID)

  --------------------------------------------------
  -- Empty PetMatch script
  --------------------------------------------------
  if IsBlank(code) then
    if existing then
      self:RemoveScript(teamID)
    end

    return true
  end

  --------------------------------------------------
  -- Existing PBS script
  --------------------------------------------------
  if existing then
    local teamName = GetTeamName(team)

    if existing:GetName() ~= teamName then
      existing:SetName(teamName)
    end

    if NormalizeScript(existing:GetCode()) ~= code then
      return existing:
      SetCode(code)
    end

    return true
  end

  --------------------------------------------------
  -- New PBS script
  --------------------------------------------------
  local script =
      ScriptClass:New(
        {
          name = GetTeamName(team),
          code = code,
        },
        self,
        teamID
      )

  local success, errorMessage = script:SetCode(code)

  if not success then
    return false, errorMessage
  end

  self:AddScript(
    teamID,
    script
  )

  return true
end

function Plugin:ReportImportError(team, errorMessage)
  if not errorMessage then
    return
  end

  geterrorhandler()(
    "PetMatch script error for " .. GetTeamName(team) .. ": " .. tostring(errorMessage)
  )
end

function Plugin:SyncTeamFromPetMatch(team)
  if syncingToPetMatch then
    return
  end

  if not team or team.id == nil then
    return
  end

  syncingFromPetMatch = true

  local success, errorMessage = self:ImportTeamScript(team)

  syncingFromPetMatch = false

  if not success then
    self:ReportImportError(team, errorMessage)
  end
end

function Plugin:RemoveTeamFromPetBattleScripts(team)
  if syncingToPetMatch then
    return
  end

  local teamID = type(team) == "table" and team.id or team

  if not teamID then
    return
  end

  syncingFromPetMatch = true

  if self:GetScript(teamID) then
    self:RemoveScript(teamID)
  end

  syncingFromPetMatch = false
end

--------------------------------------------------
-- Full initial sync
--------------------------------------------------
function Plugin:SyncFromPetMatch()
  if syncingToPetMatch then
    return
  end

  syncingFromPetMatch = true

  local teams = PetMatch.API:GetTeams()

  local existingTeams = {}

  for teamID, team in pairs(teams) do
    existingTeams[teamID] = true

    local success, errorMessage =
        self:ImportTeamScript(team)

    if not success then
      self:ReportImportError(
        team,
        errorMessage
      )
    end
  end

  --------------------------------------------------
  -- Remove stale PBS scripts
  --------------------------------------------------
  local staleKeys = {}

  for teamID in self:IterateScripts() do
    if not existingTeams[teamID] then
      staleKeys[#staleKeys + 1] = teamID
    end
  end

  for _, teamID in ipairs(staleKeys) do
    self:RemoveScript(teamID)
  end

  syncingFromPetMatch = false
end

--------------------------------------------------
-- PetBattleScripts -> PetMatch
--------------------------------------------------
function Plugin:SyncScriptToPetMatch(teamID)
  if syncingFromPetMatch then
    return
  end

  if not teamID then
    return
  end

  local team = PetMatch.API:GetTeam(teamID)

  if not team then
    return
  end

  syncingToPetMatch = true

  local script = self:GetScript(teamID)
  local code = script and NormalizeScript(
    script:GetCode()
  ) or ""

  if NormalizeScript(team.script) ~= code then
    PetMatch.API:
        SetScript(
          teamID,
          code
        )
  end

  syncingToPetMatch = false
end

--------------------------------------------------
-- PBS event handlers
--------------------------------------------------
function Plugin:OnScriptChanged(_, plugin, teamID)
  if syncingFromPetMatch then
    return
  end

  --------------------------------------------------
  -- Ignore changes from other PBS plugins
  --------------------------------------------------
  if plugin
      and plugin ~= self
      and plugin ~= "PetMatch" then
    return
  end

  if teamID then
    self:SyncScriptToPetMatch(teamID)

    return
  end

  --------------------------------------------------
  -- Compatibility fallback:
  -- if PBS does not provide a key,
  -- do one full reverse sync.
  --------------------------------------------------

  self:SyncToPetMatch()
end

--------------------------------------------------
-- Full reverse sync fallback
--------------------------------------------------
function Plugin:SyncToPetMatch()
  if syncingFromPetMatch then
    return
  end

  syncingToPetMatch = true

  local teams = PetMatch.API:GetTeams()

  for teamID, team in pairs(teams) do
    local script = self:GetScript(teamID)
    local code = script and NormalizeScript(
      script:GetCode()
    ) or ""

    if NormalizeScript(team.script) ~= code then
      PetMatch.API:
          SetScript(
            teamID,
            code
          )
    end
  end

  syncingToPetMatch = false
end

--------------------------------------------------
-- Public PetMatch API callbacks
--------------------------------------------------
function Plugin:OnPetMatchTeamCreated(team)
  self:SyncTeamFromPetMatch(team)
end

function Plugin:OnPetMatchTeamUpdated(team)
  self:SyncTeamFromPetMatch(team)
end

function Plugin:OnPetMatchTeamDeleted(team)
  self:RemoveTeamFromPetBattleScripts(team)
end

function Plugin:RegisterPetMatchCallbacks()
  if not PetMatch.API.RegisterCallback then
    return
  end

  self.petMatchTeamCreatedCallback =
      function(team)
        self:OnPetMatchTeamCreated(team)
      end

  self.petMatchTeamUpdatedCallback =
      function(team)
        self:OnPetMatchTeamUpdated(team)
      end

  self.petMatchTeamDeletedCallback =
      function(team)
        self:OnPetMatchTeamDeleted(team)
      end

  PetMatch.API:RegisterCallback(
    "TEAM_CREATED",
    self.petMatchTeamCreatedCallback
  )

  PetMatch.API:RegisterCallback(
    "TEAM_UPDATED",
    self.petMatchTeamUpdatedCallback
  )

  PetMatch.API:RegisterCallback(
    "TEAM_DELETED",
    self.petMatchTeamDeletedCallback
  )
end

function Plugin:UnregisterPetMatchCallbacks()
  if not PetMatch.API.UnregisterCallback then
    return
  end

  if self.petMatchTeamCreatedCallback then
    PetMatch.API:UnregisterCallback(
      "TEAM_CREATED",
      self.petMatchTeamCreatedCallback
    )
  end

  if self.petMatchTeamUpdatedCallback then
    PetMatch.API:UnregisterCallback(
      "TEAM_UPDATED",
      self.petMatchTeamUpdatedCallback
    )
  end

  if self.petMatchTeamDeletedCallback then
    PetMatch.API:UnregisterCallback(
      "TEAM_DELETED",
      self.petMatchTeamDeletedCallback
    )
  end

  self.petMatchTeamCreatedCallback = nil
  self.petMatchTeamUpdatedCallback = nil
  self.petMatchTeamDeletedCallback = nil
end

--------------------------------------------------
-- Enable / Disable
--------------------------------------------------
function Plugin:OnEnable()
  EnsurePluginOrder()

  --------------------------------------------------
  -- PetBattleScripts events
  --------------------------------------------------
  self:RegisterMessage(
    "PET_BATTLE_SCRIPT_SCRIPT_ADDED",
    "OnScriptChanged"
  )

  self:RegisterMessage(
    "PET_BATTLE_SCRIPT_SCRIPT_REMOVED",
    "OnScriptChanged"
  )

  self:RegisterMessage(
    "PET_BATTLE_SCRIPT_SCRIPT_UPDATE",
    "OnScriptChanged"
  )

  --------------------------------------------------
  -- PetMatch events
  --------------------------------------------------
  self:RegisterPetMatchCallbacks()

  --------------------------------------------------
  -- One full sync at startup only
  --------------------------------------------------
  self:SyncFromPetMatch()
end

function Plugin:OnDisable()
  self:UnregisterAllMessages()
  self:UnregisterPetMatchCallbacks()
end
