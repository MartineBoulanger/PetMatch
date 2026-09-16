local _, addon = ...

local L = addon.L
local DeleteTeamDialog = {}

local DIALOG_WIDTH = 384

local CONTENT_MARGIN = {
  left = -12,
  right = 12,
  top = 4,
  bottom = 8,
}

local CONTENT_PADDING = 14

local dialogInstance

--------------------------------------------------
-- Delete
--------------------------------------------------
function DeleteTeamDialog:Delete()
  local team = self.Team

  if not team then
    return false
  end

  local deleted = addon.Services.Team:Delete(team.id)

  if not deleted then
    addon.Logger:Warn(
      L["UNABLE_DELETE_TEAM"]
    )
    return false
  end

  return true
end

--------------------------------------------------
-- Clear state
--------------------------------------------------
function DeleteTeamDialog:ClearState()
  self.Team = nil
end

--------------------------------------------------
-- Create content
--------------------------------------------------
function DeleteTeamDialog:CreateContent(dialog)
  local content = dialog:GetContentFrame()

  self.Message =
      addon.UI.Base.Label:Create(
        content,
        {
          text = "",
          justify = "CENTER",
          color = addon.UI.Theme.Colors.Text,
        }
      )

  self.Message:SetPoint(
    "TOPLEFT",
    content,
    "TOPLEFT",
    0,
    0
  )

  self.Message:SetPoint(
    "TOPRIGHT",
    content,
    "TOPRIGHT",
    0,
    0
  )

  self.Message:SetJustifyH("CENTER")
  self.Message:SetJustifyV("TOP")
  self.Message:SetWordWrap(true)
end

--------------------------------------------------
-- Create dialog
--------------------------------------------------
function DeleteTeamDialog:Create()
  if dialogInstance then
    return dialogInstance
  end

  local dialog =
      addon.UI.Base.Dialog:Create({
        name = "PetMatchDeleteTeamDialog",
        title = L["DELETE_TEAM"],
        width = DIALOG_WIDTH,
        contentMargin = CONTENT_MARGIN,
        padding = CONTENT_PADDING,
        bottomSpacing = 0,
        onAccept = function() return self:Delete() end,
        onCancel =
            function()
              self:ClearState()
              return true
            end,
        onClose = function() self:ClearState() end,
      })

  self:CreateContent(dialog)

  --------------------------------------------------
  -- Footer
  --------------------------------------------------
  self.CancelButton =
      dialog:AddCancelButton({
        text = L["CANCEL"],
        width = 100,
      })

  self.DeleteButton =
      dialog:AddAcceptButton({
        text = L["DELETE"],
        width = 100,
      })

  --------------------------------------------------
  -- State
  --------------------------------------------------
  self.Dialog = dialog
  self.Frame = dialog:GetFrame()

  dialogInstance = dialog

  dialog:RefreshLayout()

  return dialog
end

--------------------------------------------------
-- Show
--------------------------------------------------
function DeleteTeamDialog:Show(team)
  if not team then
    return
  end

  local dialog = self:Create()

  self.Team = team

  dialog:SetTitle(L["DELETE_TEAM"])

  local teamName = team.name or L["UNNAMED_TEAM"]

  self.Message:SetText(
    L["DELETE_TEAM1"]
    .. "\""
    .. teamName
    .. "\"?\n\n"
    .. L["DELETE_TEAM2"]
  )

  dialog:Show()
  dialog:RefreshLayout()

  self.Frame:Raise()
end

--------------------------------------------------
-- Hide
--------------------------------------------------
function DeleteTeamDialog:Hide()
  if dialogInstance then
    dialogInstance:Hide()
  end
end

--------------------------------------------------
-- Register
--------------------------------------------------
addon.UI.Dialogs.DeleteTeamDialog = DeleteTeamDialog
