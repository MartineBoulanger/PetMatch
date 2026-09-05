local _, addon = ...

local TeamList = {}

local HEADER_HEIGHT = 28
local HEADER_SPACING = 1
local CARD_SPACING = 1
local CONTENT_PADDING = 0
local CONTENT_WIDTH = 230

function TeamList:Create(parent)
  local frame =
      addon.UI.Components.ScrollBox:Create(
        parent,
        {
          width = CONTENT_WIDTH + 5,
          height = 545,
          contentGap = 6
        }
      )

  self.Frame = frame

  frame.cards = {}
  frame.items = {}

  self.FolderHeaders = {}

  self.FolderDropIndicator =
      frame.Content:CreateTexture(
        nil,
        "OVERLAY"
      )

  self.FolderDropIndicator:SetHeight(1)

  self.FolderDropIndicator:SetColorTexture(
    1,
    0.82,
    0,
    1
  )

  self.FolderDropIndicator:Hide()

  self.TeamDropIndicator =
      frame.Content:CreateTexture(
        nil,
        "OVERLAY"
      )

  self.TeamDropIndicator:SetHeight(1)

  self.TeamDropIndicator:SetColorTexture(
    1,
    0.82,
    0,
    1
  )

  self.TeamDropIndicator:Hide()

  self.ExpandedFolderKey = nil

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

  addon.EventBus:Register(
    addon.Events.SETTINGS_CHANGED,
    function(key)
      if key ~= "teamCardHeightMode" then
        return
      end

      self:Refresh()
    end
  )
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
  self.FolderHeaders = {}
end

