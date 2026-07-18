local addonName, addon = ...

local ImportDialog = {}

local DIALOG_WIDTH = 320
local DIALOG_HEIGHT = 230

local function GetResultText(result)
  local lines = {}

  lines[#lines + 1] =
      string.format(
        "%d team%s imported.",
        #result.teams,
        #result.teams == 1 and "" or "s"
      )

  if #result.folders > 0 then
    lines[#lines + 1] =
        string.format(
          "%d folder%s created or used.",
          #result.folders,
          #result.folders == 1 and "" or "s"
        )
  end

  if #result.missingSpecies > 0 then
    lines[#lines + 1] =
        string.format(
          "%d missing pet%s.",
          #result.missingSpecies,
          #result.missingSpecies == 1 and "" or "s"
        )
  end

  if #result.warnings > 0 then
    lines[#lines + 1] =
        string.format(
          "%d warning%s.",
          #result.warnings,
          #result.warnings == 1 and "" or "s"
        )
  end

  return table.concat(lines, "\n")
end

function ImportDialog:Create()
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

  self.Title =
      addon.UI.Components.Label:Create(
        frame,
        {
          text = "Import Teams",
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
          text = "Paste a PetMatch or Rematch export below.",
          width = DIALOG_WIDTH - 24,
          justify = "LEFT",
          color = addon.UI.Theme.Colors.Text,
        }
      )

  self.Description:SetPoint(
    "TOPLEFT",
    self.Title,
    "BOTTOMLEFT",
    0,
    -8
  )

  self.InputBackground =
      addon.UI.Components.Panel:Create(
        frame,
        {
          width = DIALOG_WIDTH - 23,
          height = 110,
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
    DIALOG_WIDTH - 96
  )

  self.Input:SetHeight(170)

  self.ScrollFrame:SetScrollChild(
    self.Input
  )

  self.Input:SetScript(
    "OnTextChanged",
    function()
      self.ScrollFrame:UpdateScrollChildRect()
      self:ClearStatus()
    end
  )

  self.Input:SetScript(
    "OnEscapePressed",
    function()
      self:Hide()
    end
  )

  self.Status =
      addon.UI.Components.Label:Create(
        frame,
        {
          text = "",
          width = DIALOG_WIDTH,
          justify = "LEFT",
          color = addon.UI.Theme.Colors.Text,
        }
      )

  self.Status:SetPoint(
    "BOTTOMLEFT",
    self.InputBackground,
    "BOTTOMLEFT",
    0,
    -30
  )

  self.Status:SetHeight(42)

  self.ImportButton =
      addon.UI.Components.Button:Create(
        frame,
        {
          text = "Import",
          width = 100,

          onClick = function()
            self:Import()
          end,
        }
      )

  self.ImportButton:SetPoint(
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
    self.ImportButton,
    "LEFT",
    -8,
    0
  )

  frame:Hide()

  return frame
end

function ImportDialog:SetStatus(
    message,
    isError
)
  if not self.Status then
    return
  end

  self.Status:SetText(
    message or ""
  )

  if isError then
    self.Status:SetTextColor(
      1,
      0.25,
      0.25
    )
  else
    self.Status:SetTextColor(
      0.25,
      1,
      0.25
    )
  end
end

function ImportDialog:ClearStatus()
  if not self.Status then
    return
  end

  self.Status:SetText("")
end

function ImportDialog:Import()
  local value =
      self.Input:GetText() or ""

  value =
      addon.Utils:Trim(value)

  if value == "" then
    self:SetStatus(
      "Paste an export string first.",
      true
    )

    return
  end

  self.ImportButton:SetEnabled(false)

  local result, errorMessage =
      addon.Services.ImportExport:
      Import(value)

  self.ImportButton:SetEnabled(true)

  if not result then
    self:SetStatus(
      errorMessage
      or "Import failed.",
      true
    )

    return
  end

  local importedTeam = result.teams and result.teams[#result.teams]

  if importedTeam then
    addon.Services.Team:SelectForUI(importedTeam.id)
    addon.Services.Team:Load(importedTeam.id)
  end

  self:Hide()
end

function ImportDialog:Show()
  self:Create()

  self.Input:SetText("")
  self:ClearStatus()

  self.Frame:Show()
  self.Frame:Raise()

  self.Input:SetFocus()
end

function ImportDialog:Hide()
  if not self.Frame then
    return
  end

  if self.Input then
    self.Input:ClearFocus()
  end

  self.Frame:Hide()
end

addon.UI.Views.ImportDialog =
    ImportDialog
