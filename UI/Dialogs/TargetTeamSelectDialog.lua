local _, addon = ...

local TargetTeamSelectDialog = {}

local DIALOG_WIDTH = 300

local LIST_HEIGHT = 160

local ROW_HEIGHT = 26

local ROW_SPACING = 2

local CONTENT_MARGIN = {
  left = -12,
  right = 12,
  top = 4,
  bottom = 8,
}

local CONTENT_PADDING = 12

local dialogInstance

--------------------------------------------------
-- Create
--------------------------------------------------
function TargetTeamSelectDialog:Create()
  if dialogInstance then
    return dialogInstance
  end

  local dialog =
      addon.UI.Base.Dialog:Create({
        name = "PetMatchTargetTeamSelectDialog",
        title = "Choose Team",
        width = DIALOG_WIDTH,
        contentMargin = CONTENT_MARGIN,
        padding = CONTENT_PADDING,
        bottomSpacing = 0,
        onCancel =
            function()
              self.Teams = nil
              self.NPCID = nil

              return true
            end,
        onClose =
            function()
              self.Teams = nil
              self.NPCID = nil
            end,
      })

  local content = dialog:GetContentFrame()

  ------------------------------------------------
  -- Description
  ------------------------------------------------
  self.Description =
      addon.UI.Base.Label:Create(
        content,
        {
          text = "Multiple teams are available for this target. "
              .. "Select the team you want to load.",
          justify = "LEFT",
          color = addon.UI.Theme.Colors.Text,
        }
      )

  self.Description:SetPoint(
    "TOPLEFT",
    content,
    "TOPLEFT",
    0,
    0
  )

  self.Description:SetPoint(
    "TOPRIGHT",
    content,
    "TOPRIGHT",
    0,
    0
  )

  ------------------------------------------------
  -- Team list
  ------------------------------------------------
  self.ScrollFrame =
      addon.UI.Components.ScrollBox:Create(
        content,
        {
          width = DIALOG_WIDTH - 70,
          height = LIST_HEIGHT,
        }
      )

  self.ScrollFrame:SetPoint(
    "TOPLEFT",
    self.Description,
    "BOTTOMLEFT",
    0,
    -12
  )

  self.ScrollFrame:SetPoint(
    "TOPRIGHT",
    content,
    "TOPRIGHT",
    -16,
    0
  )

  self.ScrollFrame.Content:SetWidth(
    DIALOG_WIDTH - 70
  )

  ------------------------------------------------
  -- Footer
  ------------------------------------------------
  self.CancelButton =
      dialog:AddCancelButton({
        text = "Cancel",
        width = 100,
      })

  ------------------------------------------------
  -- State
  ------------------------------------------------
  self.Dialog = dialog
  self.Frame = dialog:GetFrame()

  self.Teams = nil
  self.NPCID = nil
  self.TeamRows = {}

  ------------------------------------------------
  -- Cleanup
  ------------------------------------------------
  self.Frame:HookScript(
    "OnHide",
    function()
      self.Teams = nil
      self.NPCID = nil
    end
  )

  ------------------------------------------------
  -- Layout
  ------------------------------------------------
  dialog:RefreshLayout()

  dialogInstance = dialog

  return dialog
end

--------------------------------------------------
-- Clear rows
--------------------------------------------------
function TargetTeamSelectDialog:ClearTeamRows()
  for _, row in ipairs(
    self.TeamRows
    or {}
  ) do
    row:Hide()
    row:SetParent(nil)
  end

  self.TeamRows = {}
end

