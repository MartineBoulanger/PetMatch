local _, addon = ...

local Header = {}
Header.__index = Header

local HEADER_HEIGHT = 60
local PET_ICON_SIZE = 48
local FAMILY_ICON_SIZE = 18

local PET_RARITY_COLORS = {
  [1] = ITEM_QUALITY_COLORS[0],
  [2] = ITEM_QUALITY_COLORS[1],
  [3] = ITEM_QUALITY_COLORS[2],
  [4] = ITEM_QUALITY_COLORS[3],
  [5] = ITEM_QUALITY_COLORS[4],
  [6] = ITEM_QUALITY_COLORS[5]
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

local PET_TYPE_SUFFIX = {
  [1]  = "Humanoid",
  [2]  = "Dragonkin",
  [3]  = "Flying",
  [4]  = "Undead",
  [5]  = "Critter",
  [6]  = "Magic",
  [7]  = "Elemental",
  [8]  = "Beast",
  [9]  = "Aquatic",
  [10] = "Mechanical"
}

local function GetPetTypeName(petType)
  petType = tonumber(petType)

  if not petType then
    return nil
  end

  if PET_TYPE_SUFFIX then
    return PET_TYPE_SUFFIX[petType]
  end

  return nil
end

local function GetQualityColor(quality)
  quality = tonumber(quality) or 0

  local color =
      PET_RARITY_COLORS
      and PET_RARITY_COLORS[quality]

  if not color then
    return 1, 1, 1
  end

  return color.r or 1,
      color.g or 1,
      color.b or 1
end

local function BuildSubtitle(pet)
  local petTypeName =
      pet.petTypeName
      or GetPetTypeName(
        pet.petType
      )

  local expansionName =
      pet.expansionName

  if petTypeName
      and expansionName then
    return petTypeName
        .. " • "
        .. expansionName
  end

  return petTypeName
      or expansionName
      or ""
end

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

  instance.IconBorder =
      CreateFrame(
        "Frame",
        nil,
        instance.Frame,
        "BackdropTemplate"
      )

  instance.IconBorder:SetSize(
    PET_ICON_SIZE + 6,
    PET_ICON_SIZE + 6
  )

  instance.IconBorder:SetPoint(
    "TOPLEFT",
    instance.Frame,
    "TOPLEFT",
    0,
    0
  )

  instance.IconBorder:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 12,
  })

  instance.IconBorder:SetBackdropColor(
    0.03,
    0.03,
    0.03,
    0.9
  )

  instance.Icon = instance.IconBorder:CreateTexture(nil, "ARTWORK")
  instance.Icon:SetSize(PET_ICON_SIZE, PET_ICON_SIZE)
  instance.Icon:SetPoint("CENTER")
  instance.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

  instance.Name =
      instance.Frame:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlightLarge"
      )

  instance.Name:SetPoint(
    "TOPLEFT",
    instance.IconBorder,
    "TOPRIGHT",
    12,
    -2
  )

  instance.Name:SetPoint(
    "RIGHT",
    instance.Frame,
    "RIGHT",
    -65,
    0
  )

  instance.Name:SetJustifyH("LEFT")
  instance.Name:SetWordWrap(false)

  instance.FamilyIcon =
      instance.Frame:CreateTexture(
        nil,
        "ARTWORK"
      )

  instance.FamilyIcon:SetSize(
    FAMILY_ICON_SIZE,
    FAMILY_ICON_SIZE
  )

  instance.FamilyIcon:SetPoint(
    "TOPLEFT",
    instance.Name,
    "BOTTOMLEFT",
    0,
    -6
  )

  instance.Subtitle =
      instance.Frame:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontNormal"
      )

  instance.Subtitle:SetPoint(
    "LEFT",
    instance.FamilyIcon,
    "RIGHT",
    5,
    0
  )

  instance.Subtitle:SetPoint(
    "RIGHT",
    instance.Frame,
    "RIGHT",
    -30,
    0
  )

  instance.Subtitle:SetJustifyH("LEFT")
  instance.Subtitle:SetWordWrap(false)

  instance.Level =
      instance.Frame:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlight"
      )

  instance.Level:SetPoint(
    "TOPRIGHT",
    instance.Frame,
    "TOPRIGHT",
    0,
    -2
  )

  instance.Breed =
      instance.Frame:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontNormal"
      )

  instance.Breed:SetPoint(
    "TOPRIGHT",
    instance.Level,
    "BOTTOMRIGHT",
    0,
    -8
  )

  return instance
end

function Header:SetPet(pet)
  self.Icon:SetTexture(
    pet.icon
  )

  self.Name:SetText(
    pet.name or "Unknown"
  )

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

  self.Name:SetTextColor(
    r,
    g,
    b,
    1
  )

  self.Breed:SetTextColor(
    r,
    g,
    b,
    1
  )

  self.Level:SetTextColor(
    r,
    g,
    b,
    1
  )

  self.IconBorder:SetBackdropBorderColor(
    r,
    g,
    b,
    1
  )

  if pet.level and pet.level > 0 then
    self.Level:SetFormattedText(
      "Level %d",
      pet.level
    )
  else
    self.Level:SetText(
      "Not Collected"
    )
  end

  local breed =
      pet.breedName
      or pet.breedID

  if breed then
    self.Breed:SetFormattedText(
      "%s",
      tostring(breed)
    )

    self.Breed:Show()
  else
    self.Breed:SetText("")
    self.Breed:Hide()
  end

  local familyIcon =
      PET_FAMILY_ICONS[
      tonumber(pet.petType)
      ]

  if familyIcon then
    self.FamilyIcon:SetTexture(
      familyIcon
    )

    self.FamilyIcon:Show()
  else
    self.FamilyIcon:SetTexture(nil)
    self.FamilyIcon:Hide()
  end

  self.Subtitle:SetText(
    BuildSubtitle(pet)
  )
end

function Header:GetFrame()
  return self.Frame
end

addon.UI.PetCard.Header = Header
