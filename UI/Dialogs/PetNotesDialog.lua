local _, addon = ...

local L = addon.L
local PetNotesDialog = {}

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
-- State
--------------------------------------------------
function PetNotesDialog:ClearState()
  self.PetGUID = nil
  self.SpeciesID = nil
  self.ActiveScope = nil
  self.Notes = nil
  self.ShowScopeTabs = nil

  if self.Input then
    self.Input:ClearFocus()
  end
end

function PetNotesDialog:StoreCurrentText()
  if not self.ActiveScope or not self.Notes then
    return
  end

  self.Notes[self.ActiveScope] = self.Input:GetText() or ""
end

--------------------------------------------------
-- Switch between note types
--------------------------------------------------
function PetNotesDialog:SetScope(scope)
  if scope ~= "species" and scope ~= "individual" then
    return
  end

  if scope == "individual" and not self.PetGUID then
    return
  end

  self:StoreCurrentText()

  self.ActiveScope = scope

  if scope == "species" then
    self.ScopeDescription:SetText(
      L["SPECIES_NOTE_DESCRIPTION"]
    )
  else
    self.ScopeDescription:SetText(
      L["INDIVIDUAL_NOTE_DESCRIPTION"]
    )
  end

  self.Input:SetText(self.Notes[scope] or "")
  self.ScrollFrame:SetVerticalScroll(0)

  self.SpeciesButton:SetEnabled(scope ~= "species")
  self.IndividualButton:SetEnabled(
    self.PetGUID ~= nil and scope ~= "individual"
  )

  self.Input:SetFocus()
  self.Input:SetCursorPosition(0)
end

--------------------------------------------------
-- Update scope visibility
--------------------------------------------------
function PetNotesDialog:UpdateScopeVisibility()
  local showTabs = self.ShowScopeTabs == true

  self.SpeciesButton:SetShown(showTabs)
  self.IndividualButton:SetShown(showTabs)
  self.ScopeDescription:SetShown(showTabs)

  self.InputBackground:ClearAllPoints()

  if showTabs then
    self.InputBackground:SetPoint(
      "TOPLEFT",
      self.ScopeDescription,
      "BOTTOMLEFT",
      0,
      -10
    )

    self.InputBackground:SetPoint(
      "TOPRIGHT",
      self.ScopeDescription,
      "BOTTOMRIGHT",
      0,
      -10
    )
  else
    self.InputBackground:SetPoint(
      "TOPLEFT",
      self.PetName,
      "BOTTOMLEFT",
      0,
      -10
    )

    self.InputBackground:SetPoint(
      "TOPRIGHT",
      self.PetName,
      "BOTTOMRIGHT",
      0,
      -10
    )
  end

  self.InputBackground:SetHeight(NOTES_HEIGHT)
end

--------------------------------------------------
-- Save
--------------------------------------------------
function PetNotesDialog:Save()
  if not self.SpeciesID then
    return false
  end

  self:StoreCurrentText()

  local service = addon.Services.PetNotes

  if not service then
    return false
  end

  -- Validate the entire operation before writing.
  if type(self.Notes.species) ~= "string" then
    return false
  end

  if self.PetGUID
      and type(self.Notes.individual) ~= "string" then
    return false
  end

  local saved

  -- Save species notes when they are accessible,
  -- or when editing an uncollected species.
  if self.ShowScopeTabs or not self.PetGUID then
    saved = service:SetSpeciesNote(
      self.SpeciesID,
      self.Notes.species
    )

    if not saved then
      return false
    end
  end

  -- Save individual notes for owned pets.
  if self.PetGUID then
    saved = service:SetPetNote(
      self.PetGUID,
      self.Notes.individual
    )

    if not saved then
      return false
    end
  end

  return true
end

