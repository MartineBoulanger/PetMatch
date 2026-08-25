local _, addon = ...

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
      "No pets were added to the levelling queue."
    )

    return true
  end

  if added == 1 then
    addon.Logger:Info(
      "Added 1 pet to the levelling queue."
    )
  else
    addon.Logger:Info(
      "Added "
      .. added
      .. " pets to the levelling queue."
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
        title = "Fill Levelling Queue",
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
        text = "Cancel",
      })

  self.FillButton =
      dialog:AddAcceptButton({
        text = "Add Pets",
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
      "Every pet that can be levelled is already in the queue."
    )

    return
  end

  local dialog = self:Create()

  self.Candidates = candidates

  local message

  if #candidates == 1 then
    message =
    "Add 1 pet to the levelling queue?"
  else
    message =
        "Add "
        .. #candidates
        .. " pets to the levelling queue?"
  end

  self.Message:SetText(
    message
    .. "\n\n"
    .. "Every pet below level 25 will be added. "
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
