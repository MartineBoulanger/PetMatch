local _, addon = ...

local EditTeamDialog = {}

local DIALOG_WIDTH = 340
local CONTENT_MARGIN = {
  left = -12,
  right = 12,
  top = 4,
  bottom = 8
}
local CONTENT_PADDING = 16
local FIELD_SPACING = 6
local SOURCE_BUTTON_SPACING = 10

local dialogInstance

--------------------------------------------------
-- Cleanup
--------------------------------------------------
function EditTeamDialog:ClearState()
  self.Team = nil
  self.PetSource = "saved"

  if self.NameInput then
    self.NameInput:ClearFocus()
    self.NameInput:SetText("")
  end
end

--------------------------------------------------
-- Save
--------------------------------------------------
function EditTeamDialog:Save()
  local team = self.Team

  if not team then
    addon.Logger:Warn("No team selected")
    return false
  end

  local name = addon.Utils:Trim(self.NameInput:GetText() or "")

  if name == "" then
    addon.Logger:Warn("Enter a team name")
    self.NameInput:SetFocus()
    self.NameInput:HighlightText()
    return false
  end

  local replacePets = self.PetSource == "current"
  local updatedTeam, errorMessage = addon.Services.Team:Edit(team.id, name, replacePets)

  if not updatedTeam then
    addon.Logger:Warn(errorMessage or "Unable to edit team")
    self.NameInput:SetFocus()
    self.NameInput:HighlightText()
    return false
  end

  addon.EventBus:Fire(addon.Events.TEAM_SELECTED, updatedTeam)

  return true
end

--------------------------------------------------
-- Pet Source
--------------------------------------------------
function EditTeamDialog:SetPetSource(source)
  if source ~= "saved" and source ~= "current" then
    source = "saved"
  end

  self.PetSource = source

  local useSaved = source == "saved"

  if self.KeepSavedButton then
    self.KeepSavedButton:SetEnabled(not useSaved)
  end

  if self.UseCurrentButton then
    self.UseCurrentButton:SetEnabled(useSaved)
  end
end

--------------------------------------------------
-- Create content
--------------------------------------------------
function EditTeamDialog:CreateContent(dialog)
  local content = dialog:GetContentFrame()

  --------------------------------------------------
  -- Team name label
  --------------------------------------------------
  self.NameLabel = addon.UI.Base.Label:Create(content,
    {
      text = "Team name",
      width = DIALOG_WIDTH - (CONTENT_MARGIN.left + CONTENT_MARGIN.right) - (CONTENT_PADDING * 2) + 10,
      justify =
      "LEFT"
    })

  self.NameLabel:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
  self.NameLabel:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, 0)

  --------------------------------------------------
  -- Team name input
  --------------------------------------------------
  self.NameInput = CreateFrame("EditBox", nil, content, "InputBoxTemplate")
  self.NameInput:SetHeight(28)
  self.NameInput:SetPoint("TOPLEFT", self.NameLabel, "BOTTOMLEFT", 4, 2)
  self.NameInput:SetPoint("TOPRIGHT", self.NameLabel, "BOTTOMRIGHT", 2, -4)
  self.NameInput:SetAutoFocus(false)
  self.NameInput:SetMaxLetters(80)

  --------------------------------------------------
  -- Pet source description
  --------------------------------------------------
  self.PetSourceLabel = addon.UI.Base.Label:Create(content,
    {
      text = "Choose which pets should be saved " .. "in the edited team",
      width = DIALOG_WIDTH -
          (CONTENT_MARGIN.left + CONTENT_MARGIN.right) - (CONTENT_PADDING * 2),
      justify = "LEFT"
    })

  self.PetSourceLabel:SetPoint("TOPLEFT", self.NameInput, "BOTTOMLEFT", -4, -SOURCE_BUTTON_SPACING)
  self.PetSourceLabel:SetPoint("TOPRIGHT", self.NameInput, "BOTTOMRIGHT", 4, -SOURCE_BUTTON_SPACING)

  --------------------------------------------------
  -- Keep saved pets
  --------------------------------------------------
  self.KeepSavedButton = addon.UI.Base.Button:Create(content,
    {
      text = "Keep Saved Pets",
      width = 137,
      onClick = function()
        self:SetPetSource("saved")
      end
    })
  self.KeepSavedButton:SetPoint("TOPLEFT", self.PetSourceLabel, "BOTTOMLEFT", -3, -12)

  --------------------------------------------------
  -- Use current slots
  --------------------------------------------------
  self.UseCurrentButton = addon.UI.Base.Button:Create(content,
    {
      text = "Use Current Slots",
      width = 137,
      onClick = function()
        self:SetPetSource("current")
      end
    })
  self.UseCurrentButton:SetPoint("LEFT", self.KeepSavedButton, "RIGHT", SOURCE_BUTTON_SPACING, 0)

  --------------------------------------------------
  -- Keyboard handling
  --------------------------------------------------
  self.NameInput:SetScript("OnEnterPressed", function() dialog:Cancel() end)
  self.NameInput:SetScript("OnEscapePressed", function() dialog:Cancel() end)
end

--------------------------------------------------
-- Create dialog
--------------------------------------------------
function EditTeamDialog:Create()
  if dialogInstance then
    return dialogInstance
  end

  local dialog = addon.UI.Base.Dialog:Create({
    name = "PetMatchEditTeamDialog",
    title = "Edit Team",
    width = DIALOG_WIDTH,
    contentMargin = CONTENT_MARGIN,
    padding = CONTENT_PADDING,
    bottomSpacing = 0,
    onAccept = function() return self:Save() end,
    onCancel = function()
      self:ClearState()
      return true
    end,
    onClose = function() self:ClearState() end
  })

  self:CreateContent(dialog)

  --------------------------------------------------
  -- Footer buttons
  --------------------------------------------------
  self.CancelButton = dialog:AddCancelButton({ text = "Cancel", width = 100 })
  self.SaveButton = dialog:AddAcceptButton({ text = "Save Changes", width = 120 })

  dialogInstance = dialog
  self.Dialog = dialog
  self.Frame = dialog:GetFrame()

  dialog:RefreshLayout()

  return dialog
end

--------------------------------------------------
-- Show
--------------------------------------------------
function EditTeamDialog:Show(team)
  if not team then
    addon.Logger:Warn("Select a team first")
    return
  end

  local dialog = self:Create()
  self.Team = team
  self.NameInput:SetText(team.name or "")
  self:SetPetSource("saved")
  dialog:Show()

  --------------------------------------------------
  -- Refresh again after the text and controls
  -- have received their final dimensions
  --------------------------------------------------
  dialog:RefreshLayout()

  self.NameInput:SetFocus()
  self.NameInput:HighlightText()
end

--------------------------------------------------
-- Hide
--------------------------------------------------
function EditTeamDialog:Hide()
  if not dialogInstance then
    return
  end
  dialogInstance:Hide()
end

--------------------------------------------------
-- Register
--------------------------------------------------
addon.UI.Dialogs.EditTeamDialog = EditTeamDialog
