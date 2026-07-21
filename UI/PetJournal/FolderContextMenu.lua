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

  addon.UI.Views.FolderDialog:ShowRename(
    folder
  )
end

function FolderContextMenu:DeleteFolder(folderKey)
  local folder = addon.Services.Folder:Get(folderKey)

  if not folder then
    return
  end

  StaticPopup_Show(
    "PETMATCH_DELETE_FOLDER",
    folder.name,
    nil,
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

  addon.UI.Views.ImportDialog:ShowForFolder(
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

  addon.UI.Views.ExportDialog:ShowFolder(folderKey)
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

addon.UI.Views.FolderContextMenu =
    FolderContextMenu
