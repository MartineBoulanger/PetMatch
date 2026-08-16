local _, addon = ...

local LevellingQueuePanel = {}
LevellingQueuePanel.PendingItemID = nil
LevellingQueuePanel.PendingItemControl = nil

local TOOLBAR_HEIGHT = 32
local TOOLBAR_BUTTON_SIZE = 34
local TOOLBAR_BUTTON_SPACING = 2

local LEVELLING_ITEMS = {
  {
    itemID = 98114,
    name = "Pet Treat",
  },
  {
    itemID = 98112,
    name = "Lesser Pet Treat",
  },
  {
    itemID = 122457,
    name = "Ultimate Battle-Training Stone",
  },
  {
    itemID = 116429,
    name = "Flawless Battle-Training Stone",
  },
  {
    itemID = 98715,
    name = "Marked Flawless Battle-Stone",
  },
}

function LevellingQueuePanel:CreateToolbarItems()
  if not self.Toolbar then
    return
  end

  self.ToolbarButtons = {}

  local previousFrame = nil

  for _, item in ipairs(
    LEVELLING_ITEMS
  ) do
    local control =
        addon.UI.Components.ToolbarIconButton:
        Create(
          self.Toolbar,
          {
            itemID = item.itemID,
            size = TOOLBAR_BUTTON_SIZE,
            showCount = true,
            tooltipTitle = item.name,
            onClick = function(clickedControl)
              self:OnToolbarItemClicked(clickedControl)
            end,
          }
        )

    local button = control:GetFrame()

    if previousFrame then
      button:SetPoint(
        "LEFT",
        previousFrame,
        "RIGHT",
        TOOLBAR_BUTTON_SPACING,
        0
      )
    else
      button:SetPoint(
        "LEFT",
        self.Toolbar,
        "LEFT",
        4,
        0
      )
    end

    self.ToolbarButtons[#self.ToolbarButtons + 1] = control

    previousFrame = button
  end
end

function LevellingQueuePanel:Create(parent)
  if self.Frame then
    return self.Frame
  end

  local frame =
      CreateFrame(
        "Frame",
        nil,
        parent
      )

  frame:SetAllPoints(parent)

  self.Frame = frame

  --------------------------------------------------
  -- Toolbar
  --------------------------------------------------
  self.Toolbar =
      CreateFrame(
        "Frame",
        nil,
        frame
      )

  self.Toolbar:SetPoint(
    "TOPLEFT",
    frame,
    "TOPLEFT",
    -20,
    2
  )

  self.Toolbar:SetPoint(
    "TOPRIGHT",
    frame,
    "TOPRIGHT",
    0,
    5
  )

  self.Toolbar:SetHeight(TOOLBAR_HEIGHT)

  --------------------------------------------------
  -- Count
  --------------------------------------------------
  self.Count =
      self.Toolbar:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlightSmall"
      )

  self.Count:SetPoint(
    "RIGHT",
    self.Toolbar,
    "RIGHT",
    -23,
    0
  )

  --------------------------------------------------
  -- Leveling items
  --------------------------------------------------
  self:CreateToolbarItems()

  --------------------------------------------------
  -- Background
  --------------------------------------------------
  self.ListBackground =
      CreateFrame(
        "Frame",
        nil,
        frame,
        "BackdropTemplate"
      )

  self.ListBackground:EnableMouse(true)
  self.ListBackground:RegisterForDrag("LeftButton")

  self.ListBackground:SetBackdrop({
    bgFile = "Interface\\FrameGeneral\\UI-Background-Marble",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",

    tile = true,
    tileSize = 128,
    edgeSize = 12,

    insets = {
      left = 3,
      right = 3,
      top = 3,
      bottom = 3,
    },
  })

  self.ListBackground:SetBackdropColor(
    0.55,
    0.55,
    0.55,
    0.95
  )

  self.ListBackground:SetBackdropBorderColor(
    0.35,
    0.35,
    0.35,
    1
  )

  self.ListBackground:SetPoint(
    "TOPLEFT",
    self.Toolbar,
    "BOTTOMLEFT",
    0,
    -3
  )

  self.ListBackground:SetPoint(
    "BOTTOMRIGHT",
    frame,
    "BOTTOMRIGHT",
    -20,
    0
  )

  self.ListBackground:SetScript(
    "OnReceiveDrag",
    function()
      self:HandleExternalDrop()
    end
  )

  self.ListBackground:HookScript(
    "OnMouseUp",
    function(_, button)
      if button ~= "LeftButton" then
        return
      end
      self:HandleExternalDrop()
    end
  )

  --------------------------------------------------
  -- List
  --------------------------------------------------
  self.List =
      addon.UI.Views.LevellingQueueList:
      Create(
        self.ListBackground
      )

  self.List:ClearAllPoints()

  self.List:SetPoint(
    "TOPLEFT",
    self.ListBackground,
    "TOPLEFT",
    4,
    -4
  )

  --------------------------------------------------
  -- Empty state
  --------------------------------------------------
  self.EmptyText =
      self.ListBackground:
      CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlight"
      )

  self.EmptyText:SetPoint(
    "CENTER",
    self.ListBackground,
    "CENTER",
    0,
    0
  )

  self.EmptyText:SetWidth(200)
  self.EmptyText:SetJustifyH("CENTER")
  self.EmptyText:SetText("No pets are currently in the levelling queue.")

  self.EmptyText:SetTextColor(
    0.70,
    0.70,
    0.70,
    1
  )

  --------------------------------------------------
  -- Events
  --------------------------------------------------
  self:RegisterEvents()
  self:Refresh()

  return frame
