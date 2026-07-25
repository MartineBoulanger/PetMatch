local _, addon = ...

addon.UI = addon.UI or {}
addon.UI.Views = addon.UI.Views or {}

local FolderContextMenu = {}

local function IsVirtualFolder(folderKey)
  return folderKey
      == addon.Services.Folder.ALL
      or folderKey
      == addon.Services.Folder.UNSORTED
      or folderKey
      == addon.Services.Folder.FAVORITES
end

function FolderContextMenu:Show(
    owner,
    folderKey
)
  if not owner or not folderKey then
    return
  end

  local folder =
      addon.Services.Folder:Get(folderKey)

  local isVirtual =
      IsVirtualFolder(folderKey)

  MenuUtil.CreateContextMenu(
    owner,
    function(_, rootDescription)
      local folderName =
          folder
          and folder.name
          or "Folder"

      rootDescription:CreateTitle(
        folderName
      )

      local renameButton =
          rootDescription:CreateButton(
            "Rename Folder",
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
            "Delete Folder",
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
        "Import Teams",
        function()
          self:ImportTeams(folderKey)
        end
      )

      local exportButton =
          rootDescription:CreateButton(
            "Export Teams",
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

function FolderContextMenu:RenameFolder(
    folderKey
)
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

  addon.DeleteFolderDialog:Show(
    folder
  )
end

function FolderContextMenu:ImportTeams(
    folderKey
)
  local storageFolderID = folderKey

  if folderKey
      == addon.Services.Folder.UNSORTED then
    storageFolderID = nil
  elseif IsVirtualFolder(folderKey) then
    storageFolderID = nil
  end

  addon.UI.Dialogs.ImportDialog:ShowForFolder(
    storageFolderID
  )
end

function FolderContextMenu:ExportTeams(
    folderKey
)
  local folder = addon.Services.Folder:Get(folderKey)

  if not folder then
    return
  end

  addon.UI.Dialogs.ExportDialog:ShowFolder(folderKey)
end

addon.UI.Actions.FolderContextMenu =
    FolderContextMenu
