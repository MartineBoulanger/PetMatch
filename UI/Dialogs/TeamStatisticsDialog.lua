local _, addon = ...

local TeamStatisticsDialog = {}

local DIALOG_WIDTH = 384

local CONTENT_MARGIN = {
  left = -12,
  right = 12,
  top = 0,
  bottom = 8,
}

local CONTENT_PADDING = 12

local TAB_WIDTH = 90
local TAB_HEIGHT = 24

local dialogInstance

--------------------------------------------------
-- Helpers
--------------------------------------------------
local function FormatRate(value)
  return string.format(
    "%.1f%%",
    tonumber(value) or 0
  )
end

--------------------------------------------------
-- Clear state
--------------------------------------------------
function TeamStatisticsDialog:ClearState()
  self.Team = nil
  self.OverallStats = nil
  self.PvEStats = nil
  self.PvPStats = nil
  self.ActiveTab = nil
end

--------------------------------------------------
-- Update tabs
--------------------------------------------------
function TeamStatisticsDialog:UpdateTabs()
  if not self.OverallTab
      or not self.PvETab
      or not self.PvPTab then
    return
  end

  self.OverallTab:SetEnabled(
    self.ActiveTab ~= "overall"
  )

  self.PvETab:SetEnabled(
    self.ActiveTab ~= "pve"
  )

  self.PvPTab:SetEnabled(
    self.ActiveTab ~= "pvp"
  )
end

--------------------------------------------------
-- Show stats
--------------------------------------------------
function TeamStatisticsDialog:ShowStats(tab)
  local stats

  if tab == "overall" then
    stats = self.OverallStats
  elseif tab == "pve" then
    stats = self.PvEStats
  elseif tab == "pvp" then
    stats = self.PvPStats
  end

  if not stats then
    return
  end

  self.ActiveTab = tab

  local statisticsService = addon.Services.TeamStatistics
  local winRate = statisticsService:GetWinRate(stats)
  local lossRate = statisticsService:GetLossRate(stats)

  self.WinsValue:SetText(
    tostring(stats.wins or 0)
  )

  self.LossesValue:SetText(
    tostring(stats.losses or 0)
  )

  self.DrawsValue:SetText(
    tostring(stats.draws or 0)
  )

  self.WinRatingValue:SetText(
    FormatRate(winRate)
  )

  self.LossRatingValue:SetText(
    FormatRate(lossRate)
  )

  --------------------------------------------------
  -- Colors
  --------------------------------------------------
  local winRateColor = addon.UI.Theme.Colors.Text

  if winRate > 60 then
    winRateColor = addon.UI.Theme.Colors.Success
  elseif winRate > 40 then
    winRateColor = addon.UI.Theme.Colors.Header
  elseif winRate > 0 then
    winRateColor = addon.UI.Theme.Colors.Error
  end

  self.WinRatingValue:SetTextColor(
    unpack(winRateColor)
  )

  local lossRateColor = addon.UI.Theme.Colors.Text

  if lossRate > 60 then
    lossRateColor = addon.UI.Theme.Colors.Error
  elseif lossRate > 40 then
    lossRateColor = addon.UI.Theme.Colors.Header
  elseif lossRate > 0 then
    lossRateColor = addon.UI.Theme.Colors.Success
  end

  self.LossRatingValue:SetTextColor(
    unpack(lossRateColor)
  )


  self:UpdateTabs()
end

