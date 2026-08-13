local _, addon = ...

local Header = {}
Header.__index = Header

local HEADER_HEIGHT = 56

local PET_ICON_SIZE = 48
local FAMILY_ICON_SIZE = 40
local ICON_BORDER_PADDING = 4

-- local CIRCLE_MASK = "Interface\\Common\\RingBorder"
local CIRCLE_MASK = "Interface\\CHARACTERFRAME\\TempPortraitAlphaMask"

local PET_RARITY_COLORS = {
  [1] = ITEM_QUALITY_COLORS[0],
  [2] = ITEM_QUALITY_COLORS[1],
  [3] = ITEM_QUALITY_COLORS[2],
  [4] = ITEM_QUALITY_COLORS[3],
  [5] = ITEM_QUALITY_COLORS[4],
  [6] = ITEM_QUALITY_COLORS[5],
}

local PET_FAMILY_ICONS = {
  [1] = "Interface\\Icons\\Pet_Type_Humanoid",
  [2] = "Interface\\Icons\\Pet_Type_Dragon",
  [3] = "Interface\\Icons\\Pet_Type_Flying",
  [4] = "Interface\\Icons\\Pet_Type_Undead",
  [5] = "Interface\\Icons\\Pet_Type_Critter",
  [6] = "Interface\\Icons\\Pet_Type_Magical",
  [7] = "Interface\\Icons\\Pet_Type_Elemental",
  [8] = "Interface\\Icons\\Pet_Type_Beast",
  [9] = "Interface\\Icons\\Pet_Type_Water",
  [10] = "Interface\\Icons\\Pet_Type_Mechanical",
}

--------------------------------------------------
-- Helpers
--------------------------------------------------
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

local function GetPetFamilyName(petType)
  petType = tonumber(petType)

  if not petType then
    return nil
  end

  return _G[
  "BATTLE_PET_NAME_" .. petType
  ]
end

--------------------------------------------------
-- Circular icon
--------------------------------------------------
local function CreateCircularIcon(parent, iconSize)
  local frame =
      CreateFrame(
        "Frame",
        nil,
        parent
      )

  frame:SetSize(
    iconSize + ICON_BORDER_PADDING,
    iconSize + ICON_BORDER_PADDING
  )

  --------------------------------------------------
  -- Quality border
  --------------------------------------------------

  frame.Border =
      frame:CreateTexture(
        nil,
        "BACKGROUND"
      )

  frame.Border:SetAllPoints()

  frame.Border:SetColorTexture(
    1,
    1,
    1,
    1
  )

  frame.BorderMask =
      frame:CreateMaskTexture()

  frame.BorderMask:SetTexture(
    CIRCLE_MASK,
    "CLAMPTOBLACKADDITIVE",
    "CLAMPTOBLACKADDITIVE"
  )

  frame.BorderMask:SetAllPoints(
    frame.Border
  )

  frame.Border:AddMaskTexture(
    frame.BorderMask
  )

  --------------------------------------------------
  -- Pet icon
  --------------------------------------------------

  frame.Icon =
      frame:CreateTexture(
        nil,
        "ARTWORK"
      )

  frame.Icon:SetSize(
    iconSize,
    iconSize
  )

  frame.Icon:SetPoint(
    "CENTER"
  )

  frame.Icon:SetTexCoord(
    0.08,
    0.92,
    0.08,
    0.92
  )

  --------------------------------------------------
  -- Circular icon mask
  --------------------------------------------------

  frame.IconMask =
      frame:CreateMaskTexture()

  frame.IconMask:SetTexture(
    CIRCLE_MASK,
    "CLAMPTOBLACKADDITIVE",
    "CLAMPTOBLACKADDITIVE"
  )

  frame.IconMask:SetAllPoints(
    frame.Icon
  )

  frame.Icon:AddMaskTexture(
    frame.IconMask
  )

  return frame
end

