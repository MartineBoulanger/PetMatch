local _, addon                   = ...

local PetList                    = {}

PetList.Hooked                   = false
PetList.TagMenuInstalled         = false
PetList.LoaderFrame              = nil

local BREED_LABEL_RIGHT_OFFSET   = -8
local NAME_RIGHT_SPACING         = 8

local STATUS_ICON_SIZE           = 12
local STATUS_ICON_SPACING        = 3
local STATUS_BREED_SPACING       = 3

local RAID_MARKER_TEXTURE_FORMAT = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_%d"
local TEAM_ICON_TEXTURE          = "Interface\\Icons\\Tracking_WildPet"
local LEVELING_ICON_TEXTURE      = "Interface\\Addons\\PetMatch\\Media\\levelingarrow"

local NORMAL_ROW_HEIGHT          = 46
local COMPACT_ROW_HEIGHT         = 30

local COMPACT_ICON_SIZE          = 30
local COMPACT_LEVEL_SIZE         = 22
local COMPACT_FAMILY_ICON_SIZE   = 28

local COMPACT_ICON_LEFT_OFFSET   = -37
local COMPACT_LEVEL_OVERLAP      = -6
local COMPACT_NAME_SPACING       = 4

local PET_RARITY_COLORS          = {
  [1] = ITEM_QUALITY_COLORS[0],
  [2] = ITEM_QUALITY_COLORS[1],
  [3] = ITEM_QUALITY_COLORS[2],
  [4] = ITEM_QUALITY_COLORS[3],
  [5] = ITEM_QUALITY_COLORS[4],
  [6] = ITEM_QUALITY_COLORS[5]
}

local RANDOM_PET_ICON            = "Interface\\Icons\\INV_Misc_Dice_02"

local LEVELING_PET_ICON          = "Interface\\AddOns\\PetMatch\\Media\\levelingicon"

