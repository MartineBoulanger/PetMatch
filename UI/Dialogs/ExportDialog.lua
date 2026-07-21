local addonName, addon = ...

addon.UI = addon.UI or {}
addon.UI.Views = addon.UI.Views or {}

local ExportDialog = {}

local DIALOG_WIDTH = 320
local DIALOG_HEIGHT = 340

function ExportDialog:Create()
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

  frame:SetPoint(
    "CENTER",
    UIParent,
    "CENTER",
    0,
    0
  )

  frame:SetFrameStrata("DIALOG")
  frame:SetClampedToScreen(true)
  frame:EnableMouse(true)

  self.Frame = frame

  self.Title =
      addon.UI.Components.Label:Create(
        frame,
        {
          text = "Export Team",
          font = addon.UI.Theme.Fonts.Header,
          width = DIALOG_WIDTH - 24,
          justify = "CENTER",
          color = addon.UI.Theme.Colors.Header,
        }
      )

  self.Title:SetPoint(
    "TOPLEFT",
    frame,
    "TOPLEFT",
    12,
    -12
  )

  self.Description =
      addon.UI.Components.Label:Create(
        frame,
        {
          text =
          "Copy this Rematch string and share it with another player.",
          fontObject = "GameFontHighlightSmall",
        }
      )

  self.Description:SetPoint(
    "TOPLEFT",
    self.Title,
    "BOTTOMLEFT",
    0,
    -8
  )

  self.Description:SetPoint(
    "RIGHT",
    frame,
    "RIGHT",
    -16,
    0
  )

  self.Description:SetJustifyH("LEFT")

  self.InputBackground =
      addon.UI.Components.Panel:Create(
        frame,
        {
          width = DIALOG_WIDTH - 23,
          height = 220,
        }
      )

  self.InputBackground:SetPoint(
    "TOPLEFT",
    self.Description,
    "BOTTOMLEFT",
    0,
    -12
  )

  self.ScrollFrame =
      CreateFrame(
        "ScrollFrame",
        nil,
        self.InputBackground,
        "UIPanelScrollFrameTemplate"
      )

  self.ScrollFrame:SetPoint(
    "TOPLEFT",
    self.InputBackground,
    "TOPLEFT",
    8,
    -8
  )

  self.ScrollFrame:SetPoint(
    "BOTTOMRIGHT",
    self.InputBackground,
    "BOTTOMRIGHT",
    -28,
    8
  )

  self.Input =
      CreateFrame(
        "EditBox",
        nil,
        self.ScrollFrame
      )

  self.Input:SetMultiLine(true)
  self.Input:SetAutoFocus(false)
  self.Input:SetFontObject(
    "ChatFontNormal"
  )

  self.Input:SetWidth(440)
  self.Input:SetTextInsets(
    4,
    4,
    4,
    4
  )

  self.Input:SetScript(
    "OnEscapePressed",
    function()
      self:Hide()
    end
  )

  self.Input:SetHeight(200)

  self.Input:SetScript(
    "OnTextChanged",
    function()
      self.ScrollFrame:
          UpdateScrollChildRect()
    end
  )

  self.ScrollFrame:SetScrollChild(
    self.Input
  )

  self.CopyButton =
      addon.UI.Components.Button:Create(
        frame,
        {
          text = "Select All",
          width = 90,
          height = 24,

          onClick = function()
            self.Input:SetFocus()
            self.Input:HighlightText()
          end,
        }
      )

  self.CopyButton:SetPoint(
    "BOTTOMLEFT",
    frame,
    "BOTTOMLEFT",
    16,
    16
  )

  self.CloseButton =
      addon.UI.Components.Button:Create(
        frame,
        {
          text = "Close",
          width = 80,
          height = 24,

          onClick = function()
            self:Hide()
          end,
        }
      )

  self.CloseButton:SetPoint(
    "BOTTOMRIGHT",
    frame,
    "BOTTOMRIGHT",
    -16,
    16
  )

  frame:Hide()

  return frame
end

function ExportDialog:Show(team)
  local frame = self:Create()

  team =
      team
      or addon.Services.Team:GetSelected()

  if not team then
    addon.Logger:Warn(
      "Select a team first"
    )

    return
  end

  local value, errorMessage =
      addon.Services.ImportExport:
      ExportRematchTeam(team)

  if not value then
    addon.Logger:Warn(
      errorMessage
      or "Unable to export team"
    )

    return
  end

  self.Input:SetText(value)
  self.Input:SetCursorPosition(0)

  frame:Show()
  frame:Raise()

  self.Input:SetFocus()
  self.Input:HighlightText()
end

function ExportDialog:ShowAll()
  self:Create()

  local exportString, errorMessage =
      addon.Services.ImportExport:ExportAll()

  if not exportString then
    addon.Logger:Warn(
      errorMessage
      or "Unable to export folders and teams"
    )

    return
  end

  self.Title:SetText(
    "Export All Folders and Teams"
  )


  self.Input:SetText(exportString)
  self.Input:HighlightText()

  self.Frame:Show()
  self.Input:SetFocus()
end

function ExportDialog:ShowFolder(
    folderKey
)
  if not folderKey then
    return
  end

  self:Create()

  local exportString, errorMessage =
      addon.Services.ImportExport:ExportFolder(folderKey)

  if not exportString then
    addon.Logger:Warn(
      errorMessage
      or "Unable to export folder"
    )

    return
  end

  local folder =
      addon.Services.Folder:Get(folderKey)

  local folderName =
      folder
      and folder.name
      or "Folder"

  self.Title:SetText(
    "Export Folder: " .. folderName
  )

  self.Input:SetText(exportString)
  self.Input:HighlightText()

  self.Frame:Show()
  self.Input:SetFocus()
end

function ExportDialog:Hide()
  if not self.Frame then
    return
  end

  self.Input:ClearFocus()
  self.Input:HighlightText(0, 0)
  self.Frame:Hide()
end

addon.UI.Views.ExportDialog = ExportDialog
