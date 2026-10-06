local _, addon = ...

local L = addon.L

local TeamSetupPanel = {}

local MENU_TEMPLATES = {
  "WowStyle1FilterDropdownTemplate",
  "WowStyle1DropdownTemplate",
}

local TARGET_TEXT_MAX_LENGTH = 22

local function TruncateText(text)
  if type(text) ~= "string" then
    return text
  end

  if #text <= TARGET_TEXT_MAX_LENGTH then
    return text
  end

  return text:sub(1, TARGET_TEXT_MAX_LENGTH - 5) .. "..."
end

local function SetMenuButtonText(dropdown, text)
  if type(dropdown.SetDefaultText) == "function" then
    dropdown:SetDefaultText(text)
    return true
  end

  if type(dropdown.SetText) == "function" then
    dropdown:SetText(text)
    return true
  end

  return false
end

function TeamSetupPanel:CreateMenuButton(parent, text, width, height, populateMenu)
  local dropdown

  for _, template in ipairs(MENU_TEMPLATES) do
    local created, frame =
        pcall(
          CreateFrame,
          "DropdownButton",
          nil,
          parent,
          template
        )

    if created and frame then
      dropdown = frame
      break
    end
  end

  if not dropdown then
    addon.Logger:Warn(L["UNABLE_CREATING_MENU"])
    return nil
  end

  dropdown:SetHeight(height or 22)

  SetMenuButtonText(
    dropdown, text or L["NONE"]
  )

  dropdown.resizeToText = false
  dropdown:SetWidth(width or 150)

  dropdown:SetupMenu(
    function(_, rootDescription)
      if type(populateMenu) == "function" then
        populateMenu(rootDescription)
      end
    end
  )

  return dropdown
end

function TeamSetupPanel:Create()
  if self.Frame then
    return self.Frame
  end

  if not PetJournal then
    return nil
  end

  local frame =
      CreateFrame(
        "Frame",
        "PetMatchTeamSetupPanel",
        PetJournal,
        "BackdropTemplate"
      )

  frame:SetFrameStrata(
    PetJournal:GetFrameStrata()
  )

  frame:SetFrameLevel(
    PetJournal:GetFrameLevel() + 40
  )

  frame:SetSize(330, 28)

  frame:SetPoint(
    "BOTTOM",
    PetJournalLoadoutBorder,
    "TOP",
    0,
    12
  )

  frame:SetBackdrop({
    bgFile = "Interface\\FrameGeneral\\UI-Background-Marble",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 128,
    edgeSize = 4,
    insets = {
      left = 2,
      right = 2,
      top = 2,
      bottom = 2,
    },
  })

  frame:SetBackdropBorderColor(
    0.2,
    0.8,
    1,
    0.9
  )

  local title =
      frame:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontNormal"
      )

  title:SetPoint(
    "LEFT",
    frame,
    "LEFT",
    10,
    0
  )

  title:SetText(L["TEAM_SETUP"])

  local targetLabel =
      frame:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlightSmall"
      )

  targetLabel:SetPoint(
    "LEFT",
    title,
    "RIGHT",
    15,
    0
  )

  targetLabel:SetText(L["TARGET_NPC"])

  local selector =
      self:CreateMenuButton(
        frame,
        L["NONE"],
        160,
        22,
        function(root)
          self:PopulateTargetMenu(root)
        end
      )

  if not selector then
    return nil
  end

  selector:SetPoint(
    "LEFT",
    targetLabel,
    "RIGHT",
    10,
    0
  )

  self.Frame = frame
  self.TargetSelector = selector

  frame:Hide()

  return frame
end

function TeamSetupPanel:Refresh()
  if not self.Frame then
    return
  end

  local teamSetup = addon.Services.TeamSetup

  self.Frame:SetShown(teamSetup and teamSetup:IsActive())

  if not teamSetup or not self.TargetSelector then
    return
  end

  local npcID = teamSetup:GetTargetNPCID()

  local text = L["NONE"]

  if npcID then
    local targetService = addon.Services.PetBattleTarget

    if targetService then
      local target = targetService:GetByNPCID(npcID)
      local npcName = target and targetService:GetTargetDisplayName(target)

      if npcName then
        text = npcName
      end
    end
  end

  SetMenuButtonText(
    self.TargetSelector,
    TruncateText(text)
  )
end

function TeamSetupPanel:Initialize()
  self:Create()

  addon.EventBus:Register(
    addon.Events.TEAM_SETUP_CHANGED,
    function()
      self:Refresh()
    end
  )

  addon.EventBus:Register(
    addon.Events.TEAM_SETUP_TARGET_CHANGED,
    function()
      self:Refresh()
    end
  )

  self:Refresh()
end

function TeamSetupPanel:PopulateTargetMenu(root)
  local targetService = addon.Services.PetBattleTarget

  if not targetService then
    return
  end

  root:CreateTitle(L["TARGET_NPC"])

  root:CreateButton(
    L["NONE"],
    function()
      addon.Services.TeamSetup:ClearTargetNPC()
      self:Refresh()
    end
  )

  root:CreateDivider()

  local groups = targetService:GetTargetsByExpansion()

  for expansionID = 10, 0, -1 do
    local targets = groups[expansionID]

    if targets and #targets > 0 then
      local expansionName = targetService:GetExpansionName(expansionID)
      local expansion = root:CreateButton(expansionName)

      expansion:CreateTitle(expansionName)

      local mapGroups = targetService:GetTargetsByMap(targets)

      local maps = {}

      for mapID, mapTargets in pairs(mapGroups) do
        maps[#maps + 1] = {
          id = mapID,
          name = targetService:GetMapName(mapID),
          targets = mapTargets,
        }
      end

      table.sort(
        maps,
        function(left, right)
          return left.name < right.name
        end
      )

      for _, map in ipairs(maps) do
        local mapMenu = expansion:CreateButton(map.name)

        mapMenu:CreateTitle(map.name)

        local npcTargets = {}

        for _, target in ipairs(map.targets) do
          local npcID = targetService:GetNPCID(target)

          local npcName =
              targetService:GetTargetDisplayName(target)

          if npcID and npcName then
            npcTargets[#npcTargets + 1] = {
              id = npcID,
              name = npcName,
            }
          end
        end

        table.sort(
          npcTargets,
          function(left, right)
            return left.name < right.name
          end
        )

        for _, npc in ipairs(npcTargets) do
          mapMenu:CreateButton(
            npc.name,
            function()
              addon.Services.TeamSetup:SetTargetNPC(npc.id)
              self:Refresh()
            end
          )
        end
      end
    end
  end
end

addon.UI.Views.TeamSetupPanel = TeamSetupPanel