local PET_FAMILY_ICONS           = {
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

local PendingSlotOverlays        = {}
local BattleSlotTagOverlays      = {}

local function GetPendingSpecialSlotIcon(
    specialSlot
)
  if type(specialSlot) ~= "table" then
    return nil
  end

  if specialSlot.type == "leveling"
      or specialSlot.type == "levelingQueue" then
    return LEVELING_PET_ICON
  end

  if specialSlot.type == "random" then
    local petType =
        tonumber(
          specialSlot.petType
        )
        or 0

    if petType > 0 then
      return PET_FAMILY_ICONS[
      petType
      ]
    end

    return RANDOM_PET_ICON
  end

  return nil
end

local function GetPendingSlotOverlay(slotIndex)
  local existing =
      PendingSlotOverlays[
      slotIndex
      ]

  if existing then
    return existing
  end

  local slotFrame =
      _G[
      "PetJournalLoadoutPet"
      .. tostring(slotIndex)
      ]

  if not slotFrame then
    return nil
  end

  local overlay =
      CreateFrame(
        "Frame",
        nil,
        slotFrame
      )

  overlay:SetSize(
    20,
    20
  )

  overlay:SetPoint(
    "TOPRIGHT",
    slotFrame,
    "TOPRIGHT",
    -4,
    -4
  )

  --------------------------------------------------
  -- Hide the normal pet behind the special icon
  --------------------------------------------------

  overlay.Background =
      overlay:CreateTexture(
        nil,
        "BACKGROUND"
      )

  overlay.Background:SetAllPoints()
  overlay.Background:SetColorTexture(
    0.03,
    0.03,
    0.03,
    0.75
  )

  --------------------------------------------------
  -- Special-slot icon
  --------------------------------------------------

  overlay.Icon =
      overlay:CreateTexture(
        nil,
        "ARTWORK"
      )

  overlay.Icon:SetPoint(
    "TOPLEFT",
    overlay,
    "TOPLEFT",
    2,
    -2
  )

  overlay.Icon:SetPoint(
    "BOTTOMRIGHT",
    overlay,
    "BOTTOMRIGHT",
    -2,
    2
  )

  overlay.Icon:SetTexCoord(
    0.08,
    0.92,
    0.08,
    0.92
  )

  overlay:Hide()

  PendingSlotOverlays[
  slotIndex
  ] = overlay

  return overlay
end

local function GetBattleSlotTagOverlay(slotIndex)
  local existing = BattleSlotTagOverlays[slotIndex]

  if existing then
    return existing
  end

  local slotFrame = _G["PetJournalLoadoutPet" .. tostring(slotIndex)]

  if not slotFrame then
    return nil
  end

  local overlay =
      CreateFrame(
        "Frame",
        nil,
        slotFrame
      )

  overlay:SetSize(
    18,
    18
  )

  overlay:SetFrameLevel(
    slotFrame:GetFrameLevel()
    + 10
  )

  overlay.Icon = overlay:CreateTexture(
    nil,
    "OVERLAY"
  )

  overlay.Icon:SetAllPoints()

  overlay.Icon:SetTexCoord(
    0,
    1,
    0,
    1
  )

  overlay:Hide()

  BattleSlotTagOverlays[slotIndex] = overlay

  return overlay
end

local function LayoutBattleSlotBadges(slotIndex)
  local slotFrame = _G["PetJournalLoadoutPet" .. tostring(slotIndex)]

  if not slotFrame then
    return
  end

  local specialOverlay = PendingSlotOverlays[slotIndex]
  local tagOverlay = BattleSlotTagOverlays[slotIndex]
  local hasSpecial = specialOverlay and specialOverlay:IsShown()
  local hasTag = tagOverlay and tagOverlay:IsShown()

  if tagOverlay then
    tagOverlay:ClearAllPoints()

    tagOverlay:SetPoint(
      "TOPRIGHT",
      slotFrame,
      "TOPRIGHT",
      -4,
      -4
    )
  end

  if specialOverlay then
    specialOverlay:ClearAllPoints()

    if hasTag then
      specialOverlay:SetPoint(
        "RIGHT",
        tagOverlay,
        "LEFT",
        -2,
        0
      )
    else
      specialOverlay:SetPoint(
        "TOPRIGHT",
        slotFrame,
        "TOPRIGHT",
        -4,
        -4
      )
    end
  end
end

local function RefreshPendingBattleSlotVisual(
    slotIndex
)
  local battleSlotService =
      addon.Services.BattleSlot

  if not battleSlotService then
    return
  end

  local overlay =
      GetPendingSlotOverlay(
        slotIndex
      )

  if not overlay then
    return
  end

  local specialSlot =
      battleSlotService:
      GetPendingSpecialSlot(
        slotIndex
      )

  if not specialSlot then
    overlay:Hide()
    LayoutBattleSlotBadges(slotIndex)
    return
  end

  local icon =
      GetPendingSpecialSlotIcon(
        specialSlot
      )

  if not icon then
    overlay:Hide()
    LayoutBattleSlotBadges(slotIndex)
    return
  end

  overlay.Icon:SetTexture(
    icon
  )

  overlay:Show()
  LayoutBattleSlotBadges(slotIndex)
end

local function RefreshAllPendingBattleSlotVisuals()
  for slotIndex = 1, 3 do
    RefreshPendingBattleSlotVisual(
      slotIndex
    )
  end
end

local function BuildRandomSpecialSlot(
    petType
)
  petType =
      tonumber(petType)
      or 0

  return {
    type = "random",
    petType = petType,
    rawPetTag =
        "ZR"
        .. tostring(
          petType
        ),
  }
end

local function BuildLevelingSpecialSlot()
  return {
    type = "leveling",
    rawPetTag = "ZL",
  }
end

local function GetRaidMarkerTexture(tagID)
  tagID = tonumber(tagID)

  if not tagID
      or tagID < 1
      or tagID > 8 then
    return nil
  end

  return string.format(
    RAID_MARKER_TEXTURE_FORMAT,
    tagID
  )
end

local function RefreshBattleSlotTagVisual(slotIndex)
  local overlay = GetBattleSlotTagOverlay(slotIndex)

  if not overlay then
    return
  end

  local battleSlot = addon.Services.BattleSlot
  local tagService = addon.Services.PetTag

  if not battleSlot or not tagService then
    overlay:Hide()
    return
  end

  local slotInfo = battleSlot:GetSlotLoadout(slotIndex)
  local petGUID = slotInfo and slotInfo.petGUID

  if not petGUID then
    overlay:Hide()
    return
  end

  local definition = tagService:GetTagDefinition(petGUID)

  if not definition then
    overlay:Hide()
    return
  end

  local texture = GetRaidMarkerTexture(definition.id)

  if not texture then
    overlay:Hide()
    return
  end

  overlay.Icon:SetTexture(
    texture
  )

  overlay:Show()
end

local function RefreshAllBattleSlotTagVisuals()
  for slotIndex = 1, 3 do
    RefreshBattleSlotTagVisual(slotIndex)
  end
end

local function IsBreedVisible()
  return addon.Settings:Get(
    "showPetListBreed"
  ) ~= false
end

local function GetBreedPosition()
  return addon.Settings:Get(
    "petListBreedPosition"
  ) or "right"
end

local function UsesRightSideBreed()
  return IsBreedVisible()
      and GetBreedPosition() == "right"
end

local function UsesCompactRows()
  return addon.Settings:Get(
    "compactPetListRows"
  ) == true
end

local function GetPetJournalScrollBox()
  if not _G.PetJournal then
    return nil
  end

  return _G.PetJournal.ScrollBox
      or (
        _G.PetJournal.PetList
        and _G.PetJournal.PetList.ScrollBox
      )
end

local function GetPetIcon(button)
  if not button then
    return nil
  end

  return button.icon
      or button.Icon
      or button.petIcon
      or button.PetIcon
end

local function GetPetLevelText(button)
  return button
      and button.dragButton
      and button.dragButton.level
      or nil
end

local function GetPetLevelBackground(button)
  return button
      and button.dragButton
      and button.dragButton.levelBG
      or nil
end

local function SaveRegionLayout(region)
  if not region then
    return nil
  end

  local layout = {
    width = region:GetWidth(),
    height = region:GetHeight(),
    anchors = {},
  }

  for index = 1, region:GetNumPoints() do
    local point,
    relativeTo,
    relativePoint,
    offsetX,
    offsetY =
        region:GetPoint(index)

    layout.anchors[index] = {
      point,
      relativeTo,
      relativePoint,
      offsetX,
      offsetY,
    }
  end

  return layout
end

local function GetPetFamilyBackground(button)
  if not button then
    return nil
  end

  return button.petTypeIcon
      or button.PetTypeIcon
      or button.petTypeTexture
      or button.PetTypeTexture
      or button.typeIcon
      or button.TypeIcon
end

local function SaveNameAnchors(button)
  if button.PetMatchOriginalNameAnchors
      or not button.name then
    return
  end

  local anchors = {}

  for index = 1,
  button.name:GetNumPoints() do
    local point,
    relativeTo,
    relativePoint,
    offsetX,
    offsetY =
        button.name:GetPoint(index)

    anchors[index] = {
      point,
      relativeTo,
      relativePoint,
      offsetX,
      offsetY,
    }
  end

  button.PetMatchOriginalNameAnchors =
      anchors
end

local function RestoreNameAnchors(button)
  if not button.name then
    return
  end

  local anchors =
      button.PetMatchOriginalNameAnchors

  if not anchors then
    return
  end

  button.name:ClearAllPoints()

  for _, anchor in ipairs(anchors) do
    button.name:SetPoint(
      anchor[1],
      anchor[2],
      anchor[3],
      anchor[4],
      anchor[5]
    )
  end
end

local function SaveOriginalRowLayout(button)
  if button.PetMatchOriginalRowLayout then
    return
  end

  button.PetMatchOriginalRowLayout = {
    icon =
        SaveRegionLayout(
          GetPetIcon(button)
        ),

    familyBackground =
        SaveRegionLayout(
          GetPetFamilyBackground(button)
        ),

    levelBackground =
        SaveRegionLayout(
          GetPetLevelBackground(button)
        ),

    levelText =
        SaveRegionLayout(
          GetPetLevelText(button)
        ),
  }
end

local function RestoreRegionLayout(
    region,
    layout
)
  if not region or not layout then
    return
  end

  region:ClearAllPoints()

  if layout.width
      and layout.height then
    region:SetSize(
      layout.width,
      layout.height
    )
  end

  for _, anchor in ipairs(
    layout.anchors or {}
  ) do
    region:SetPoint(
      anchor[1],
      anchor[2],
      anchor[3],
      anchor[4],
      anchor[5]
    )
  end
end

local function RestoreNormalRow(button)
  local layout =
      button.PetMatchOriginalRowLayout

  if not layout then
    return
  end

  -- Never touch the row width. Blizzard's ScrollBox
  -- owns the horizontal size of every pet row.
  button:SetHeight(
    NORMAL_ROW_HEIGHT
  )

  local icon =
      GetPetIcon(button)

  RestoreRegionLayout(
    icon,
    layout.icon
  )

  RestoreRegionLayout(
    GetPetFamilyBackground(button),
    layout.familyBackground
  )

  RestoreRegionLayout(
    GetPetLevelBackground(button),
    layout.levelBackground
  )

  RestoreRegionLayout(
    GetPetLevelText(button),
    layout.levelText
  )

  local iconBorder =
      button.iconBorder
      or button.IconBorder

  if iconBorder and icon then
    iconBorder:ClearAllPoints()
    iconBorder:SetAllPoints(icon)
  end

  RestoreNameAnchors(button)
end

local function ApplyCompactRow(button)
  SaveOriginalRowLayout(button)

  -- Height only. Do not call SetWidth/SetSize on the row
  -- and do not re-anchor Blizzard's background textures.
  button:SetHeight(
    COMPACT_ROW_HEIGHT
  )

  local icon =
      GetPetIcon(button)

  if icon then
    icon:ClearAllPoints()

    icon:SetSize(
      COMPACT_ICON_SIZE,
      COMPACT_ICON_SIZE
    )

    icon:SetPoint(
      "LEFT",
      button,
      "LEFT",
      COMPACT_ICON_LEFT_OFFSET,
      0
    )
  end

  local iconBorder =
      button.iconBorder
      or button.IconBorder

  if iconBorder and icon then
    iconBorder:ClearAllPoints()
    iconBorder:SetAllPoints(icon)
  end

  local levelBackground =
      GetPetLevelBackground(button)

  if levelBackground and icon then
    levelBackground:ClearAllPoints()

    levelBackground:SetSize(
      COMPACT_LEVEL_SIZE,
      COMPACT_LEVEL_SIZE
    )

    levelBackground:SetPoint(
      "LEFT",
      icon,
      "RIGHT",
      COMPACT_LEVEL_OVERLAP,
      0
    )
  end

  local levelText =
      GetPetLevelText(button)

  if levelText then
    levelText:ClearAllPoints()

    if levelBackground then
      levelText:SetPoint(
        "CENTER",
        levelBackground,
        "CENTER",
        0,
        0
      )
    elseif icon then
      levelText:SetPoint(
        "LEFT",
        icon,
        "RIGHT",
        1,
        0
      )
    end
  end

  local familyBackground =
      GetPetFamilyBackground(button)

  if familyBackground then
    familyBackground:ClearAllPoints()

    familyBackground:SetSize(
      COMPACT_FAMILY_ICON_SIZE * 2,
      COMPACT_FAMILY_ICON_SIZE
    )

    familyBackground:SetPoint(
      "RIGHT",
      button,
      "RIGHT",
      -2,
      0
    )
  end
end

local function ApplyRowLayout(button)
  if not button then
    return
  end

  SaveOriginalRowLayout(button)

  if UsesCompactRows() then
    ApplyCompactRow(button)
  else
    RestoreNormalRow(button)
  end
end

local function ApplyScrollBoxRowExtent()
  local scrollBox =
      GetPetJournalScrollBox()

  if not scrollBox
      or type(scrollBox.GetView)
      ~= "function" then
    return
  end

  local view =
      scrollBox:GetView()

  if not view
      or type(view.SetElementExtent)
      ~= "function" then
    return
  end

  local rowHeight =
      UsesCompactRows()
      and COMPACT_ROW_HEIGHT
      or NORMAL_ROW_HEIGHT

  view:SetElementExtent(
    rowHeight
  )

  if type(scrollBox.FullUpdate)
      == "function" then
    local updateImmediately =
        _G.ScrollBoxConstants
        and _G.ScrollBoxConstants
        .UpdateImmediately
        or nil

    scrollBox:FullUpdate(
      updateImmediately
    )
  end
end

local function GetPetGUID(elementData)
  if type(elementData) ~= "table"
      or not elementData.index then
    return nil
  end

  local petGUID =
      C_PetJournal.GetPetInfoByIndex(
        elementData.index
      )

  return petGUID
end

local function GetOwnerPetGUID(owner)
  if not owner then
    return nil
  end

  if owner.petID then
    return owner.petID
  end

  local parent =
      owner.GetParent
      and owner:GetParent()

  if parent and parent.petID then
    return parent.petID
  end

  return nil
end

local function RefreshPetJournal()
  if type(_G.PetJournal_UpdatePetList)
      == "function" then
    _G.PetJournal_UpdatePetList()
    return
  end

  local scrollBox =
      _G.PetJournal
      and _G.PetJournal.ScrollBox

  if scrollBox
      and scrollBox.FullUpdate then
    scrollBox:FullUpdate(
      _G.ScrollBoxConstants
      and
      _G.ScrollBoxConstants.UpdateImmediately
      or nil
    )
  end
end

local function CreateBreedLabel(button)
  if button.PetMatchBreedLabel then
    return button.PetMatchBreedLabel
  end

  local label =
      button:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlightSmall"
      )

  label:SetJustifyH("RIGHT")
  label:SetWordWrap(false)
  label:SetNonSpaceWrap(false)
  label:SetMaxLines(1)
  label:SetText("")
  label:Hide()

  button.PetMatchBreedLabel =
      label

  return label