end

function LevellingQueuePanel:HandleExternalDrop()
  local drag = addon.UI.Components.LevellingQueueDrag

  if not drag
      or not drag:IsDragging() then
    return false
  end

  if drag:GetSource()
      ~= "petJournal" then
    return false
  end

  local petGUID =
      drag:GetPetGUID()

  if not petGUID then
    return false
  end

  local success,
  errorMessage =
      addon.Services.LevellingQueue:
      Add(
        petGUID
      )

  if not success then
    drag:Clear()

    if errorMessage then
      addon.Logger:Warn(
        errorMessage
      )
    end

    return false
  end

  --------------------------------------------------
  -- Clear both PetMatch drag state
  -- and Blizzard's cursor payload
  --------------------------------------------------
  drag:Clear()

  if type(ClearCursor) == "function" then
    ClearCursor()
  end

  return true
end

function LevellingQueuePanel:OnToolbarItemClicked(control)
  if not control or not control.ItemID then
    return
  end

  if self.PendingItemID == control.ItemID then
    self:CancelItemTargeting()
    return
  end

  self.PendingItemID = control.ItemID
  self.PendingItemControl = control

  self:RefreshItemTargeting()
end

function LevellingQueuePanel:IsItemTargeting()
  return self.PendingItemID ~= nil
end

function LevellingQueuePanel:RefreshItemTargeting()
  local list = addon.UI.Views.LevellingQueueList

  if list and list.SetItemTargeting then
    list:SetItemTargeting(self.PendingItemID ~= nil)
  end
end

function LevellingQueuePanel:CancelItemTargeting()
  self.PendingItemID = nil
  self.PendingItemControl = nil

  self:RefreshItemTargeting()
end

function LevellingQueuePanel:RefreshToolbarItems()
  if not self.ToolbarButtons then
    return
  end

  for _, control in ipairs(self.ToolbarButtons) do
    local itemID = control.ItemID

    local count =
        C_Item.GetItemCount(
          itemID,
          false,
          false,
          false
        )
        or 0

    control:SetCount(count)
    control:SetEnabled(count > 0)
  end
end

function LevellingQueuePanel:UsePendingItemOnPet(petGUID)
  local itemID = self.PendingItemID

  if not itemID or not petGUID then
    return false
  end

  --------------------------------------------------
  -- Verify that the pet still exists.
  --------------------------------------------------
  local pet = addon.Services.PetJournal:GetPet(petGUID)

  if not pet then
    self:CancelItemTargeting()
    return false
  end

  --------------------------------------------------
  -- Item use enters battle-pet targeting.
  -- Target the selected queue pet on the next frame.
  --------------------------------------------------
  C_Timer.After(
    0,
    function()
      C_PetJournal.SpellTargetBattlePet(
        petGUID
      )

      self:CancelItemTargeting()

      C_Timer.After(
        0.1,
        function()
          self:RefreshToolbarItems()
        end
      )
    end
  )

  return true
end

function LevellingQueuePanel:Refresh()
  if not self.Frame then
    return
  end

  local service = addon.Services.LevellingQueue

  if not service then
    return
  end

  local count = service:GetCount()

  if count == 1 then
    self.Count:SetText(
      "1 pet"
    )
  else
    self.Count:SetFormattedText(
      "%d pets",
      count
    )
  end

  self.EmptyText:SetShown(count == 0)
  self:RefreshToolbarItems()
  addon.UI.Views.LevellingQueueList:Refresh()
end

function LevellingQueuePanel:RegisterEvents()
  if self.EventsRegistered then
    return
  end

  self.EventsRegistered = true

  --------------------------------------------------
  -- PetMatch events
  --------------------------------------------------
  addon.EventBus:Register(
    addon.Events.LEVELLING_QUEUE_CHANGED,
    function()
      if not self.Frame then
        return
      end

      self:Refresh()
    end
  )

  --------------------------------------------------
  -- Blizzard bag events
  --------------------------------------------------
  self.EventFrame =
      self.EventFrame
      or CreateFrame("Frame")

  self.EventFrame:RegisterEvent(
    "BAG_UPDATE_DELAYED"
  )

  self.EventFrame:SetScript(
    "OnEvent",
    function(_, event)
      if event == "BAG_UPDATE_DELAYED" then
        if not self.Frame then
          return
        end

        self:RefreshToolbarItems()
      end
    end
  )
end

addon.UI.Views.LevellingQueuePanel = LevellingQueuePanel
