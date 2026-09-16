local _, addon = ...

local L = addon.L
local FillLevellingQueueDialog = {}

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
-- Fill
--------------------------------------------------
function FillLevellingQueueDialog:Fill()
  local candidates = self.Candidates

  self:ClearState()

  local added =
      addon.Services.LevellingQueue:
      Fill(
        candidates
      )

  if added == 0 then
    addon.Logger:Warn(
      L["NOT_ADDED_QUEUE"]
    )

    return true
  end

  if added == 1 then
    addon.Logger:Info(
      L["ONE_PET_ADDED_QUEUE"]
    )
  else
    addon.Logger:Info(
      L["ADDED_QUEUE1"]
      .. added
      .. L["ADDED_QUEUE2"]
    )
  end

  return true
end

--------------------------------------------------
-- Clear state
--------------------------------------------------
function FillLevellingQueueDialog:ClearState()
  self.Candidates = nil
end

--------------------------------------------------
-- Create content
--------------------------------------------------
function FillLevellingQueueDialog:CreateContent(dialog)
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
function FillLevellingQueueDialog:Create()
  if dialogInstance then
    return dialogInstance
  end

  local dialog =
      addon.UI.Base.Dialog:Create({
        name = "PetMatchFillLevellingQueueDialog",
        title = L["FILL_QUEUE"],
        width = DIALOG_WIDTH,
        contentMargin = CONTENT_MARGIN,
        padding = CONTENT_PADDING,
        bottomSpacing = 0,
        onAccept = function() return self:Fill() end,
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
      })

  self.FillButton =
      dialog:AddAcceptButton({
        text = L["ADD_PETS"],
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
function FillLevellingQueueDialog:Show()
  local service = addon.Services.LevellingQueue

  if not service then
    return
  end

  local candidates = service:GetFillCandidates()

  if #candidates == 0 then
    addon.Logger:Warn(
      L["ALL_ALREADY_IN_QUEUE"]
    )

    return
  end

  local dialog = self:Create()

  self.Candidates = candidates

  local message

  if #candidates == 1 then
    message =
        L["ADD_ONE_PET_QUEUE"]
  else
    message =
        L["ADD_MULTI_PETS_QUEUE1"]
        .. #candidates
        .. L["ADD_MULTI_PETS_QUEUE2"]
  end

  self.Message:SetText(
    message
    .. "\n\n"
    .. L["ALL_PETS_ADD_TO_QUEUE"]
  )

  dialog:Show()
  dialog:RefreshLayout()

  self.Frame:Raise()
end

--------------------------------------------------
-- Hide
--------------------------------------------------
function FillLevellingQueueDialog:Hide()
  if dialogInstance then
    dialogInstance:Hide()
  end
end

--------------------------------------------------
-- Register
--------------------------------------------------
addon.UI.Dialogs.FillLevellingQueueDialog = FillLevellingQueueDialog
