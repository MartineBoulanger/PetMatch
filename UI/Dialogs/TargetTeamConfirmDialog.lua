local _, addon = ...

local L = addon.L
local TargetTeamConfirmDialog = {}

local DIALOG_WIDTH = 320

local CONTENT_MARGIN = {
  left = -12,
  right = 12,
  top = 4,
  bottom = 8,
}

local CONTENT_PADDING = 12

local dialogInstance

--------------------------------------------------
-- Create
--------------------------------------------------
function TargetTeamConfirmDialog:Create()
  if dialogInstance then
    return dialogInstance
  end

  local dialog =
      addon.UI.Base.Dialog:Create({
        name = "PetMatchTargetTeamConfirmDialog",
        title = L["LOAD_TEAM"],
        width = DIALOG_WIDTH,
        contentMargin = CONTENT_MARGIN,
        padding = CONTENT_PADDING,
        bottomSpacing = 0,
        onAccept =
            function()
              return self:LoadTeam()
            end,
        onCancel =
            function()
              self.Team = nil
              self.NPCID = nil
              return true
            end,
        onClose =
            function()
              self.Team = nil
              self.NPCID = nil
            end,
      })

  local content = dialog:GetContentFrame()

  ------------------------------------------------
  -- Description
  ------------------------------------------------
  self.Description =
      addon.UI.Base.Label:Create(
        content,
        {
          text = "",
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

  ------------------------------------------------
  -- Footer
  ------------------------------------------------
  self.CancelButton =
      dialog:AddCancelButton({
        text = L["CANCEL"],
      })

  self.LoadButton =
      dialog:AddAcceptButton({
        text = L["LOAD_TEAM"],
        width = 100,
      })

  ------------------------------------------------
  -- State
  ------------------------------------------------
  self.Dialog = dialog
  self.Frame = dialog:GetFrame()

  self.Team = nil
  self.NPCID = nil

  ------------------------------------------------
  -- Cleanup
  ------------------------------------------------

  self.Frame:HookScript(
    "OnHide",
    function()
      self.Team = nil
      self.NPCID = nil
    end
  )

  ------------------------------------------------
  -- Layout
  ------------------------------------------------

  dialog:RefreshLayout()

  dialogInstance = dialog

  return dialog
end

--------------------------------------------------
-- Show
--------------------------------------------------
function TargetTeamConfirmDialog:Show(team, npcID)
  if not team or not team.id then
    return
  end

  local dialog = self:Create()

  self.Team = team
  self.NPCID = npcID

  dialog:SetTitle(
    L["LOAD_TEAM"]
  )

  self.Description:SetText(
    L["LOAD"] .. " \""
    .. (team.name or L["UNNAMED_TEAM"])
    .. "\" " .. L["LOAD_CURRENT"]
  )

  dialog:Show()
  dialog:RefreshLayout()

  self.Frame:Raise()
end

--------------------------------------------------
-- Hide
--------------------------------------------------
function TargetTeamConfirmDialog:Hide()
  if not dialogInstance then
    return
  end

  dialogInstance:Hide()

  self.Team = nil
  self.NPCID = nil
end

--------------------------------------------------
-- Load team
--------------------------------------------------
function TargetTeamConfirmDialog:LoadTeam()
  local team = self.Team

  if not team or not team.id then
    return
  end

  local teamService = addon.Services.Team

  if not teamService then
    return
  end

  local success, errorMessage = teamService:Load(team.id)

  if not success then
    addon.Logger:Warn(
      errorMessage
      or L["UNABLE_LOAD_TEAM"]
    )

    return false
  end

  return true
end

--------------------------------------------------
-- Register
--------------------------------------------------
addon.UI.Dialogs.TargetTeamConfirmDialog = TargetTeamConfirmDialog
