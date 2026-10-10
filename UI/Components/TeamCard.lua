local _, addon = ...

local L = addon.L
local TeamCard = {}
local TargetNameCache = {}
local PendingTargetNames = {}

local CARD_WIDTH = 230

local CARD_HEIGHT_NORMAL = 28
local CARD_HEIGHT_LARGE = 34

local SLOT_SPACING = 0
local SLOT_START_X = 2

local function ApplyVisualState(frame)
  if frame.Selected then
    frame:SetBackdropBorderColor(0.20, 0.70, 1.00, 1.00)
  else
    frame:SetBackdropColor(0.04, 0.04, 0.04, 0.70)
    frame:SetBackdropBorderColor(0.35, 0.35, 0.35, 1.00)
  end
end

local function GetCardHeight()
  local mode = addon.Settings:GetUI("teamCardHeightMode") or "normal"

  if mode == "large" then
    return CARD_HEIGHT_LARGE
  end

  return CARD_HEIGHT_NORMAL
end

local function IsLargeCard()
  return addon.Settings:GetUI("teamCardHeightMode") == "large"
end

local function GetTargetName(team)
  if type(team) ~= "table" or type(team.targetNPCIDs) ~= "table" then
    return nil
  end

  local npcID = tonumber(team.targetNPCIDs[1])

  if not npcID then
    return nil
  end

  --------------------------------------------------
  -- Already resolved
  --------------------------------------------------
  if TargetNameCache[npcID] then
    return TargetNameCache[npcID]
  end

  --------------------------------------------------
  -- Request tooltip data
  --------------------------------------------------
  local hyperlink = string.format("unit:Creature-0-0-0-0-%d-0000000000", npcID)
  local data = C_TooltipInfo.GetHyperlink(hyperlink)

  if not data then
    return nil
  end

  --------------------------------------------------
  -- Try to resolve immediately
  --------------------------------------------------
  for _, line in ipairs(data.lines or {}) do
    if line.type == Enum.TooltipDataLineType.UnitName then
      local leftText = line.leftText

      if leftText and not issecretvalue(leftText) then
        TargetNameCache[npcID] = leftText
        return leftText
      end
    end
  end

  --------------------------------------------------
  -- Tooltip data is still loading
  --------------------------------------------------
  if data.dataInstanceID then
    PendingTargetNames[data.dataInstanceID] = npcID
  end

  return nil
end

