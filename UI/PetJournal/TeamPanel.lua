local addonName, addon = ...

addon.UI = addon.UI or {}
addon.UI.Views = addon.UI.Views or {}

local TeamPanel = {}

local PANEL_WIDTH = 450
local PANEL_HEIGHT = 604
local PANEL_PADDING = 8
local HEADER_HEIGHT = 28
local CONTENT_GAP = 5

function TeamPanel:Create()
  if self.Frame then
    return self.Frame
  end

  assert(PetJournal, "PetMatch: PetJournal is unavailable")

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
    0,
    -1
  )

  self.Frame = frame

  self.Title =
      addon.UI.Components.Label:Create(
        frame,
        {
          text = addon.Name or "PetMatch",
          font = addon.UI.Theme.Fonts.Header,
          width = PANEL_WIDTH - (PANEL_PADDING * 2),
          justify = "LEFT",
        }
      )

  self.Title:ClearAllPoints()

  self.Title:SetPoint(
    "TOP",
    frame,
    "TOP",
    0,
    -PANEL_PADDING
  )

  self.FolderTabs =
      addon.UI.Views.FolderTabs:Create(frame)

  self.FolderTabs:ClearAllPoints()
  self.FolderTabs:SetPoint(
    "TOPLEFT",
    frame,
    "TOPLEFT",
    PANEL_PADDING,
    -(HEADER_HEIGHT + CONTENT_GAP)
  )

  self.FolderTabs:SetHeight(
    PANEL_HEIGHT
    - HEADER_HEIGHT
    - CONTENT_GAP
    - PANEL_PADDING
  )

  self.TeamListControls =
      addon.UI.Views.TeamListControls:Create(
        frame
      )

  self.TeamListControls:ClearAllPoints()
  self.TeamListControls:SetPoint(
    "TOPLEFT",
    self.FolderTabs,
    "TOPRIGHT",
    CONTENT_GAP,
    0
  )

  self.TeamList =
      addon.UI.Views.TeamList:Create(frame)

  self.TeamList:ClearAllPoints()
  self.TeamList:SetPoint(
    "TOPLEFT",
    self.TeamListControls,
    "BOTTOMLEFT",
    -CONTENT_GAP,
    -CONTENT_GAP
  )

  self.TeamList:SetSize(
    280,
    455
  )

  local availableListHeight =
      PANEL_HEIGHT
      - HEADER_HEIGHT
      - CONTENT_GAP
      - self.TeamListControls:GetHeight()
      - CONTENT_GAP
      - PANEL_PADDING

  self.TeamList:SetHeight(
    availableListHeight
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

function TeamPanel:Refresh()
  if self.TeamList
      and addon.UI.Views.TeamList.Refresh then
    addon.UI.Views.TeamList:Refresh()
  end
end

addon.UI.Views.TeamPanel = TeamPanel