end

local function UpdateBreedLabelSize(
    breedLabel
)
  if not breedLabel then
    return
  end

  breedLabel:SetWidth(0)
  breedLabel:SetWordWrap(false)
  breedLabel:SetNonSpaceWrap(false)
  breedLabel:SetMaxLines(1)

  local width =
      math.ceil(
        breedLabel:GetUnboundedStringWidth()
        or breedLabel:GetStringWidth()
        or 0
      )

  local height =
      math.ceil(
        breedLabel:GetStringHeight()
        or 0
      )

  breedLabel:SetSize(
    math.max(width + 4, 1),
    math.max(height, 1)
  )
end

local function CreateStatusIcon(
    button,
    key,
    tooltip
)
  button.PetMatchStatusIcons =
      button.PetMatchStatusIcons or {}

  if button.PetMatchStatusIcons[key] then
    return button.PetMatchStatusIcons[key]
  end

  local frame =
      CreateFrame(
        "Frame",
        nil,
        button
      )

  frame:SetSize(
    STATUS_ICON_SIZE,
    STATUS_ICON_SIZE
  )

  frame:EnableMouse(true)

  frame.Texture =
      frame:CreateTexture(
        nil,
        "OVERLAY"
      )

  frame.Texture:SetAllPoints()
  frame.Texture:SetTexCoord(
    0.08,
    0.92,
    0.08,
    0.92
  )

  frame.TooltipText = tooltip

  frame:SetScript(
    "OnEnter",
    function(self)
      if not self.TooltipText then
        return
      end

      GameTooltip:SetOwner(
        self,
        "ANCHOR_RIGHT"
      )

      GameTooltip:SetText(
        self.TooltipText,
        1,
        1,
        1
      )

      GameTooltip:Show()
    end
  )

  frame:SetScript(
    "OnLeave",
    function()
      GameTooltip:Hide()
    end
  )

  frame:Hide()

  button.PetMatchStatusIcons[key] =
      frame

  return frame