--------------------------------------------------
-- Create content
--------------------------------------------------
function TeamStatisticsDialog:CreateContent(dialog)
  local content = dialog:GetContentFrame()

  --------------------------------------------------
  -- Tabs
  --------------------------------------------------
  self.OverallTab =
      CreateFrame(
        "Button",
        nil,
        content,
        "UIPanelButtonTemplate"
      )

  self.OverallTab:SetSize(
    TAB_WIDTH,
    TAB_HEIGHT
  )

  self.OverallTab:SetPoint(
    "TOP",
    content,
    "TOP",
    -(TAB_WIDTH + 6),
    0
  )

  self.OverallTab:SetText(
    "Overall"
  )

  self.PvETab =
      CreateFrame(
        "Button",
        nil,
        content,
        "UIPanelButtonTemplate"
      )

  self.PvETab:SetSize(
    TAB_WIDTH,
    TAB_HEIGHT
  )

  self.PvETab:SetPoint(
    "LEFT",
    self.OverallTab,
    "RIGHT",
    6,
    0
  )

  self.PvETab:SetText(
    "PvE"
  )

  self.PvPTab =
      CreateFrame(
        "Button",
        nil,
        content,
        "UIPanelButtonTemplate"
      )

  self.PvPTab:SetSize(
    TAB_WIDTH,
    TAB_HEIGHT
  )

  self.PvPTab:SetPoint(
    "LEFT",
    self.PvETab,
    "RIGHT",
    6,
    0
  )

  self.PvPTab:SetText(
    "PvP"
  )

  self.OverallTab:SetScript(
    "OnClick",
    function()
      self:ShowStats(
        "overall"
      )
    end
  )

  self.PvETab:SetScript(
    "OnClick",
    function()
      self:ShowStats(
        "pve"
      )
    end
  )

  self.PvPTab:SetScript(
    "OnClick",
    function()
      self:ShowStats(
        "pvp"
      )
    end
  )

  --------------------------------------------------
  -- Statistics labels
  --------------------------------------------------
  self.WinsLabel =
      addon.UI.Base.Label:Create(
        content,
        {
          text = "Wins",
          justify = "LEFT",
          color = addon.UI.Theme.Colors.Text,
        }
      )

  self.WinsLabel:SetPoint(
    "TOPLEFT",
    self.OverallTab,
    "BOTTOMLEFT",
    0,
    -12
  )

  self.WinsValue =
      addon.UI.Base.Label:Create(
        content,
        {
          text = "0",
          justify = "RIGHT",
          color = addon.UI.Theme.Colors.Text,
        }
      )

  self.WinsValue:SetPoint(
    "TOPRIGHT",
    self.PvPTab,
    "BOTTOMRIGHT",
    0,
    -12
  )

  --------------------------------------------------

  self.LossesLabel =
      addon.UI.Base.Label:Create(
        content,
        {
          text = "Losses",
          justify = "LEFT",
          color = addon.UI.Theme.Colors.Text,
        }
      )

  self.LossesLabel:SetPoint(
    "TOPLEFT",
    self.WinsLabel,
    "BOTTOMLEFT",
    0,
    -8
  )

  self.LossesValue =
      addon.UI.Base.Label:Create(
        content,
        {
          text = "0",
          justify = "RIGHT",
          color = addon.UI.Theme.Colors.Text,
        }
      )

  self.LossesValue:SetPoint(
    "TOPRIGHT",
    self.WinsValue,
    "BOTTOMRIGHT",
    0,
    -8
  )

  --------------------------------------------------

  self.DrawsLabel =
      addon.UI.Base.Label:Create(
        content,
        {
          text = "Draws",
          justify = "LEFT",
          color = addon.UI.Theme.Colors.Text,
        }
      )

  self.DrawsLabel:SetPoint(
    "TOPLEFT",
    self.LossesLabel,
    "BOTTOMLEFT",
    0,
    -8
  )

  self.DrawsValue =
      addon.UI.Base.Label:Create(
        content,
        {
          text = "0",
          justify = "RIGHT",
          color = addon.UI.Theme.Colors.Text,
        }
      )

  self.DrawsValue:SetPoint(
    "TOPRIGHT",
    self.LossesValue,
    "BOTTOMRIGHT",
    0,
    -8
  )

  --------------------------------------------------
  -- Divider
  --------------------------------------------------
  self.RatingDivider =
      content:CreateTexture(
        nil,
        "ARTWORK"
      )

  self.RatingDivider:SetHeight(1)

  self.RatingDivider:SetPoint(
    "TOPLEFT",
    self.DrawsLabel,
    "BOTTOMLEFT",
    0,
    -16
  )

  self.RatingDivider:SetPoint(
    "TOPRIGHT",
    self.DrawsValue,
    "BOTTOMRIGHT",
    0,
    -16
  )

  self.RatingDivider:SetColorTexture(
    0.35,
    0.35,
    0.35,
    1
  )

  --------------------------------------------------
  -- Ratings
  --------------------------------------------------
  self.WinRatingLabel =
      addon.UI.Base.Label:Create(
        content,
        {
          text = "Win Rating",
          justify = "LEFT",
          color = addon.UI.Theme.Colors.Text,
        }
      )

  self.WinRatingLabel:SetPoint(
    "TOPLEFT",
    self.RatingDivider,
    "BOTTOMLEFT",
    0,
    -16
  )

  self.WinRatingValue =
      addon.UI.Base.Label:Create(
        content,
        {
          text = "0.0%",
          justify = "RIGHT",
          color = addon.UI.Theme.Colors.Text,
        }
      )

  self.WinRatingValue:SetPoint(
    "TOPRIGHT",
    self.RatingDivider,
    "BOTTOMRIGHT",
    0,
    -16
  )

  --------------------------------------------------

  self.LossRatingLabel =
      addon.UI.Base.Label:Create(
        content,
        {
          text = "Loss Rating",
          justify = "LEFT",
          color = addon.UI.Theme.Colors.Text,
        }
      )

  self.LossRatingLabel:SetPoint(
    "TOPLEFT",
    self.WinRatingLabel,
    "BOTTOMLEFT",
    0,
    -8
  )

  self.LossRatingValue =
      addon.UI.Base.Label:Create(
        content,
        {
          text = "0.0%",
          justify = "RIGHT",
          color = addon.UI.Theme.Colors.Text,
        }
      )

  self.LossRatingValue:SetPoint(
    "TOPRIGHT",
    self.WinRatingValue,
    "BOTTOMRIGHT",
    0,
    -8
  )

  content:SetHeight(210)
