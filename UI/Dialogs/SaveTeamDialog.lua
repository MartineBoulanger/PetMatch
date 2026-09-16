local _, addon = ...

local L = addon.L
local SaveTeamDialog = {}

local DIALOG_WIDTH = 320

local CONTENT_MARGIN = {
  left = -12,
  right = 12,
  top = 4,
  bottom = 8,
}

local CONTENT_PADDING = 14

local dialogInstance

--------------------------------------------------
-- Clear state
--------------------------------------------------
function SaveTeamDialog:ClearState()
  if self.NameInput then
    self.NameInput:ClearFocus()
    self.NameInput:SetText("")
  end
end

--------------------------------------------------
-- Save
--------------------------------------------------
function SaveTeamDialog:Save()
  local name = addon.Utils:Trim(self.NameInput:GetText() or "")

  if name == "" then
    addon.Logger:Warn(L["TEAM_NAME_ERROR"])
    self.NameInput:SetFocus()
    self.NameInput:HighlightText()
    return false
  end

  --------------------------------------------------
  -- Selected folder
  --------------------------------------------------
  local teamList = addon.UI.Views.TeamList
  local folderKey = teamList and teamList.ExpandedFolderKey or nil

  local folderID = nil

  if folderKey
      and folderKey ~= addon.Services.Folder.ALL
      and folderKey ~= addon.Services.Folder.FAVORITES
      and folderKey ~= addon.Services.Folder.UNSORTED then
    local folder =
        addon.Services.Folder:Get(
          folderKey
        )

    if folder then
      folderID = folder.id
    end
  end

  --------------------------------------------------
  -- Pending special slots
  --------------------------------------------------
  local pendingSpecialSlots = addon.Services.BattleSlot:GetPendingSpecialSlots()

  local team, errorMessage =
      addon.Services.Team:CreateFromBattleSlots(name, folderID, pendingSpecialSlots)

  if not team then
    addon.Logger:Warn(errorMessage or L["UNABLE_SAVE_TEAM"])
    self.NameInput:SetFocus()
    self.NameInput:HighlightText()
    return false
  end

  addon.Services.Team:SetActive(team.id)
  addon.Services.BattleSlot:SetPendingSpecialSlots(team.specialSlots)

  return true
end

--------------------------------------------------
-- Create content
--------------------------------------------------
function SaveTeamDialog:CreateContent(dialog)
  local content = dialog:GetContentFrame()

  --------------------------------------------------
  -- Team name label
  --------------------------------------------------
  self.NameLabel =
      addon.UI.Base.Label:Create(
        content,
        {
          text = L["TEAM_NAME"],
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
  -- Team name input
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
  self.NameInput:SetMaxLetters(80)

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
function SaveTeamDialog:Create()
  if dialogInstance then
    return dialogInstance
  end

  local dialog =
      addon.UI.Base.Dialog:Create({
        name = "PetMatchSaveTeamDialog",
        title = L["SAVE_CURRENT"],
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
-- Show
--------------------------------------------------
function SaveTeamDialog:Show()
  local dialog = self:Create()

  self.NameInput:SetText("")

  dialog:SetTitle(L["SAVE_CURRENT"])
  dialog:Show()
  dialog:RefreshLayout()

  self.NameInput:SetFocus()
  self.NameInput:HighlightText()
end

--------------------------------------------------
-- Hide
--------------------------------------------------
function SaveTeamDialog:Hide()
  if dialogInstance then
    dialogInstance:Hide()
  end
end

--------------------------------------------------
-- Register
--------------------------------------------------
addon.UI.Dialogs.SaveTeamDialog = SaveTeamDialog
