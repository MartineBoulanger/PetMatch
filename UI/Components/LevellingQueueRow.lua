local _, addon = ...

local LevellingQueueRow = {}
LevellingQueueRow.__index = LevellingQueueRow

local ROW_HEIGHT = 42
local ICON_SIZE = 32

local PET_RARITY_COLORS = {
  [1] = ITEM_QUALITY_COLORS[0],
  [2] = ITEM_QUALITY_COLORS[1],
  [3] = ITEM_QUALITY_COLORS[2],
  [4] = ITEM_QUALITY_COLORS[3],
  [5] = ITEM_QUALITY_COLORS[4],
  [6] = ITEM_QUALITY_COLORS[5],
}

local PET_FAMILY_ICONS = {
  [1]  = "Interface\\Icons\\Pet_Type_Humanoid",
  [2]  = "Interface\\Icons\\Pet_Type_Dragon",
  [3]  = "Interface\\Icons\\Pet_Type_Flying",
  [4]  = "Interface\\Icons\\Pet_Type_Undead",
  [5]  = "Interface\\Icons\\Pet_Type_Critter",
  [6]  = "Interface\\Icons\\Pet_Type_Magical",
  [7]  = "Interface\\Icons\\Pet_Type_Elemental",
  [8]  = "Interface\\Icons\\Pet_Type_Beast",
  [9]  = "Interface\\Icons\\Pet_Type_Water",
  [10] = "Interface\\Icons\\Pet_Type_Mechanical",
}

local function GetQualityColor(quality)
  quality = tonumber(quality) or 0

  local color =
      PET_RARITY_COLORS
      and PET_RARITY_COLORS[quality]

  if not color then
    return 1, 1, 1
  end

  return
      color.r or 1,
      color.g or 1,
      color.b or 1
end

function LevellingQueueRow:Create(
    parent,
    list
)
  local instance =
      setmetatable(
        {},
        LevellingQueueRow
      )

  instance.List = list

  local frame =
      CreateFrame(
        "Button",
        nil,
        parent,
        "BackdropTemplate"
      )

  frame:SetHeight(
    ROW_HEIGHT
  )

  frame:RegisterForClicks(
    "LeftButtonUp",
    "RightButtonUp"
  )

  frame:RegisterForDrag(
    "LeftButton"
  )

  frame:SetBackdrop({
    bgFile = "Interface\\FrameGeneral\\UI-Background-Marble",
    edgeFile = "Interface\\Buttons\\WHITE8X8",

    tile = true,
    tileSize = 64,
    edgeSize = 1,
  })

  frame:SetBackdropColor(
    0.18,
    0.18,
    0.18,
    0.90
  )

  frame:SetBackdropBorderColor(
    0.35,
    0.30,
    0.20,
    0.90
  )

  instance.Frame = frame

  --------------------------------------------------
  -- Position
  --------------------------------------------------
  instance.Position =
      frame:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlightSmall"
      )

  instance.Position:SetPoint(
    "LEFT",
    frame,
    "LEFT",
    6,
    0
  )

  instance.Position:SetWidth(20)
  instance.Position:SetJustifyH("CENTER")

  --------------------------------------------------
  -- Icon
  --------------------------------------------------
  instance.Icon =
      frame:CreateTexture(
        nil,
        "ARTWORK"
      )

  instance.Icon:SetSize(
    ICON_SIZE,
    ICON_SIZE
  )

  instance.Icon:SetPoint(
    "LEFT",
    instance.Position,
    "RIGHT",
    4,
    0
  )

  instance.Icon:SetTexCoord(
    0.08,
    0.92,
    0.08,
    0.92
  )

  --------------------------------------------------
  -- Name
  --------------------------------------------------
  instance.Name =
      frame:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlight"
      )

  instance.Name:SetPoint(
    "TOPLEFT",
    instance.Icon,
    "TOPRIGHT",
    8,
    -4
  )

  instance.Name:SetPoint(
    "RIGHT",
    frame,
    "RIGHT",
    -42,
    0
  )

  instance.Name:SetJustifyH("LEFT")
  instance.Name:SetWordWrap(false)

  --------------------------------------------------
  -- Level
  --------------------------------------------------
  instance.Level =
      frame:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontNormalSmall"
      )

  instance.Level:SetPoint(
    "BOTTOMLEFT",
    instance.Icon,
    "BOTTOMRIGHT",
    8,
    4
  )

  instance.Level:SetPoint(
    "RIGHT",
    frame,
    "RIGHT",
    -42,
    0
  )

  instance.Level:SetJustifyH("LEFT")

  --------------------------------------------------
  -- Family
  --------------------------------------------------
  instance.Family =
      frame:CreateTexture(
        nil,
        "BACKGROUND",
        nil,
        2
      )

  instance.Family:SetSize(
    ICON_SIZE,
    ICON_SIZE
  )

  instance.Family:SetPoint(
    "RIGHT",
    frame,
    "RIGHT",
    -4,
    0
  )

  instance.Family:SetAlpha(
    0.20
  )

  --------------------------------------------------
  -- Tooltip
  --------------------------------------------------
  if addon.UI.Components.PetTooltip then
    addon.UI.Components.PetTooltip:
        Attach(
          frame,

          function(control)
            if not control.petGUID then
              return nil
            end

            return "petGUID",
                control.petGUID
          end,

          "ANCHOR_RIGHT"
        )
  end

  --------------------------------------------------
  -- Hover
  --------------------------------------------------
  frame:SetScript(
    "OnEnter",
    function()
      frame:SetBackdropColor(
        0.28,
        0.28,
        0.28,
        0.95
      )
    end
  )

  frame:SetScript(
    "OnLeave",
    function()
      frame:SetBackdropColor(
        0.18,
        0.18,
        0.18,
        0.90
      )
    end
  )

  --------------------------------------------------
  -- Right click
  --------------------------------------------------
  frame:SetScript(
    "OnClick",
    function(_, button)
      --------------------------------------------------
      -- Item targeting
      --------------------------------------------------
      if button == "LeftButton"
          and instance.ItemTargeting
          and instance.PetGUID then
        addon.UI.Views.LevellingQueuePanel:
            UsePendingItemOnPet(instance.PetGUID)
        return
      end

      --------------------------------------------------
      -- Context menu
      --------------------------------------------------
      if button == "RightButton" then
        instance:OpenContextMenu()
      end
    end
  )

  --------------------------------------------------
  -- Drag
  --------------------------------------------------
  frame:SetScript(
    "OnDragStart",
    function()
      instance:StartDrag()
    end
  )

  frame:SetScript(
    "OnDragStop",
    function()
      instance:StopDrag()
    end
  )

  frame:Hide()

  return instance