--------------------------------------------------
-- Create team row
--------------------------------------------------
function TargetTeamSelectDialog:CreateTeamRow(team, index)
  local content = self.ScrollFrame.Content

  local row =
      CreateFrame(
        "Frame",
        nil,
        content,
        "BackdropTemplate"
      )

  row:SetHeight(
    ROW_HEIGHT
  )

  row:SetPoint(
    "TOPLEFT",
    content,
    "TOPLEFT",
    2,
    -4 - (
      (index - 1)
      * (
        ROW_HEIGHT
        + ROW_SPACING
      )
    )
  )

  row:SetPoint(
    "TOPRIGHT",
    content,
    "TOPRIGHT",
    -4,
    -4 - (
      (index - 1)
      * (
        ROW_HEIGHT
        + ROW_SPACING
      )
    )
  )

  ------------------------------------------------
  -- Background
  ------------------------------------------------
  row:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
  })

  local colors = addon.UI.Theme.Colors

  local normalBackground =
      colors.Background
      or {
        r = 0.08,
        g = 0.08,
        b = 0.08,
        a = 0.65,
      }

  local borderColor =
      colors.Border
      or {
        r = 0.25,
        g = 0.25,
        b = 0.25,
        a = 1,
      }

  local hoverBackground =
      colors.Hover
      or {
        r = 0.15,
        g = 0.15,
        b = 0.15,
        a = 1,
      }

  row:SetBackdropColor(
    normalBackground.r or 0.08,
    normalBackground.g or 0.08,
    normalBackground.b or 0.08,
    normalBackground.a or 0.65
  )

  row:SetBackdropBorderColor(
    borderColor.r or 0.35,
    borderColor.g or 0.35,
    borderColor.b or 0.35,
    borderColor.a or 1
  )

  ------------------------------------------------
  -- Pet icons
  ------------------------------------------------
  row.PetSlots = {}

  local slotSize = 24
  local slotSpacing = 0
  local slotStartX = 2

  for slot = 1, 3 do
    local petSlot =
        addon.UI.Components.PetSlot:Create(row)

    local petSlotFrame = petSlot:GetFrame()

    petSlotFrame:SetSize(
      slotSize,
      slotSize
    )

    petSlotFrame:ClearAllPoints()

    petSlotFrame:SetPoint(
      "LEFT",
      row,
      "LEFT",
      slotStartX
      + (
        (slot - 1)
        * (slotSize + slotSpacing)
      ),
      0
    )

    local specialSlot = team.specialSlots
        and team.specialSlots[slot]

    if specialSlot then
      petSlot:SetSpecialSlot(specialSlot)
    else
      petSlot:SetPet(
        team.pets
        and team.pets[slot]
        or nil,
        team,
        slot
      )
    end

    row.PetSlots[slot] = petSlot
  end

  ------------------------------------------------
  -- Team name
  ------------------------------------------------
  row.Name =
      addon.UI.Base.Label:Create(
        row,
        {
          text = team.name or "Unnamed Team",
          justify = "LEFT",
          color = addon.UI.Theme.Colors.Text,
        }
      )

  local nameOffset =
      slotStartX
      + (3 * slotSize)
      + (2 * slotSpacing)
      + 6

  row.Name:SetPoint(
    "LEFT",
    row,
    "LEFT",
    nameOffset,
    0
  )

  row.Name:SetPoint(
    "RIGHT",
    row,
    "RIGHT",
    -10,
    0
  )

  row.Name:SetWordWrap(false)
  row.Name:SetNonSpaceWrap(false)
  row.Name:SetMaxLines(1)

  ------------------------------------------------
  -- Mouse interaction
  ------------------------------------------------
  row:EnableMouse(true)

  row:SetScript(
    "OnEnter",
    function()
      row:SetBackdropColor(
        hoverBackground.r or 0.15,
        hoverBackground.g or 0.15,
        hoverBackground.b or 0.15,
        hoverBackground.a or 1
      )
    end
  )

  row:SetScript(
    "OnLeave",
    function()
      row:SetBackdropColor(
        normalBackground.r or 0.08,
        normalBackground.g or 0.08,
        normalBackground.b or 0.08,
        normalBackground.a or 0.85
      )
    end
  )

  row:SetScript(
    "OnMouseUp",
    function(_, button)
      if button ~= "LeftButton" then
        return
      end

      self:LoadTeam(team)
    end
  )

  self.TeamRows[#self.TeamRows + 1] = row
end

--------------------------------------------------
-- Refresh teams
--------------------------------------------------
function TargetTeamSelectDialog:RefreshTeams()
  if not self.Frame then
    return
  end

  self:ClearTeamRows()

  local teams = self.Teams

  if type(teams) ~= "table" then
    teams = {}
  end

  for index, team in ipairs(teams) do
    self:CreateTeamRow(
      team,
      index
    )
  end

  local teamCount = #teams

  local contentHeight =
      8 + (teamCount * ROW_HEIGHT)
      + (
        math.max(0, teamCount - 1)
        * ROW_SPACING
      )

  self.ScrollFrame.Content:SetHeight(
    math.max(
      1,
      contentHeight
    )
  )
end

--------------------------------------------------
-- Show
--------------------------------------------------
function TargetTeamSelectDialog:Show(teams, npcID)
  if type(teams) ~= "table" or #teams < 2 then
    return
  end

  local dialog = self:Create()

  self.Teams = teams
  self.NPCID = npcID

  dialog:SetTitle(
    "Choose Team"
  )

  self.Description:SetText(
    "Multiple teams are available for this target. "
    .. "Select the team you want to load."
  )

  self:RefreshTeams()

  dialog:Show()
  dialog:RefreshLayout()

  self.Frame:Raise()
end

--------------------------------------------------
-- Hide
--------------------------------------------------
function TargetTeamSelectDialog:Hide()
  if not dialogInstance then
    return
  end

  dialogInstance:Hide()

  self.Teams = nil
  self.NPCID = nil
end

--------------------------------------------------
-- Load team
--------------------------------------------------
function TargetTeamSelectDialog:LoadTeam(team)
  if not team or not team.id then
    return
  end

  local teamService = addon.Services.Team

  if not teamService then
    return
  end

  local success, errorMessage =
      teamService:Load(
        team.id
      )

  if not success then
    addon.Logger:Warn(
      errorMessage
      or "Unable to load team"
    )
    return
  end

  self:Hide()
end

--------------------------------------------------
-- Register
--------------------------------------------------
addon.UI.Dialogs.TargetTeamSelectDialog = TargetTeamSelectDialog
