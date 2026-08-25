local _, addon = ...

local ClearLevellingQueueDialog = {}

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
-- Clear
--------------------------------------------------
function ClearLevellingQueueDialog:Clear()
  local removed =
      addon.Services.LevellingQueue:
      Clear()

  if removed == 0 then
    addon.Logger:Warn(
      "The levelling queue is already empty."
    )

    return true
  end

  if removed == 1 then
    addon.Logger:Info(
      "Removed 1 pet from the levelling queue."
    )
  else
    addon.Logger:Info(
      "Removed "
      .. removed
      .. " pets from the levelling queue."
    )
  end

  return true
end

--------------------------------------------------
-- Create content
--------------------------------------------------
function ClearLevellingQueueDialog:CreateContent(dialog)
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
function ClearLevellingQueueDialog:Create()
  if dialogInstance then
    return dialogInstance
  end

  local dialog =
      addon.UI.Base.Dialog:Create({
        name = "PetMatchClearLevellingQueueDialog",
        title = "Clear Levelling Queue",
        width = DIALOG_WIDTH,
        contentMargin = CONTENT_MARGIN,
        padding = CONTENT_PADDING,
        bottomSpacing = 0,
        onAccept = function() return self:Clear() end,
        onCancel = function() return true end,
      })

  self:CreateContent(dialog)

  --------------------------------------------------
  -- Footer
  --------------------------------------------------
  self.CancelButton =
      dialog:AddCancelButton({
        text = "Cancel",
      })

  self.ClearButton =
      dialog:AddAcceptButton({
        text = "Clear Queue",
        width = 120
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
function ClearLevellingQueueDialog:Show()
  local service = addon.Services.LevellingQueue

  if not service then
    return
  end

  local count = service:GetCount()

  if count == 0 then
    addon.Logger:Warn(
      "The levelling queue is already empty."
    )

    return
  end

  local dialog = self:Create()

  local message

  if count == 1 then
    message =
    "Remove 1 pet from the levelling queue?"
  else
    message =
        "Remove all "
        .. count
        .. " pets from the levelling queue?"
  end

  self.Message:SetText(
    message
    .. "\n\n"
    .. "With this action the levelling queue will be emptied."
  )

  dialog:Show()
  dialog:RefreshLayout()

  self.Frame:Raise()
end

--------------------------------------------------
-- Hide
--------------------------------------------------
function ClearLevellingQueueDialog:Hide()
  if dialogInstance then
    dialogInstance:Hide()
  end
end

--------------------------------------------------
-- Register
--------------------------------------------------
addon.UI.Dialogs.ClearLevellingQueueDialog = ClearLevellingQueueDialog
