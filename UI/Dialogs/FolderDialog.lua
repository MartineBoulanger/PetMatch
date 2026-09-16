local _, addon = ...

local L = addon.L
local FolderDialog = {}

local DIALOG_WIDTH = 320
local CONTENT_PADDING = 14
local CONTENT_MARGIN = {
  left = -12,
  right = 12,
  top = 4,
  bottom = 8,
}

local dialogInstance

--------------------------------------------------
-- State
--------------------------------------------------
function FolderDialog:ClearState()
  self.Mode = "create"
  self.Folder = nil

  if self.NameInput then
    self.NameInput:ClearFocus()
    self.NameInput:SetText("")
  end
end

--------------------------------------------------
-- Save
--------------------------------------------------
function FolderDialog:Save()
  local name = addon.Utils:Trim(self.NameInput:GetText() or "")

  if name == "" then
    addon.Logger:Warn(L["FOLDER_NAME_ERROR"])
    self.NameInput:SetFocus()
    self.NameInput:HighlightText()
    return false
  end

  local folder
  local errorMessage

  if self.Mode == "rename" then
    if not self.Folder then
      addon.Logger:Warn(L["NO_FOLDER_SELECTED"])
      return false
    end

    folder, errorMessage =
        addon.Services.Folder:Rename(
          self.Folder.id,
          name
        )
  else
    folder, errorMessage =
        addon.Services.Folder:Create(
          name
        )
  end

  if not folder then
    addon.Logger:Warn(errorMessage or L["UNABLE_SAVE_FOLDER"])
    self.NameInput:SetFocus()
    self.NameInput:HighlightText()
    return false
  end

  addon.Services.Folder:Select(folder.id)

  return true
end

--------------------------------------------------
-- Create content
--------------------------------------------------
function FolderDialog:CreateContent(dialog)
  local content = dialog:GetContentFrame()

  --------------------------------------------------
  -- Name label
  --------------------------------------------------
  self.NameLabel =
      addon.UI.Base.Label:Create(
        content,
        {
          text = L["FOLDER_NAME"],
          justify = "LEFT",
        }
      )

  self.NameLabel:SetPoint(
    "TOPLEFT",
    content,
    "TOPLEFT",
    0,
    0
  )

  self.NameLabel:SetPoint(
    "TOPRIGHT",
    content,
    "TOPRIGHT",
    0,
    0
  )

  --------------------------------------------------
  -- Name input
  --------------------------------------------------
  self.NameInput =
      CreateFrame(
        "EditBox",
        nil,
        content,
        "InputBoxTemplate"
      )

  self.NameInput:SetHeight(28)

  self.NameInput:SetPoint(
    "TOPLEFT",
    self.NameLabel,
    "BOTTOMLEFT",
    4,
    2
  )

  self.NameInput:SetPoint(
    "TOPRIGHT",
    self.NameLabel,
    "BOTTOMRIGHT",
    0,
    -4
  )

  self.NameInput:SetAutoFocus(false)
  self.NameInput:SetMaxLetters(60)

  --------------------------------------------------
  -- Keyboard
  --------------------------------------------------
  self.NameInput:SetScript(
    "OnEnterPressed",
    function()
      dialog:Accept()
    end
  )

  self.NameInput:SetScript(
    "OnEscapePressed",
    function()
      dialog:Cancel()
    end
  )
end

--------------------------------------------------
-- Create dialog
--------------------------------------------------
function FolderDialog:Create()
  if dialogInstance then
    return dialogInstance
  end

  local dialog =
      addon.UI.Base.Dialog:Create({
        name = "PetMatchFolderDialog",
        title = L["CREATE_FOLDER"],
        width = DIALOG_WIDTH,
        contentMargin = CONTENT_MARGIN,
        padding = CONTENT_PADDING,
        bottomSpacing = 0,
        onAccept = function() return self:Save() end,
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
        text = L["CANCEL"],
        width = 100,
      })

  self.SaveButton =
      dialog:AddAcceptButton({
        text = L["SAVE"],
        width = 100,
      })

  dialogInstance = dialog

  self.Dialog = dialog
  self.Frame = dialog:GetFrame()

  dialog:RefreshLayout()

  return dialog
end

--------------------------------------------------
-- Show create
--------------------------------------------------
function FolderDialog:ShowCreate()
  local dialog = self:Create()

  self.Mode = "create"
  self.Folder = nil

  dialog:SetTitle(L["CREATE_FOLDER"])

  self.NameInput:SetText(L["NEW_FOLDER"])

  dialog:Show()
  dialog:RefreshLayout()

  self.NameInput:SetFocus()
  self.NameInput:HighlightText()
end

--------------------------------------------------
-- Show rename
--------------------------------------------------
function FolderDialog:ShowRename(folder)
  if not folder then
    return
  end

  local dialog = self:Create()

  self.Mode = "rename"
  self.Folder = folder

  dialog:SetTitle(L["RENAME_FOLDER"])

  self.NameInput:SetText(folder.name or "")

  dialog:Show()
  dialog:RefreshLayout()

  self.NameInput:SetFocus()
  self.NameInput:HighlightText()
end

--------------------------------------------------
-- Hide
--------------------------------------------------
function FolderDialog:Hide()
  if dialogInstance then
    dialogInstance:Hide()
  end
end

--------------------------------------------------
-- Register
--------------------------------------------------
addon.UI.Dialogs.FolderDialog = FolderDialog
