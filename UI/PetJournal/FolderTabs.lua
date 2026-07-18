local addonName, addon = ...

addon.UI = addon.UI or {}
addon.UI.Views = addon.UI.Views or {}

local FolderTabs = {}

local TAB_WIDTH = 112
local TAB_HEIGHT = 26
local TAB_SPACING = 2

function FolderTabs:Create(parent)
  local frame =
      addon.UI.Components.Panel:Create(
        parent,
        {
          width = 126,
          height = 535,
        }
      )

  self.Frame = frame
  self.Buttons = {}

  self.CreateButton =
      addon.UI.Components.Button:Create(
        frame,
        {
          text = "New",
          width = 48,
          height = 24,

          onClick = function()
            addon.UI.Views.FolderDialog:ShowCreate()
          end,
        }
      )

  self.CreateButton:SetPoint(
    "BOTTOMLEFT",
    frame,
    "BOTTOMLEFT",
    7,
    7
  )

  self.RenameButton =
      addon.UI.Components.Button:Create(
        frame,
        {
          text = "Rename",
          width = 60,
          height = 24,

          onClick = function()
            self:RenameSelected()
          end,
        }
      )

  self.RenameButton:SetPoint(
    "LEFT",
    self.CreateButton,
    "RIGHT",
    4,
    0
  )

  self.DeleteButton =
      addon.UI.Components.Button:Create(
        frame,
        {
          text = "Delete",
          width = 112,
          height = 24,

          onClick = function()
            self:DeleteSelected()
          end,
        }
      )

  self.DeleteButton:SetPoint(
    "BOTTOMLEFT",
    self.CreateButton,
    "TOPLEFT",
    0,
    4
  )

  self.ImportButton =
      addon.UI.Components.Button:Create(
        frame,
        {
          text = "Import",
          width = 54,
          height = 24,

          onClick = function()
            addon.UI.Views.ImportDialog:Show()
          end,
        }
      )

  self.ImportButton:SetPoint(
    "BOTTOMLEFT",
    self.DeleteButton,
    "TOPLEFT",
    0,
    4
  )

  self.ExportButton =
      addon.UI.Components.Button:Create(
        frame,
        {
          text = "Export",
          width = 54,
          height = 24,

          onClick = function()
            -- Wordt in de volgende stap toegevoegd.
          end,
        }
      )

  self.ExportButton:SetPoint(
    "LEFT",
    self.ImportButton,
    "RIGHT",
    4,
    0
  )

  self.ExportButton:Disable()

  if not self.EventsRegistered then
    self.EventsRegistered = true

    local function Refresh()
      if self.Frame then
        self:Refresh()
      end
    end

    addon.EventBus:Register(
      addon.Events.FOLDER_CREATED,
      Refresh
    )

    addon.EventBus:Register(
      addon.Events.FOLDER_UPDATED,
      Refresh
    )

    addon.EventBus:Register(
      addon.Events.FOLDER_DELETED,
      Refresh
    )

    addon.EventBus:Register(
      addon.Events.FOLDER_SELECTED,
      Refresh
    )
  end

  self:Refresh()

  return frame
end

function FolderTabs:ClearButtons()
  for _, button in ipairs(self.Buttons or {}) do
    button:Hide()
    button:SetParent(nil)
  end

  self.Buttons = {}
end

function FolderTabs:CreateTab(label, folderKey, index)
  local button =
      addon.UI.Components.Button:Create(
        self.Frame,
        {
          text = label,
          width = TAB_WIDTH,
          height = TAB_HEIGHT,

          onClick = function()
            addon.Services.Folder:Select(
              folderKey
            )
          end,
        }
      )

  button:SetPoint(
    "TOPLEFT",
    self.Frame,
    "TOPLEFT",
    7,
    -7 - ((index - 1)
      * (TAB_HEIGHT + TAB_SPACING))
  )

  button.FolderKey = folderKey

  local acceptsTeams =
      folderKey == addon.Services.Folder.UNSORTED
      or (
        folderKey ~= addon.Services.Folder.ALL
        and folderKey ~= addon.Services.Folder.FAVORITES
      )

  if acceptsTeams then
    addon.UI.DragDrop:RegisterFolderTarget(
      button,
      folderKey
    )
  end

  table.insert(
    self.Buttons,
    button
  )

  return button
end

function FolderTabs:Refresh()
  if not self.Frame then
    return
  end

  addon.UI.DragDrop:ClearFolderTargets()

  self:ClearButtons()

  local index = 1

  self:CreateTab(
    "All Teams",
    addon.Services.Folder.ALL,
    index
  )

  index = index + 1

  self:CreateTab(
    "Favorites",
    addon.Services.Folder.FAVORITES,
    index
  )

  index = index + 1

  self:CreateTab(
    "Unsorted",
    addon.Services.Folder.UNSORTED,
    index
  )

  index = index + 1

  for _, folder in ipairs(
    addon.Services.Folder:GetSortedFolders()
  ) do
    self:CreateTab(
      folder.name,
      folder.id,
      index
    )

    index = index + 1
  end

  local selectedKey =
      addon.Services.Folder:GetSelectedKey()

  for _, button in ipairs(self.Buttons) do
    local selected =
        button.FolderKey == selectedKey

    if selected then
      button:Disable()
    else
      button:Enable()
    end
  end

  local customFolderSelected =
      selectedKey ~= addon.Services.Folder.ALL
      and selectedKey ~= addon.Services.Folder.UNSORTED
      and selectedKey ~= addon.Services.Folder.FAVORITES

  if customFolderSelected then
    self.RenameButton:Enable()
    self.DeleteButton:Enable()
  else
    self.RenameButton:Disable()
    self.DeleteButton:Disable()
  end
end

StaticPopupDialogs.PETMATCH_DELETE_FOLDER = {
  text = "Delete folder \"%s\"?\n\nTeams inside it will be moved to Unsorted.",
  button1 = "Delete",
  button2 = "Cancel",

  OnAccept = function(_, folder)
    if not folder then
      return
    end

    local success, errorMessage =
        addon.Services.Folder:Delete(
          folder.id
        )

    if not success then
      addon.Logger:Warn(
        errorMessage or "Unable to delete folder"
      )

      return
    end

    addon.Services.Folder:Select(
      addon.Services.Folder.UNSORTED
    )

    addon.Logger:Info(
      "Deleted folder:",
      folder.name
    )
  end,

  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

function FolderTabs:GetSelectedFolder()
  local selectedKey =
      addon.Services.Folder:GetSelectedKey()

  if selectedKey == addon.Services.Folder.ALL
      or selectedKey == addon.Services.Folder.UNSORTED
      or selectedKey == addon.Services.Folder.FAVORITES then
    return nil
  end

  return addon.Services.Folder:Get(
    selectedKey
  )
end

function FolderTabs:RenameSelected()
  local folder = self:GetSelectedFolder()

  if not folder then
    addon.Logger:Warn(
      "Select a custom folder first"
    )

    return
  end

  addon.UI.Views.FolderDialog:ShowRename(
    folder
  )
end

function FolderTabs:DeleteSelected()
  local folder = self:GetSelectedFolder()

  if not folder then
    addon.Logger:Warn(
      "Select a custom folder first"
    )

    return
  end

  StaticPopup_Show(
    "PETMATCH_DELETE_FOLDER",
    folder.name,
    nil,
    folder
  )
end

addon.UI.Views.FolderTabs = FolderTabs