end

local function GetTeamIcon(button)
  local icon =
      CreateStatusIcon(
        button,
        "team",
        "Used in a PetMatch team"
      )

  icon.Texture:SetTexture(
    TEAM_ICON_TEXTURE
  )

  icon.Texture:SetTexCoord(
    0.08,
    0.92,
    0.08,
    0.92
  )

  return icon
end

local function GetTagIcon(button)
  local icon =
      CreateStatusIcon(
        button,
        "tag",
        nil
      )

  icon.Texture:SetTexCoord(
    0,
    1,
    0,
    1
  )

  return icon
end

local function GetLevelingIcon(button)
  local icon =
      CreateStatusIcon(
        button,
        "leveling",
        "In the Levelling Queue"
      )

  icon.Texture:SetTexture(
    LEVELING_ICON_TEXTURE
  )

  icon.Texture:SetTexCoord(
    0,
    1,
    0,
    1
  )

  return icon
end

local function ClearStatusIcons(button)
  if not button.PetMatchStatusIcons then
    return
  end

  for _, icon in pairs(
    button.PetMatchStatusIcons
  ) do
    icon:ClearAllPoints()
    icon:Hide()
  end
end

local function ClearBreedLabel(button)
  if button.PetMatchBreedLabel then
    button.PetMatchBreedLabel:SetText("")
    button.PetMatchBreedLabel:ClearAllPoints()
    button.PetMatchBreedLabel:Hide()
  end