function TeamCard:Create(parent, team)
  assert(parent, L["PARENT_TEAM_ERROR"])
  assert(team, L["TEAM_CARD_ERROR"])

  local frame = CreateFrame(
    "Button",
    nil,
    parent,
    "BackdropTemplate"
  )

  frame:RegisterForClicks(
    "LeftButtonUp",
    "RightButtonUp"
  )

  frame:RegisterForDrag("LeftButton")

  frame:SetScript(
    "OnDragStart",
    function(self)
      self.WasDragged = true

      local started =
          addon.UI.Components.DragDrop:StartTeam(
            self.Team,
            self
          )

      if started == false then
        self.WasDragged = false
        return
      end

      local teamList = addon.UI.Views.TeamList

      if teamList then
        teamList:BeginTeamDrag(self)
      end
    end
  )

  frame:SetScript(
    "OnDragStop",
    function(self)
      local teamList = addon.UI.Views.TeamList

      if teamList then
        teamList:FinishTeamDrag()
      end

      addon.UI.Components.DragDrop:StopTeam()

      C_Timer.After(
        0,
        function()
          self.WasDragged = false
        end
      )
    end
  )

  frame:SetSize(CARD_WIDTH, GetCardHeight())

  frame:SetBackdrop({
    bgFile = "Interface\\FrameGeneral\\UI-Background-Marble",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 128,
    edgeSize = 8,
    insets = {
      left = 3,
      right = 3,
      top = 3,
      bottom = 3,
    },
  })

  frame:SetBackdropBorderColor(0.35, 0.35, 0.35, 1)

  frame.BackgroundGradient = frame:CreateTexture(
    nil,
    "BACKGROUND",
    nil,
    1
  )

  frame.BackgroundGradient:SetPoint("TOPLEFT", 1, -1)
  frame.BackgroundGradient:SetPoint("BOTTOMRIGHT", -1, 1)

  frame.BackgroundGradient:SetColorTexture(1, 1, 1, 1)

  frame.BackgroundGradient:SetGradient(
    "VERTICAL",
    CreateColor(0.015, 0.015, 0.015, 0.70),
    CreateColor(0.13, 0.13, 0.13, 0.8)
  )

  frame.Highlight =
      frame:CreateTexture(
        nil,
        "HIGHLIGHT"
      )

  frame.Highlight:SetAtlas(
    "PetList-ButtonHighlight",
    true
  )

  frame.Highlight:SetPoint(
    "TOPLEFT",
    frame,
    "TOPLEFT",
    0,
    0
  )

  frame.Highlight:SetPoint(
    "BOTTOMRIGHT",
    frame,
    "BOTTOMRIGHT",
    0,
    0
  )

  frame.Highlight:SetBlendMode(
    "BLEND"
  )

  frame:SetHighlightTexture(
    frame.Highlight
  )

  frame.Team = team
  frame.Selected = false
  frame.Hovered = false
  frame.PetSlots = {}

  for slotIndex = 1, 3 do
    local petSlot = addon.UI.Components.PetSlot:Create(frame)
    local petSlotFrame = petSlot:GetFrame()

    if IsLargeCard() then
      petSlotFrame:SetHeight(
        CARD_HEIGHT_LARGE - 8
      )
      petSlotFrame:SetWidth(
        26
      )
    else
      petSlotFrame:SetHeight(
        CARD_HEIGHT_NORMAL - 4
      )
    end

    petSlotFrame:SetPoint(
      "LEFT",
      frame,
      "LEFT",
      SLOT_START_X
      + ((slotIndex - 1)
        * (
          petSlotFrame:GetWidth()
          + SLOT_SPACING
        )),
      0
    )

    frame.PetSlots[slotIndex] = petSlot
  end

  frame.Title = frame:CreateFontString(
    nil,
    "OVERLAY",
    "GameFontNormalSmall"
  )

  if IsLargeCard() then
    frame.Title:SetWordWrap(true)
    frame.Title:SetNonSpaceWrap(false)
    frame.Title:SetMaxLines(2)
  else
    frame.Title:SetWordWrap(false)
    frame.Title:SetNonSpaceWrap(false)
    frame.Title:SetMaxLines(1)
  end

  frame.Title:ClearAllPoints()

  frame.Title:SetJustifyH("LEFT")
  frame.Title:SetJustifyV("MIDDLE")

  frame.Target =
      frame:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlightSmall"
      )

  frame.Target:SetJustifyH("LEFT")
  frame.Target:SetJustifyV("MIDDLE")

  frame.Target:SetWordWrap(false)
  frame.Target:SetNonSpaceWrap(false)
  frame.Target:SetMaxLines(1)

  frame.Target:SetTextColor(
    1,
    1,
    1,
    1
  )

  frame.Target:SetText("")
  frame.Target:Hide()

  frame.MenuButton =
      CreateFrame(
        "Button",
        nil,
        frame
      )

  frame.MenuButton:SetSize(18, 18)

  frame.MenuButton:SetPoint(
    "RIGHT",
    frame,
    "RIGHT",
    -3,
    3
  )

  frame.MenuButton.Text =
      frame.MenuButton:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontNormalLarge"
      )

  frame.MenuButton.Text:SetPoint(
    "CENTER",
    0,
    2
  )

  frame.MenuButton.Text:SetText("...")

  frame.MenuButton:SetScript(
    "OnClick",
    function(button)
      if not frame.Team then
        return
      end

      addon.UI.Actions.TeamContextMenu:Show(
        button,
        frame.Team
      )
    end
  )

  frame.MenuButton:SetScript(
    "OnEnter",
    function(button)
      GameTooltip:SetOwner(
        button,
        "ANCHOR_RIGHT"
      )

      GameTooltip:SetText("Team Menu")
      GameTooltip:Show()
    end
  )

  frame.MenuButton:SetScript(
    "OnLeave",
    function()
      GameTooltip:Hide()
    end
  )

  frame.FavoriteButton =
      CreateFrame(
        "Button",
        nil,
        frame
      )

  frame.FavoriteButton:SetSize(
    24,
    24
  )

  frame.FavoriteButton:SetPoint(
    "LEFT",
    frame.MenuButton,
    "LEFT",
    -20,
    -6
  )

  frame.FavoriteButton.Icon =
      frame.FavoriteButton:CreateTexture(
        nil,
        "ARTWORK"
      )

  frame.FavoriteButton.Icon:SetSize(
    30,
    30
  )

  frame.FavoriteButton.Icon:SetPoint(
    "CENTER"
  )

  frame.FavoriteButton.Icon:SetTexture(
    addon.UI.Theme.Icons.Favorite
  )

  frame.FavoriteButton.Text =
      frame.FavoriteButton:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontNormalLarge"
      )

  frame.FavoriteButton.Text:SetPoint(
    "CENTER"
  )

  frame.FavoriteButton:SetScript(
    "OnClick",
    function()
      local team = frame.Team

      if not team then
        return
      end

      local updatedTeam, errorMessage =
          addon.Services.Team:ToggleFavorite(
            team.id
          )

      if not updatedTeam then
        addon.Logger:Warn(
          errorMessage
          or L["UNABLE_FAVORITE_UPDATE"]
        )

        return
      end

      frame:SetTeam(updatedTeam)
    end
  )

  frame.FavoriteButton:SetScript(
    "OnEnter",
    function(button)
      GameTooltip:SetOwner(
        button,
        "ANCHOR_RIGHT"
      )

      if frame.Team
          and frame.Team.favorite then
        GameTooltip:SetText(
          L["REMOVE_FAVORITE"]
        )
      else
        GameTooltip:SetText(
          L["ADD_FAVORITE"]
        )
      end

      GameTooltip:Show()
    end
  )

  frame.FavoriteButton:SetScript(
    "OnLeave",
    function()
      GameTooltip:Hide()
    end
  )

  function frame:RefreshState()
    local team = self.Team

    if not team then
      return
    end

    if team.favorite then
      self.FavoriteButton.Icon:SetDesaturated(false)
      self.FavoriteButton.Icon:SetAlpha(1)
    else
      self.FavoriteButton.Icon:SetDesaturated(true)
      self.FavoriteButton.Icon:SetAlpha(0.4)
    end
  end

  function frame:SetTeam(newTeam)
    self.Team = newTeam

    local title = newTeam.name or "Unnamed Team"

    self.Title:SetText(title)

    local targetName = GetTargetName(newTeam)

    self.Title:ClearAllPoints()
    self.Target:ClearAllPoints()

    if targetName then
      --------------------------------------------------
      -- With target:
      -- same layout for Normal and Large
      --------------------------------------------------
      self.Title:SetWordWrap(false)
      self.Title:SetNonSpaceWrap(false)
      self.Title:SetMaxLines(1)

      self.Target:SetText(
        targetName
      )

      self.Target:Show()

      self.Title:ClearAllPoints()
      self.Target:ClearAllPoints()

      if IsLargeCard() then
        self.Title:SetPoint(
          "BOTTOMLEFT",
          self,
          "LEFT",
          86,
          3
        )
      else
        self.Title:SetPoint(
          "TOPLEFT",
          self,
          "TOPLEFT",
          80,
          -2
        )
      end

      self.Title:SetPoint(
        "RIGHT",
        self,
        "RIGHT",
        -48,
        0
      )

      if IsLargeCard() then
        self.Target:SetPoint(
          "TOPLEFT",
          self.Title,
          "BOTTOMLEFT",
          0,
          -5
        )
      else
        self.Target:SetPoint(
          "TOPLEFT",
          self.Title,
          "BOTTOMLEFT",
          0,
          -2
        )
      end

      self.Target:SetPoint(
        "RIGHT",
        self,
        "RIGHT",
        -48,
        0
      )
    else
      --------------------------------------------------
      -- No target:
      -- allow team name to wrap to 2 lines
      --------------------------------------------------
      self.Target:SetText("")
      self.Target:Hide()

      self.Title:SetWordWrap(true)
      self.Title:SetNonSpaceWrap(false)
      self.Title:SetMaxLines(2)

      if IsLargeCard() then
        self.Title:SetPoint(
          "LEFT",
          self,
          "LEFT",
          86,
          0
        )
      else
        self.Title:SetPoint(
          "LEFT",
          self,
          "LEFT",
          80,
          0
        )
      end

      self.Title:SetPoint(
        "RIGHT",
        self,
        "RIGHT",
        -48,
        0
      )
    end

    --------------------------------------------------
    -- Favorite
    --------------------------------------------------
    if newTeam.favorite then
      self.FavoriteButton.Icon:SetDesaturated(false)
      self.FavoriteButton.Icon:SetVertexColor(
        1,
        0.82,
        0
      )
      self.FavoriteButton.Icon:SetAlpha(1)
    else
      self.FavoriteButton.Icon:SetDesaturated(true)
      self.FavoriteButton.Icon:SetVertexColor(
        0.7,
        0.7,
        0.7
      )
      self.FavoriteButton.Icon:SetAlpha(0.45)
    end

    --------------------------------------------------
    -- Pet slots
    --------------------------------------------------
    for slotIndex = 1, 3 do
      local petSlot = self.PetSlots[slotIndex]

      local specialSlot =
          newTeam.specialSlots
          and newTeam.specialSlots[slotIndex]

      if specialSlot then
        petSlot:SetSpecialSlot(
          specialSlot
        )
      else
        petSlot:SetPet(
          newTeam.pets
          and newTeam.pets[slotIndex]
          or nil,
          newTeam,
          slotIndex
        )
      end
    end

    self:RefreshState()
  end

  function frame:SetSelected(selected)
    self.Selected = selected == true
    ApplyVisualState(self)
  end

  frame:SetScript("OnEnter", function(self)
    self.Hovered = true
    ApplyVisualState(self)
  end)

  frame:SetScript("OnLeave", function(self)
    self.Hovered = false
    ApplyVisualState(self)
  end)

  frame:SetScript("OnClick", function(self, button)
    if self.WasDragged then
      return
    end

    local team = self.Team

    if not team then
      return
    end

    if button == "RightButton" then
      addon.UI.Actions.TeamContextMenu:Show(
        self,
        team
      )

      return
    end

    if button ~= "LeftButton" then
      return
    end

    local success, errorMessage =
        addon.Services.Team:Load(team.id)

    if not success then
      addon.Logger:Warn(
        errorMessage or L["UNABLE_LOAD_TEAM"]
      )

      return
    end

    addon.Settings:Set("selectedTeamID", team.id)

    addon.EventBus:Fire(
      addon.Events.TEAM_SELECTED,
      team,
      self
    )

    addon.Services.LoadoutMonitor:
        ScheduleCheck()
  end)

  frame:SetTeam(team)
  ApplyVisualState(frame)

  return frame
end

local targetLoaderFrame = CreateFrame("Frame")

targetLoaderFrame:RegisterEvent("TOOLTIP_DATA_UPDATE")

targetLoaderFrame:SetScript(
  "OnEvent",
  function(_, _, dataInstanceID)
    local npcID = PendingTargetNames[dataInstanceID]

    if not npcID then
      return
    end

    local hyperlink =
        string.format(
          "unit:Creature-0-0-0-0-%d-0000000000",
          npcID
        )

    local data =
        C_TooltipInfo.GetHyperlink(hyperlink)

    if not data then
      return
    end

    for _, line in ipairs(data.lines or {}) do
      if line.type == Enum.TooltipDataLineType.UnitName then
        local leftText = line.leftText

        if leftText and issecretvalue(leftText) then
          PendingTargetNames[dataInstanceID] = nil
          return
        end

        if leftText then
          TargetNameCache[npcID] = leftText

          PendingTargetNames[dataInstanceID] = nil

          local teamList = addon.UI and addon.UI.Views and addon.UI.Views.TeamList

          if teamList and type(teamList.Refresh) == "function" then
            teamList:Refresh()
          end

          return
        end
      end
    end
  end
)

addon.UI.Components.TeamCard = TeamCard