end

function LevellingQueueRow:SetPet(item)
  local pet = item and item.pet

  if not pet then
    self:Clear()
    return
  end

  self.Item = item
  self.PetGUID = item.petGUID
  self.Index = item.index
  self.Frame.petGUID = item.petGUID

  self.Position:SetFormattedText(
    "%d",
    item.index
  )

  self.Icon:SetTexture(pet.icon)

  self.Name:SetText(pet.name or "Unknown Pet")

  local r, g, b = GetQualityColor(pet.quality)

  self.Name:SetTextColor(
    r,
    g,
    b,
    1
  )

  local level =
      tonumber(
        pet.level
      )
      or 0

  self.Level:SetFormattedText(
    "Level %d",
    level
  )

  self.Level:SetTextColor(
    r,
    g,
    b,
    1
  )

  local texture =
      PET_FAMILY_ICONS[
      tonumber(
        pet.petType
      )
      ]

  if texture then
    self.Family:SetTexture(texture)
    self.Family:Show()
  else
    self.Family:SetTexture(nil)
    self.Family:Hide()
  end

  self.Frame:Show()
end

function LevellingQueueRow:Clear()
  self.Item = nil
  self.PetGUID = nil
  self.Index = nil

  self.Frame.petGUID = nil

  self.Position:SetText("")
  self.Icon:SetTexture(nil)
  self.Name:SetText("")
  self.Level:SetText("")
  self.Family:SetTexture(nil)
  self.Family:Hide()

  self.Frame:Hide()
end

function LevellingQueueRow:SetItemTargeting(enabled)
  self.ItemTargeting = enabled == true

  if self.ItemTargeting then
    self.Frame:SetBackdropBorderColor(
      1,
      0.82,
      0,
      1
    )
  else
    self.Frame:SetBackdropBorderColor(
      0.35,
      0.30,
      0.20,
      0.90
    )
  end
end

-- context menu - liefst aparte file
function LevellingQueueRow:OpenContextMenu()
  if not self.PetGUID then
    return
  end

  local petGUID = self.PetGUID

  MenuUtil.CreateContextMenu(
    self.Frame,

    function(_, root)
      local service = addon.Services.LevellingQueue
      local index = service:GetIndex(petGUID)
      local count = service:GetCount()

      --------------------------------------------------
      -- Move Up
      --------------------------------------------------
      local moveUp =
          root:CreateButton(
            "Move Up",
            function()
              service:MoveUp(
                petGUID
              )
            end
          )

      moveUp:SetEnabled(
        index ~= nil
        and index > 1
      )

      --------------------------------------------------
      -- Move Down
      --------------------------------------------------
      local moveDown =
          root:CreateButton(
            "Move Down",
            function()
              service:MoveDown(
                petGUID
              )
            end
          )

      moveDown:SetEnabled(
        index ~= nil
        and index < count
      )

      root:CreateDivider()

      --------------------------------------------------
      -- Remove
      --------------------------------------------------
      root:CreateButton(
        "Remove from Levelling Queue",
        function()
          service:Remove(
            petGUID
          )
        end
      )
    end
  )
end

function LevellingQueueRow:StartDrag()
  if self.ItemTargeting then
    return
  end

  if not self.PetGUID
      or not self.List then
    return
  end

  local drag = addon.UI.Components.LevellingQueueDrag

  if not drag then
    return
  end

  drag:Start(
    self.PetGUID,
    "levellingQueue",
    self.Index
  )

  self.List:BeginRowDrag(self)
end

function LevellingQueueRow:StopDrag()
  if not self.List then
    return
  end

  self.List:FinishRowDrag(
    self
  )

  C_Timer.After(
    0,
    function()
      local drag =
          addon.UI.Components.LevellingQueueDrag

      if drag then
        drag:Clear()
      end
    end
  )
end

addon.UI.Components.LevellingQueueRow = LevellingQueueRow
