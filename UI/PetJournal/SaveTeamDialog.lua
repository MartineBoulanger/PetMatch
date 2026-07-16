local addonName, addon = ...

addon.UI = addon.UI or {}
addon.UI.Views = addon.UI.Views or {}

local SaveTeamDialog = {}

local DIALOG_WIDTH = 320
local DIALOG_HEIGHT = 145

function SaveTeamDialog:Create()
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

  frame:ClearAllPoints()
  frame:SetPoint(
    "CENTER",
    UIParent,
    "CENTER",
    0,
    0
  )

  self.Frame = frame

  self.Title =
      addon.UI.Components.Label:Create(
        frame,
        {
          text = "Save Current Team",
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

  self.NameLabel =
      addon.UI.Components.Label:Create(
        frame,
        {
          text = "Team name",
          width = DIALOG_WIDTH - 24,
          justify = "LEFT",
        }
      )

  self.NameLabel:SetPoint(
    "TOPLEFT",
    self.Title,
    "BOTTOMLEFT",
    0,
    -12
  )

  self.NameInput =
      CreateFrame(
        "EditBox",
        nil,
        frame,
        "InputBoxTemplate"
      )

  self.NameInput:SetSize(
    DIALOG_WIDTH - 30,
    28
  )

  self.NameInput:SetPoint(
    "TOPLEFT",
    self.NameLabel,
    "BOTTOMLEFT",
    4,
    -4
  )

  self.NameInput:SetAutoFocus(false)
  self.NameInput:SetMaxLetters(80)

  self.SaveButton =
      addon.UI.Components.Button:Create(
        frame,
        {
          text = "Save",
          width = 100,

          onClick = function()
            self:Save()
          end,
        }
      )

  self.SaveButton:SetPoint(
    "BOTTOMRIGHT",
    frame,
    "BOTTOMRIGHT",
    -12,
    12
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
    "RIGHT",
    self.SaveButton,
    "LEFT",
    -8,
    0
  )

  self.NameInput:SetScript(
    "OnEnterPressed",
    function()
      self:Save()
    end
  )

  self.NameInput:SetScript(
    "OnEscapePressed",
    function()
      self:Hide()
    end
  )

  frame:Hide()

  return frame
end

function SaveTeamDialog:Show()
  local frame = self:Create()

  self.NameInput:SetText("")
  self.NameInput:SetFocus()
  self.NameInput:HighlightText()

  frame:Show()
end

function SaveTeamDialog:Hide()
  if not self.Frame then
    return
  end

  self.NameInput:ClearFocus()
  self.Frame:Hide()
end

function SaveTeamDialog:Save()
  local name =
      addon.Utils:Trim(
        self.NameInput:GetText() or ""
      )

  local folderID =
      addon.Services.Folder:GetSelectedStorageFolderID()

  local team, errorMessage =
      addon.Services.Team:CreateFromBattleSlots(
        name,
        folderID
      )

  if not team then
    addon.Logger:Warn(
      errorMessage or "Unable to save team"
    )

    self.NameInput:SetFocus()
    self.NameInput:HighlightText()

    return
  end

  addon.Services.Team:SetActive(
    team.id
  )

  local destinationName = "Unsorted"

  if folderID then
    local folder =
        addon.Services.Folder:Get(folderID)

    if folder then
      destinationName = folder.name
    end
  end

  addon.Logger:Info(
    "Saved team:",
    team.name,
    "in",
    destinationName
  )

  self:Hide()
end

addon.UI.Views.SaveTeamDialog = SaveTeamDialog
