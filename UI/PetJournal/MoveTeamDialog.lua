local addonName, addon = ...

addon.UI = addon.UI or {}
addon.UI.Views = addon.UI.Views or {}

local MoveTeamDialog = {}

local DIALOG_WIDTH = 300
local DIALOG_HEIGHT = 360

local BUTTON_WIDTH = 250
local BUTTON_HEIGHT = 28
local BUTTON_SPACING = 4

function MoveTeamDialog:Create()
  if self.Frame then
    return self.Frame
  end

  local frame =
      addon.UI.Components.Panel:Create(
        UIParent,
        {
          width = DIALOG_WIDTH,
          height = DIALOG_HEIGHT,
        }
      )

  frame:SetFrameStrata("DIALOG")
  frame:SetClampedToScreen(true)
  frame:EnableMouse(true)

  frame:ClearAllPoints()
  frame:SetPoint(
    "CENTER",
    UIParent,
    "CENTER",
    0,
    0
  )

  self.Frame = frame
  self.Team = nil
  self.FolderButtons = {}

  self.Title =
      addon.UI.Components.Label:Create(
        frame,
        {
          text = "Move Team",
          font = addon.UI.Theme.Fonts.Header,
          width = DIALOG_WIDTH - 24,
          justify = "CENTER",
          color = addon.UI.Theme.Colors.Header
        }
      )

  self.Title:SetPoint(
    "TOPLEFT",
    frame,
    "TOPLEFT",
    12,
    -12
  )

  self.ScrollFrame =
      addon.UI.Components.ScrollBox:Create(
        frame,
        {
          width = DIALOG_WIDTH - 40,
          height = 270,
        }
      )

  self.ScrollFrame:SetPoint(
    "TOPLEFT",
    self.Title,
    "BOTTOMLEFT",
    0,
    -12
  )

  self.ScrollFrame.Content:SetWidth(
    DIALOG_WIDTH - 52
  )

  self.CancelButton =
      addon.UI.Components.Button:Create(
        frame,
        {
          text = "Cancel",
          width = 100,

          onClick = function()
            self:Hide()
          end,
        }
      )

  self.CancelButton:SetPoint(
    "BOTTOMRIGHT",
    frame,
    "BOTTOMRIGHT",
    -12,
    12
  )

  frame:Hide()

  return frame
end

function MoveTeamDialog:ClearFolderButtons()
  for _, button in ipairs(
    self.FolderButtons or {}
  ) do
    button:Hide()
    button:SetParent(nil)
  end

  self.FolderButtons = {}
end

function MoveTeamDialog:CreateFolderButton(
    text,
    folderID,
    index
)
  local button =
      addon.UI.Components.Button:Create(
        self.ScrollFrame.Content,
        {
          text = text,
          width = BUTTON_WIDTH,
          height = BUTTON_HEIGHT,

          onClick = function()
            self:MoveToFolder(folderID)
          end,
        }
      )

  button:SetPoint(
    "TOPLEFT",
    self.ScrollFrame.Content,
    "TOPLEFT",
    4,
    -4 - ((index - 1)
      * (BUTTON_HEIGHT + BUTTON_SPACING))
  )

  table.insert(
    self.FolderButtons,
    button
  )
end

function MoveTeamDialog:RefreshFolders()
  if not self.Frame then
    return
  end

  self:ClearFolderButtons()

  local index = 1

  self:CreateFolderButton(
    "Unsorted",
    nil,
    index
  )

  index = index + 1

  for _, folder in ipairs(
    addon.Services.Folder:GetSortedFolders()
  ) do
    self:CreateFolderButton(
      folder.name,
      folder.id,
      index
    )

    index = index + 1
  end

  self.ScrollFrame.Content:SetHeight(
    math.max(
      1,
      8 + ((index - 1)
        * (BUTTON_HEIGHT + BUTTON_SPACING))
    )
  )
end

function MoveTeamDialog:Show(team)
  if not team then
    addon.Logger:Warn(
      "Select a team first"
    )

    return
  end

  local frame = self:Create()

  self.Team = team

  self.Title:SetText(
    "Move team: " .. (team.name or "Unnamed Team")
  )

  self:RefreshFolders()

  frame:Show()
end

function MoveTeamDialog:Hide()
  if not self.Frame then
    return
  end

  self.Frame:Hide()
  self.Team = nil
end

function MoveTeamDialog:MoveToFolder(folderID)
  local team = self.Team

  if not team then
    return
  end

  local movedTeam, errorMessage =
      addon.Services.Team:MoveToFolder(
        team.id,
        folderID
      )

  if not movedTeam then
    addon.Logger:Warn(
      errorMessage or "Unable to move team"
    )

    return
  end

  local destinationKey =
      folderID
      or addon.Services.Folder.UNSORTED

  addon.Services.Folder:Select(
    destinationKey
  )

  local destinationName = "Unsorted"

  if folderID then
    local folder =
        addon.Services.Folder:Get(folderID)

    destinationName =
        folder
        and folder.name
        or "Unknown Folder"
  end

  addon.Logger:Info(
    "Moved team:",
    movedTeam.name,
    "to",
    destinationName
  )

  -- Het detailpaneel leegmaken, omdat de TeamList
  -- na de folderwissel opnieuw wordt opgebouwd.
  addon.EventBus:Fire(
    addon.Events.TEAM_SELECTED,
    nil,
    nil
  )

  self:Hide()
end

addon.UI.Views.MoveTeamDialog = MoveTeamDialog
