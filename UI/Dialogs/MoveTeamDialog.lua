local _, addon = ...

local L = addon.L
local MoveTeamDialog = {}

local DIALOG_WIDTH = 320
local LIST_HEIGHT = 270

local BUTTON_HEIGHT = 28
local BUTTON_SPACING = 4

local CONTENT_MARGIN = {
  left = -12,
  right = 12,
  top = 4,
  bottom = 8,
}

local CONTENT_PADDING = 12

local dialogInstance

--------------------------------------------------
-- Create
--------------------------------------------------
function MoveTeamDialog:Create()
  if dialogInstance then
    return dialogInstance
  end

  local dialog =
      addon.UI.Base.Dialog:Create({
        name = "PetMatchMoveTeamDialog",
        title = L["MOVE_TEAM"],
        width = DIALOG_WIDTH,
        contentMargin = CONTENT_MARGIN,
        padding = CONTENT_PADDING,
        bottomSpacing = 0,
        onCancel =
            function()
              self.Team = nil
              return true
            end,
        onClose = function() self.Team = nil end,
      })

  local content = dialog:GetContentFrame()

  --------------------------------------------------
  -- Description
  --------------------------------------------------
  self.Description =
      addon.UI.Base.Label:Create(
        content,
        {
          text = L["SELECT_TEAM_MOVE1"] .. L["SELECT_TEAM_MOVE2"],
          justify = "LEFT",
          color = addon.UI.Theme.Colors.Text,
        }
      )

  self.Description:SetPoint(
    "TOPLEFT",
    content,
    "TOPLEFT",
    0,
    0
  )

  self.Description:SetPoint(
    "TOPRIGHT",
    content,
    "TOPRIGHT",
    0,
    0
  )

  --------------------------------------------------
  -- Folder list
  --------------------------------------------------
  self.ScrollFrame =
      addon.UI.Components.ScrollBox:Create(
        content,
        {
          width = DIALOG_WIDTH - 70,
          height = LIST_HEIGHT,
        }
      )

  self.ScrollFrame:SetPoint(
    "TOPLEFT",
    self.Description,
    "BOTTOMLEFT",
    0,
    -12
  )

  self.ScrollFrame:SetPoint(
    "TOPRIGHT",
    content,
    "TOPRIGHT",
    -16,
    0
  )

  self.ScrollFrame.Content:SetWidth(DIALOG_WIDTH - 70)

  --------------------------------------------------
  -- Footer
  --------------------------------------------------
  self.CancelButton =
      dialog:AddCancelButton({
        text = L["CANCEL"],
        width = 100,
      })

  --------------------------------------------------
  -- State
  --------------------------------------------------
  self.Dialog = dialog
  self.Frame = dialog:GetFrame()
  self.Team = nil
  self.FolderButtons = {}

  --------------------------------------------------
  -- Cleanup
  --------------------------------------------------
  self.Frame:HookScript(
    "OnHide",
    function()
      self.Team = nil
    end
  )

  --------------------------------------------------
  -- Layout
  --------------------------------------------------
  dialog:RefreshLayout()
  dialogInstance = dialog

  return dialog
end

--------------------------------------------------
-- Clear folder buttons
--------------------------------------------------
function MoveTeamDialog:ClearFolderButtons()
  for _, button in ipairs(
    self.FolderButtons
    or {}
  ) do
    button:Hide()
    button:SetParent(nil)
  end

  self.FolderButtons = {}
end

--------------------------------------------------
-- Create folder button
--------------------------------------------------
function MoveTeamDialog:CreateFolderButton(text, folderID, index)
  local content = self.ScrollFrame.Content

  local button =
      addon.UI.Base.Button:Create(
        content,
        {
          text = text,
          height = BUTTON_HEIGHT,
          onClick = function() self:MoveToFolder(folderID) end,
        }
      )

  --------------------------------------------------
  -- Let the buttons follow the available width
  -- instead of using a hard-coded 250px width.
  --------------------------------------------------
  button:SetPoint(
    "TOPLEFT",
    content,
    "TOPLEFT",
    4,
    -4 - ((index - 1) * (BUTTON_HEIGHT + BUTTON_SPACING))
  )

  button:SetPoint(
    "TOPRIGHT",
    content,
    "TOPRIGHT",
    -4,
    -4 - ((index - 1) * (BUTTON_HEIGHT + BUTTON_SPACING))
  )

  self.FolderButtons[#self.FolderButtons + 1] = button
end

--------------------------------------------------
-- Refresh folders
--------------------------------------------------
function MoveTeamDialog:RefreshFolders()
  if not self.Frame then
    return
  end

  self:ClearFolderButtons()

  local index = 1

  --------------------------------------------------
  -- Unsorted
  --------------------------------------------------
  self:CreateFolderButton(
    L["UNSORTED"],
    nil,
    index
  )

  index = index + 1

  --------------------------------------------------
  -- Folders
  --------------------------------------------------
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

  --------------------------------------------------
  -- Scroll content height
  --------------------------------------------------
  local buttonCount = index - 1

  local contentHeight =
      8 + (buttonCount * BUTTON_HEIGHT)
      + (math.max(0, buttonCount - 1) * BUTTON_SPACING)

  self.ScrollFrame.Content:SetHeight(
    math.max(1, contentHeight)
  )
end

--------------------------------------------------
-- Show
--------------------------------------------------
function MoveTeamDialog:Show(team)
  if not team then
    addon.Logger:Warn(L["SELECT_TEAM"])
    return
  end

  local dialog = self:Create()

  self.Team = team

  dialog:SetTitle(L["MOVE_TEAM"])

  self.Description:SetText(
    L["SELECT_TEAM_MOVE1"]
    .. "\""
    .. (team.name or L["UNNAMED_TEAM"])
    .. "\""
    .. L["SELECT_TEAM_MOVE2"]
  )

  self:RefreshFolders()

  dialog:Show()
  dialog:RefreshLayout()

  self.Frame:Raise()
end

--------------------------------------------------
-- Hide
--------------------------------------------------
function MoveTeamDialog:Hide()
  if not dialogInstance then
    return
  end

  dialogInstance:Hide()
  self.Team = nil
end

--------------------------------------------------
-- Move team
--------------------------------------------------
function MoveTeamDialog:MoveToFolder(folderID)
  local team = self.Team

  if not team then
    return
  end

  local movedTeam, errorMessage = addon.Services.Team:MoveToFolder(team.id, folderID)

  if not movedTeam then
    addon.Logger:Warn(
      errorMessage
      or L["UNABLE_MOVE_TEAM"]
    )
    return
  end

  local destinationKey =
      folderID
      or addon.Services.Folder.UNSORTED

  addon.Services.Folder:Select(destinationKey)

  addon.EventBus:Fire(
    addon.Events.TEAM_SELECTED,
    nil,
    nil
  )

  self:Hide()
end

--------------------------------------------------
-- Register
--------------------------------------------------
addon.UI.Dialogs.MoveTeamDialog = MoveTeamDialog
