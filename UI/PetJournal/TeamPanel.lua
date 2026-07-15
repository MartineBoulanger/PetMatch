local addonName, addon = ...

addon.UI = addon.UI or {}
addon.UI.Views = addon.UI.Views or {}

local TeamPanel = {}

local PANEL_WIDTH = 750
local PANEL_HEIGHT = 460

local TOOLBAR_HEIGHT = 40
local CONTENT_TOP_OFFSET = -58

local TEAM_LIST_WIDTH = 300
local TEAM_LIST_HEIGHT = 390

local DETAIL_WIDTH = 280
local DETAIL_HEIGHT = 210

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
    6,
    0
  )

  self.Frame = frame

  -- Toolbar
  self.Toolbar =
      addon.UI.Views.Toolbar:Create(frame)

  self.Toolbar:ClearAllPoints()
  self.Toolbar:SetPoint(
    "TOPLEFT",
    frame,
    "TOPLEFT",
    10,
    -10
  )

  self.Toolbar:SetSize(
    PANEL_WIDTH - 20,
    TOOLBAR_HEIGHT
  )

  self.FolderTabs =
      addon.UI.Views.FolderTabs:Create(frame)

  self.FolderTabs:ClearAllPoints()
  self.FolderTabs:SetPoint(
    "TOPLEFT",
    frame,
    "TOPLEFT",
    10,
    CONTENT_TOP_OFFSET
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
    8,
    0
  )

  self.TeamList =
      addon.UI.Views.TeamList:Create(frame)

  self.TeamList:ClearAllPoints()
  self.TeamList:SetPoint(
    "TOPLEFT",
    self.TeamListControls,
    "BOTTOMLEFT",
    0,
    -6
  )

  self.TeamList:SetSize(
    300,
    314
  )

  self.TeamDetail =
      addon.UI.Views.TeamDetail:Create(frame)

  self.TeamDetail:ClearAllPoints()
  self.TeamDetail:SetPoint(
    "TOPLEFT",
    self.TeamListControls,
    "TOPRIGHT",
    10,
    0
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
