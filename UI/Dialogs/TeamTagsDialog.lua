local _, addon = ...

addon.UI = addon.UI or {}
addon.UI.Views = addon.UI.Views or {}

local TeamTagsDialog = {}

local WIDTH = 340
local HEIGHT = 410
local ROW_HEIGHT = 28
local ROW_SPACING = 4

function TeamTagsDialog:Create()
  if self.Frame then
    return self.Frame
  end

  local frame =
      addon.UI.Base.Panel:Create(
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
  self.Team = nil
  self.Rows = {}

  self.Title =
      addon.UI.Base.Label:Create(
        frame,
        {
          text = "Team Tags",
          font = addon.UI.Theme.Fonts.Header,
          width = WIDTH - 24,
          justify = "CENTER",
          color = addon.UI.Theme.Colors.Header,
        }
      )

  self.Title:SetPoint(
    "TOPLEFT",
    frame,
    "TOPLEFT",
    12,
    -12
  )

  self.NewTagInput =
      CreateFrame(
        "EditBox",
        nil,
        frame,
        "InputBoxTemplate"
      )

  self.NewTagInput:SetSize(210, 26)
  self.NewTagInput:SetPoint(
    "TOPLEFT",
    self.Title,
    "BOTTOMLEFT",
    4,
    -12
  )

  self.NewTagInput:SetAutoFocus(false)
  self.NewTagInput:SetMaxLetters(50)

  self.CreateTagButton =
      addon.UI.Base.Button:Create(
        frame,
        {
          text = "Create",
          width = 90,
          height = 24,

          onClick = function()
            self:CreateAndAssignTag()
          end,
        }
      )

  self.CreateTagButton:SetPoint(
    "LEFT",
    self.NewTagInput,
    "RIGHT",
    8,
    0
  )

  self.ScrollFrame =
      addon.UI.Components.ScrollBox:Create(
        frame,
        {
          width = WIDTH - 28,
          height = 275,
        }
      )

  self.ScrollFrame:SetPoint(
    "TOPLEFT",
    self.NewTagInput,
    "BOTTOMLEFT",
    -4,
    -12
  )

  self.ScrollFrame.Content:SetWidth(
    WIDTH - 50
  )

  self.CloseButton =
      addon.UI.Base.Button:Create(
        frame,
        {
          text = "Close",
          width = 100,

          onClick = function()
            self:Hide()
          end,
        }
      )

  self.CloseButton:SetPoint(
    "BOTTOMRIGHT",
    frame,
    "BOTTOMRIGHT",
    -12,
    12
  )

  self.NewTagInput:SetScript(
    "OnEnterPressed",
    function()
      self:CreateAndAssignTag()
    end
  )

  self.NewTagInput:SetScript(
    "OnEscapePressed",
    function()
      self:Hide()
    end
  )

  if not self.TagEventsRegistered then
    self.TagEventsRegistered = true

    local function Refresh()
      if self.Frame and self.Frame:IsShown() then
        self:Refresh()
      end
    end

    addon.EventBus:Register(
      addon.Events.TAG_CREATED,
      Refresh
    )

    addon.EventBus:Register(
      addon.Events.TAG_UPDATED,
      Refresh
    )

    addon.EventBus:Register(
      addon.Events.TAG_DELETED,
      Refresh
    )

    addon.EventBus:Register(
      addon.Events.TEAM_TAGS_CHANGED,
      Refresh
    )
  end

  frame:Hide()

  return frame
end

function TeamTagsDialog:ClearRows()
  for _, row in ipairs(self.Rows or {}) do
    row:Hide()
    row:ClearAllPoints()
    row:SetParent(nil)
  end

  self.Rows = {}
end

function TeamTagsDialog:Refresh()
  if not self.Frame or not self.Team then
    return
  end

  self:ClearRows()

  local tags =
      addon.Services.Tag:GetSortedTags()

  local rowCount = 0

  for _, tag in ipairs(tags) do
    rowCount = rowCount + 1

    local row =
        CreateFrame(
          "Button",
          nil,
          self.ScrollFrame.Content,
          "UIPanelButtonTemplate"
        )

    row:SetSize(
      WIDTH - 58,
      ROW_HEIGHT
    )

    row:SetPoint(
      "TOPLEFT",
      self.ScrollFrame.Content,
      "TOPLEFT",
      4,
      -4 - ((rowCount - 1)
        * (ROW_HEIGHT + ROW_SPACING))
    )

    row.Tag = tag

    local selected =
        addon.Services.Team:HasTag(
          self.Team,
          tag.id
        )

    row:SetText(
      (selected and "[x] " or "[ ] ")
      .. tag.name
    )

    row:SetScript(
      "OnClick",
      function()
        local updatedTeam, errorMessage =
            addon.Services.Team:ToggleTag(
              self.Team.id,
              tag.id
            )

        if not updatedTeam then
          addon.Logger:Warn(
            errorMessage
            or "Unable to update tags"
          )

          return
        end

        self.Team = updatedTeam
        self:Refresh()
      end
    )

    table.insert(self.Rows, row)
  end

  self.ScrollFrame.Content:SetHeight(
    math.max(
      1,
      8 + (rowCount
        * (ROW_HEIGHT + ROW_SPACING))
    )
  )
end

function TeamTagsDialog:CreateAndAssignTag()
  if not self.Team then
    return
  end

  local name =
      addon.Utils:Trim(
        self.NewTagInput:GetText() or ""
      )

  local tag =
      addon.Services.Tag:FindByName(name)

  local errorMessage

  if not tag then
    tag, errorMessage =
        addon.Services.Tag:Create(name)
  end

  if not tag then
    addon.Logger:Warn(
      errorMessage or "Unable to create tag"
    )

    self.NewTagInput:SetFocus()
    self.NewTagInput:HighlightText()

    return
  end

  local updatedTeam

  updatedTeam, errorMessage =
      addon.Services.Team:AddTag(
        self.Team.id,
        tag.id
      )

  if not updatedTeam then
    addon.Logger:Warn(
      errorMessage or "Unable to assign tag"
    )

    return
  end

  self.Team = updatedTeam

  self.NewTagInput:SetText("")
  self.NewTagInput:ClearFocus()

  self:Refresh()
end

function TeamTagsDialog:Show(team)
  if not team then
    return
  end

  local frame = self:Create()

  self.Team = team

  self.Title:SetText(
    "Tags: " .. (team.name or "Unnamed Team")
  )

  self.NewTagInput:SetText("")

  self:Refresh()

  frame:Show()
end

function TeamTagsDialog:Hide()
  if not self.Frame then
    return
  end

  self.NewTagInput:ClearFocus()
  self.Frame:Hide()
  self.Team = nil
end

addon.UI.Dialogs.TeamTagsDialog =
    TeamTagsDialog
