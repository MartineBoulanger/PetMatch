local _, addon = ...

local L = addon.L
local LevellingQueueRow = {}
LevellingQueueRow.__index = LevellingQueueRow

local ROW_HEIGHT = 48
local ICON_SIZE = 36

local function GetQualityColor(quality)
  quality = tonumber(quality) or 0

  local color = addon.Constants.PET_RARITY_COLORS[quality]

  if not color then
    return 1, 1, 1
  end

  return
      color.r or 1,
      color.g or 1,
      color.b or 1
end

function LevellingQueueRow:IsItemTargeting()
  local panel = addon.UI.Views.LevellingQueuePanel
  return panel and panel.PendingItemID ~= nil
end

local function HandleSpecialPetClick(petGUID)
  if not petGUID then
    return false
  end

  if not SpellIsTargeting() then
    return false
  end

  local pet =
      addon.Services.PetJournal:GetPet(petGUID)

  if not pet or pet.canBattle ~= true then
    return false
  end

  C_PetJournal.SpellTargetBattlePet(petGUID)

  return true
end

function LevellingQueueRow:Create(parent, list)
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

  --------------------------------------------------
  -- Blizzard-style row
  --------------------------------------------------
  frame:SetBackdrop({
    bgFile = "Interface\\FrameGeneral\\UI-Background-Marble",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 128,
    edgeSize = 8,
    insets = {
      left = 3,
      right = 3,
      top = 3,
      bottom = 3,
    },
  })

  frame:SetBackdropBorderColor(0.35, 0.35, 0.35, 1)

  instance.BackgroundGradient = frame:CreateTexture(
    nil,
    "BACKGROUND",
    nil,
    1
  )

  instance.BackgroundGradient:SetPoint("TOPLEFT", 1, -1)
  instance.BackgroundGradient:SetPoint("BOTTOMRIGHT", -1, 1)

  instance.BackgroundGradient:SetColorTexture(1, 1, 1, 1)

  instance.BackgroundGradient:SetGradient(
    "VERTICAL",
    CreateColor(0.015, 0.015, 0.015, 0.70),
    CreateColor(0.13, 0.13, 0.13, 0.8)
  )

  --------------------------------------------------
  -- Blizzard-style hover highlight
  --------------------------------------------------
  instance.Highlight =
      frame:CreateTexture(
        nil,
        "HIGHLIGHT"
      )

  instance.Highlight:SetAtlas(
    "PetList-ButtonHighlight",
    true
  )

  instance.Highlight:SetPoint(
    "TOPLEFT",
    frame,
    "TOPLEFT",
    0,
    0
  )

  instance.Highlight:SetPoint(
    "BOTTOMRIGHT",
    frame,
    "BOTTOMRIGHT",
    0,
    0
  )

  instance.Highlight:SetBlendMode(
    "BLEND"
  )

  frame:SetHighlightTexture(
    instance.Highlight
  )

  instance.Frame = frame

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
    frame,
    "LEFT",
    6,
    0
  )

  instance.Icon:SetTexCoord(
    0.08,
    0.92,
    0.08,
    0.92
  )

  --------------------------------------------------
  -- Blizzard pet icon border
  --------------------------------------------------
  instance.IconBorder =
      frame:CreateTexture(
        nil,
        "OVERLAY"
      )

  instance.IconBorder:SetTexture(
    651080
  )

  instance.IconBorder:SetPoint(
    "TOPLEFT",
    instance.Icon,
    "TOPLEFT",
    -3,
    3
  )

  instance.IconBorder:SetPoint(
    "BOTTOMRIGHT",
    instance.Icon,
    "BOTTOMRIGHT",
    3,
    -3
  )

  instance.IconBorder:SetVertexColor(
    0.35,
    0.35,
    0.35,
    1
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
    11
  )

  instance.Level:SetJustifyH("LEFT")

  --------------------------------------------------
  -- Experience
  --------------------------------------------------
  instance.XPBar =
      CreateFrame(
        "StatusBar",
        nil,
        frame
      )

  instance.XPBar:SetSize(
    130,
    8
  )

  instance.XPBar:SetPoint(
    "BOTTOMLEFT",
    instance.Icon,
    "BOTTOMRIGHT",
    8,
    0
  )

  instance.XPBar:SetFrameLevel(
    frame:GetFrameLevel() + 5
  )


  instance.XPBar:SetStatusBarTexture(
    "Interface\\TargetingFrame\\UI-TargetingFrame-BarFill"
  )

  instance.XPBar:SetStatusBarColor(0, 0.55, 0.75, 1)

  instance.XPBar:SetMinMaxValues(
    0,
    1
  )

  instance.XPBar:SetValue(0)

  instance.XPBarBackground =
      instance.XPBar:CreateTexture(
        nil,
        "BACKGROUND"
      )

  instance.XPBarBackground:SetAllPoints(
    instance.XPBar
  )

  instance.XPBarBackground:SetColorTexture(
    0.26,
    0.26,
    0.26,
    0.7
  )

  instance.XPBarBorder =
      instance.XPBar:CreateTexture(
        nil,
        "OVERLAY"
      )

  instance.XPBarBorder:SetTexture(
    "Interface\\Tooltips\\UI-StatusBar-Border"
  )

  instance.XPBarBorder:SetPoint(
    "TOPLEFT",
    instance.XPBar,
    "TOPLEFT",
    -2,
    2
  )

  instance.XPBarBorder:SetPoint(
    "BOTTOMRIGHT",
    instance.XPBar,
    "BOTTOMRIGHT",
    2,
    -2
  )

  --------------------------------------------------
  -- Experience text
  --------------------------------------------------
  instance.XPText =
      instance.XPBar:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlightSmall"
      )

  instance.XPText:SetPoint(
    "CENTER",
    instance.XPBar,
    "CENTER",
    0,
    0
  )

  instance.XPText:SetJustifyH("CENTER")

  --------------------------------------------------
  -- Breed
  --------------------------------------------------
  instance.Breed =
      frame:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlightSmall"
      )

  instance.Breed:SetPoint(
    "RIGHT",
    frame,
    "RIGHT",
    -8,
    0
  )

  instance.Breed:SetWidth(38)
  instance.Breed:SetJustifyH("RIGHT")

  instance.Breed:SetTextColor(
    1,
    1,
    1,
    1
  )

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
    ICON_SIZE + 4,
    ICON_SIZE + 4
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

          "ANCHOR_RIGHT",
          "queue"
        )
    addon.UI.Components.PetTooltip:
        SetClickBlocker(
          frame,
          function()
            return SpellIsTargeting() == true
          end
        )
  end

  frame:SetScript(
    "OnClick",
    function(_, button)
      if button == "LeftButton"
          and instance.PetGUID
          and SpellIsTargeting() then
        if HandleSpecialPetClick(
              instance.PetGUID
            ) then
          return
        end
      end

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

  self.Icon:SetTexture(pet.icon)

  self.Name:SetText(pet.name or L["UNKNOWN"])

  local _, _, _, _, quality =
      C_PetJournal.GetPetStats(
        item.petGUID
      )

  local r, g, b =
      GetQualityColor(
        quality
      )

  self.Name:SetTextColor(
    r,
    g,
    b,
    1
  )

  if self.IconBorder then
    self.IconBorder:SetVertexColor(
      r,
      g,
      b,
      1
    )
  end

  local level = tonumber(pet.level) or 0
  local xp = tonumber(pet.xp) or 0
  local maxXP = tonumber(pet.maxXP) or 0

  if maxXP > 0 and level < 25 then
    self.XPBar:SetMinMaxValues(
      0,
      maxXP
    )

    self.XPBar:SetValue(
      math.min(
        xp,
        maxXP
      )
    )

    local percentage = 0

    if maxXP > 0 then
      percentage =
          math.floor(
            (xp / maxXP) * 100
            + 0.5
          )
    end

    self.XPText:SetFormattedText(
      "%d/%d (%d%%)",
      xp,
      maxXP,
      percentage
    )

    self.XPBar:Show()
  else
    self.XPBar:SetMinMaxValues(
      0,
      1
    )

    self.XPBar:SetValue(0)
    self.XPText:SetText("")
    self.XPBar:Hide()
  end

  self.Level:SetFormattedText(
    L["LEVEL"] .. " %d",
    level
  )

  self.Level:SetTextColor(
    1,
    1,
    1,
    1
  )

  local showBreed =
      addon.Settings:GetUI("petListBreedPosition") ~= "hidden"

  if showBreed then
    local breed =
        addon.Services.Breed:
        GetJournalBreed(
          item.petGUID
        )

    if breed then
      self.Breed:SetText(
        breed
      )

      self.Breed:Show()
    else
      self.Breed:SetText("")
      self.Breed:Hide()
    end
  else
    self.Breed:SetText("")
    self.Breed:Hide()
  end

  local texture =
      addon.Constants.PET_FAMILY_ICONS[tonumber(pet.petType)]

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

  self.Icon:SetTexture(nil)
  self.Name:SetText("")
  self.Level:SetText("")
  self.Family:SetTexture(nil)
  self.Family:Hide()
  self.XPBar:SetValue(0)
  self.XPText:SetText("")
  self.XPBar:Hide()
  self.Breed:SetText("")
  self.Breed:Hide()

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
            L["MOVE_UP"],
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
            L["MOVE_DOWN"],
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
        L["REMOVE_FROM_QUEUE"],
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