local function ShowPetFamilyTooltip(
    owner,
    abilityID,
    speciesID,
    petID
)
  abilityID =
      tonumber(
        abilityID
      )

  if not abilityID then
    return
  end

  if type(
        _G.PetJournal_ShowAbilityTooltip
      ) ~= "function" then
    return
  end

  --------------------------------------------------
  -- Use Blizzard's own tooltip
  --------------------------------------------------

  _G.PetJournal_ShowAbilityTooltip(
    owner,
    abilityID,
    speciesID,
    petID
  )

  local tooltip =
      _G.PetJournalPrimaryAbilityTooltip

  if not tooltip then
    return
  end

  --------------------------------------------------
  -- Keep tooltip above Pet Card
  --------------------------------------------------

  tooltip:SetFrameStrata(
    "TOOLTIP"
  )

  local cardFrame =
      owner:GetParent()

  while cardFrame
    and cardFrame:GetParent() do
    if cardFrame:GetWidth() == 360 then
      break
    end

    cardFrame =
        cardFrame:GetParent()
  end

  local minimumLevel = 200

  if cardFrame then
    minimumLevel =
        math.max(
          minimumLevel,
          cardFrame:GetFrameLevel() + 50
        )
  end

  tooltip:SetFrameLevel(
    minimumLevel
  )

  --------------------------------------------------
  -- Ownership
  --------------------------------------------------

  tooltip.anchoredTo =
      owner

  tooltip:Show()
end

local function HidePetFamilyTooltip(owner)
  local tooltip =
      _G.PetJournalPrimaryAbilityTooltip

  if not tooltip then
    return
  end

  if tooltip.anchoredTo
      and tooltip.anchoredTo ~= owner then
    return
  end

  tooltip:Hide()
  tooltip.anchoredTo = nil
end

local function CreateFamilyIcon(parent, iconSize)
  local borderWidth = 2
  local frameSize = iconSize + (borderWidth * 2)

  local frame =
      CreateFrame(
        "Frame",
        nil,
        parent
      )

  frame:SetSize(
    frameSize,
    frameSize
  )

  --------------------------------------------------
  -- Gold circular border
  --------------------------------------------------

  frame.Border =
      frame:CreateTexture(
        nil,
        "BACKGROUND"
      )

  frame.Border:SetAllPoints()

  frame.Border:SetColorTexture(
    0.75,
    0.55,
    0.20,
    1
  )

  frame.BorderMask =
      frame:CreateMaskTexture()

  frame.BorderMask:SetTexture(
    CIRCLE_MASK,
    "CLAMPTOBLACKADDITIVE",
    "CLAMPTOBLACKADDITIVE"
  )

  frame.BorderMask:SetAllPoints(
    frame.Border
  )

  frame.Border:AddMaskTexture(
    frame.BorderMask
  )

  --------------------------------------------------
  -- Black inner circle
  --------------------------------------------------
  frame.Background =
      frame:CreateTexture(
        nil,
        "BORDER"
      )

  frame.Background:SetSize(
    iconSize,
    iconSize
  )

  frame.Background:SetPoint(
    "CENTER"
  )

  frame.Background:SetColorTexture(
    0.03,
    0.03,
    0.03,
    0.88
  )

  frame.BackgroundMask =
      frame:CreateMaskTexture()

  frame.BackgroundMask:SetTexture(
    CIRCLE_MASK,
    "CLAMPTOBLACKADDITIVE",
    "CLAMPTOBLACKADDITIVE"
  )

  frame.BackgroundMask:SetAllPoints(
    frame.Background
  )

  frame.Background:AddMaskTexture(
    frame.BackgroundMask
  )

  --------------------------------------------------
  -- Family icon
  --------------------------------------------------

  frame.Icon =
      frame:CreateTexture(
        nil,
        "ARTWORK"
      )

  frame.Icon:SetSize(
    iconSize - 4,
    iconSize - 4
  )

  frame.Icon:SetPoint(
    "CENTER"
  )

  return frame
end

