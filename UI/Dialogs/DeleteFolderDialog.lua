local _, addon = ...

addon.UI.Dialogs = addon.UI.Dialogs or {}

local L = addon.L
local DeleteFolderDialog = {}

local DIALOG_WIDTH = 384

local dialogInstance

local function CountFolderTeams(folderID)
  local count = 0

  for _, team in pairs(
    addon.Services.Team:GetTeams()
  ) do
    if team.folderID == folderID then
      count = count + 1
    end
  end

  return count
end

local function DeleteFolder(
    folder,
    deleteTeams
)
  if not folder then
    return
  end

  local success, errorMessage =
      addon.Services.Folder:Delete(
        folder.id,
        deleteTeams
      )

  if not success then
    addon.Logger:Warn(
      errorMessage
      or L["UNABLE_DELETE_FOLDER"]
    )

    return
  end

  addon.Services.Folder:Select(
    addon.Services.Folder.UNSORTED
  )
end

local function CreateDialog()
  local dialog = addon.UI.Base.Dialog:Create({
    name = "PetMatchDeleteFolderDialog",
    title = L["DELETE_FOLDER"],
    width = DIALOG_WIDTH,
    contentMargin = {
      left = -12,
      top = 4
    },
    bottomSpacing = 0,
    onAccept = function(control)
      DeleteFolder(
        control.folder,
        false
      )
    end,
    onExtraAccept = function(control)
      DeleteFolder(
        control.folder,
        true
      )
    end,
    onCancel = function(control) control.folder = nil end
  })

  dialog.CancelButton = dialog:AddCancelButton({
    text = L["CANCEL"]
  })

  dialog.MoveButton = dialog:AddAcceptButton({
    text = L["MOVE_TO_UNSORTED"],
    width = 140
  })

  dialog.DeleteButton = dialog:AddExtraButton({
    text = L["DELETE_TEAMS"],
    width = 110
  })

  local content = dialog:GetContentFrame()
  local message = content:CreateFontString(
    nil,
    "OVERLAY",
    "GameFontHighlight"
  )

  message:SetPoint(
    "TOPLEFT",
    content,
    "TOPLEFT",
    0,
    0
  )

  message:SetPoint(
    "TOPRIGHT",
    content,
    "TOPRIGHT",
    0,
    0
  )

  message:SetJustifyH("CENTER")
  message:SetJustifyV("TOP")
  message:SetWordWrap(true)

  dialog.Message = message

  dialog:GetFrame():HookScript(
    "OnHide",
    function()
      dialog.Folder = nil
    end
  )

  return dialog
end

function DeleteFolderDialog:Show(folder)
  if not folder then
    return
  end

  if not dialogInstance then
    dialogInstance = CreateDialog()
  end

  local teamCount = CountFolderTeams(folder.id)
  local teamText

  if teamCount == 1 then
    teamText = L["ONE_TEAM"]
  else
    teamText =
        tostring(teamCount)
        .. L["TEAMS"]
  end

  dialogInstance.folder = folder

  dialogInstance.Message:SetText(
    L["DELETE_FOLDER1"]
    .. folder.name
    .. "\"?\n\n"
    .. L["DELETE_FOLDER2"]
    .. teamText
    .. ".\n"
    .. L["DELETE_FOLDER3"]
    .. L["DELETE_FOLDER4"]
  )

  dialogInstance.DeleteButton:SetEnabled(
    teamCount > 0
  )

  dialogInstance:Show()
end

function DeleteFolderDialog:Hide()
  if dialogInstance then
    dialogInstance:Hide()
  end
end

addon.UI.Dialogs.DeleteFolderDialog = DeleteFolderDialog
