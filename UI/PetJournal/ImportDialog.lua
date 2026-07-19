local addonName, addon = ...

local ImportDialog = {}

local DIALOG_WIDTH = 320
local DIALOG_HEIGHT = 340

local function GetSortedFolders()
  local folderService =
      addon.Services.Folder

  local sourceFolders =
      folderService:GetSortedFolders()

  local folders = {}

  for folderID, folder in pairs(
    sourceFolders or {}
  ) do
    if type(folder) == "table" then
      folders[#folders + 1] = {
        id = folder.id or folderID,
        name =
            folder.name
            or "Unnamed Folder",
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
          text = "Paste a PetMatch or Rematch import string below.",
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
          height = 130,
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
    "OnEscapePressed",
    function()
      self:Hide()
    end
  )

  self.FolderDropdown =
      CreateFrame(
        "DropdownButton",
        nil,
        frame,
        "WowStyle1DropdownTemplate"
      )

  self.FolderDropdown:SetPoint(
    "TOPLEFT",
    self.InputBackground,
    "BOTTOMLEFT",
    0,
    -10
  )

  self.FolderDropdown:SetSize(
    DIALOG_WIDTH - 23,
    26
  )

  self.NewTeamRadio =
      CreateFrame(
        "CheckButton",
        nil,
        frame,
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
      self.NewTeamRadio:CreateFontString(
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

  self.NewTeamRadio.Label:SetText(
    "Save as new team"
  )

  self.NewTeamRadio:SetScript(
    "OnClick",
    function()
      self:SetSaveMode("new")
    end
  )

  self.OverrideRadio =
      CreateFrame(
        "CheckButton",
        nil,
        frame,
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
      self.OverrideRadio:CreateFontString(
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
    self.OverrideRadio,
    "BOTTOMLEFT",
    0,
    -10
  )

  self.Status:SetHeight(42)

  self.SaveButton =
      addon.UI.Components.Button:Create(
        frame,
        {
          text = "Save Team",
          width = 95,

          onClick = function()
            self:SaveTeam()
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

  self.LoadButton =
      addon.UI.Components.Button:Create(
        frame,
        {
          text = "Load",
          width = 95,

          onClick = function()
            self:LoadTeam()
          end,
        }
      )

  self.LoadButton:SetPoint(
    "RIGHT",
    self.SaveButton,
    "LEFT",
    -6,
    0
  )

  self.CancelButton =
      addon.UI.Components.Button:Create(
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
    self.LoadButton,
    "LEFT",
    -6,
    0
  )

  self.Input:SetScript(
    "OnTextChanged",
    function()
      self:UpdateButtons()
    end
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

  self.SelectedFolderID =
      addon.Services.Folder:GetSelectedStorageFolderID()

  if self.RefreshFolderDropdown then
    self:RefreshFolderDropdown()
  end

  self.SaveMode = "new"

  self:UpdateSaveMode()
  self:UpdateButtons()
  -- self:RefreshFolderDropdown()
  self.Frame:Show()
  -- self.Frame:Raise()
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

function ImportDialog:SetSelectedFolder(
    folderID
)
  self.SelectedFolderID = folderID
  self:RefreshFolderDropdown()
end

function ImportDialog:GetImportData()
  local value =
      addon.Utils:Trim(
        self.Input:GetText() or ""
      )

  local importData, errorMessage =
      addon.Services.ImportExport:
      Parse(value)

  if not importData then
    self:SetStatus(
      errorMessage or "Invalid import string"
    )

    return nil
  end

  importData.folderID =
      self.SelectedFolderID

  return importData
end

function ImportDialog:SaveTeam()
  if self.SaveMode == "override" then
    self:OverrideExisting()
    return
  end

  local importData, folderID = self:GetImportData()

  if not importData then
    return
  end

  local team, err =
      addon.Services.Team:CreateFromImport(
        importData,
        folderID
      )

  if not team then
    self:SetStatus(
      err or "Unable to save team."
    )
    return
  end

  local folderKey =
      team.folderID
      or addon.Services.Folder.UNSORTED

  addon.Services.Folder:Select(folderKey)

  C_Timer.After(0, function()
    local success, loadError =
        addon.Services.Team:Load(team.id)

    if not success then
      self:SetStatus(
        loadError or "Unable to load team."
      )
      return
    end

    self:Hide()
  end)
end

function ImportDialog:OverrideExisting()
  local selectedTeam =
      addon.Services.Team:GetSelected()

  if not selectedTeam then
    self:SetStatus(
      "Select a team to override"
    )

    return
  end

  local importData =
      self:GetImportData()

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

function ImportDialog:LoadTeam()
  local importData =
      self:GetImportData()

  if not importData then
    return
  end

  local success, errorMessage =
      addon.Services.Team:
      LoadFromImport(importData)

  if not success then
    self:SetStatus(
      errorMessage
      or "Unable to load team"
    )

    return
  end

  self:Hide()
end

function ImportDialog:UpdateButtons()
  local hasText =
      addon.Utils:Trim(
        self.Input and self.Input:GetText() or ""
      ) ~= ""

  local selectedTeam =
      addon.Services.Team:GetSelected()

  local hasSelectedTeam =
      selectedTeam ~= nil

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

function ImportDialog:RefreshFolderDropdown()
  if not self.FolderDropdown then
    return
  end

  local selectedFolderID =
      self.SelectedFolderID

  local selectedText =
  "Unsorted"

  if selectedFolderID then
    local selectedFolder =
        addon.Services.Folder:Get(
          selectedFolderID
        )

    if selectedFolder then
      selectedText =
          selectedFolder.name
          or "Unsorted"
    end
  end

  self.FolderDropdown:SetDefaultText(
    selectedText
  )

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
        local folderID =
            folder.id

        local folderName =
            folder.name

        rootDescription:CreateRadio(
          folderName,
          function()
            return self.SelectedFolderID
                == folderID
          end,
          function()
            self.SelectedFolderID =
                folderID

            self:RefreshFolderDropdown()
          end
        )
      end
    end
  )
end

function ImportDialog:SetSaveMode(mode)
  local selectedTeam =
      addon.Services.Team:GetSelected()

  if mode == "override"
      and not selectedTeam then
    mode = "new"
  end

  self.SaveMode = mode

  self.NewTeamRadio:SetChecked(
    mode == "new"
  )

  self.OverrideRadio:SetChecked(
    mode == "override"
  )
end

function ImportDialog:UpdateSaveMode()
  local selectedTeam =
      addon.Services.Team:GetSelected()

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

  self:SetSaveMode(
    self.SaveMode or "new"
  )
end

addon.UI.Views.ImportDialog =
    ImportDialog
