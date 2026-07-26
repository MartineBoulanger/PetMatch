local _, addon = ...

local TeamList = {}

local HEADER_HEIGHT = 28
local HEADER_SPACING = 0
local CARD_SPACING = 0
local CONTENT_PADDING = 0
local CONTENT_WIDTH = 238

function TeamList:Create(parent)
  local frame =
      addon.UI.Components.ScrollBox:Create(
        parent,
        {
          width = CONTENT_WIDTH,
          height = 545,
        }
      )

  self.Frame = frame

  frame.cards = {}
  frame.items = {}


  self.ExpandedFolderKey =
      addon.Services.Folder:GetSelectedKey()
      or addon.Services.Folder.ALL

  self:RegisterEvents()
  self:Refresh()

  frame:Show()

  return frame
end

function TeamList:RegisterEvents()
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
                tostring(card.Team.id)
                == tostring(team.id)
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

    addon.EventBus:Register(
      addon.Events.TEAM_FAVORITE_CHANGED,
      RefreshList
    )
  end

  if not self.FolderEventsRegistered then
    self.FolderEventsRegistered = true

    addon.EventBus:Register(
      addon.Events.FOLDER_SELECTED,
      function()
        self.ExpandedFolderKey =
            addon.Services.Folder:GetSelectedKey()

        self:Refresh()
      end
    )

    local function RefreshFolders()
      self:Refresh()
    end

    addon.EventBus:Register(
      addon.Events.FOLDER_CREATED,
      RefreshFolders
    )

    addon.EventBus:Register(
      addon.Events.FOLDER_UPDATED,
      RefreshFolders
    )

    addon.EventBus:Register(
      addon.Events.FOLDER_DELETED,
      function()
        local selectedKey =
            addon.Services.Folder:GetSelectedKey()

        self.ExpandedFolderKey =
            selectedKey
            or addon.Services.Folder.UNSORTED

        self:Refresh()
      end
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

  if not self.LoadoutMonitorRegistered then
    self.LoadoutMonitorRegistered = true

    addon.EventBus:Register(
      addon.Events.CURRENT_TEAM_DIRTY_CHANGED,
      function()
        self:Refresh()
      end
    )
  end
end

function TeamList:ClearItems()
  if not self.Frame then
    return
  end

  addon.UI.Components.DragDrop:ClearFolderTargets()

  for _, item in ipairs(
    self.Frame.items or {}
  ) do
    item:Hide()
    item:ClearAllPoints()
    item:SetParent(nil)
  end

  self.Frame.items = {}
  self.Frame.cards = {}
end

function TeamList:GetFolderSections()
  local sections = {
    {
      label = "All Teams",
      folderKey = addon.Services.Folder.ALL,
    },
    {
      label = "Favorites",
      folderKey = addon.Services.Folder.FAVORITES,
    },
    {
      label = "Unsorted",
      folderKey = addon.Services.Folder.UNSORTED,
    },
  }

  for _, folder in ipairs(
    addon.Services.Folder:GetSortedFolders()
  ) do
    sections[#sections + 1] = {
      label = folder.name,
      folderKey = folder.id,
      folder = folder,
    }
  end

  return sections
end

function TeamList:CreateFolderHeader(section, currentOffset)
  local folderKey = section.folderKey

  local expanded =
      self.ExpandedFolderKey == folderKey

  local teams =
      addon.Services.Team:GetVisibleTeams(
        folderKey
      )

  local button =
      addon.UI.Components.AccordionHeader:Create(
        self.Frame.Content,
        {
          width = CONTENT_WIDTH,
          height = HEADER_HEIGHT,
          label = section.label,
          count = #teams,
          expanded = expanded,
        }
      )

  button.FolderKey = folderKey

  addon.UI.Components.DragDrop:RegisterFolderTarget(
    button,
    folderKey
  )

  button:ClearAllPoints()

  button:SetPoint(
    "TOPLEFT",
    self.Frame.Content,
    "TOPLEFT",
    0,
    -currentOffset
  )

  table.insert(
    self.Frame.items,
    button
  )

  button:SetScript(
    "OnClick",
    function(_, mouseButton)
      if mouseButton == "RightButton" then
        addon.UI.Actions.FolderContextMenu:Show(
          button,
          folderKey
        )

        return
      end

      if self.ExpandedFolderKey == folderKey then
        self.ExpandedFolderKey = nil
      else
        self.ExpandedFolderKey = folderKey
      end

      self:Refresh()
    end
  )

  return currentOffset
      + HEADER_HEIGHT
      + HEADER_SPACING
end

function TeamList:CreateTeamCards(
    folderKey,
    currentOffset
)
  local teams =
      addon.Services.Team:GetVisibleTeams(
        folderKey
      )

  if #teams == 0 then
    local holder =
        CreateFrame(
          "Frame",
          nil,
          self.Frame.Content
        )

    holder:SetSize(
      CONTENT_WIDTH,
      26
    )

    holder:SetPoint(
      "TOPLEFT",
      self.Frame.Content,
      "TOPLEFT",
      0,
      -currentOffset
    )

    local emptyLabel =
        holder:CreateFontString(
          nil,
          "OVERLAY",
          "GameFontDisableSmall"
        )

    emptyLabel:SetPoint(
      "LEFT",
      holder,
      "LEFT",
      12,
      0
    )

    emptyLabel:SetText(
      "No teams in this folder"
    )

    table.insert(
      self.Frame.items,
      holder
    )

    return currentOffset
        + holder:GetHeight()
        + CARD_SPACING
  end

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
      0,
      -currentOffset
    )

    table.insert(
      self.Frame.items,
      card
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

  return currentOffset
end

function TeamList:UpdateCardSelection()
  local selectedTeamID =
      addon.Services.Team:GetSelectedID()

  for _, card in ipairs(
    self.Frame.cards or {}
  ) do
    local cardTeamID =
        card.Team
        and card.Team.id

    local selected =
        selectedTeamID ~= nil
        and cardTeamID ~= nil
        and tostring(cardTeamID)
        == tostring(selectedTeamID)

    card:SetSelected(selected)
  end
end

function TeamList:Refresh()
  addon.UI.Components.DragDrop:ClearFolderTargets()

  if self.Refreshing then
    return
  end

  if not self.Frame then
    return
  end

  self.Refreshing = true
  self:ClearItems()

  self.Frame.items = {}
  self.Frame.cards = {}

  local sections =
      self:GetFolderSections()

  local currentOffset =
      CONTENT_PADDING

  for _, section in ipairs(sections) do
    currentOffset =
        self:CreateFolderHeader(
          section,
          currentOffset
        )

    if self.ExpandedFolderKey
        == section.folderKey then
      currentOffset =
          self:CreateTeamCards(
            section.folderKey,
            currentOffset
          )
    end
  end

  self.Frame.Content:SetHeight(
    math.max(
      1,
      currentOffset + CONTENT_PADDING
    )
  )

  self:UpdateCardSelection()

  self.Refreshing = false
end

addon.UI.Views.TeamList = TeamList
