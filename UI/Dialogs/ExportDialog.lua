local _, addon = ...

local ExportDialog = {}

local DIALOG_WIDTH = 420
local INPUT_HEIGHT = 220

local CONTENT_MARGIN = {
  left = -12,
  right = 12,
  top = 4,
  bottom = 8,
}

local CONTENT_PADDING = 14

local dialogInstance

--------------------------------------------------
-- State
--------------------------------------------------
function ExportDialog:ClearState()
  if self.Input then
    self.Input:ClearFocus()
    self.Input:HighlightText(0, 0)
  end
end

--------------------------------------------------
-- Select all
--------------------------------------------------
function ExportDialog:SelectAll()
  if not self.Input then
    return
  end

  self.Input:SetFocus()
  self.Input:HighlightText()
end

--------------------------------------------------
-- Set export value
--------------------------------------------------
function ExportDialog:SetValue(value)
  if not self.Input then
    return
  end

  self.Input:SetText(
    value or ""
  )

  self.Input:SetCursorPosition(0)

  if self.ScrollFrame
      and type(
        self.ScrollFrame.UpdateScrollChildRect
      ) == "function" then
    self.ScrollFrame:
        UpdateScrollChildRect()
  end
end

--------------------------------------------------
-- Create content
--------------------------------------------------
function ExportDialog:CreateContent(dialog)
  local content = dialog:GetContentFrame()

  --------------------------------------------------
  -- Description
  --------------------------------------------------
  self.Description =
      addon.UI.Base.Label:Create(
        content,
        {
          text = "Copy this Rematch string "
              .. "and share it with another player.",
          fontObject = "GameFontHighlightSmall",
          justify = "LEFT",
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

  self.Description:SetJustifyH("LEFT")

  --------------------------------------------------
  -- Input background
  --------------------------------------------------
  self.InputBackground =
      CreateFrame(
        "Frame",
        nil,
        content,
        "BackdropTemplate"
      )

  self.InputBackground:SetPoint(
    "TOPLEFT",
    self.Description,
    "BOTTOMLEFT",
    -2,
    -10
  )

  self.InputBackground:SetPoint(
    "TOPRIGHT",
    self.Description,
    "BOTTOMRIGHT",
    2,
    -10
  )

  self.InputBackground:SetHeight(INPUT_HEIGHT)
  self.InputBackground:SetBackdrop({
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

  self.InputBackground:SetBackdropColor(
    0.48,
    0.48,
    0.48,
    0.55
  )

  self.InputBackground:SetBackdropBorderColor(
    0.35,
    0.35,
    0.35,
    1
  )

  --------------------------------------------------
  -- Scroll frame
  --------------------------------------------------
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
    -26,
    8
  )

  --------------------------------------------------
  -- Export text input
  --------------------------------------------------
  self.Input =
      CreateFrame(
        "EditBox",
        nil,
        self.ScrollFrame
      )

  self.Input:SetMultiLine(true)
  self.Input:SetAutoFocus(false)
  self.Input:SetMaxLetters(0)
  self.Input:SetFontObject("ChatFontNormal")
  self.Input:SetWidth(DIALOG_WIDTH - 88)

  self.Input:SetTextInsets(
    4,
    4,
    4,
    4
  )

  self.Input:SetScript(
    "OnEscapePressed",
    function()
      dialog:Cancel()
    end
  )

  self.Input:SetScript(
    "OnTextChanged",
    function()
      if self.ScrollFrame
          and type(self.ScrollFrame.UpdateScrollChildRect) == "function" then
        self.ScrollFrame:UpdateScrollChildRect()
      end
    end
  )

  self.Input:SetHeight(INPUT_HEIGHT - 20)
  self.ScrollFrame:SetScrollChild(self.Input)
end

--------------------------------------------------
-- Create dialog
--------------------------------------------------
function ExportDialog:Create()
  if dialogInstance then
    return dialogInstance
  end

  local dialog =
      addon.UI.Base.Dialog:Create({
        name = "PetMatchExportDialog",
        title = "Export Team",
        width = DIALOG_WIDTH,
        contentMargin = CONTENT_MARGIN,
        padding = CONTENT_PADDING,
        bottomSpacing = 0,
        onCancel =
            function()
              self:ClearState()
              return true
            end,
        onClose = function() self:ClearState() end,
      })

  self:CreateContent(dialog)

  --------------------------------------------------
  -- Footer buttons
  --------------------------------------------------
  self.CloseButton = dialog:AddCancelButton({ text = "Cancel", width = 80, })

  self.CopyButton =
      dialog:AddFooterButton({
        text = "Select All",
        width = 90,
        onClick = function() self:SelectAll() end,
      })

  dialogInstance = dialog
  self.Dialog = dialog
  self.Frame = dialog:GetFrame()

  dialog:RefreshLayout()

  return dialog
end

--------------------------------------------------
-- Show a team
--------------------------------------------------
function ExportDialog:Show(team)
  local dialog = self:Create()

  team = team or addon.Services.Team:GetSelected()

  if not team then
    addon.Logger:Warn("Select a team first")
    return
  end

  local value,
  errorMessage =
      addon.Services.ImportExport:
      ExportRematchTeam(
        team
      )

  if not value then
    addon.Logger:Warn(
      errorMessage
      or "Unable to export team"
    )
    return
  end

  dialog:SetTitle("Export Team")

  self.Description:SetText(
    "Copy this Rematch string "
    .. "and share it with another player."
  )

  self:SetValue(value)

  dialog:Show()
  dialog:RefreshLayout()

  self:SelectAll()
end

--------------------------------------------------
-- Show all folders and teams
--------------------------------------------------
function ExportDialog:ShowAll()
  local dialog = self:Create()
  local exportString, errorMessage = addon.Services.ImportExport:ExportAll()

  if not exportString then
    addon.Logger:Warn(
      errorMessage
      or "Unable to export folders and teams"
    )
    return
  end

  dialog:SetTitle("Export All Folders and Teams")

  self.Description:SetText(
    "Copy this export string to share "
    .. "all folders and teams."
  )

  self:SetValue(exportString)

  dialog:Show()
  dialog:RefreshLayout()

  self:SelectAll()
end

--------------------------------------------------
-- Show a folder
--------------------------------------------------
function ExportDialog:ShowFolder(folderKey)
  if not folderKey then
    return
  end

  local dialog = self:Create()
  local exportString, errorMessage = addon.Services.ImportExport:ExportFolder(folderKey)

  if not exportString then
    addon.Logger:Warn(
      errorMessage
      or "Unable to export folder"
    )
    return
  end

  local folder = addon.Services.Folder:Get(folderKey)
  local folderName = folder and folder.name or "Folder"

  dialog:SetTitle(
    "Export Folder: "
    .. folderName
  )

  self.Description:SetText(
    "Copy this export string "
    .. "to share the selected folder."
  )

  self:SetValue(exportString)

  dialog:Show()
  dialog:RefreshLayout()

  self:SelectAll()
end

--------------------------------------------------
-- Hide
--------------------------------------------------
function ExportDialog:Hide()
  if dialogInstance then
    dialogInstance:Hide()
  end
end

--------------------------------------------------
-- Register
--------------------------------------------------
addon.UI.Dialogs.ExportDialog = ExportDialog
