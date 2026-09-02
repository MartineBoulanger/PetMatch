local _, addon = ...

local Panels = {}

local PANEL_WIDTH = 275
local PANEL_HEIGHT = 606
local CONTENT_GAP = 5
local TAB_HEIGHT = 28

local function GetPetJournalCloseButton()
  if CollectionsJournal
      and CollectionsJournal.CloseButton then
    return CollectionsJournal.CloseButton
  end

  if PetJournal
      and PetJournal.CloseButton then
    return PetJournal.CloseButton
  end

  local parent =
      PetJournal
      and PetJournal:GetParent()

  if parent
      and parent.CloseButton then
    return parent.CloseButton
  end

  return _G.CollectionsJournalCloseButton
end

function Panels:BringToFront()
  if not self.Frame then
    return
  end

  self.Frame:SetFrameStrata("HIGH")
  self.Frame:SetFrameLevel(100)

  if self.CloseButton then
    self.CloseButton:SetFrameStrata(
      self.Frame:GetFrameStrata()
    )

    self.CloseButton:SetFrameLevel(
      self.Frame:GetFrameLevel() + 1000
    )
  end
end

function Panels:SendBehindCenterPanel()
  if not self.Frame then
    return
  end

  self.Frame:SetFrameStrata("LOW")
  self.Frame:SetFrameLevel(1)

  if self.CloseButton then
    self.CloseButton:SetFrameStrata(
      self.Frame:GetFrameStrata()
    )

    self.CloseButton:SetFrameLevel(
      self.Frame:GetFrameLevel() + 100
    )
  end
end

function Panels:HookCenterFrame(centerFrame)
  if not centerFrame then
    return
  end

  if centerFrame.__PetMatchLayerHooked then
    return
  end

  centerFrame.__PetMatchLayerHooked = true

  centerFrame:HookScript(
    "OnMouseDown",
    function()
      self:SendBehindCenterPanel()
    end
  )
end

function Panels:UpdateLayering()
  if not self.Frame then
    return
  end

  local centerFrame =
      GetUIPanel
      and GetUIPanel("center")
      or nil

  if centerFrame then
    self:HookCenterFrame(centerFrame)
    self:SendBehindCenterPanel()
  else
    self:BringToFront()
  end
end

function Panels:MoveCloseButton()
  if not self.Frame then
    return
  end

  local closeButton = GetPetJournalCloseButton()

  if not closeButton then
    addon.Logger:Warn(
      "PetMatch: Pet Journal close button was not found."
    )
    return
  end

  if not self.CloseButtonState then
    local points = {}

    for index = 1, closeButton:GetNumPoints() do
      local point,
      relativeTo,
      relativePoint,
      offsetX,
      offsetY =
          closeButton:GetPoint(index)

      points[#points + 1] = {
        point = point,
        relativeTo = relativeTo,
        relativePoint = relativePoint,
        offsetX = offsetX,
        offsetY = offsetY,
      }
    end

    self.CloseButtonState = {
      button = closeButton,
      parent = closeButton:GetParent(),
      points = points,
      frameStrata = closeButton:GetFrameStrata(),
      frameLevel = closeButton:GetFrameLevel(),
    }
  end

  closeButton:SetParent(
    self.Frame
  )

  closeButton:ClearAllPoints()

  closeButton:SetPoint(
    "TOPRIGHT",
    self.Frame,
    "TOPRIGHT",
    0,
    0
  )

  closeButton:SetFrameStrata(
    self.Frame:GetFrameStrata()
  )

  closeButton:SetFrameLevel(
    self.Frame:GetFrameLevel() + 1000
  )

  closeButton:Show()

  if not closeButton.__PetMatchCloseHooked then
    closeButton.__PetMatchCloseHooked = true

    closeButton:SetScript(
      "OnClick",
      function()
        self:Hide()

        if CollectionsJournal then
          HideUIPanel(
            CollectionsJournal
          )
        elseif PetJournal then
          local parent =
              PetJournal:GetParent()

          if parent then
            HideUIPanel(
              parent
            )
          else
            PetJournal:Hide()
          end
        end
      end
    )
  end

  self.CloseButton = closeButton
end

function Panels:RestoreCloseButton()
  local state = self.CloseButtonState

  if not state
      or not state.button then
    return
  end

  local closeButton = state.button

  closeButton:SetParent(
    state.parent
  )

  closeButton:ClearAllPoints()

  for _, pointData in ipairs(
    state.points or {}
  ) do
    closeButton:SetPoint(
      pointData.point,
      pointData.relativeTo,
      pointData.relativePoint,
      pointData.offsetX,
      pointData.offsetY
    )
  end

  closeButton:SetFrameStrata(
    state.frameStrata
  )

  closeButton:SetFrameLevel(
    state.frameLevel
  )

  closeButton:Show()
