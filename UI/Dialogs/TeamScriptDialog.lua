local addonName, addon = ...

local TeamScriptDialog = {}

local DIALOG_WIDTH = 360
local DIALOG_HEIGHT = 380

function TeamScriptDialog:Create()
  if self.Frame then
    return self.Frame
  end

  local frame =
      addon.UI.Base.Panel:Create(
        UIParent,
        {
          width = DIALOG_WIDTH,
          height = DIALOG_HEIGHT,
          background =
          "Interface/Tooltips/chatbubble-background",
        }
      )

  frame:SetFrameStrata("DIALOG")
  frame:SetClampedToScreen(true)
  frame:EnableMouse(true)
  frame:SetMovable(true)

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
      addon.UI.Base.Label:Create(
        frame,
        {
          text = "Team Script",
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

  self.TeamName =
      addon.UI.Base.Label:Create(
        frame,
        {
          text = "",
          width = DIALOG_WIDTH - 24,
          justify = "LEFT",
          color = addon.UI.Theme.Colors.Text,
        }
      )

  self.TeamName:SetPoint(
    "TOPLEFT",
    self.Title,
    "BOTTOMLEFT",
    0,
    -8
  )

  self.Description =
      addon.UI.Base.Label:Create(
        frame,
        {
          text =
          "Enter a Pet Battle Script for this team.",
          width = DIALOG_WIDTH - 24,
          justify = "LEFT",
          color = addon.UI.Theme.Colors.Text,
        }
      )

  self.Description:SetPoint(
    "TOPLEFT",
    self.TeamName,
    "BOTTOMLEFT",
    0,
    -6
  )

  self.InputBackground =
      addon.UI.Base.Panel:Create(
        frame,
        {
          width = DIALOG_WIDTH - 24,
          height = DIALOG_HEIGHT - 135,
          background =
          "Interface/Tooltips/chatbubble-background",
        }
      )

  self.InputBackground:SetPoint(
    "TOPLEFT",
    self.Description,
    "BOTTOMLEFT",
    0,
    -10
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
  self.Input:SetFontObject("ChatFontNormal")
  self.Input:SetJustifyH("LEFT")
  self.Input:SetJustifyV("TOP")
  self.Input:SetTextInsets(4, 4, 4, 4)

  self.Input:SetWidth(
    DIALOG_WIDTH - 76
  )

  self.Input:SetHeight(
    DIALOG_HEIGHT - 155
  )

  self.ScrollFrame:SetScrollChild(
    self.Input
  )

  self.Input:SetScript(
    "OnEscapePressed",
    function()
      self:Hide()
    end
  )

  self.SaveButton =
      addon.UI.Base.Button:Create(
        frame,
        {
          text = "Save",
          width = 95,

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
      addon.UI.Base.Button:Create(
        frame,
        {
          text = "Cancel",
          width = 95,

          onClick = function()
            self:Hide()
          end,
        }
      )

  self.CancelButton:SetPoint(
    "RIGHT",
    self.SaveButton,
    "LEFT",
    -6,
    0
  )

  self.DragHandle =
      CreateFrame(
        "Frame",
        nil,
        frame
      )

  self.DragHandle:SetPoint(
    "TOPLEFT",
    frame,
    "TOPLEFT",
    0,
    0
  )

  self.DragHandle:SetPoint(
    "TOPRIGHT",
    frame,
    "TOPRIGHT",
    0,
    0
  )

  self.DragHandle:SetHeight(42)
  self.DragHandle:EnableMouse(true)
  self.DragHandle:RegisterForDrag(
    "LeftButton"
  )

  self.DragHandle:SetScript(
    "OnDragStart",
    function()
      frame:StartMoving()
    end
  )

  self.DragHandle:SetScript(
    "OnDragStop",
    function()
      frame:StopMovingOrSizing()
    end
  )

  frame:Hide()

  return frame
end

function TeamScriptDialog:Show(team)
  if not team then
    return
  end

  self:Create()

  self.TeamID = team.id

  self.TeamName:SetText(
    team.name or "Unnamed Team"
  )

  self.Input:SetText(
    team.script or ""
  )

  self.ScrollFrame:SetVerticalScroll(0)

  self.Frame:Show()
  self.Frame:Raise()

  self.Input:SetFocus()
  self.Input:SetCursorPosition(0)
end

function TeamScriptDialog:Save()
  if not self.TeamID then
    return
  end

  local script =
      self.Input:GetText() or ""

  local team, errorMessage =
      addon.Services.Team:SetScript(
        self.TeamID,
        script
      )

  if not team then
    addon.Logger:Warn(
      errorMessage
      or "Unable to save team script"
    )

    return
  end

  self:Hide()
end

function TeamScriptDialog:Hide()
  if not self.Frame then
    return
  end

  if self.Input then
    self.Input:ClearFocus()
  end

  self.TeamID = nil
  self.Frame:Hide()
end

addon.UI.Dialogs.TeamScriptDialog =
    TeamScriptDialog