--------------------------------------------------
-- Create
--------------------------------------------------
function Header:Create(parent)
  local instance =
      setmetatable(
        {},
        Header
      )

  instance.Frame =
      CreateFrame(
        "Frame",
        nil,
        parent
      )

  instance.Frame:SetHeight(
    HEADER_HEIGHT
  )

  --------------------------------------------------
  -- Pet icon
  --------------------------------------------------
  instance.PetIcon =
      CreateCircularIcon(
        instance.Frame,
        PET_ICON_SIZE
      )

  instance.PetIcon:SetPoint(
    "LEFT",
    instance.Frame,
    "LEFT",
    0,
    -5
  )

  --------------------------------------------------
  -- Family icon
  --------------------------------------------------
  instance.FamilyIcon =
      CreateFamilyIcon(
        instance.Frame,
        FAMILY_ICON_SIZE
      )

  instance.FamilyIcon:SetPoint(
    "RIGHT",
    instance.Frame,
    "RIGHT",
    0,
    -5
  )

  --------------------------------------------------
  -- Pet family tooltip
  --------------------------------------------------
  instance.FamilyIcon:SetScript(
    "OnEnter",
    function(control)
      if not instance.Interactive then
        return
      end

      if not instance.PassiveAbilityID then
        return
      end

      ShowPetFamilyTooltip(
        control,
        instance.PassiveAbilityID,
        instance.SpeciesID,
        instance.PetID
      )
    end
  )

  instance.FamilyIcon:SetScript(
    "OnLeave",
    function(control)
      HidePetFamilyTooltip(
        control
      )
    end
  )

  instance.FamilyIcon:EnableMouse(false)

  --------------------------------------------------
  -- Pet name
  --------------------------------------------------
  instance.Name =
      instance.Frame:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlightLarge"
      )

  instance.Name:SetPoint(
    "CENTER",
    instance.Frame,
    "CENTER",
    0,
    0
  )

  instance.Name:SetPoint(
    "LEFT",
    instance.PetIcon,
    "RIGHT",
    10,
    0
  )

  instance.Name:SetPoint(
    "RIGHT",
    instance.FamilyIcon,
    "LEFT",
    -10,
    0
  )

  instance.Name:SetJustifyH(
    "CENTER"
  )

  instance.Name:SetJustifyV(
    "MIDDLE"
  )

  instance.Name:SetWordWrap(
    true
  )

  instance.Name:SetNonSpaceWrap(
    false
  )

  instance.Interactive = false

  return instance
end

--------------------------------------------------
-- Pet
--------------------------------------------------
function Header:SetPet(pet)
  self.PetType =
      tonumber(
        pet.petType
      )

  self.SpeciesID =
      tonumber(
        pet.speciesID
      )

  self.PetID =
      pet.petGUID
      or pet.petID

  self.PassiveAbilityID =
      PET_BATTLE_PET_TYPE_PASSIVES
      and PET_BATTLE_PET_TYPE_PASSIVES[
      self.PetType
      ]

  --------------------------------------------------
  -- Quality
  --------------------------------------------------
  local r, g, b

  if pet.quality ~= nil then
    r, g, b =
        GetQualityColor(
          pet.quality
        )
  else
    r, g, b =
        0.82,
        0.82,
        0.82
  end

  --------------------------------------------------
  -- Pet icon
  --------------------------------------------------

  self.PetIcon.Icon:SetTexture(
    pet.icon
  )

  self.PetIcon.Border:SetVertexColor(
    r,
    g,
    b,
    1
  )

  --------------------------------------------------
  -- Name
  --------------------------------------------------

  self.Name:SetText(
    pet.name
    or "Unknown"
  )

  self.Name:SetTextColor(
    r,
    g,
    b,
    1
  )

  --------------------------------------------------
  -- Family icon
  --------------------------------------------------

  local familyIcon =
      PET_FAMILY_ICONS[
      self.PetType
      ]

  if familyIcon then
    self.FamilyIcon.Icon:SetTexture(
      familyIcon
    )

    self.FamilyIcon:Show()
  else
    self.FamilyIcon.Icon:SetTexture(
      nil
    )

    self.FamilyIcon:Hide()
  end
end

--------------------------------------------------
-- Interaction
--------------------------------------------------
function Header:SetInteractive(interactive)
  self.Interactive =
      interactive == true

  self.FamilyIcon:EnableMouse(
    self.Interactive
  )

  if not self.Interactive
      and GameTooltip:IsOwned(
        self.FamilyIcon
      ) then
    GameTooltip:Hide()
  end
end

--------------------------------------------------
-- Accessors
--------------------------------------------------
function Header:GetFrame()
  return self.Frame
end

addon.UI.PetCard.Header = Header