end

--------------------------------------------------
-- Create dialog
--------------------------------------------------
function TeamStatisticsDialog:Create()
  if dialogInstance then
    return dialogInstance
  end

  local dialog =
      addon.UI.Base.Dialog:Create({
        name = "PetMatchTeamStatisticsDialog",
        title = "Team Statistics",
        width = DIALOG_WIDTH,
        contentMargin = CONTENT_MARGIN,
        padding = CONTENT_PADDING,
        bottomSpacing = 4,
        onClose =
            function()
              self:ClearState()
            end,
        showFooter = false
      })

  self:CreateContent(dialog)

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
function TeamStatisticsDialog:Show(team)
  if not team then
    return
  end

  local statisticsService = addon.Services.TeamStatistics

  if not statisticsService then
    return
  end

  local dialog = self:Create()

  local stats = statisticsService:GetStats(team)
  local overall = statisticsService:GetOverall(team)

  if not stats or not overall then
    return
  end

  self.Team = team
  self.OverallStats = overall
  self.PvEStats = stats.pve
  self.PvPStats = stats.pvp

  local teamName =
      team.name
      or "Unnamed Team"

  dialog:SetTitle(
    teamName
    .. " Statistics"
  )

  self:ShowStats(
    "overall"
  )

  dialog:Show()
  dialog:RefreshLayout()

  self.Frame:Raise()
end

--------------------------------------------------
-- Hide
--------------------------------------------------
function TeamStatisticsDialog:Hide()
  if dialogInstance then
    dialogInstance:Hide()
  end
end

--------------------------------------------------
-- Register
--------------------------------------------------
addon.UI.Dialogs.TeamStatisticsDialog = TeamStatisticsDialog
