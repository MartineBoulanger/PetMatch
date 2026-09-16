local _, addon = ...

local L = addon.L
local TeamNotesDialog = {}

local DIALOG_WIDTH = 400
local NOTES_HEIGHT = 240

local CONTENT_MARGIN = {
  left = -12,
  right = 12,
  top = 4,
  bottom = 8,
}

local CONTENT_PADDING = 14

local dialogInstance

--------------------------------------------------
-- Clear state
--------------------------------------------------
function TeamNotesDialog:ClearState()
  self.TeamID = nil
  if self.Input then
    self.Input:ClearFocus()
  end
end

--------------------------------------------------
-- Save
--------------------------------------------------
function TeamNotesDialog:Save()
  if not self.TeamID then
    addon.Logger:Warn(L["NO_TEAM_SELECTED"])
    return false
  end

  local notes = self.Input:GetText() or ""
  local team, errorMessage = addon.Services.Team:SetNotes(self.TeamID, notes)

  if not team then
    addon.Logger:Warn(
      errorMessage
      or L["UNABLE_SAVE_NOTES"]
    )
    return false
  end

  return true
end

--------------------------------------------------
-- Create content
--------------------------------------------------
function TeamNotesDialog:CreateContent(dialog)
  local content = dialog:GetContentFrame()

  --------------------------------------------------
  -- Team name
  --------------------------------------------------
  self.TeamName =
      addon.UI.Base.Label:Create(
        content,
        {
          text = "",
          justify = "LEFT",
          color = addon.UI.Theme.Colors.Text,
        }
      )

  self.TeamName:SetPoint(
    "TOPLEFT",
    content,
    "TOPLEFT",
    0,
    0
  )

  self.TeamName:SetPoint(
    "TOPRIGHT",
    content,
    "TOPRIGHT",
    0,
    0
  )

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
    self.TeamName,
    "BOTTOMLEFT",
    0,
    -10
  )

  self.InputBackground:SetPoint(
    "TOPRIGHT",
    self.TeamName,
    "BOTTOMRIGHT",
    0,
    -10
  )

  self.InputBackground:SetHeight(NOTES_HEIGHT)

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
    -28,
    8
  )

  --------------------------------------------------
  -- Notes input
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
  self.Input:SetJustifyH("LEFT")
  self.Input:SetJustifyV("TOP")

  self.Input:SetTextInsets(
    4,
    4,
    4,
    4
  )

  self.Input:SetWidth(
    DIALOG_WIDTH - 100
  )

  self.Input:SetHeight(
    NOTES_HEIGHT - 20
  )

  self.ScrollFrame:SetScrollChild(self.Input)

  --------------------------------------------------
  -- Keep scroll range correct
  --------------------------------------------------
  self.Input:SetScript(
    "OnTextChanged",
    function(editBox)
      C_Timer.After(
        0,

        function()
          if not editBox
              or not editBox:IsShown() then
            return
          end

          local visibleHeight =
              self.ScrollFrame:GetHeight()
              or 1

          local textHeight = 0

          if type(editBox.GetFontString)
              == "function" then
            local fontString =
                editBox:GetFontString()

            if fontString
                and type(
                  fontString.GetStringHeight
                ) == "function" then
              textHeight =
                  fontString:GetStringHeight()
                  or 0
            end
          end

          editBox:SetHeight(
            math.max(
              visibleHeight,
              math.ceil(textHeight) + 16
            )
          )

          if type(
                self.ScrollFrame
                .UpdateScrollChildRect
              ) == "function" then
            self.ScrollFrame:
                UpdateScrollChildRect()
          end
        end
      )
    end
  )

  --------------------------------------------------
  -- Keyboard
  --------------------------------------------------
  self.Input:SetScript(
    "OnEscapePressed",
    function()
      dialog:Cancel()
    end
  )
end

--------------------------------------------------
-- Create dialog
--------------------------------------------------
function TeamNotesDialog:Create()
  if dialogInstance then
    return dialogInstance
  end

  local dialog =
      addon.UI.Base.Dialog:Create({
        name = "PetMatchTeamNotesDialog",
        title = L["TEAM_NOTES"],
        width = DIALOG_WIDTH,
        contentMargin = CONTENT_MARGIN,
        padding = CONTENT_PADDING,
        bottomSpacing = 0,
        onAccept = function() return self:Save() end,
        onCancel =
            function()
              self:ClearState()
              return true
            end,
        onClose = function() self:ClearState() end,
      })

  self:CreateContent(dialog)

  --------------------------------------------------
  -- Footer
  --------------------------------------------------
  self.CancelButton =
      dialog:AddCancelButton({
        text = L["CANCEL"],
        width = 95,
      })

  self.SaveButton =
      dialog:AddAcceptButton({
        text = L["SAVE"],
        width = 95,
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
function TeamNotesDialog:Show(team)
  if not team then
    return
  end

  local dialog = self:Create()

  self.TeamID = team.id

  dialog:SetTitle(L["TEAM_NOTES"])

  self.TeamName:SetText(
    team.name
    or L["UNNAMED_TEAM"]
  )

  self.Input:SetText(
    team.notes
    or ""
  )

  self.ScrollFrame:SetVerticalScroll(0)

  dialog:Show()
  dialog:RefreshLayout()

  self.Input:SetFocus()
  self.Input:SetCursorPosition(0)
end

--------------------------------------------------
-- Hide
--------------------------------------------------
function TeamNotesDialog:Hide()
  if dialogInstance then
    dialogInstance:Hide()
  end
end

--------------------------------------------------
-- Register
--------------------------------------------------
addon.UI.Dialogs.TeamNotesDialog = TeamNotesDialog
