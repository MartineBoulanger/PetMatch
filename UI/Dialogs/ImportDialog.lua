local _, addon = ...

local ImportDialog = {}

local DIALOG_WIDTH = 400
local INPUT_HEIGHT = 130
local STATUS_HEIGHT = 42

local CONTENT_MARGIN = {
  left = -12,
  right = 12,
  top = 4,
  bottom = 8,
}

local CONTENT_PADDING = 14

local dialogInstance

--------------------------------------------------
-- Sorted folders
--------------------------------------------------
local function GetSortedFolders()
  local folderService = addon.Services.Folder
  local sourceFolders = folderService:GetSortedFolders()
  local folders = {}

  for folderID, folder in pairs(
    sourceFolders or {}
  ) do
    if type(folder) == "table" then
      folders[#folders + 1] = {
        id = folder.id or folderID,
        name = folder.name or "Unnamed Folder",
      }
    end
  end

  table.sort(
    folders,
    function(left, right)
      return string.lower(
        left.name or ""
      ) < string.lower(
        right.name or ""
      )
    end
  )

  return folders
end

--------------------------------------------------
-- Clear state
--------------------------------------------------
function ImportDialog:ClearState()
  if self.Input then
    self.Input:ClearFocus()
  end
end

--------------------------------------------------
-- Create content
--------------------------------------------------
function ImportDialog:CreateContent(dialog)
  local content = dialog:GetContentFrame()

  --------------------------------------------------
  -- Description
  --------------------------------------------------
  self.Description =
      addon.UI.Base.Label:Create(
        content,
        {
          text = "Paste a PetMatch or Rematch "
              .. "import string below.",
          justify = "LEFT",
          color = addon.UI.Theme.Colors.Text,
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
  -- Input
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

  self.Input:SetFontObject(
    "ChatFontNormal"
  )

  self.Input:SetJustifyH("LEFT")
  self.Input:SetJustifyV("TOP")

  self.Input:SetTextInsets(
    4,
    4,
    4,
    4
  )

  self.Input:SetWidth(
    DIALOG_WIDTH - 88
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
      self:UpdateButtons()
    end
  )

  self.ScrollFrame:SetScrollChild(self.Input)

  --------------------------------------------------
  -- Folder dropdown
  --------------------------------------------------
  self.FolderDropdown =
      CreateFrame(
        "DropdownButton",
        nil,
        content,
        "WowStyle1DropdownTemplate"
      )

  self.FolderDropdown:SetPoint(
    "TOPLEFT",
    self.InputBackground,
    "BOTTOMLEFT",
    2,
    -10
  )

  self.FolderDropdown:SetPoint(
    "TOPRIGHT",
    self.InputBackground,
    "BOTTOMRIGHT",
    -2,
    -10
  )

  self.FolderDropdown:SetHeight(26)

  --------------------------------------------------
  -- Save as new team
  --------------------------------------------------
  self.NewTeamRadio =
      CreateFrame(
        "CheckButton",
        nil,
        content,
        "UIRadioButtonTemplate"
      )

  self.NewTeamRadio:SetPoint(
    "TOPLEFT",
    self.FolderDropdown,
    "BOTTOMLEFT",
    0,
    -10
  )

  self.NewTeamRadio.Label =
      self.NewTeamRadio:
      CreateFontString(
        nil,
        "OVERLAY",
        "GameFontNormal"
      )

  self.NewTeamRadio.Label:SetPoint(
    "LEFT",
    self.NewTeamRadio,
    "RIGHT",
    4,
    0
  )

  self.NewTeamRadio.Label:SetText("Save as new team")

  self.NewTeamRadio:SetScript(
    "OnClick",
    function()
      self:SetSaveMode("new")
    end
  )

  --------------------------------------------------
  -- Override selected team
  --------------------------------------------------
  self.OverrideRadio =
      CreateFrame(
        "CheckButton",
        nil,
        content,
        "UIRadioButtonTemplate"
      )

  self.OverrideRadio:SetPoint(
    "TOPLEFT",
    self.NewTeamRadio,
    "BOTTOMLEFT",
    0,
    -2
  )

  self.OverrideRadio.Label =
      self.OverrideRadio:
      CreateFontString(
        nil,
        "OVERLAY",
        "GameFontNormal"
      )

  self.OverrideRadio.Label:SetPoint(
    "LEFT",
    self.OverrideRadio,
    "RIGHT",
    4,
    0
  )

  self.OverrideRadio.Label:SetText(
    "Override selected team"
  )

  self.OverrideRadio:SetScript(
    "OnClick",
    function()
      self:SetSaveMode("override")
    end
  )

  --------------------------------------------------
  -- Status
  --------------------------------------------------
  self.Status =
      addon.UI.Base.Label:Create(
        content,
        {
          text = "",
          justify = "LEFT",
          color = addon.UI.Theme.Colors.Text,
        }
      )

  self.Status:SetPoint(
    "TOPLEFT",
    self.OverrideRadio,
    "BOTTOMLEFT",
    0,
    -10
  )

  self.Status:SetPoint(
    "TOPRIGHT",
    content,
    "TOPRIGHT",
    0,
    0
  )

  self.Status:SetHeight(STATUS_HEIGHT)
end

--------------------------------------------------
-- Create dialog
--------------------------------------------------
function ImportDialog:Create()
  if dialogInstance then
    return dialogInstance
  end

  local dialog =
      addon.UI.Base.Dialog:Create({
        name = "PetMatchImportDialog",
        title = "Import Teams",
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
  self.CancelButton =
      dialog:AddCancelButton({
        text = "Cancel",
        width = 95,
      })

  self.SaveButton =
      dialog:AddFooterButton({
        text = "Save",
        width = 95,
        onClick = function() self:SaveTeam() end,
      })

  self.LoadButton =
      dialog:AddFooterButton({
        text = "Load",
        width = 95,
        onClick = function() self:LoadTeam() end,
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
function ImportDialog:Show()
  local dialog = self:Create()

  self.Input:SetText("")
  self:ClearStatus()

  self.SelectedFolderID = addon.Services.Folder:GetSelectedStorageFolderID()

  self.SaveMode = "new"

  self:RefreshFolderDropdown()
  self:UpdateSaveMode()
  self:UpdateButtons()

  dialog:Show()
  dialog:RefreshLayout()

  self.Input:SetFocus()
end

--------------------------------------------------
-- Show for folder
--------------------------------------------------
function ImportDialog:ShowForFolder(folderKey)
  local dialog = self:Create()

  self.Input:SetText("")
  self:ClearStatus()

  if folderKey == addon.Services.Folder.UNSORTED then
    self.SelectedFolderID = nil
  elseif addon.Services.Folder:Get(folderKey) then
    self.SelectedFolderID = folderKey
  end

  self.SaveMode = "new"

  self:RefreshFolderDropdown()
  self:UpdateSaveMode()
  self:UpdateButtons()

  dialog:Show()
  dialog:RefreshLayout()

  self.Input:SetFocus()
end

--------------------------------------------------
-- Hide
--------------------------------------------------
function ImportDialog:Hide()
  if dialogInstance then
    dialogInstance:Hide()
  end
end

--------------------------------------------------
-- Set the status
--------------------------------------------------
function ImportDialog:SetStatus(message, isError)
  local color

  if not self.Status then
    return
  end

  self.Status:SetText(message or "")

  if isError then
    color = addon.UI.Theme.Colors.Error
  else
    color = addon.UI.Theme.Colors.Success
  end

  self.Status:SetTextColor(
    color[1],
    color[2],
    color[3],
    color[4]
  )
end

--------------------------------------------------
-- Clear the status
--------------------------------------------------
function ImportDialog:ClearStatus()
  if not self.Status then
    return
  end

  self.Status:SetText("")
end

--------------------------------------------------
-- Import
--------------------------------------------------
function ImportDialog:Import()
  local value = self.Input:GetText() or ""
  value = addon.Utils:Trim(value)

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

--------------------------------------------------
-- Folder options
--------------------------------------------------
function ImportDialog:GetFolderOptions()
  local options = {
    {
      id = nil,
      name = "Unsorted",
    },
  }

  for _, folder in ipairs(
    addon.Services.Folder:GetFolders()
  ) do
    options[#options + 1] = {
      id = folder.id,
      name = folder.name,
    }
  end

  return options
end

--------------------------------------------------
-- Selected folder
--------------------------------------------------
function ImportDialog:SetSelectedFolder(
    folderID
)
  self.SelectedFolderID = folderID
  self:RefreshFolderDropdown()
end

--------------------------------------------------
-- Import data
--------------------------------------------------
function ImportDialog:GetImportData()
  local value = addon.Utils:Trim(self.Input:GetText() or "")
  local importData, errorMessage = addon.Services.ImportExport:Parse(value)

  if not importData then
    self:SetStatus(errorMessage or "Invalid import string")
    return nil
  end

  importData.folderID = self.SelectedFolderID

  return importData
end

--------------------------------------------------
-- Save team
--------------------------------------------------
function ImportDialog:SaveTeam()
  if self.SaveMode == "override" then
    self:OverrideExisting()
    return
  end

  local value = addon.Utils:Trim(self.Input:GetText() or "")

  if value == "" then
    self:SetStatus(
      "Paste an export string first.",
      true
    )
    return
  end

  self.SaveButton:SetEnabled(false)

  local prepared, errorMessage = addon.Services.ImportExport:PrepareImport(value)

  if not prepared then
    self:SetStatus(
      errorMessage
      or "Unable to prepare import.",
      true
    )
    return
  end

  if prepared.requiresPreview then
    addon.UI.Dialogs.ImportPreviewDialog:Show(
      prepared.document,
      {
        defaultFolderID = self.SelectedFolderID,
        conflictMode = addon.Settings:Get("duplicateTeamMode") or "replace",
      }
    )
    self:Hide()
    return
  end

  local result, importError =
      addon.Services.ImportExport:Import(
        value,
        {
          defaultFolderID = self.SelectedFolderID,
          conflictMode = addon.Settings:Get("duplicateTeamMode") or "replace",
        }
      )

  self.SaveButton:SetEnabled(true)

  if not result then
    self:SetStatus(
      importError
      or "Unable to import.",
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

--------------------------------------------------
-- Override existing team
--------------------------------------------------
function ImportDialog:OverrideExisting()
  local selectedTeam = addon.Services.Team:GetSelected()

  if not selectedTeam then
    self:SetStatus("Select a team to override")
    return
  end

  local importData = self:GetImportData()

  if not importData then
    return
  end

  local team, errorMessage =
      addon.Services.Team:
      OverrideFromImport(
        selectedTeam.id,
        importData
      )

  if not team then
    self:SetStatus(
      errorMessage
      or "Unable to override team"
    )

    return
  end

  addon.Services.Folder:Select(
    selectedTeam.folderID
    or addon.Services.Folder.UNSORTED
  )

  C_Timer.After(0, function()
    local success, loadError =
        addon.Services.Team:Load(
          selectedTeam.id
        )

    if not success then
      self:SetStatus(
        loadError or "Unable to load team."
      )
      return
    end

    self:Hide()
  end)

  self:Hide()
end

--------------------------------------------------
-- Load team
--------------------------------------------------
function ImportDialog:LoadTeam()
  local importData = self:GetImportData()

  if not importData then
    return
  end

  local success, errorMessage = addon.Services.Team:LoadFromImport(importData)

  if not success then
    self:SetStatus(
      errorMessage
      or "Unable to load team"
    )
    return
  end

  self:Hide()
end

--------------------------------------------------
-- Update buttons
--------------------------------------------------
function ImportDialog:UpdateButtons()
  local hasText =
      addon.Utils:Trim(
        self.Input and self.Input:GetText() or ""
      ) ~= ""

  local selectedTeam = addon.Services.Team:GetSelected()
  local hasSelectedTeam = selectedTeam ~= nil

  if self.SaveButton then
    self.SaveButton:SetEnabled(hasText)
  end

  if self.LoadButton then
    self.LoadButton:SetEnabled(hasText)
  end

  if self.OverrideRadio then
    if hasSelectedTeam then
      self.OverrideRadio:Enable()

      if self.OverrideRadio.Label then
        self.OverrideRadio.Label:SetTextColor(
          1,
          0.82,
          0
        )
      end
    else
      self.OverrideRadio:Disable()

      if self.OverrideRadio.Label then
        self.OverrideRadio.Label:SetTextColor(
          0.5,
          0.5,
          0.5
        )
      end

      if self.SaveMode == "override"
          and self.NewTeamRadio then
        self:SetSaveMode("new")
      end
    end
  end
end

--------------------------------------------------
-- Refresh folder dropdown
--------------------------------------------------
function ImportDialog:RefreshFolderDropdown()
  if not self.FolderDropdown then
    return
  end

  local selectedFolderID = self.SelectedFolderID
  local selectedText = "Unsorted"

  if selectedFolderID then
    local selectedFolder = addon.Services.Folder:Get(selectedFolderID)

    if selectedFolder then
      selectedText =
          selectedFolder.name
          or "Unsorted"
    end
  end

  self.FolderDropdown:SetDefaultText(selectedText)

  self.FolderDropdown:SetupMenu(
    function(
        dropdown,
        rootDescription
    )
      rootDescription:CreateRadio(
        "Unsorted",
        function()
          return self.SelectedFolderID == nil
        end,
        function()
          self.SelectedFolderID = nil
          self:RefreshFolderDropdown()
        end
      )

      local folders = GetSortedFolders()

      for _, folder in ipairs(folders) do
        local folderID = folder.id
        local folderName = folder.name

        rootDescription:CreateRadio(
          folderName,
          function()
            return self.SelectedFolderID == folderID
          end,
          function()
            self.SelectedFolderID = folderID
            self:RefreshFolderDropdown()
          end
        )
      end
    end
  )
end

--------------------------------------------------
-- Save mode
--------------------------------------------------
function ImportDialog:SetSaveMode(mode)
  local selectedTeam = addon.Services.Team:GetSelected()

  if mode == "override" and not selectedTeam then
    mode = "new"
  end

  self.SaveMode = mode

  self.NewTeamRadio:SetChecked(mode == "new")
  self.OverrideRadio:SetChecked(mode == "override")
end

--------------------------------------------------
-- Update save mode
--------------------------------------------------
function ImportDialog:UpdateSaveMode()
  local selectedTeam = addon.Services.Team:GetSelected()

  if selectedTeam then
    self.OverrideRadio:Enable()
    self.OverrideRadio.Label:SetTextColor(
      1,
      0.82,
      0
    )
  else
    self.OverrideRadio:Disable()
    self.OverrideRadio.Label:SetTextColor(
      0.5,
      0.5,
      0.5
    )

    if self.SaveMode == "override" then
      self.SaveMode = "new"
    end
  end

  self:SetSaveMode(self.SaveMode or "new")
end

--------------------------------------------------
-- Register
--------------------------------------------------
addon.UI.Dialogs.ImportDialog = ImportDialog
