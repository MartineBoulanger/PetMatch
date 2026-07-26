local _, addon = ...

local EditTeamDialog = {}

local DIALOG_WIDTH = 340
local DIALOG_HEIGHT = 190

function EditTeamDialog:Create()
  if self.Frame then
    return self.Frame
  end

  local frame =
      addon.UI.Base.Panel:Create(
        UIParent,
        {
          width = DIALOG_WIDTH,
          height = DIALOG_HEIGHT,
          background = "Interface/Tooltips/chatbubble-background"
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
  self.PetSource = "saved"

  self.Title =
      addon.UI.Base.Label:Create(
        frame,
        {
          text = "Edit Team",
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
      addon.UI.Base.Label:Create(
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
    DIALOG_WIDTH - 34,
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

  self.KeepSavedButton =
      addon.UI.Base.Button:Create(
        frame,
        {
          text = "Keep Saved Pets",
          width = 145,

          onClick = function()
            self:SetPetSource("saved")
          end,
        }
      )

  self.KeepSavedButton:SetPoint(
    "TOPLEFT",
    self.NameInput,
    "BOTTOMLEFT",
    -4,
    -10
  )


  self.UseCurrentButton =
      addon.UI.Base.Button:Create(
        frame,
        {
          text = "Use Current Slots",
          width = 145,

          onClick = function()
            self:SetPetSource("current")
          end,
        }
      )

  self.UseCurrentButton:SetPoint(
    "LEFT",
    self.KeepSavedButton,
    "RIGHT",
    8,
    0
  )

  self.SaveButton =
      addon.UI.Base.Button:Create(
        frame,
        {
          text = "Save Changes",
          width = 120,

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

function EditTeamDialog:SetReplacePets(replacePets)
  self.ReplacePets = replacePets == true

  if self.ReplacePets then
    self.ReplaceButton:SetText(
      "Use Current Slots"
    )
  else
    self.ReplaceButton:SetText(
      "Keep Saved Pets"
    )
  end
end

function EditTeamDialog:Show(team)
  if not team then
    addon.Logger:Warn(
      "Select a team first"
    )

    return
  end

  local frame = self:Create()

  self.Team = team

  self.NameInput:SetText(
    team.name or ""
  )

  self:SetPetSource("saved")

  frame:Show()

  self.NameInput:SetFocus()
  self.NameInput:HighlightText()
end

function EditTeamDialog:Hide()
  if not self.Frame then
    return
  end

  self.NameInput:ClearFocus()
  self.Frame:Hide()

  self.Team = nil
  self.PetSource = "saved"
end

function EditTeamDialog:Save()
  local team = self.Team

  if not team then
    addon.Logger:Warn(
      "No team selected"
    )

    return
  end

  local name =
      addon.Utils:Trim(
        self.NameInput:GetText() or ""
      )

  local replacePets = self.PetSource == "current"
  local updatedTeam, errorMessage =
      addon.Services.Team:Edit(
        team.id,
        name,
        replacePets
      )

  if not updatedTeam then
    addon.Logger:Warn(
      errorMessage
      or "Unable to edit team"
    )

    self.NameInput:SetFocus()
    self.NameInput:HighlightText()

    return
  end

  addon.EventBus:Fire(
    addon.Events.TEAM_SELECTED,
    updatedTeam
  )

  self:Hide()
end

function EditTeamDialog:SetPetSource(source)
  self.PetSource = source

  local useSaved = source == "saved"

  if useSaved then
    self.KeepSavedButton:Disable()
    self.UseCurrentButton:Enable()
  else
    self.KeepSavedButton:Enable()
    self.UseCurrentButton:Disable()
  end
end

addon.UI.Dialogs.EditTeamDialog = EditTeamDialog