end

local function ClearPetMatchDisplay(button)
  ClearBreedLabel(button)
  ClearStatusIcons(button)
  RestoreNameAnchors(button)
end

local function UpdateTeamIcon(
    button,
    petGUID
)
  local icon = GetTeamIcon(button)

  local teamService =
      addon.Services
      and addon.Services.Team

  local isInTeam =
      teamService
      and type(
        teamService.IsPetInAnyTeam
      ) == "function"
      and teamService:IsPetInAnyTeam(
        petGUID
      )

  icon:SetShown(
    isInTeam == true
  )

  return isInTeam == true
      and icon
      or nil
end

local function UpdateTagIcon(
    button,
    petGUID
)
  local icon =
      GetTagIcon(button)

  local tagService =
      addon.Services
      and addon.Services.PetTag

  local definition =
      tagService
      and tagService:GetTagDefinition(
        petGUID
      )

  if not definition then
    icon.Texture:SetTexture(nil)
    icon.TooltipText = nil
    icon:Hide()

    return nil
  end

  local texture =
      GetRaidMarkerTexture(
        definition.id
      )

  if not texture then
    icon.Texture:SetTexture(nil)
    icon.TooltipText = nil
    icon:Hide()

    return nil
  end

  icon.Texture:SetTexture(
    texture
  )

  icon.Texture:SetTexCoord(
    0,
    1,
    0,
    1
  )

  icon.TooltipText =
      string.format(
        "Pet tag: %s",
        definition.name
        or "Unknown"
      )

  icon:Show()

  return icon
end

local function UpdateLevelingIcon(button, petGUID)
  local icon = GetLevelingIcon(button)
  local queueService = addon.Services and addon.Services.LevellingQueue
  local petService = addon.Services and addon.Services.PetJournal

  if not queueService or not petService or not petGUID then
    icon:Hide()
    return nil
  end

  local pet = petService:GetPet(petGUID)

  if not pet then
    icon:Hide()
    return nil
  end

  local level = tonumber(pet.level)

  local showIcon =
      level ~= nil
      and level < 25
      and queueService:Contains(
        petGUID
      )

  icon:SetShown(
    showIcon == true
  )

  return showIcon and icon or nil
end

local function GetFavoriteIcon(button)
  if not button then
    return nil
  end

  local dragButton =
      button.dragButton

  if not dragButton then
    return nil
  end

  return dragButton.favorite
      or dragButton.Favorite
      or dragButton.favoriteIcon
      or dragButton.FavoriteIcon
end

local function PositionFavoriteIcon(button)
  local favoriteIcon =
      GetFavoriteIcon(button)

  if not favoriteIcon then
    return
  end

  local icon = GetPetIcon(button)
  favoriteIcon:ClearAllPoints()

  if not icon then
    return
  end

  if not UsesCompactRows() then
    favoriteIcon:SetPoint(
      "TOPLEFT",
      icon,
      "TOPLEFT",
      -5,
      8
    )
  else
    favoriteIcon:SetPoint(
      "TOPLEFT",
      icon,
      "TOPLEFT",
      -12,
      4
    )
  end
end

local function ApplyNameRightAnchor(
    button,
    rightRegion
)
  if not button.name then
    return
  end

  SaveNameAnchors(button)

  button.name:ClearAllPoints()

  if UsesCompactRows() then
    local levelBackground =
        GetPetLevelBackground(button)

    local icon =
        GetPetIcon(button)

    local leftRegion =
        levelBackground
        or icon

    if leftRegion then
      button.name:SetPoint(
        "LEFT",
        leftRegion,
        "RIGHT",
        COMPACT_NAME_SPACING,
        0
      )
    else
      button.name:SetPoint(
        "LEFT",
        button,
        "LEFT",
        2,
        0
      )
    end

    button.name:SetPoint(
      "TOP",
      button,
      "TOP",
      0,
      0
    )

    button.name:SetPoint(
      "BOTTOM",
      button,
      "BOTTOM",
      0,
      0
    )
  else
    ------------------------------------------------
    -- Originele Blizzard-linkerpositie herstellen
    ------------------------------------------------

    local anchors =
        button.PetMatchOriginalNameAnchors

    local firstAnchor =
        anchors
        and anchors[1]

    if firstAnchor then
      button.name:SetPoint(
        firstAnchor[1],
        firstAnchor[2],
        firstAnchor[3],
        firstAnchor[4],
        firstAnchor[5]
      )
    end
  end

  --------------------------------------------------
  -- Alleen rechts begrenzen voor breed/statusiconen
  --------------------------------------------------

  if rightRegion then
    button.name:SetPoint(
      "RIGHT",
      rightRegion,
      "LEFT",
      -NAME_RIGHT_SPACING,
      0
    )
  end

  button.name:SetJustifyH("LEFT")
  button.name:SetJustifyV("MIDDLE")
end

