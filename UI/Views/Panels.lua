local _, addon = ...

local Panels = {}

local PANEL_WIDTH = 275
local PANEL_HEIGHT = 608
local CONTENT_GAP = 5
local TAB_HEIGHT = 28

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
        PetJournal,
        "SimplePanelTemplate"
      )

  frame:SetSize(
    PANEL_WIDTH,
    PANEL_HEIGHT
  )

  local text = frame:CreateFontString(
    nil,
    "OVERLAY",
    "GameFontNormalLarge"
  )

  text:SetPoint(
    "TOP",
    frame,
    "TOP",
    0,
    -9
  )

  text:SetText("PetMatch")

  frame.Background =
      frame:CreateTexture(
        nil,
        "BACKGROUND"
      )

  frame.Background:SetPoint(
    "TOPLEFT",
    frame,
    "TOPLEFT",
    4,
    -4
  )

  frame.Background:SetPoint(
    "BOTTOMRIGHT",
    frame,
    "BOTTOMRIGHT",
    -4,
    4
  )

  frame:ClearAllPoints()
  frame:SetPoint(
    "TOPLEFT",
    PetJournal,
    "TOPRIGHT",
    0,
    2
  )

  self.Frame = frame

  self.ContentFrame =
      CreateFrame(
        "Frame",
        nil,
        frame
      )

  self.ContentFrame:SetPoint(
    "TOPLEFT",
    frame,
    "TOPLEFT",
    4,
    -4
  )

  self.ContentFrame:SetPoint(
    "BOTTOMRIGHT",
    frame,
    "BOTTOMRIGHT",
    -4,
    4
  )

  self.TeamsFrame =
      CreateFrame(
        "Frame",
        nil,
        self.ContentFrame
      )

  self.TeamsFrame:SetAllPoints(
    self.ContentFrame
  )

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

  self.OptionsList =
      addon.UI.Views.OptionsList:Create(
        self.OptionsFrame
      )

  self.OptionsList:ClearAllPoints()

  self.OptionsList:SetPoint(
    "TOPLEFT",
    self.OptionsFrame,
    "TOPLEFT",
    4,
    -26
  )

  self.OptionsList:SetPoint(
    "BOTTOMRIGHT",
    self.OptionsFrame,
    "BOTTOMRIGHT",
    -25,
    24
  )

  self.TeamListControls =
      addon.UI.Actions.TeamListControls:Create(
        self.TeamsFrame
      )

  self.TeamListControls:ClearAllPoints()
  self.TeamListControls:SetPoint(
    "TOPLEFT",
    self.TeamsFrame,
    "TOPLEFT",
    3,
    -18
  )

  self.NewFolderButton =
      self:CreateNewFolderButton(
        self.TeamsFrame
      )

  self.TeamListFrame =
      addon.UI.Views.TeamList:Create(
        self.TeamsFrame
      )

  self.TeamListFrame:ClearAllPoints()

  self.TeamListFrame:SetPoint(
    "TOPLEFT",
    self.TeamListControls,
    "BOTTOMLEFT",
    0,
    -CONTENT_GAP
  )

  self.TeamListFrame:SetPoint(
    "TOPRIGHT",
    self.TeamListControls,
    "BOTTOMRIGHT",
    0,
    -CONTENT_GAP
  )

  self.TeamListFrame:SetPoint(
    "BOTTOMLEFT",
    self.NewFolderButton,
    "TOPLEFT",
    0,
    2
  )

  self.TeamListFrame:SetPoint(
    "BOTTOMRIGHT",
    self.NewFolderButton,
    "TOPRIGHT",
    0,
    2
  )

  self:CreateTabs(frame)
  self:SelectTab("teams")

  frame:Hide()

  return frame
end

function Panels:CreateTabs(parent)
  self.Tabs = {}

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

  local optionsTab =
      CreateFrame(
        "Button",
        nil,
        parent,
        "PanelTabButtonTemplate"
      )

  optionsTab:SetText("Options")
  optionsTab:SetHeight(TAB_HEIGHT)

  optionsTab:SetPoint(
    "BOTTOMRIGHT",
    parent,
    "BOTTOMRIGHT",
    -12,
    -25
  )

  teamsTab:SetPoint(
    "RIGHT",
    optionsTab,
    "LEFT",
    -3,
    0
  )

  optionsTab:SetScript(
    "OnClick",
    function()
      self:SelectTab("options")
    end
  )

  teamsTab:SetFrameLevel(
    parent:GetFrameLevel() + 20
  )

  optionsTab:SetFrameLevel(
    parent:GetFrameLevel() + 20
  )

  self.Tabs.options = {
    button = optionsTab,
    frame = self.OptionsFrame,
  }
end

function Panels:SelectTab(tabKey)
  if not self.Tabs then
    return
  end

  for key, tab in pairs(self.Tabs) do
    local selected =
        key == tabKey

    tab.frame:SetShown(selected)

    if selected then
      PanelTemplates_SelectTab(
        tab.button
      )
    else
      PanelTemplates_DeselectTab(
        tab.button
      )
    end
  end

  self.SelectedTab = tabKey
end

function Panels:Show()
  local frame = self:Create()

  if self.TeamList
      and addon.UI.Views.TeamList.Refresh then
    addon.UI.Views.TeamList:Refresh()
  end

  frame:Show()
end

function Panels:Hide()
  if self.Frame then
    self.Frame:Hide()
  end
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
    1,
    0
  )

  self.NewFolderButton = button

  return button
end

function Panels:Refresh()
  if addon.UI.Views.TeamList.Refresh then
    addon.UI.Views.TeamList:Refresh()
  end
end

addon.UI.Views.Panels = Panels
