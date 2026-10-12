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
  self.SelectedColor = nil
  self.SelectedIcon = nil

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

  if self.Mode == "edit" or self.Mode == "rename" then
    if not self.Folder then
      addon.Logger:Warn(L["NO_FOLDER_SELECTED"])
      return false
    end

    folder, errorMessage =
        addon.Services.Folder:Update(
          self.Folder.id,
          name,
          self.SelectedColor,
          self.SelectedIcon
        )
  else
    folder, errorMessage =
        addon.Services.Folder:Create(
          name,
          self.SelectedColor,
          self.SelectedIcon
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
-- Update color preview
--------------------------------------------------
function FolderDialog:UpdateColorPreview()
  if not self.ColorPreview then
    return
  end

  if not self.SelectedColor then
    self.ColorPreview:SetColorTexture(1, 1, 1, 1)
    return
  end

  local hex = self.SelectedColor:gsub("^#", "")

  if #hex == 8 then
    hex = hex:sub(3)
  end

  local r = tonumber(hex:sub(1, 2), 16)
  local g = tonumber(hex:sub(3, 4), 16)
  local b = tonumber(hex:sub(5, 6), 16)

  if r and g and b then
    self.ColorPreview:SetColorTexture(
      r / 255, g / 255, b / 255, 1
    )
  end
end

--------------------------------------------------
-- Open color picker
--------------------------------------------------
function FolderDialog:OpenColorPicker()
  local r, g, b = 1, 1, 1

  if self.SelectedColor then
    local hex = self.SelectedColor:gsub("^#", "")

    if #hex == 8 then
      hex = hex:sub(3)
    end

    r = (tonumber(hex:sub(1, 2), 16) or 255) / 255
    g = (tonumber(hex:sub(3, 4), 16) or 255) / 255
    b = (tonumber(hex:sub(5, 6), 16) or 255) / 255
  end

  local previousColor = self.SelectedColor

  local function ApplyColor()
    local red, green, blue = ColorPickerFrame:GetColorRGB()

    self.SelectedColor = string.format(
      "FF%02X%02X%02X",
      math.floor(red * 255 + 0.5),
      math.floor(green * 255 + 0.5),
      math.floor(blue * 255 + 0.5)
    )

    self:UpdateColorPreview()
  end

  ColorPickerFrame:SetupColorPickerAndShow({
    r = r,
    g = g,
    b = b,
    hasOpacity = false,
    swatchFunc = ApplyColor,
    cancelFunc = function()
      self.SelectedColor = previousColor
      self:UpdateColorPreview()
    end,
  })

  --------------------------------------------------
  -- Keep Blizzard ColorPicker above PetMatch dialogs
  --------------------------------------------------
  local parentFrame = self.Dialog:GetFrame()

  ColorPickerFrame:SetFrameStrata("FULLSCREEN_DIALOG")
  ColorPickerFrame:SetFrameLevel(
    parentFrame:GetFrameLevel() + 1000
  )

  ColorPickerFrame:Raise()
end

--------------------------------------------------
-- Update icon preview
--------------------------------------------------
function FolderDialog:UpdateIconPreview()
  if not self.IconPreview then
    return
  end

  if self.SelectedIcon then
    self.IconPreview:SetTexture(self.SelectedIcon)
    self.IconPreview:Show()
  else
    self.IconPreview:SetTexture(nil)
    self.IconPreview:Hide()
  end
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
  -- Color label
  --------------------------------------------------
  self.ColorLabel = addon.UI.Base.Label:Create(content, {
    text = L["FOLDER_COLOR"] or "Folder Color",
    justify = "LEFT",
  })

  self.ColorLabel:SetPoint(
    "TOPLEFT",
    self.NameInput,
    "BOTTOMLEFT",
    -4,
    -12
  )

  --------------------------------------------------
  -- Color preview
  --------------------------------------------------
  self.ColorPreviewFrame = CreateFrame("Frame", nil, content)
  self.ColorPreviewFrame:SetSize(26, 26)
  self.ColorPreviewFrame:SetPoint(
    "TOPLEFT",
    self.ColorLabel,
    "BOTTOMLEFT",
    4,
    -8
  )

  self.ColorPreview = self.ColorPreviewFrame:CreateTexture(nil, "ARTWORK")
  self.ColorPreview:SetAllPoints()
  self.ColorPreview:SetColorTexture(1, 1, 1, 1)

  --------------------------------------------------
  -- Choose color
  --------------------------------------------------
  self.ColorButton = addon.UI.Base.Button:Create(content, {
    text = L["CHOOSE_COLOR"] or "Choose Color",
    width = 125,
    onClick = function()
      self:OpenColorPicker()
    end,
  })

  self.ColorButton:SetPoint(
    "LEFT",
    self.ColorPreviewFrame,
    "RIGHT",
    10,
    0
  )

  --------------------------------------------------
  -- Reset color
  --------------------------------------------------
  self.ResetColorButton = addon.UI.Base.Button:Create(content, {
    text = L["RESET"] or "Reset",
    width = 75,
    onClick = function()
      self.SelectedColor = nil
      self:UpdateColorPreview()
    end,
  })

  self.ResetColorButton:SetPoint(
    "LEFT",
    self.ColorButton,
    "RIGHT",
    22,
    0
  )

  --------------------------------------------------
  -- Icon label
  --------------------------------------------------
  self.IconLabel = addon.UI.Base.Label:Create(content, {
    text = L["FOLDER_ICON"] or "Folder Icon",
    justify = "LEFT",
  })

  self.IconLabel:SetPoint(
    "TOPLEFT",
    self.ColorPreviewFrame,
    "BOTTOMLEFT",
    -4,
    -12
  )

  --------------------------------------------------
  -- Icon preview
  --------------------------------------------------
  self.IconPreviewFrame = CreateFrame("Frame", nil, content)
  self.IconPreviewFrame:SetSize(26, 26)
  self.IconPreviewFrame:SetPoint(
    "TOPLEFT",
    self.IconLabel,
    "BOTTOMLEFT",
    4,
    -8
  )

  self.IconPreview = self.IconPreviewFrame:CreateTexture(nil, "ARTWORK")
  self.IconPreview:SetAllPoints()

  --------------------------------------------------
  -- Choose icon
  --------------------------------------------------
  self.IconButton = addon.UI.Base.Button:Create(content, {
    text = L["CHOOSE_ICON"] or "Choose Icon",
    width = 125,
    onClick = function()
      addon.UI.Dialogs.IconPicker:Show(function(icon)
        self.SelectedIcon = icon
        self:UpdateIconPreview()
      end)
    end,
  })

  self.IconButton:SetPoint(
    "LEFT",
    self.IconPreviewFrame,
    "RIGHT",
    10,
    0
  )

  --------------------------------------------------
  -- Reset icon
  --------------------------------------------------
  self.ResetIconButton = addon.UI.Base.Button:Create(content, {
    text = L["RESET"] or "Reset",
    width = 75,
    onClick = function()
      self.SelectedIcon = nil
      self:UpdateIconPreview()
    end,
  })

  self.ResetIconButton:SetPoint(
    "LEFT",
    self.IconButton,
    "RIGHT",
    22,
    0
  )

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
  self.SelectedColor = nil
  self.SelectedIcon = nil

  self:UpdateColorPreview()
  self:UpdateIconPreview()

  dialog:SetTitle(L["CREATE_FOLDER"])

  self.NameInput:SetText(L["NEW_FOLDER"])

  dialog:Show()
  dialog:RefreshLayout()

  self.NameInput:SetFocus()
  self.NameInput:HighlightText()
end

--------------------------------------------------
-- Show edit
--------------------------------------------------
function FolderDialog:ShowEdit(folder)
  if not folder then
    return
  end

  local dialog = self:Create()

  self.Mode = "edit"
  self.Folder = folder

  dialog:SetTitle(L["EDIT_FOLDER"])

  self.NameInput:SetText(folder.name or "")

  self.SelectedColor = folder.color
  self.SelectedIcon = folder.icon

  self:UpdateColorPreview()
  self:UpdateIconPreview()

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