local function LayoutRightSide(
    button,
    breedLabel,
    tagIcon,
    levelingIcon,
    teamIcon
)
  if breedLabel then
    breedLabel:ClearAllPoints()

    breedLabel:SetPoint(
      "RIGHT",
      button,
      "RIGHT",
      BREED_LABEL_RIGHT_OFFSET,
      0
    )
  end

  if tagIcon then
    tagIcon:ClearAllPoints()
  end

  if levelingIcon then
    levelingIcon:ClearAllPoints()
  end

  if teamIcon then
    teamIcon:ClearAllPoints()
  end

  local rightRegion
  local rightPoint
  local rightOffset

  if breedLabel then
    rightRegion = breedLabel
    rightPoint = "LEFT"
    rightOffset = -STATUS_BREED_SPACING
  else
    rightRegion = button
    rightPoint = "RIGHT"
    rightOffset = BREED_LABEL_RIGHT_OFFSET
  end

  if teamIcon then
    teamIcon:SetPoint(
      "RIGHT",
      rightRegion,
      rightPoint,
      rightOffset,
      0
    )

    rightRegion = teamIcon
    rightPoint = "LEFT"
    rightOffset = -STATUS_ICON_SPACING
  end

  if levelingIcon then
    levelingIcon:SetPoint(
      "RIGHT",
      rightRegion,
      rightPoint,
      rightOffset,
      0
    )

    rightRegion = levelingIcon
    rightPoint = "LEFT"
    rightOffset = -STATUS_ICON_SPACING
  end

  if tagIcon then
    tagIcon:SetPoint(
      "RIGHT",
      rightRegion,
      rightPoint,
      rightOffset,
      0
    )

    rightRegion = tagIcon
  end

  local leftMostRegion =
      tagIcon
      or levelingIcon
      or teamIcon
      or breedLabel

  ApplyNameRightAnchor(
    button,
    leftMostRegion
  )
end

local function UpdatePetNameColor(
    button,
    petGUID
)
  if not button
      or not button.name
      or not petGUID then
    return
  end

  local _, _, _, _, quality =
      C_PetJournal.GetPetStats(
        petGUID
      )

  local color =
      PET_RARITY_COLORS[quality]

  if color then
    button.name:SetTextColor(
      color.r,
      color.g,
      color.b
    )
  else
    button.name:SetTextColor(
      1,
      1,
      1
    )
  end
end

local function InstallLevellingDrag(button)
  if not button
      or button.PetMatchLevellingDragInstalled then
    return
  end

  button.PetMatchLevellingDragInstalled =
      true

  button:RegisterForDrag(
    "LeftButton"
  )

  button:HookScript(
    "OnDragStart",
    function(control)
      local petGUID =
          control.petID
          or control.petGUID

      if not petGUID then
        return
      end

      local queueService =
          addon.Services.LevellingQueue

      if not queueService then
        return
      end

      --------------------------------------------------
      -- Only allow pets that can actually
      -- enter the queue.
      --------------------------------------------------

      if queueService:Contains(
            petGUID
          ) then
        return
      end

      local allowed =
          queueService:CanAdd(
            petGUID
          )

      if not allowed then
        return
      end

      addon.UI.Components.LevellingQueueDrag:
          Start(
            petGUID,
            "petJournal"
          )
    end
  )

  button:HookScript(
    "OnDragStop",
    function()
      C_Timer.After(
        0,
        function()
          local drag = addon.UI.Components.LevellingQueueDrag

          if drag
              and drag:GetSource()
              == "petJournal" then
            drag:Clear()

            if type(ClearCursor)
                == "function" then
              ClearCursor()
            end
          end
        end
      )
    end
  )
end

local function UpdatePetButton(button, elementData)
  if not button then
    return
  end

  ApplyRowLayout(button)

  local petGUID = GetPetGUID(elementData)

  if not petGUID then
    ClearPetMatchDisplay(button)
    return
  end

  button.petGUID = petGUID
  InstallLevellingDrag(button)

  local breedLabel

  if UsesRightSideBreed() then
    local breed =
        addon.Services.Breed:
        GetJournalBreed(
          petGUID
        )

    if breed then
      breedLabel = CreateBreedLabel(button)
      breedLabel:SetText(breed)
      UpdateBreedLabelSize(breedLabel)
      breedLabel:Show()
    else
      ClearBreedLabel(button)
    end
  else
    ClearBreedLabel(button)
  end

  local teamIcon =
      UpdateTeamIcon(
        button,
        petGUID
      )

  local levelingIcon =
      UpdateLevelingIcon(
        button,
        petGUID
      )

  local tagIcon =
      UpdateTagIcon(
        button,
        petGUID
      )

  UpdatePetNameColor(
    button,
    petGUID
  )

  LayoutRightSide(
    button,
    breedLabel,
    tagIcon,
    levelingIcon,
    teamIcon
  )

  PositionFavoriteIcon(button)

  local tooltip =
      addon.UI.Components.PetTooltip

  if tooltip
      and button.dragButton then
    tooltip:Attach(
      button.dragButton,

      function()
        if button.petID then
          return "petGUID",
              button.petID
        end

        if button.speciesID then
          return "speciesID",
              button.speciesID
        end

        return nil
      end,

      "ANCHOR_RIGHT"
    )
  end
end

