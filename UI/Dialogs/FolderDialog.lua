local addonName, addon = ...

addon.UI = addon.UI or {}
addon.UI.Views = addon.UI.Views or {}

local FolderDialog = {}

local WIDTH = 320
local HEIGHT = 145

function FolderDialog:Create()
  if self.Frame then
    return self.Frame
  end

  local frame =
      addon.UI.Components.Panel:Create(
        UIParent,
        {
          width = WIDTH,
          height = HEIGHT,
          background = "Interface/Tooltips/chatbubble-background"
        }
      )

  frame:SetFrameStrata("DIALOG")
  frame:SetClampedToScreen(true)
  frame:EnableMouse(true)
  frame:SetPoint("CENTER", UIParent, "CENTER")

  self.Frame = frame
  self.Mode = "create"
  self.Folder = nil

  self.Title =
      addon.UI.Components.Label:Create(
        frame,
        {
          text = "Create Folder",
          font = addon.UI.Theme.Fonts.Header,
          width = WIDTH - 24,
          justify = "CENTER",
          color = addon.UI.Theme.Colors.Header
        }
      )

  self.Title:SetPoint(
    "TOPLEFT",
    frame,
    "TOPLEFT",
    12,
    -12
  )

  self.NameLabel =
      addon.UI.Components.Label:Create(
        frame,
        {
          text = "Folder name",
          width = WIDTH - 24,
          justify = "LEFT",
        }
      )

  self.NameLabel:SetPoint(
    "TOPLEFT",
    self.Title,
    "BOTTOMLEFT",
    0,
    -12
  )

  self.NameInput =
      CreateFrame(
        "EditBox",
        nil,
        frame,
        "InputBoxTemplate"
      )

  self.NameInput:SetSize(WIDTH - 32, 28)
  self.NameInput:SetPoint(
    "TOPLEFT",
    self.NameLabel,
    "BOTTOMLEFT",
    4,
    -4
  )

  self.NameInput:SetAutoFocus(false)
  self.NameInput:SetMaxLetters(60)

  self.SaveButton =
      addon.UI.Components.Button:Create(
        frame,
        {
          text = "Save",
          width = 100,

          onClick = function()
            self:Save()
          end,
        }
      )

  self.SaveButton:SetPoint(
    "BOTTOMRIGHT",
    frame,
    "BOTTOMRIGHT",
    -12,
    12
  )

  self.CancelButton =
      addon.UI.Components.Button:Create(
        frame,
        {
          text = "Cancel",
          width = 100,

          onClick = function()
            self:Hide()
          end,
        }
      )

  self.CancelButton:SetPoint(
    "RIGHT",
    self.SaveButton,
    "LEFT",
    -8,
    0
  )

  self.NameInput:SetScript(
    "OnEnterPressed",
    function()
      self:Save()
    end
  )

  self.NameInput:SetScript(
    "OnEscapePressed",
    function()
      self:Hide()
    end
  )

  frame:Hide()

  return frame
end

function FolderDialog:ShowCreate()
  local frame = self:Create()

  self.Mode = "create"
  self.Folder = nil

  self.Title:SetText("Create Folder")
  self.NameInput:SetText("New Folder")

  frame:Show()

  self.NameInput:SetFocus()
end

function FolderDialog:ShowRename(folder)
  if not folder then
    return
  end

  local frame = self:Create()

  self.Mode = "rename"
  self.Folder = folder

  self.Title:SetText("Rename Folder")
  self.NameInput:SetText(folder.name or "")

  frame:Show()

  self.NameInput:SetFocus()
  self.NameInput:HighlightText()
end

function FolderDialog:Hide()
  if not self.Frame then
    return
  end

  self.NameInput:ClearFocus()
  self.Frame:Hide()

  self.Folder = nil
end

function FolderDialog:Save()
  local name =
      addon.Utils:Trim(
        self.NameInput:GetText() or ""
      )

  local folder
  local errorMessage

  if self.Mode == "rename" then
    if not self.Folder then
      return
    end

    folder, errorMessage =
        addon.Services.Folder:Rename(
          self.Folder.id,
          name
        )
  else
    folder, errorMessage =
        addon.Services.Folder:Create(name)
  end

  if not folder then
    addon.Logger:Warn(
      errorMessage or "Unable to save folder"
    )

    self.NameInput:SetFocus()
    self.NameInput:HighlightText()

    return
  end

  addon.Services.Folder:Select(folder.id)

  addon.Logger:Info(
    self.Mode == "rename"
    and "Renamed folder:"
    or "Created folder:",
    folder.name
  )

  self:Hide()
end

addon.UI.Views.FolderDialog = FolderDialog
