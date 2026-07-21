local addonName, addon = ...

addon.UI = addon.UI or {}
addon.UI.Views = addon.UI.Views or {}

local TeamPanel = {}

local PANEL_WIDTH = 300
local PANEL_HEIGHT = 604
local PANEL_PADDING = 8
local CONTENT_GAP = 5

function TeamPanel:Create()
  if self.Frame then
    return self.Frame
  end

  assert(
    PetJournal,
    "PetMatch: PetJournal is unavailable"
  )

  local frame =
      addon.UI.Components.Panel:Create(
        PetJournal,
        {
          width = PANEL_WIDTH,
          height = PANEL_HEIGHT,
        }
      )

  frame:ClearAllPoints()
  frame:SetPoint(
    "TOPLEFT",
    PetJournal,
    "TOPRIGHT",
    -2,
    -1
  )

  self.Frame = frame

  self.TeamListControls =
      addon.UI.Views.TeamListControls:Create(
        frame
      )

  self.TeamListControls:ClearAllPoints()
  self.TeamListControls:SetPoint(
    "TOPLEFT",
    frame,
    "TOPLEFT",
    PANEL_PADDING,
    -PANEL_PADDING
  )

  self.TeamListControls:SetPoint(
    "TOPRIGHT",
    frame,
    "TOPRIGHT",
    -PANEL_PADDING,
    -PANEL_PADDING
  )

  self.NewFolderButton =
      self:CreateNewFolderButton(
        frame
      )

  self.TeamListFrame =
      addon.UI.Views.TeamList:Create(
        frame
      )

  self.TeamListFrame:ClearAllPoints()

  self.TeamListFrame:SetPoint(
    "TOPLEFT",
    self.TeamListControls,
    "BOTTOMLEFT",
    0,
    -CONTENT_GAP
  )

  self.TeamListFrame:SetPoint(
    "TOPRIGHT",
    self.TeamListControls,
    "BOTTOMRIGHT",
    0,
    -CONTENT_GAP
  )

  self.TeamListFrame:SetPoint(
    "BOTTOMLEFT",
    self.NewFolderButton,
    "TOPLEFT",
    0,
    CONTENT_GAP
  )

  self.TeamListFrame:SetPoint(
    "BOTTOMRIGHT",
    self.NewFolderButton,
    "TOPRIGHT",
    0,
    CONTENT_GAP
  )

  frame:Hide()

  return frame
end

function TeamPanel:Show()
  local frame = self:Create()

  if self.TeamList
      and addon.UI.Views.TeamList.Refresh then
    addon.UI.Views.TeamList:Refresh()
  end

  frame:Show()
end

function TeamPanel:Hide()
  if self.Frame then
    self.Frame:Hide()
  end
end

function TeamPanel:CreateNewFolderButton(parent)
  local button =
      addon.UI.Components.Button:Create(
        parent,
        {
          text = "New Folder",
          width = 100,
          height = 24,

          onClick = function()
            addon.UI.Views.FolderDialog:
                ShowCreate()
          end,
        }
      )

  button:ClearAllPoints()

  button:SetPoint(
    "BOTTOMLEFT",
    parent,
    "BOTTOMLEFT",
    CONTENT_GAP,
    CONTENT_GAP
  )

  -- button:SetPoint(
  --   "BOTTOMRIGHT",
  --   parent,
  --   "BOTTOMRIGHT",
  --   -CONTENT_GAP,
  --   CONTENT_GAP
  -- )

  self.NewFolderButton = button

  return button
end

function TeamPanel:Refresh()
  local frameWidth = self.Frame:GetWidth()

  if frameWidth and frameWidth > 0 then
    self.Frame.Content:SetWidth(
      math.max(1, frameWidth - 24)
    )
  end
  if self.TeamList
      and addon.UI.Views.TeamList.Refresh then
    addon.UI.Views.TeamList:Refresh()
  end
end

addon.UI.Views.TeamPanel = TeamPanel