--------------------------------------------------
-- Create content
--------------------------------------------------
function PetNotesDialog:CreateContent(dialog)
  local content = dialog:GetContentFrame()

  --------------------------------------------------
  -- Pet name
  --------------------------------------------------
  self.PetName = addon.UI.Base.Label:Create(
    content,
    {
      text = "",
      justify = "LEFT",
      color = addon.UI.Theme.Colors.Text,
    }
  )

  self.PetName:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
  self.PetName:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, 0)

  --------------------------------------------------
  -- Scope buttons
  --------------------------------------------------
  self.SpeciesButton = CreateFrame(
    "Button",
    nil,
    content,
    "UIPanelButtonTemplate"
  )

  self.SpeciesButton:SetSize(150, 25)
  self.SpeciesButton:SetPoint(
    "TOPLEFT",
    self.PetName,
    "BOTTOMLEFT",
    0,
    -10
  )

  self.SpeciesButton:SetText(L["SPECIES_NOTE"] or "Species Note")

  self.SpeciesButton:SetScript("OnClick", function()
    self:SetScope("species")
  end)

  self.IndividualButton = CreateFrame(
    "Button",
    nil,
    content,
    "UIPanelButtonTemplate"
  )

  self.IndividualButton:SetSize(150, 25)
  self.IndividualButton:SetPoint(
    "LEFT",
    self.SpeciesButton,
    "RIGHT",
    8,
    0
  )

  self.IndividualButton:SetText(
    L["INDIVIDUAL_NOTE"] or "Individual Note"
  )

  self.IndividualButton:SetScript("OnClick", function()
    self:SetScope("individual")
  end)

  --------------------------------------------------
  -- Scope description
  --------------------------------------------------
  self.ScopeDescription = addon.UI.Base.Label:Create(
    content,
    {
      text = "",
      justify = "LEFT",
      color = addon.UI.Theme.Colors.TextMuted,
    }
  )

  self.ScopeDescription:SetPoint(
    "TOPLEFT",
    self.SpeciesButton,
    "BOTTOMLEFT",
    0,
    -8
  )

  self.ScopeDescription:SetPoint(
    "TOPRIGHT",
    content,
    "TOPRIGHT",
    0,
    -33
  )

  --------------------------------------------------
  -- Input background
  --------------------------------------------------
  self.InputBackground = CreateFrame(
    "Frame",
    nil,
    content,
    "BackdropTemplate"
  )

  self.InputBackground:SetPoint(
    "TOPLEFT",
    self.SpeciesButton,
    "BOTTOMLEFT",
    0,
    -10
  )

  self.InputBackground:SetPoint(
    "TOPRIGHT",
    content,
    "TOPRIGHT",
    0,
    -45
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

  self.InputBackground:SetBackdropColor(0.48, 0.48, 0.48, 0.55)
  self.InputBackground:SetBackdropBorderColor(0.35, 0.35, 0.35, 1)

  --------------------------------------------------
  -- Scroll frame
  --------------------------------------------------
  self.ScrollFrame = CreateFrame(
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
  self.Input = CreateFrame(
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
  self.Input:SetTextInsets(4, 4, 4, 4)
  self.Input:SetWidth(DIALOG_WIDTH - 100)
  self.Input:SetHeight(NOTES_HEIGHT - 20)

  self.ScrollFrame:SetScrollChild(self.Input)

  addon.SkinManager:ApplyMultiLineEditBox(
    self.InputBackground,
    self.ScrollFrame
  )

  --------------------------------------------------
  -- Keep scroll range correct
  --------------------------------------------------
  self.Input:SetScript("OnTextChanged", function(editBox)
    C_Timer.After(0, function()
      if not editBox or not editBox:IsShown() then
        return
      end

      local visibleHeight = self.ScrollFrame:GetHeight() or 1
      local textHeight = 0

      if type(editBox.GetFontString) == "function" then
        local fontString = editBox:GetFontString()

        if fontString
            and type(fontString.GetStringHeight) == "function" then
          textHeight = fontString:GetStringHeight() or 0
        end
      end

      editBox:SetHeight(
        math.max(visibleHeight, math.ceil(textHeight) + 16)
      )

      if type(self.ScrollFrame.UpdateScrollChildRect) == "function" then
        self.ScrollFrame:UpdateScrollChildRect()
      end
    end)
  end)

  --------------------------------------------------
  -- Keyboard
  --------------------------------------------------
  self.Input:SetScript("OnEscapePressed", function()
    dialog:Cancel()
  end)
end

--------------------------------------------------
-- Create dialog
--------------------------------------------------
function PetNotesDialog:Create()
  if dialogInstance then
    return dialogInstance
  end

  local dialog = addon.UI.Base.Dialog:Create({
    name = "PetMatchPetNotesDialog",
    title = L["PET_NOTES"] or "Pet Notes",
    width = DIALOG_WIDTH,
    contentMargin = CONTENT_MARGIN,
    padding = CONTENT_PADDING,
    bottomSpacing = 0,
    onAccept = function()
      return self:Save()
    end,
    onCancel = function()
      self:ClearState()
      return true
    end,
    onClose = function()
      self:ClearState()
    end,
  })

  self:CreateContent(dialog)

  self.CancelButton = dialog:AddCancelButton({
    text = L["CANCEL"],
    width = 95,
  })

  self.SaveButton = dialog:AddAcceptButton({
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
function PetNotesDialog:Show(petGUID, speciesID, petName)
  speciesID = tonumber(speciesID)

  if not speciesID then
    return
  end

  local service = addon.Services.PetNotes

  if not service then
    return
  end

  if type(petGUID) ~= "string" or petGUID == "" then
    petGUID = nil
  end

  local dialog = self:Create()

  self.PetGUID = petGUID
  self.SpeciesID = speciesID

  self.Notes = {
    species = service:GetSpeciesNote(speciesID) or "",
    individual = petGUID
        and (service:GetPetNote(petGUID) or "")
        or "",
  }

  -- Show both note types when duplicates exist,
  -- or when an existing species note must remain accessible.
  local hasDuplicates = service:HasDuplicates(speciesID)
  local hasSpeciesNote = service:HasSpeciesNote(speciesID)

  self.ShowScopeTabs =
      petGUID ~= nil
      and (hasDuplicates or hasSpeciesNote)

  self.ActiveScope = nil

  dialog:SetTitle(L["PET_NOTES"] or "Pet Notes")
  self.PetName:SetText(petName or L["UNKNOWN"])

  self:UpdateScopeVisibility()

  -- Owned pets default to individual notes.
  -- Uncollected species use species notes.
  self:SetScope(
    petGUID and "individual" or "species"
  )

  dialog:Show()
  dialog:RefreshLayout()

  self.Input:SetFocus()
  self.Input:SetCursorPosition(0)
end

--------------------------------------------------
-- Hide
--------------------------------------------------
function PetNotesDialog:Hide()
  if dialogInstance then
    dialogInstance:Hide()
  end
end

--------------------------------------------------
-- Register
--------------------------------------------------
addon.UI.Dialogs.PetNotesDialog = PetNotesDialog
