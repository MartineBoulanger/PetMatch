local _, addon = ...

local L = addon.L
local FolderContextMenu = {}

local function IsVirtualFolder(folderKey)
  return folderKey
      == addon.Services.Folder.UNSORTED
      or folderKey
      == addon.Services.Folder.FAVORITES
end

function FolderContextMenu:Show(owner, folderKey)
  if not owner or not folderKey then
    return
  end

  local folder = addon.Services.Folder:Get(folderKey)
  local isVirtual = IsVirtualFolder(folderKey)

  MenuUtil.CreateContextMenu(
    owner,
    function(_, rootDescription)
      local folderName = folder and folder.name or L["FOLDER"]

      rootDescription:CreateTitle(folderName)

      local folderService = addon.Services.Folder
      local index = folderService:GetIndex(folderKey)
      local folders = folderService:GetSortedFolders()

      local moveUp =
          rootDescription:CreateButton(
            L["MOVE_UP"],
            function()
              folderService:MoveUp(folderKey)
            end
          )

      moveUp:SetEnabled(
        index ~= nil
        and index > 1
      )

      local moveDown =
          rootDescription:CreateButton(
            L["MOVE_DOWN"],
            function()
              folderService:MoveDown(folderKey)
            end
          )

      moveDown:SetEnabled(
        index ~= nil
        and index < #folders
      )

      rootDescription:CreateDivider()

      local renameButton =
          rootDescription:CreateButton(
            L["RENAME_FOLDER"],
            function()
              self:RenameFolder(folderKey)
            end
          )

      renameButton:SetEnabled(
        not isVirtual
        and folder ~= nil
      )

      local deleteButton =
          rootDescription:CreateButton(
            L["DELETE_FOLDER"],
            function()
              self:DeleteFolder(folderKey)
            end
          )

      deleteButton:SetEnabled(
        not isVirtual
        and folder ~= nil
      )

      rootDescription:CreateDivider()

      rootDescription:CreateButton(
        L["IMPORT_TEAMS"],
        function()
          self:ImportTeams(folderKey)
        end
      )

      local exportButton =
          rootDescription:CreateButton(
            L["EXPORT_TEAMS"],
            function()
              self:ExportTeams(folderKey)
            end
          )

      exportButton:SetEnabled(
        not isVirtual
        and folder ~= nil
      )
    end
  )
end

function FolderContextMenu:RenameFolder(folderKey)
  local folder = addon.Services.Folder:Get(folderKey)

  if not folder then
    return
  end

  addon.UI.Dialogs.FolderDialog:ShowRename(
    folder
  )
end

function FolderContextMenu:DeleteFolder(folderKey)
  local folder = addon.Services.Folder:Get(folderKey)

  if not folder then
    return
  end

  addon.UI.Dialogs.DeleteFolderDialog:Show(
    folder
  )
end

function FolderContextMenu:ImportTeams(folderKey)
  local storageFolderID = folderKey

  if folderKey == addon.Services.Folder.UNSORTED then
    storageFolderID = nil
  elseif IsVirtualFolder(folderKey) then
    storageFolderID = nil
  end

  addon.UI.Dialogs.ImportDialog:ShowForFolder(
    storageFolderID
  )
end

function FolderContextMenu:ExportTeams(folderKey)
  local folder = addon.Services.Folder:Get(folderKey)

  if not folder then
    return
  end

  addon.UI.Dialogs.ExportDialog:ShowFolder(folderKey)
end

addon.UI.Actions.FolderContextMenu = FolderContextMenu