end

function Panels:UpdatePosition()
  if not self.Frame
      or not PetJournal then
    return
  end

  self.Frame:ClearAllPoints()

  self.Frame:SetPoint(
    "TOPLEFT",
    PetJournal,
    "TOPRIGHT",
    -6,
    0
  )
end

function Panels:Create()
  if self.Frame then
    return self.Frame
  end

  assert(
    PetJournal,
    "PetMatch: PetJournal is unavailable"
  )

  local frame =
      CreateFrame(
        "Frame",
        "PetMatchPanels",
        UIParent,
        "DefaultPanelTemplate"
      )

  frame:SetFrameStrata("HIGH")
  self.NormalFrameStrata = frame:GetFrameStrata()

  frame:EnableMouse(true)

  frame:HookScript(
    "OnMouseDown",
    function()
      self:BringToFront()
    end
  )

  frame:SetSize(
    PANEL_WIDTH,
    PANEL_HEIGHT
  )

  self.Frame = frame
  self:UpdatePosition()

  --------------------------------------------------
  -- Blizzard title
  --------------------------------------------------
  if frame.TitleContainer
      and frame.TitleContainer.TitleText then
    frame.TitleContainer.TitleText:SetText(
      "PetMatch"
    )
  elseif type(frame.SetTitle) == "function" then
    frame:SetTitle(
      "PetMatch"
    )
  end

  --------------------------------------------------
  -- Existing content frame
  --------------------------------------------------
  self.ContentFrame =
      CreateFrame(
        "Frame",
        nil,
        frame
      )

  self.ContentFrame:SetPoint(
    "TOPLEFT",
    frame.TitleContainer,
    "BOTTOMLEFT",
    0,
    -4
  )

  self.ContentFrame:SetPoint(
    "TOPRIGHT",
    frame,
    "TOPRIGHT",
    -4,
    0
  )

  self.ContentFrame:SetPoint(
    "BOTTOMLEFT",
    frame,
    "BOTTOMLEFT",
    0,
    4
  )

  self.ContentFrame:SetPoint(
    "BOTTOMRIGHT",
    frame,
    "BOTTOMRIGHT",
    -4,
    4
  )

  --------------------------------------------------
  -- Teams
  --------------------------------------------------
  self.TeamsFrame =
      CreateFrame(
        "Frame",
        nil,
        self.ContentFrame
      )

  self.TeamsFrame:SetAllPoints(
    self.ContentFrame
  )

  --------------------------------------------------
  -- Levelling Queue
  --------------------------------------------------
  self.LevellingQueueFrame =
      CreateFrame(
        "Frame",
        nil,
        self.ContentFrame
      )

  self.LevellingQueueFrame:SetAllPoints(
    self.ContentFrame
  )

  self.LevellingQueueFrame:Hide()

  --------------------------------------------------
  -- Options
  --------------------------------------------------
  self.OptionsFrame =
      CreateFrame(
        "Frame",
        nil,
        self.ContentFrame
      )

  self.OptionsFrame:SetAllPoints(
    self.ContentFrame
  )

  self.OptionsFrame:Hide()

  --------------------------------------------------
  -- Options marble background
  --------------------------------------------------
  self.OptionsBackground =
      CreateFrame(
        "Frame",
        nil,
        self.OptionsFrame,
        "BackdropTemplate"
      )

  self.OptionsBackground:SetBackdrop({
    bgFile = "Interface\\FrameGeneral\\UI-Background-Marble",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 128,
    edgeSize = 12,
    insets = {
      left = 3,
      right = 3,
      top = 3,
      bottom = 3,
    },
  })

  self.OptionsBackground:SetBackdropColor(
    0.55,
    0.55,
    0.55,
    0.95
  )

  self.OptionsBackground:SetBackdropBorderColor(
    0.35,
    0.35,
    0.35,
    1
  )

  self.OptionsBackground:SetPoint(
    "TOPLEFT",
    self.OptionsFrame,
    "TOPLEFT",
    -22,
    2
  )

  self.OptionsBackground:SetPoint(
    "BOTTOMRIGHT",
    self.OptionsFrame,
    "BOTTOMRIGHT",
    -20,
    0
  )

  --------------------------------------------------
  -- Options list
  --------------------------------------------------
  self.OptionsList =
      addon.UI.Views.OptionsList:Create(
        self.OptionsBackground
      )

  self.OptionsList:ClearAllPoints()

  self.OptionsList:SetPoint(
    "TOPLEFT",
    self.OptionsBackground,
    "TOPLEFT",
    3,
    -3
  )

  self.OptionsList:SetPoint(
    "BOTTOMRIGHT",
    self.OptionsBackground,
    "BOTTOMRIGHT",
    -3,
    3
  )

  --------------------------------------------------
  -- Levelling Queue
  --------------------------------------------------
  self.LevellingQueuePanel =
      addon.UI.Views.LevellingQueuePanel:Create(
        self.LevellingQueueFrame
      )

  self.LevellingQueuePanel:SetAllPoints()
  self.LevellingQueuePanel:SetPoint(
    "TOPLEFT",
    self.LevellingQueueFrame,
    "TOPLEFT",
    -2,
    -2
  )

  self.LevellingQueuePanel:SetPoint(
    "BOTTOMRIGHT",
    self.LevellingQueueFrame,
    "BOTTOMRIGHT",
    0,
    0
  )

  --------------------------------------------------
  -- Team controls
  --------------------------------------------------
  self.TeamListControls =
      addon.UI.Actions.TeamListControls:Create(
        self.TeamsFrame
      )

  self.TeamListControls:ClearAllPoints()
  self.TeamListControls:SetPoint(
    "TOPLEFT",
    self.TeamsFrame,
    "TOPLEFT",
    -20,
    5
  )

  --------------------------------------------------
  -- New folder
  --------------------------------------------------
  self.NewFolderButton =
      self:CreateNewFolderButton(
        self.TeamsFrame
      )

  --------------------------------------------------
  -- Open PML Logs Addon button
  --------------------------------------------------
  self.PMLButton =
      self:CreatePMLButton(
        self.TeamsFrame
      )


  self.TeamListBackground =
      CreateFrame(
        "Frame",
        nil,
        self.TeamsFrame,
        "BackdropTemplate"
      )

  --------------------------------------------------
  -- Team list background
  --------------------------------------------------
  self.TeamListBackground:SetBackdrop({
    bgFile = "Interface\\FrameGeneral\\UI-Background-Marble",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 128,
    edgeSize = 12,
    insets = {
      left = 3,
      right = 3,
      top = 3,
      bottom = 3,
    },
  })

  self.TeamListBackground:SetBackdropColor(
    0.55,
    0.55,
    0.55,
    0.95
  )

  self.TeamListBackground:SetBackdropBorderColor(
    0.35,
    0.35,
    0.35,
    1
  )

  self.TeamListBackground:SetPoint(
    "TOPLEFT",
    self.TeamListControls,
    "BOTTOMLEFT",
    0,
    -CONTENT_GAP
  )

  self.TeamListBackground:SetPoint(
    "TOPRIGHT",
    self.TeamListControls,
    "BOTTOMRIGHT",
    0,
    -CONTENT_GAP
  )

  self.TeamListBackground:SetPoint(
    "BOTTOMLEFT",
    self.NewFolderButton,
    "TOPLEFT",
    0,
    -1
  )

  self.TeamListBackground:SetPoint(
    "BOTTOMRIGHT",
    self.NewFolderButton,
    "TOPRIGHT",
    0,
    -1
  )

  --------------------------------------------------
  -- Team list
  --------------------------------------------------
  self.TeamListFrame =
      addon.UI.Views.TeamList:Create(
        self.TeamsFrame
      )

  self.TeamListFrame:ClearAllPoints()

  self.TeamListFrame:SetPoint(
    "TOPLEFT",
    self.TeamListBackground,
    "TOPLEFT",
    4,
    -4
  )

  self.TeamListFrame:SetPoint(
    "TOPRIGHT",
    self.TeamListBackground,
    "TOPRIGHT",
    -4,
    -4
  )

  self.TeamListFrame:SetPoint(
    "BOTTOMLEFT",
    self.TeamListBackground,
    "BOTTOMLEFT",
    4,
    4
  )

  self.TeamListFrame:SetPoint(
    "BOTTOMRIGHT",
    self.TeamListBackground,
    "BOTTOMRIGHT",
    -4,
    4
  )

  --------------------------------------------------
  -- Tabs
  --------------------------------------------------
  self:CreateTabs(frame)
  self:SelectTab("teams")

  frame:HookScript(
    "OnShow",
    function()
      self:MoveCloseButton()
    end
  )

  frame:HookScript(
    "OnHide",
    function()
      self:RestoreCloseButton()
    end
  )

  frame:Hide()

  return frame
