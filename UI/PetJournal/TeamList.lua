local addonName, addon = ...

local TeamList = {}

function TeamList:Create(parent)
  local frame = addon.UI.Components.ScrollBox:Create(parent, { width = 300, height = 450 })
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
          card:SetSelected(
            card == selectedCard
          )
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

  if not self.FolderEventRegistered then
    self.FolderEventRegistered = true

    addon.EventBus:Register(
      addon.Events.FOLDER_SELECTED,
      function()
        self:Refresh()
      end
    )
  end

  addon.EventBus:Fire(
    "TEAM_SELECTED",
    frame.team
  )
  frame.cards = {}
  self:Refresh()
  frame:Show()
  return frame
end

function TeamList:Refresh()
  if not self.Frame then
    return
  end
  -- oude cards verwijderen
  for _, card in ipairs(self.Frame.cards) do
    card:Hide()
  end

  wipe(self.Frame.cards)
  local selectedFolderKey =
      addon.Services.Folder:GetSelectedKey()

  local teams =
      addon.Services.Team:GetVisibleTeams(
        selectedFolderKey
      )
  local cardCount = 0

  for _, team in pairs(teams) do
    cardCount = cardCount + 1

    local card =
        addon.UI.Components.TeamCard:Create(
          self.Frame.Content,
          team
        )

    card:SetPoint(
      "TOPLEFT",
      self.Frame.Content,
      "TOPLEFT",
      6,
      -8 - ((cardCount - 1) * 124)
    )

    table.insert(
      self.Frame.cards,
      card
    )
  end

  local selectedTeamID =
      addon.Services.Team:GetSelectedID()

  local selectedTeam = nil
  local selectedCard = nil

  for _, card in ipairs(
    self.Frame.cards or {}
  ) do
    local isSelected =
        selectedTeamID ~= nil
        and card.Team
        and card.Team.id == selectedTeamID

    card:SetSelected(isSelected)

    if isSelected then
      selectedTeam = card.Team
      selectedCard = card
    end
  end

  self.Frame.Content:SetWidth(275)
  self.Frame.Content:SetHeight(
    math.max(
      1,
      8 + (cardCount * 124)
    )
  )
end

addon.UI.Views = addon.UI.Views or {}
addon.UI.Views.TeamList = TeamList
