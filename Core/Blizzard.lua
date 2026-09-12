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

local function UpdatePetMatchLayering()
  local panels =
      addon.UI
      and addon.UI.Views
      and addon.UI.Views.Panels

  if panels
      and type(panels.UpdateLayering) == "function" then
    panels:UpdateLayering()
  end
end

local function AutoOpenPvENotes()
  local enabled =
      addon.Settings:Get("autoOpenNotesOnPvEBattle")

  if not enabled then
    return
  end

  --------------------------------------------------
  -- Only PvE battles
  --------------------------------------------------

  if C_PetBattles.IsPlayerNPC(
        Enum.BattlePetOwner.Enemy) ~= true then
    return
  end

  local teamService = addon.Services.Team

  if not teamService then
    return
  end

  local team = teamService:GetActive()

  if not team then
    return
  end

  local notes =
      addon.Utils:Trim(team.notes or "")

  if notes == "" then
    return
  end

  if not addon.UI
      or not addon.UI.Dialogs
      or not addon.UI.Dialogs.TeamNotesDialog then
    return
  end

  addon.UI.Dialogs.TeamNotesDialog:Show(team)
end

local function AutoOpenPetJournalAfterBattle()
  local enabled =
      addon.Settings:Get("autoOpenPetJournalAfterBattle")

  if enabled == false then
    return
  end

  C_Timer.After(
    0.5,
    function()
      if not CollectionsJournal then
        return
      end

      if not PetJournal then
        return
      end

      ShowUIPanel(CollectionsJournal)

      if CollectionsJournal_SetTab then
        CollectionsJournal_SetTab(
          CollectionsJournal,
          2
        )
      end
    end
  )
end

local function InitializePetCollectionButton()
  local petCount = PetJournal and PetJournal.PetCount

  if not petCount then
    return
  end

  if petCount.PetMatchInitialized then
    return
  end

  petCount.PetMatchInitialized = true

  petCount:EnableMouse(true)

  petCount:SetScript(
    "OnMouseUp",
    function(_, button)
      if button ~= "LeftButton" then
        return
      end

      local dialog = addon.UI
          and addon.UI.Dialogs
          and addon.UI.Dialogs.PetCollectionDialog

      if not dialog then
        return
      end

      dialog:Show()
    end
  )

  petCount:HookScript(
    "OnEnter",
    function()
      if petCount.Label then
        petCount.Label:SetTextColor(
          1,
          0.82,
          0
        )
      end

      GameTooltip:SetOwner(
        petCount,
        "ANCHOR_RIGHT"
      )

      GameTooltip:SetText(
        "Pet Collection"
      )

      GameTooltip:AddLine(
        "Click to view your pet collection statistics.",
        1,
        1,
        1,
        true
      )

      GameTooltip:Show()
    end
  )

  petCount:HookScript(
    "OnLeave",
    function()
      if petCount.Label then
        petCount.Label:SetTextColor(
          1,
          1,
          1
        )
      end

      GameTooltip:Hide()
    end
  )
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

  InitializePetCollectionButton()

  --------------------------------------------------
  -- Blizzard panel changes
  --------------------------------------------------
  hooksecurefunc(
    "ShowUIPanel",
    function()
      UpdatePetMatchLayering()
    end
  )

  hooksecurefunc(
    "HideUIPanel",
    function()
      UpdatePetMatchLayering()
    end
  )

  hooksecurefunc(
    "UpdateUIPanelPositions",
    function()
      UpdatePetMatchLayering()
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

--------------------------------------------------
-- Pet Battle
--------------------------------------------------
local petBattleFrame = CreateFrame("Frame")
petBattleFrame:RegisterEvent("PET_BATTLE_OPENING_START")
petBattleFrame:RegisterEvent("PET_BATTLE_FINAL_ROUND")
petBattleFrame:RegisterEvent("PET_BATTLE_CLOSE")
petBattleFrame:SetScript(
  "OnEvent",
  function(_, event, ...)
    if event
        == "PET_BATTLE_OPENING_START" then
      addon.Services.TeamStatistics:StartBattle()
      AutoOpenPvENotes()
    elseif event
        == "PET_BATTLE_FINAL_ROUND" then
      addon.Services.TeamStatistics:SetBattleResult(...)
    elseif event == "PET_BATTLE_CLOSE" then
      addon.Services.TeamStatistics:EndBattle()
      AutoOpenPetJournalAfterBattle()
    end
  end
)

--------------------------------------------------
-- Target changes
--------------------------------------------------
local targetFrame = CreateFrame("Frame")
targetFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
targetFrame:SetScript(
  "OnEvent",
  function(_, event)
    if event ~= "PLAYER_TARGET_CHANGED" then
      return
    end

    local targetService = addon.Services.TargetTeam

    if not targetService then
      return
    end

    local mode =
        addon.Settings:Get("targetTeamLoadMode")
        or "off"

    if mode == "off" then
      local loadButton =
          addon.UI
          and addon.UI.Actions
          and addon.UI.Actions.TargetTeamLoadButton

      if loadButton then
        loadButton:Hide()
      end

      return
    end

    local result = targetService:ResolveCurrentTarget()

    if not result.npcID then
      return
    end

    targetService:HandleResolvedTarget(result)
  end
)

--------------------------------------------------
-- Combat
--------------------------------------------------
local combatFrame = CreateFrame("Frame")
combatFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
combatFrame:SetScript(
  "OnEvent",
  function(_, event)
    if event ~= "PLAYER_REGEN_DISABLED" then
      return
    end

    if PetJournal and PetJournal:IsShown() then
      HideUIPanel(CollectionsJournal)
    end
  end
)

--------------------------------------------------
-- Addon loading
--------------------------------------------------
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