local function BuildTagMenuText(
    definition
)
  if type(definition) ~= "table" then
    return "Unknown"
  end

  local texture =
      GetRaidMarkerTexture(
        definition.id
      )

  local name =
      definition.name
      or "Unknown"

  if not texture then
    return name
  end

  return string.format(
    "|T%s:14:14:0:0|t %s",
    texture,
    name
  )
end

local function GetQueuePetState(petGUID)
  if not petGUID then
    return nil
  end

  local service = addon.Services and addon.Services.LevellingQueue

  if not service then
    return nil
  end

  local petService = addon.Services and addon.Services.PetJournal

  if not petService then
    return nil
  end

  local pet = petService:GetPet(petGUID)

  if not pet then
    return nil
  end

  local level =
      tonumber(
        pet.level
      )

  local canBattle = pet.canBattle == true
  local inQueue = service:Contains(petGUID)

  return {
    pet = pet,
    level = level,
    canBattle = canBattle,
    inQueue = inQueue,
    canAdd =
        canBattle
        and level ~= nil
        and level < 25
        and not inQueue,
  }
end

local function RefreshPendingBattleSlotState(slotIndex)
  RefreshPendingBattleSlotVisual(slotIndex)

  local updateButton = addon.UI.Actions.UpdateTeamButton

  if updateButton and updateButton.Refresh then
    updateButton:Refresh()
  end
end

local function GetBattleSlotIndexFromOwner(owner)
  if not owner then
    return nil
  end

  local frame = owner

  for _ = 1, 4 do
    if not frame then
      break
    end

    local name =
        frame.GetName
        and frame:GetName()

    if name then
      local slotIndex =
          name:match(
            "^PetJournalLoadoutPet([123])$"
          )

      if slotIndex then
        return tonumber(
          slotIndex
        )
      end
    end

    frame =
        frame.GetParent
        and frame:GetParent()
        or nil
  end

  return nil
end

