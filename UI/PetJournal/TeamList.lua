local addonName, addon = ...

local TeamList = {}

local CARD_SPACING = 5
local CONTENT_PADDING = 5

function TeamList:Create(parent)
  local frame =
      addon.UI.Components.ScrollBox:Create(
        parent,
        {
          width = 250,
          height = 450,
        }
      )

  frame.cards = {}
  self.Frame = frame

  if not self.SelectionListenerRegistered then
    self.SelectionListenerRegistered = true

    addon.EventBus:Register(
      addon.Events.TEAM_SELECTED,
      function(team, selectedCard)
        if not self.Frame then
          return
        end

        for _, card in ipairs(
          self.Frame.cards or {}
        ) do
          local selected =
              selectedCard ~= nil
              and card == selectedCard

          if not selected
              and team
              and card.Team then
            selected =
                card.Team.id == team.id
          end

          card:SetSelected(selected)
        end
      end
    )
  end

  if not self.TeamEventsRegistered then
    self.TeamEventsRegistered = true

    local function RefreshList()
      self:Refresh()
    end

    addon.EventBus:Register(
      addon.Events.TEAM_CREATED,
      RefreshList
    )

    addon.EventBus:Register(
      addon.Events.TEAM_UPDATED,
      RefreshList
    )

    addon.EventBus:Register(
      addon.Events.TEAM_DELETED,
      RefreshList
    )
  end

  if not self.FilterEventsRegistered then
    self.FilterEventsRegistered = true

    addon.EventBus:Register(
      addon.Events.SEARCH_CHANGED,
      function()
        self:Refresh()
      end
    )

    addon.EventBus:Register(
      addon.Events.TEAM_SORT_CHANGED,
      function()
        self:Refresh()
      end
    )
  end

  if not self.FavoriteEventRegistered then
    self.FavoriteEventRegistered = true

    addon.EventBus:Register(
      addon.Events.TEAM_FAVORITE_CHANGED,
      function()
        self:Refresh()
      end
    )
  end

  if not self.FolderEventRegistered then
    self.FolderEventRegistered = true

    addon.EventBus:Register(
      addon.Events.FOLDER_SELECTED,
      function()
        self:Refresh()
      end
    )
  end

  self:Refresh()
  frame:Show()

  return frame
end

function TeamList:ClearCards()
  if not self.Frame then
    return
  end

  for _, card in ipairs(
    self.Frame.cards or {}
  ) do
    card:Hide()
    card:ClearAllPoints()
    card:SetParent(nil)
  end

  self.Frame.cards = {}
end

function TeamList:Refresh()
  if not self.Frame then
    return
  end

  if self.Refreshing then
    self.RefreshPending = true
    return
  end

  self.Refreshing = true
  self.RefreshPending = false

  self:ClearCards()

  local selectedFolderKey =
      addon.Services.Folder:GetSelectedKey()

  local teams =
      addon.Services.Team:GetVisibleTeams(
        selectedFolderKey
      )

  local currentOffset = CONTENT_PADDING

  for _, team in ipairs(teams) do
    local card =
        addon.UI.Components.TeamCard:Create(
          self.Frame.Content,
          team
        )

    card:ClearAllPoints()

    card:SetPoint(
      "TOPLEFT",
      self.Frame.Content,
      "TOPLEFT",
      6,
      -currentOffset
    )

    table.insert(
      self.Frame.cards,
      card
    )

    currentOffset =
        currentOffset
        + card:GetHeight()
        + CARD_SPACING
  end

  self.Frame.Content:SetHeight(
    math.max(
      1,
      currentOffset
    )
  )

  local selectedTeamID =
      addon.Services.Team:GetSelectedID()

  for _, card in ipairs(
    self.Frame.cards
  ) do
    card:SetSelected(
      selectedTeamID ~= nil
      and card.Team ~= nil
      and card.Team.id == selectedTeamID
    )
  end

  self.Refreshing = false

  if self.RefreshPending then
    self.RefreshPending = false

    C_Timer.After(0, function()
      self:Refresh()
    end)
  end
end

addon.UI.Views = addon.UI.Views or {}
addon.UI.Views.TeamList = TeamList
