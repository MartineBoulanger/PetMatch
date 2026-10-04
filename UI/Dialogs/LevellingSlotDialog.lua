local _, addon = ...

local L = addon.L

local LevellingSlotDialog = {}

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
function LevellingSlotDialog:ClearState()
  self.SlotIndex = nil

  if self.MinimumLevelInput then
    self.MinimumLevelInput:ClearFocus()
  end

  if self.MinimumHealthInput then
    self.MinimumHealthInput:ClearFocus()
  end
end

--------------------------------------------------
-- Apply
--------------------------------------------------
function LevellingSlotDialog:Apply()
  local slotIndex = self.SlotIndex

  if not slotIndex then
    return false
  end

  --------------------------------------------------
  -- Minimum level
  --------------------------------------------------
  local minimumLevel =
      tonumber(self.MinimumLevelInput:GetText())
      or 1

  minimumLevel = math.floor(minimumLevel)

  if minimumLevel < 1 or minimumLevel > 24 then
    addon.Logger:Warn(L["MINIMUM_LEVEL_ERROR"])

    self.MinimumLevelInput:SetFocus()
    self.MinimumLevelInput:HighlightText()

    return false
  end

  --------------------------------------------------
  -- Minimum health
  --------------------------------------------------
  local healthText =
      addon.Utils:Trim(
        self.MinimumHealthInput:GetText()
        or ""
      )

  local minimumHealth

  if healthText ~= "" then
    minimumHealth = tonumber(healthText)

    if not minimumHealth or minimumHealth < 1 then
      addon.Logger:Warn(L["MINIMUM_HEALTH_ERROR"])

      self.MinimumHealthInput:SetFocus()
      self.MinimumHealthInput:HighlightText()

      return false
    end

    minimumHealth = math.floor(minimumHealth)
  end

  --------------------------------------------------
  -- Store slot setup
  --------------------------------------------------
  local success =
      addon.Services.TeamSetup:SetSpecialSlot(
        slotIndex,
        {
          type = "leveling",
          rawPetTag = "ZL",
          minimumLevel = minimumLevel,
          minimumHealth = minimumHealth,
        }
      )

  if not success then
    return false
  end

  return true
end

--------------------------------------------------
-- Create content
--------------------------------------------------
function LevellingSlotDialog:CreateContent(dialog)
  local content = dialog:GetContentFrame()

  --------------------------------------------------
  -- Minimum level
  --------------------------------------------------
  self.MinimumLevelLabel =
      addon.UI.Base.Label:Create(
        content,
        {
          text = L["MINIMUM_LEVEL"],
          justify = "LEFT",
        }
      )

  self.MinimumLevelLabel:SetPoint(
    "TOPLEFT",
    content,
    "TOPLEFT",
    0,
    0
  )

  self.MinimumLevelLabel:SetPoint(
    "TOPRIGHT",
    content,
    "TOPRIGHT",
    0,
    0
  )

  self.MinimumLevelInput =
      CreateFrame(
        "EditBox",
        nil,
        content,
        "InputBoxTemplate"
      )

  self.MinimumLevelInput:SetHeight(28)

  self.MinimumLevelInput:SetPoint(
    "TOPLEFT",
    self.MinimumLevelLabel,
    "BOTTOMLEFT",
    4,
    2
  )

  self.MinimumLevelInput:SetPoint(
    "TOPRIGHT",
    self.MinimumLevelLabel,
    "BOTTOMRIGHT",
    0,
    -4
  )

  self.MinimumLevelInput:SetAutoFocus(false)
  self.MinimumLevelInput:SetNumeric(true)
  self.MinimumLevelInput:SetMaxLetters(2)

  --------------------------------------------------
  -- Minimum health
  --------------------------------------------------
  self.MinimumHealthLabel =
      addon.UI.Base.Label:Create(
        content,
        {
          text = L["MINIMUM_HEALTH"],
          justify = "LEFT",
        }
      )

  self.MinimumHealthLabel:SetPoint(
    "TOPLEFT",
    self.MinimumLevelInput,
    "BOTTOMLEFT",
    -4,
    -12
  )

  self.MinimumHealthLabel:SetPoint(
    "TOPRIGHT",
    self.MinimumLevelInput,
    "BOTTOMRIGHT",
    0,
    -12
  )

  self.MinimumHealthInput =
      CreateFrame(
        "EditBox",
        nil,
        content,
        "InputBoxTemplate"
      )

  self.MinimumHealthInput:SetHeight(28)

  self.MinimumHealthInput:SetPoint(
    "TOPLEFT",
    self.MinimumHealthLabel,
    "BOTTOMLEFT",
    4,
    2
  )

  self.MinimumHealthInput:SetPoint(
    "TOPRIGHT",
    self.MinimumHealthLabel,
    "BOTTOMRIGHT",
    0,
    -4
  )

  self.MinimumHealthInput:SetAutoFocus(false)
  self.MinimumHealthInput:SetNumeric(true)
  self.MinimumHealthInput:SetMaxLetters(5)

  --------------------------------------------------
  -- Keyboard
  --------------------------------------------------
  self.MinimumLevelInput:SetScript(
    "OnEnterPressed",
    function()
      self.MinimumHealthInput:SetFocus()
      self.MinimumHealthInput:HighlightText()
    end
  )

  self.MinimumHealthInput:SetScript(
    "OnEnterPressed",
    function()
      dialog:Accept()
    end
  )

  self.MinimumLevelInput:SetScript(
    "OnEscapePressed",
    function()
      dialog:Cancel()
    end
  )

  self.MinimumHealthInput:SetScript(
    "OnEscapePressed",
    function()
      dialog:Cancel()
    end
  )