end

function Panels:CreateTabs(parent)
  self.Tabs = {}

  --------------------------------------------------
  -- Teams
  --------------------------------------------------
  local teamsTab =
      CreateFrame(
        "Button",
        nil,
        parent,
        "PanelTabButtonTemplate"
      )

  teamsTab:SetText("Teams")
  teamsTab:SetHeight(TAB_HEIGHT)

  teamsTab:SetScript(
    "OnClick",
    function()
      self:SelectTab("teams")
    end
  )

  self.Tabs.teams = {
    button = teamsTab,
    frame = self.TeamsFrame,
  }

  --------------------------------------------------
  -- Levelling Queue
  --------------------------------------------------
  local levellingTab =
      CreateFrame(
        "Button",
        nil,
        parent,
        "PanelTabButtonTemplate"
      )

  levellingTab:SetText("Levelling")
  levellingTab:SetHeight(TAB_HEIGHT)

  levellingTab:SetScript(
    "OnClick",
    function()
      self:SelectTab(
        "levelling"
      )
    end
  )

  self.Tabs.levelling = {
    button = levellingTab,
    frame = self.LevellingQueueFrame,
  }

  --------------------------------------------------
  -- Options
  --------------------------------------------------
  local optionsTab =
      CreateFrame(
        "Button",
        nil,
        parent,
        "PanelTabButtonTemplate"
      )

  optionsTab:SetText("Options")
  optionsTab:SetHeight(TAB_HEIGHT)

  optionsTab:SetScript(
    "OnClick",
    function()
      self:SelectTab(
        "options"
      )
    end
  )

  self.Tabs.options = {
    button = optionsTab,
    frame = self.OptionsFrame,
  }

  --------------------------------------------------
  -- Position
  --------------------------------------------------
  optionsTab:SetPoint(
    "BOTTOMRIGHT",
    parent,
    "BOTTOMRIGHT",
    -12,
    -25
  )

  levellingTab:SetPoint(
    "RIGHT",
    optionsTab,
    "LEFT",
    -3,
    0
  )

  teamsTab:SetPoint(
    "RIGHT",
    levellingTab,
    "LEFT",
    -3,
    0
  )

  --------------------------------------------------
  -- Frame levels
  --------------------------------------------------
  local tabLevel = parent:GetFrameLevel() + 20

  teamsTab:SetFrameLevel(tabLevel)
  levellingTab:SetFrameLevel(tabLevel)
  optionsTab:SetFrameLevel(tabLevel)
