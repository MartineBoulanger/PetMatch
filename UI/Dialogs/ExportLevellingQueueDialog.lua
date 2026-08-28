local _, addon = ...

local ExportLevellingQueueDialog = {}

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
function ExportLevellingQueueDialog:ClearState()
  if self.Input then
    self.Input:ClearFocus()
    self.Input:HighlightText(0, 0)
  end
end

--------------------------------------------------
-- Select all
--------------------------------------------------
function ExportLevellingQueueDialog:SelectAll()
  if not self.Input then
    return
  end

  self.Input:SetFocus()
  self.Input:HighlightText()
end

--------------------------------------------------
-- Value
--------------------------------------------------
function ExportLevellingQueueDialog:SetValue(value)
  if not self.Input then
    return
  end

  self.Input:SetText(
    value or ""
  )

  self.Input:SetCursorPosition(0)

  if self.ScrollFrame
      and type(self.ScrollFrame.UpdateScrollChildRect) == "function" then
    self.ScrollFrame:UpdateScrollChildRect()
  end
end

--------------------------------------------------
-- Content
--------------------------------------------------
function ExportLevellingQueueDialog:CreateContent(dialog)
  local content = dialog:GetContentFrame()

  --------------------------------------------------
  -- Description
  --------------------------------------------------
  self.Description =
      addon.UI.Base.Label:Create(
        content,
        {
          text = "Copy this levelling queue export "
              .. "string and share it with " .. "another player.",
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

  self.InputBackground:SetHeight(
    INPUT_HEIGHT
  )

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

  self.InputBackground:
      SetBackdropColor(
        0.48,
        0.48,
        0.48,
        0.55
      )

  self.InputBackground:
      SetBackdropBorderColor(
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
  -- Export input
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

  self.Input:SetHeight(
    INPUT_HEIGHT - 20
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
          and type(
            self.ScrollFrame
            .UpdateScrollChildRect
          ) == "function" then
        self.ScrollFrame:UpdateScrollChildRect()
      end
    end
  )

  self.ScrollFrame:SetScrollChild(
    self.Input
  )
end

--------------------------------------------------
-- Create
--------------------------------------------------
function ExportLevellingQueueDialog:Create()
  if dialogInstance then
    return dialogInstance
  end

  local dialog =
      addon.UI.Base.Dialog:Create({
        name = "PetMatchExportLevellingQueueDialog",
        title = "Export Levelling Queue",
        width = DIALOG_WIDTH,
        contentMargin = CONTENT_MARGIN,
        padding = CONTENT_PADDING,
        bottomSpacing = 0,
        onCancel =
            function()
              self:ClearState()
              return true
            end,
        onClose =
            function()
              self:ClearState()
            end,
      })

  self:CreateContent(dialog)

  --------------------------------------------------
  -- Footer
  --------------------------------------------------
  self.CloseButton =
      dialog:AddCancelButton({
        text = "Cancel",
        width = 80,
      })

  self.CopyButton =
      dialog:AddFooterButton({
        text = "Select All",
        width = 90,
        onClick =
            function()
              self:SelectAll()
            end,
      })

  dialogInstance = dialog

  self.Dialog = dialog
  self.Frame = dialog:GetFrame()

  dialog:RefreshLayout()

  return dialog
end

--------------------------------------------------
-- Show
--------------------------------------------------
function ExportLevellingQueueDialog:Show()
  local dialog = self:Create()

  local value, errorMessage =
      addon.Services.ImportExport:ExportLevellingQueue()

  if not value then
    addon.Logger:Warn(
      errorMessage
      or "Unable to export levelling queue"
    )

    return
  end

  dialog:SetTitle("Export Levelling Queue")

  self.Description:SetText(
    "Copy this levelling queue export "
    .. "string and share it with "
    .. "another player."
  )

  self:SetValue(value)

  dialog:Show()
  dialog:RefreshLayout()

  self:SelectAll()
end

--------------------------------------------------
-- Hide
--------------------------------------------------
function ExportLevellingQueueDialog:Hide()
  if dialogInstance then
    dialogInstance:Hide()
  end
end

--------------------------------------------------
-- Register
--------------------------------------------------
addon.UI.Dialogs.ExportLevellingQueueDialog = ExportLevellingQueueDialog