end

--------------------------------------------------
-- Create dialog
--------------------------------------------------
function LevellingSlotDialog:Create()
  if dialogInstance then
    return dialogInstance
  end

  local dialog = addon.UI.Base.Dialog:Create({
    name = "PetMatchLevellingSlotDialog",
    title = L["LEVELLING_PET"],
    width = DIALOG_WIDTH,
    contentMargin = CONTENT_MARGIN,
    padding = CONTENT_PADDING,
    bottomSpacing = 0,
    onAccept = function()
      return self:Apply()
    end,
    onCancel = function()
      self:ClearState()
      return true
    end,
    onClose = function()
      self:ClearState()
    end,
  })

  self:CreateContent(dialog)

  self.CancelButton =
      dialog:AddCancelButton({
        text = L["CANCEL"],
        width = 100,
      })

  self.ApplyButton =
      dialog:AddAcceptButton({
        text = L["APPLY"],
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
function LevellingSlotDialog:Show(slotIndex)
  slotIndex = tonumber(slotIndex)

  if not slotIndex or slotIndex < 1
      or slotIndex > 3 then
    return
  end

  local dialog = self:Create()

  self.SlotIndex = slotIndex

  local specialSlot =
      addon.Services.TeamSetup:GetSlot(slotIndex)

  local minimumLevel = 1
  local minimumHealth = ""

  if type(specialSlot) == "table"
      and (
        specialSlot.type == "leveling"
        or specialSlot.type == "levelingQueue"
      ) then
    minimumLevel =
        tonumber(
          specialSlot.minimumLevel
          or specialSlot.level
        )
        or 1

    if specialSlot.minimumHealth then
      minimumHealth =
          tostring(
            specialSlot.minimumHealth
          )
    end
  end

  self.MinimumLevelInput:SetText(
    tostring(minimumLevel)
  )

  self.MinimumHealthInput:SetText(minimumHealth)

  dialog:SetTitle(L["LEVELLING_PET"])

  dialog:Show()
  dialog:RefreshLayout()

  self.MinimumLevelInput:SetFocus()
  self.MinimumLevelInput:HighlightText()
end

--------------------------------------------------
-- Hide
--------------------------------------------------
function LevellingSlotDialog:Hide()
  if dialogInstance then
    dialogInstance:Hide()
  end
end

--------------------------------------------------
-- Register
--------------------------------------------------
addon.UI.Dialogs.LevellingSlotDialog = LevellingSlotDialog