function TeamList:GetFolderSections()
  local sections = {
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
  local expanded = self.ExpandedFolderKey == folderKey
  local teams = addon.Services.Team:GetVisibleTeams(folderKey)
  local draggable = folderKey ~= addon.Services.Folder.FAVORITES and folderKey ~= addon.Services.Folder.UNSORTED

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

  if draggable then
    self.FolderHeaders[
    #self.FolderHeaders + 1
    ] = {
      frame = button,
      folderKey = folderKey,
    }

    button:RegisterForDrag(
      "LeftButton"
    )

    button:SetScript(
      "OnDragStart",
      function()
        button.PetMatchFolderDragged = true

        self:BeginFolderDrag(
          button,
          folderKey
        )
      end
    )

    button:SetScript(
      "OnDragStop",
      function()
        self:FinishFolderDrag()

        --------------------------------------------------
        -- Keep the drag from also toggling
        -- the folder accordion.
        --------------------------------------------------

        C_Timer.After(
          0,
          function()
            button.PetMatchFolderDragged = nil
          end
        )
      end
    )
  end

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
      --------------------------------------------------
      -- Ignore click caused by a drag
      --------------------------------------------------
      if button.PetMatchFolderDragged then
        return
      end

      --------------------------------------------------
      -- Context menu
      --------------------------------------------------
      if mouseButton == "RightButton" then
        addon.UI.Actions.FolderContextMenu:Show(button, folderKey)
        return
      end

      --------------------------------------------------
      -- Expand / collapse
      --------------------------------------------------
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

function TeamList:CreateTeamCards(folderKey, currentOffset)
  local teams = addon.Services.Team:GetVisibleTeams(folderKey)

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

    card.FolderKey = folderKey

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

function TeamList:BeginFolderDrag(button, folderKey)
  if not button or not folderKey then
    return
  end

  self.DraggedFolderKey = folderKey
  self.DraggedFolderButton = button

  button:SetAlpha(0.35)

  addon.UI.Components.DragCursor:Start()

  self.Frame:SetScript(
    "OnUpdate",
    function()
      self:UpdateFolderDrag()
    end
  )
end

function TeamList:GetFolderDropPosition()
  local _, cursorY = GetCursorPosition()
  local scale = UIParent:GetEffectiveScale()

  cursorY = cursorY / scale

  for index, entry in ipairs(self.FolderHeaders or {}) do
    local frame = entry.frame

    if frame and frame:IsShown() then
      local top = frame:GetTop()
      local bottom = frame:GetBottom()

      if top
          and bottom
          and cursorY <= top
          and cursorY >= bottom then
        local middle = (top + bottom) / 2
        local insertAfter = cursorY < middle

        return index, insertAfter
      end
    end
  end

  return nil, nil
end

function TeamList:ShowFolderDropIndicator(targetIndex, insertAfter)
  local entry =
      self.FolderHeaders
      and self.FolderHeaders[
      targetIndex
      ]

  local frame = entry and entry.frame

  if not frame or not frame:IsShown() then
    self.FolderDropIndicator:Hide()
    return
  end

  self.FolderDropIndicator:ClearAllPoints()

  if insertAfter then
    self.FolderDropIndicator:
        SetPoint(
          "TOPLEFT",
          frame,
          "BOTTOMLEFT",
          0,
          0
        )

    self.FolderDropIndicator:
        SetPoint(
          "TOPRIGHT",
          frame,
          "BOTTOMRIGHT",
          0,
          0
        )
  else
    self.FolderDropIndicator:
        SetPoint(
          "BOTTOMLEFT",
          frame,
          "TOPLEFT",
          0,
          0
        )

    self.FolderDropIndicator:
        SetPoint(
          "BOTTOMRIGHT",
          frame,
          "TOPRIGHT",
          0,
          0
        )
  end

  self.FolderDropIndicator:Show()
end

function TeamList:UpdateFolderDrag()
  if not self.DraggedFolderKey then
    return
  end

  local targetIndex, insertAfter = self:GetFolderDropPosition()

  if not targetIndex then
    self.FolderDropTargetIndex = nil
    self.FolderDropInsertAfter = nil
    self.FolderDropIndicator:Hide()
    return
  end

  self.FolderDropTargetIndex = targetIndex
  self.FolderDropInsertAfter = insertAfter

  self:ShowFolderDropIndicator(
    targetIndex,
    insertAfter
  )
end

function TeamList:FinishFolderDrag()
  self.Frame:SetScript(
    "OnUpdate",
    nil
  )

  addon.UI.Components.DragCursor:Stop()

  if self.DraggedFolderButton then
    self.DraggedFolderButton:SetAlpha(1)
  end

  local folderKey = self.DraggedFolderKey
  local targetIndex = self.FolderDropTargetIndex
  local insertAfter = self.FolderDropInsertAfter

  self.DraggedFolderKey = nil
  self.DraggedFolderButton = nil

  self.FolderDropTargetIndex = nil
  self.FolderDropInsertAfter = nil

  if not folderKey or not targetIndex then
    return
  end

  --------------------------------------------------
  -- Current folder index
  --------------------------------------------------
  local folders = addon.Services.Folder:GetSortedFolders()

  local currentIndex

  for index, folder in ipairs(folders) do
    if folder.id == folderKey then
      currentIndex = index
      break
    end
  end

  if not currentIndex then
    return
  end

  --------------------------------------------------
  -- Convert target line to insertion index
  --------------------------------------------------
  local newIndex = targetIndex

  if insertAfter then
    newIndex = newIndex + 1
  end

  --------------------------------------------------
  -- Removing the dragged element shifts indexes
  --------------------------------------------------
  if currentIndex < newIndex then
    newIndex = newIndex - 1
  end

  newIndex =
      math.max(
        1,
        math.min(
          #folders,
          newIndex
        )
      )

  if newIndex == currentIndex then
    return
  end

  addon.Services.Folder:Move(folderKey, newIndex)
end

function TeamList:BeginTeamDrag(card)
  if not card or not card.Team then
    return
  end

  --------------------------------------------------
  -- Favorites is virtual.
  -- Reordering there has no real folder meaning.
  --------------------------------------------------

  if card.FolderKey == addon.Services.Folder.FAVORITES then
    return
  end

  self.DraggedTeamCard = card
  self.DraggedTeamID = card.Team.id
  self.DraggedTeamFolderKey = card.FolderKey

  self.TeamDropTargetIndex = nil
  self.TeamDropInsertAfter = nil

  card:SetAlpha(
    0.45
  )

  self.Frame:SetScript(
    "OnUpdate",
    function()
      self:UpdateTeamDrag()
    end
  )
end

function TeamList:GetVisibleFolderCards(folderKey)
  local result = {}

  for _, card in ipairs(
    self.Frame.cards or {}
  ) do
    if card
        and card:IsShown()
        and card.Team
        and card.FolderKey == folderKey then
      table.insert(
        result,
        card
      )
    end
  end

  return result
end

function TeamList:GetTeamDropPosition()
  if not self.DraggedTeamFolderKey then
    return nil, nil
  end

  local cards = self:GetVisibleFolderCards(self.DraggedTeamFolderKey)
  local _, cursorY = GetCursorPosition()
  local scale = UIParent:GetEffectiveScale()

  cursorY = cursorY / scale

  for index, card in ipairs(cards) do
    --------------------------------------------------
    -- Skip dragged card itself
    --------------------------------------------------

    if card ~= self.DraggedTeamCard then
      local top = card:GetTop()
      local bottom = card:GetBottom()

      if top
          and bottom
          and cursorY <= top
          and cursorY >= bottom then
        local middle =
            (
              top
              + bottom
            )
            / 2

        return index,
            cursorY < middle,
            card
      end
    end
  end

  return nil,
      nil,
      nil
end

function TeamList:ShowTeamDropIndicator(card, insertAfter)
  if not self.TeamDropIndicator or not card then
    return
  end

  self.TeamDropIndicator:ClearAllPoints()

  if insertAfter then
    self.TeamDropIndicator:
        SetPoint(
          "TOPLEFT",
          card,
          "BOTTOMLEFT",
          0,
          0
        )

    self.TeamDropIndicator:
        SetPoint(
          "TOPRIGHT",
          card,
          "BOTTOMRIGHT",
          0,
          0
        )
  else
    self.TeamDropIndicator:
        SetPoint(
          "BOTTOMLEFT",
          card,
          "TOPLEFT",
          0,
          0
        )

    self.TeamDropIndicator:
        SetPoint(
          "BOTTOMRIGHT",
          card,
          "TOPRIGHT",
          0,
          0
        )
  end

  self.TeamDropIndicator:Show()
end

function TeamList:UpdateTeamDrag()
  if not self.DraggedTeamID then
    return
  end

  local targetIndex, insertAfter, targetCard = self:GetTeamDropPosition()

  self.TeamDropTargetIndex = targetIndex
  self.TeamDropInsertAfter = insertAfter
  self.TeamDropTargetCard = targetCard

  if not targetCard then
    if self.TeamDropIndicator then
      self.TeamDropIndicator:Hide()
    end

    return
  end

  self:ShowTeamDropIndicator(
    targetCard,
    insertAfter
  )
end

function TeamList:FinishTeamDrag()
  if self.Frame then
    self.Frame:SetScript(
      "OnUpdate",
      nil
    )
  end

  if self.TeamDropIndicator then
    self.TeamDropIndicator:Hide()
  end

  if self.DraggedTeamCard then
    self.DraggedTeamCard:SetAlpha(1)
  end

  local teamID = self.DraggedTeamID
  local folderKey = self.DraggedTeamFolderKey
  local targetCard = self.TeamDropTargetCard
  local insertAfter = self.TeamDropInsertAfter

  self.DraggedTeamCard = nil
  self.DraggedTeamID = nil
  self.DraggedTeamFolderKey = nil
  self.TeamDropTargetIndex = nil
  self.TeamDropInsertAfter = nil
  self.TeamDropTargetCard = nil

  --------------------------------------------------
  -- No team reorder target.
  --
  -- Important: do nothing here.
  -- Existing DragDrop can still process dropping
  -- on a folder header.
  --------------------------------------------------

  if not teamID
      or not targetCard
      or not targetCard.Team then
    return
  end

  --------------------------------------------------
  -- Only reorder inside same real folder / Unsorted
  --------------------------------------------------

  if targetCard.FolderKey ~= folderKey then
    return
  end

  if folderKey == addon.Services.Folder.FAVORITES then
    return
  end

  local teamService = addon.Services.Team

  local teams =
      teamService:GetTeamsInFolder(
        folderKey == addon.Services.Folder.UNSORTED and nil or folderKey
      )

  local currentIndex
  local targetIndex

  for index, team in ipairs(teams) do
    if tostring(team.id) == tostring(teamID) then
      currentIndex = index
    end

    if tostring(team.id) == tostring(targetCard.Team.id) then
      targetIndex = index
    end
  end

  if not currentIndex or not targetIndex then
    return
  end

  local newIndex = targetIndex

  if insertAfter then
    newIndex = newIndex + 1
  end

  --------------------------------------------------
  -- Removing current item shifts later indexes
  --------------------------------------------------

  if currentIndex < newIndex then
    newIndex = newIndex - 1
  end

  if newIndex == currentIndex then
    return
  end

  teamService:Move(
    teamID,
    newIndex
  )
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

  local sections = self:GetFolderSections()
  local currentOffset = CONTENT_PADDING

  for _, section in ipairs(sections) do
    currentOffset =
        self:CreateFolderHeader(
          section,
          currentOffset
        )

    if self.ExpandedFolderKey == section.folderKey then
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

  if self.Frame.RefreshScrollBar then
    self.Frame:RefreshScrollBar()
  end

  self:UpdateCardSelection()
  self.Refreshing = false
end

addon.UI.Views.TeamList = TeamList