end

function Panels:SelectTab(tabKey)
  if not self.Tabs then
    return
  end

  for key, tab in pairs(self.Tabs) do
    local selected = key == tabKey
    tab.frame:SetShown(selected)

    if selected then
      PanelTemplates_SelectTab(tab.button)
    else
      PanelTemplates_DeselectTab(tab.button)
    end
  end

  self.SelectedTab = tabKey

  if tabKey == "levelling"
      and addon.UI.Views.LevellingQueuePanel
      and addon.UI.Views.LevellingQueuePanel.Refresh then
    addon.UI.Views.LevellingQueuePanel:Refresh()
  end
end

function Panels:Show()
  local frame = self:Create()

  if self.TeamList
      and addon.UI.Views.TeamList.Refresh then
    addon.UI.Views.TeamList:Refresh()
  end

  frame:Show()
  self:MoveCloseButton()
  self:UpdateLayering()
end

function Panels:Hide()
  if not self.Frame then
    return
  end

  self:RestoreCloseButton()
  self.Frame:Hide()
end

function Panels:CreateNewFolderButton(parent)
  local button =
      addon.UI.Base.Button:Create(
        parent,
        {
          text = "New Folder",
          width = 120,
          height = 22,

          onClick = function()
            addon.UI.Dialogs.FolderDialog:
                ShowCreate()
          end,
        }
      )

  button:ClearAllPoints()

  button:SetPoint(
    "BOTTOMLEFT",
    parent,
    "BOTTOMLEFT",
    -20,
    0
  )

  self.NewFolderButton = button

  return button
end

function Panels:CreatePMLButton(parent)
  local addonName = "PetMastersLeagueLogs"

  local loaded = C_AddOns.IsAddOnLoaded(addonName)

  if not loaded then
    return nil
  end

  local button =
      addon.UI.Base.Button:Create(
        parent,
        {
          text = "Open PML Logs",
          width = 120,
          height = 22,

          onClick = function()
            local pml = _G.PetMastersLeagueLogs
            if pml and pml.Toggle then
              pml.Toggle()
            end
          end,
        }
      )

  button:ClearAllPoints()

  button:SetPoint(
    "BOTTOMRIGHT",
    parent,
    "BOTTOMRIGHT",
    0,
    0
  )

  self.AddonButton = button

  return button
end

function Panels:Refresh()
  if addon.UI.Views.TeamList.Refresh then
    addon.UI.Views.TeamList:Refresh()
  end
end

addon.UI.Views.Panels = Panels