function PetList:InstallPetContextMenu()
  if self.PetMenuInstalled then
    return true
  end

  if not Menu
      or type(Menu.ModifyMenu)
      ~= "function" then
    return false
  end

  Menu.ModifyMenu(
    "MENU_PET_COLLECTION_PET",
    function(owner, root)
      local battleSlotIndex =
          GetBattleSlotIndexFromOwner(
            owner
          )

      if battleSlotIndex then
        root:CreateDivider()

        local slotMenu =
            root:CreateButton(
              "Set Pet Slot As"
            )

        slotMenu:CreateButton(
          "Use Current Pet",

          function()
            addon.Services.BattleSlot:
                SetPendingNormalSlot(
                  battleSlotIndex
                )

            RefreshPendingBattleSlotState(
              battleSlotIndex
            )
          end
        )

        slotMenu:CreateDivider()

        local randomMenu =
            slotMenu:CreateButton(
              "Random Pet"
            )

        randomMenu:CreateButton(
          "Any Pet",
          function()
            local success =
                addon.Services.BattleSlot:
                SetPendingSpecialSlot(
                  battleSlotIndex,
                  BuildRandomSpecialSlot(
                    0
                  )
                )

            if success then
              RefreshPendingBattleSlotState(
                battleSlotIndex
              )
            end
          end
        )

        local families = {
          { "Humanoid",   1 },
          { "Dragonkin",  2 },
          { "Flying",     3 },
          { "Undead",     4 },
          { "Critter",    5 },
          { "Magic",      6 },
          { "Elemental",  7 },
          { "Beast",      8 },
          { "Aquatic",    9 },
          { "Mechanical", 10 },
        }

        for _, family in ipairs(
          families
        ) do
          local name =
              family[1]

          local petType =
              family[2]

          randomMenu:CreateButton(
            name,
            function()
              local success =
                  addon.Services.BattleSlot:
                  SetPendingSpecialSlot(
                    battleSlotIndex,
                    BuildRandomSpecialSlot(
                      petType
                    )
                  )

              if success then
                RefreshPendingBattleSlotState(
                  battleSlotIndex
                )
              end
            end
          )
        end

        slotMenu:CreateButton(
          "Levelling Pet",
          function()
            local success =
                addon.Services.BattleSlot:
                SetPendingSpecialSlot(
                  battleSlotIndex,
                  BuildLevelingSpecialSlot()
                )

            if success then
              RefreshPendingBattleSlotState(
                battleSlotIndex
              )
            end
          end
        )
      end

      local petGUID =
          GetOwnerPetGUID(
            owner
          )
      if not petGUID then
        return
      end

      --------------------------------------------------
      -- Pet Tag
      --------------------------------------------------
      local tagService = addon.Services.PetTag

      if tagService then
        local submenu = root:CreateButton("Pet Tag")

        for _, definition in ipairs(
          tagService:GetDefinitions()
        ) do
          local tagID = definition.id

          submenu:CreateRadio(
            BuildTagMenuText(definition),

            function(id)
              return tagService:
              HasTag(petGUID, id)
            end,

            function(id)
              tagService:SetTag(petGUID, id)
              RefreshPetJournal()
              RefreshAllBattleSlotTagVisuals()
            end,

            tagID
          )
        end

        local currentTag = tagService:GetTag(petGUID)

        if currentTag then
          submenu:CreateDivider()
          submenu:CreateButton(
            "Remove Tag",
            function()
              tagService:ClearTag(petGUID)
              RefreshPetJournal()
              RefreshAllBattleSlotTagVisuals()
            end
          )
        end
      end

      --------------------------------------------------
      -- Levelling Queue
      --------------------------------------------------
      local queueService = addon.Services.LevellingQueue

      if not queueService then
        return
      end

      local state = GetQueuePetState(petGUID)

      if not state then
        return
      end

      --------------------------------------------------
      -- Already in queue
      --------------------------------------------------
      if state.inQueue then
        local queueMenu = root:CreateButton("Levelling Queue")
        local index = queueService:GetIndex(petGUID)
        local count = queueService:GetCount()

        --------------------------------------------------
        -- Move Up
        --------------------------------------------------
        local moveUp =
            queueMenu:CreateButton(
              "Move Up",
              function()
                queueService:MoveUp(petGUID)
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
            queueMenu:CreateButton(
              "Move Down",
              function()
                queueService:
                    MoveDown(
                      petGUID
                    )
              end
            )
        moveDown:SetEnabled(
          index ~= nil
          and index < count
        )

        queueMenu:CreateDivider()

        --------------------------------------------------
        -- Remove
        --------------------------------------------------
        queueMenu:CreateButton(
          "Remove from Levelling Queue",
          function()
            queueService:Remove(petGUID)
            RefreshPetJournal()
          end
        )
        return
      end

      --------------------------------------------------
      -- Not in queue
      --------------------------------------------------
      if state.canAdd then
        root:CreateButton(
          "Add to Levelling Queue",

          function()
            local success, errorMessage = queueService:Add(petGUID)
            if not success then
              addon.Logger:Warn(
                errorMessage
                or "Unable to add pet to the levelling queue."
              )
              return
            end
            RefreshPetJournal()
          end
        )
      end
    end
  )

  self.PetMenuInstalled = true

  return true
end

function PetList:InstallHook()
  if self.Hooked then
    return true
  end

  if type(_G.PetJournal_InitPetButton)
      ~= "function" then
    return false
  end

  hooksecurefunc(
    "PetJournal_InitPetButton",

    function(button, elementData)
      UpdatePetButton(
        button,
        elementData
      )
    end
  )

  self.Hooked = true

  return true
end

function PetList:ApplyBreedDisplay()
  local showBreed =
      IsBreedVisible()

  local position =
      GetBreedPosition()

  local letBattlePetBreedIDShowName =
      showBreed
      and position == "afterName"

  addon.Services.Breed:
      SetJournalNameDisplayEnabled(
        letBattlePetBreedIDShowName
      )

  RefreshPetJournal()
end

function PetList:ApplyPetListLayout()
  ApplyScrollBoxRowExtent()
  RefreshPetJournal()
end

function PetList:Refresh()
  RefreshPetJournal()
end

function PetList:OnAddonLoaded(name)
  if name == "Blizzard_Collections" then
    self:InstallHook()
    self:InstallPetContextMenu()
    self:ApplyPetListLayout()
    self:ApplyBreedDisplay()
    return
  end

  if name == "BattlePetBreedID" then
    addon.Services.Breed:
        ClearCache()

    self:ApplyBreedDisplay()
  end
end

function PetList:OnSettingChanged(key)
  if key == "compactPetListRows" then
    self:ApplyPetListLayout()
    return
  end

  if key ~= "showPetListBreed"
      and key ~= "petListBreedPosition" then
    return
  end

  self:ApplyBreedDisplay()
end

function PetList:RegisterRefreshEvent(eventName)
  if not eventName then
    return
  end

  addon.EventBus:Register(
    eventName,

    function()
      RefreshPetJournal()
    end
  )
end

function PetList:Initialize()
  addon.EventBus:Register(
    addon.Events.SETTINGS_CHANGED,

    function(key)
      self:OnSettingChanged(key)
    end
  )

  addon.EventBus:Register(
    addon.Events.PET_JOURNAL_UPDATED,

    function()
      addon.Services.Breed:ClearCache()
      RefreshPetJournal()
      RefreshAllBattleSlotTagVisuals()
    end
  )

  addon.EventBus:Register(
    addon.Events.TEAM_LOADED,

    function()
      RefreshAllPendingBattleSlotVisuals()
      RefreshAllBattleSlotTagVisuals()
    end
  )

  self:RegisterRefreshEvent(
    addon.Events.TEAM_LOADED
  )

  self:RegisterRefreshEvent(
    addon.Events.TEAM_UPDATED
  )

  self:RegisterRefreshEvent(
    addon.Events.TEAM_DELETED
  )

  self:RegisterRefreshEvent(
    addon.Events.PET_ADDED_TO_TEAM
  )

  self:RegisterRefreshEvent(
    addon.Events.LEVELLING_QUEUE_CHANGED
  )

  self.LoaderFrame =
      CreateFrame("Frame")

  self.LoaderFrame:RegisterEvent(
    "ADDON_LOADED"
  )

  self.LoaderFrame:SetScript(
    "OnEvent",

    function(_, _, name)
      self:OnAddonLoaded(name)
    end
  )
end

function PetList:Enable()
  self:InstallHook()
  self:InstallPetContextMenu()
  self:ApplyPetListLayout()
  self:ApplyBreedDisplay()
end

addon.ModuleManager:Register(
  "PetList",
  PetList
)
