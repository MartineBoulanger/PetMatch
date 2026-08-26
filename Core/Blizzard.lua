local _, addon = ...

addon.Blizzard = addon.Blizzard or {}
local Blizzard = {}

Blizzard.Hooked = false

local function UpdateLoadoutTitle(team)
  local titleText = _G.PetJournalLoadoutBorderSlotHeaderText

  if not titleText then
    return
  end

  local title =
      BATTLE_PET_SLOTS
      or "Battle Pet Slots"

  if team
      and type(team.name) == "string"
      and team.name ~= "" then
    title =
        team.name
  end

  titleText:SetText(title)
end

local function GetSearchAbilityHighlights(control)
  if not PetJournal or not PetJournal.searchBox then
    return nil
  end

  local searchText = PetJournal.searchBox:GetText()

  searchText = tostring(searchText or "")
  searchText = string.lower(searchText)
  searchText = searchText:match("^%s*(.-)%s*$") or ""

  if searchText == "" then
    return nil
  end

  --------------------------------------------------
  -- Determine species
  --------------------------------------------------
  local speciesID = tonumber(control.speciesID)

  if not speciesID and type(control.petID) == "string" and control.petID ~= "" then
    speciesID = select(1, C_PetJournal.GetPetInfoByPetID(control.petID))
  end

  speciesID = tonumber(speciesID)

  if not speciesID then
    return nil
  end

  --------------------------------------------------
  -- Get all six abilities
  --------------------------------------------------
  local abilityIDs = {}
  local abilityLevels = {}

  C_PetJournal.GetPetAbilityList(
    speciesID,
    abilityIDs,
    abilityLevels
  )

  local matches = nil

  for _, abilityID in ipairs(abilityIDs) do
    local abilityName = C_PetJournal.GetPetAbilityInfo(abilityID)

    if abilityName then
      local abilityNameLower = string.lower(abilityName)

      if string.find(abilityNameLower, searchText, 1, true) then
        matches = matches or {}
        matches[tonumber(abilityID)] = true
      end
    end
  end

  return matches
end

function Blizzard:Initialize()
  if self.Hooked then
    return
  end

  if not PetJournal then
    return
  end

  self.Hooked = true

  PetJournal:HookScript(
    "OnShow",
    function()
      addon.UI.Host:Update()
      local team = addon.Services.Team and addon.Services.Team:GetActive()
      UpdateLoadoutTitle(team)
    end
  )

  PetJournal:HookScript(
    "OnHide",
    function()
      addon.UI.Host:Update()
    end
  )

  addon.EventBus:Register(
    addon.Events.TEAM_LOADED,
    function(team)
      UpdateLoadoutTitle(team)
    end
  )

  hooksecurefunc(
    "PetJournal_InitPetButton",
    function(button)
      addon.UI.Components.PetTooltip:Attach(
        button,
        function(control)
          if type(control.petID) == "string" and control.petID ~= "" then
            return "petGUID", control.petID
          end

          local speciesID = tonumber(control.speciesID)

          if speciesID then
            return "speciesID", speciesID
          end

          return nil
        end,
        "ANCHOR_RIGHT",
        "petList",
        GetSearchAbilityHighlights
      )
    end
  )

  if addon.Services.PetJournal then
    addon.Services.PetJournal:Initialize()
  end

  if addon.Services.LevellingQueue then
    addon.Services.LevellingQueue:Initialize()
  end

  if addon.Services.LoadoutMonitor then
    addon.Services.LoadoutMonitor:Initialize()
  end

  local teamService = addon.Services.Team
  local activeTeam = teamService and teamService:GetActive()
  UpdateLoadoutTitle(activeTeam)
end

function Blizzard:IsCollectionsLoaded()
  if C_AddOns
      and type(C_AddOns.IsAddOnLoaded)
      == "function" then
    return C_AddOns.IsAddOnLoaded(
      "Blizzard_Collections"
    )
  end

  if type(IsAddOnLoaded) == "function" then
    return IsAddOnLoaded(
      "Blizzard_Collections"
    )
  end

  return PetJournal ~= nil
end

local frame = CreateFrame("Frame")

frame:RegisterEvent("ADDON_LOADED")
frame:SetScript(
  "OnEvent",
  function(_, event, name)
    if event == "ADDON_LOADED"
        and name == "Blizzard_Collections" then
      Blizzard:Initialize()
    end
  end
)

addon.Blizzard = Blizzard
