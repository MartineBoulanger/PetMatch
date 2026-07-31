local _, addon = ...

local BreedSection = {}
BreedSection.__index = BreedSection

local TITLE_HEIGHT = 18
local BREED_TOP_SPACING = 9
local HELP_TOP_SPACING = 8
local BOTTOM_PADDING = 4

local PET_RARITY_COLORS = {
  [1] = ITEM_QUALITY_COLORS[0],
  [2] = ITEM_QUALITY_COLORS[1],
  [3] = ITEM_QUALITY_COLORS[2],
  [4] = ITEM_QUALITY_COLORS[3],
  [5] = ITEM_QUALITY_COLORS[4],
  [6] = ITEM_QUALITY_COLORS[5]
}

local function GetQualityHex(
    quality
)
  quality = tonumber(quality) or 0

  local color =
      PET_RARITY_COLORS
      and PET_RARITY_COLORS[quality]

  if not color then
    return "ffffffff"
  end

  if color.hex then
    return string.gsub(
      color.hex,
      "^|c",
      ""
    )
  end

  return string.format(
    "ff%02x%02x%02x",
    math.floor((color.r or 1) * 255),
    math.floor((color.g or 1) * 255),
    math.floor((color.b or 1) * 255)
  )
end

function BreedSection:Create(parent)
  local instance =
      setmetatable(
        {},
        BreedSection
      )

  instance.Frame =
      CreateFrame(
        "Frame",
        nil,
        parent
      )

  instance.Frame:SetHeight(1)

  instance.Title =
      instance.Frame:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlight"
      )

  instance.Title:SetPoint(
    "TOPLEFT",
    instance.Frame,
    "TOPLEFT",
    0,
    0
  )

  instance.Title:SetText(
    "Possible Breeds"
  )

  instance.Divider =
      instance.Frame:CreateTexture(
        nil,
        "ARTWORK"
      )

  instance.Divider:SetHeight(1)

  instance.Divider:SetPoint(
    "TOPLEFT",
    instance.Title,
    "BOTTOMLEFT",
    0,
    -4
  )

  instance.Divider:SetPoint(
    "RIGHT",
    instance.Frame,
    "RIGHT",
    0,
    0
  )

  instance.Divider:SetColorTexture(
    0.45,
    0.37,
    0.18,
    0.8
  )

  instance.Breeds =
      instance.Frame:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontNormal"
      )

  instance.Breeds:SetPoint(
    "TOPLEFT",
    instance.Divider,
    "BOTTOMLEFT",
    0,
    -BREED_TOP_SPACING
  )

  instance.Breeds:SetPoint(
    "RIGHT",
    instance.Frame,
    "RIGHT",
    0,
    0
  )

  instance.Breeds:SetJustifyH("LEFT")
  instance.Breeds:SetWordWrap(true)

  instance.HelpText =
      instance.Frame:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontDisableSmall"
      )

  instance.HelpText:SetPoint(
    "TOPLEFT",
    instance.Breeds,
    "BOTTOMLEFT",
    0,
    -HELP_TOP_SPACING
  )

  instance.HelpText:SetPoint(
    "RIGHT",
    instance.Frame,
    "RIGHT",
    0,
    0
  )

  instance.HelpText:SetJustifyH("LEFT")
  instance.HelpText:SetJustifyV("TOP")
  instance.HelpText:SetWordWrap(true)

  instance.HelpText:SetText(
    "Select this pet and hover its icon or name to view detailed breed and base-stat information -- when you have BattlePetBreedID installed."
  )

  return instance
end

function BreedSection:SetPet(pet)
  local breedService =
      addon.Services.Breed

  if not breedService
      or not pet
      or not pet.speciesID then
    self.Frame:Hide()
    return false
  end

  local possibleBreeds =
      breedService:GetPossibleBreeds(
        pet.speciesID
      )

  if type(possibleBreeds) ~= "table"
      or #possibleBreeds == 0 then
    self.Breeds:SetText("")
    self.Frame:Hide()

    return false
  end

  local currentBreed =
      pet.breedName

  if not currentBreed
      and pet.breedID then
    currentBreed =
        breedService:GetBreedName(
          pet.breedID
        )
  end

  local qualityHex =
      GetQualityHex(
        pet.quality
      )

  local labels = {}

  for _, breed in ipairs(
    possibleBreeds
  ) do
    local label = breed.name

    if currentBreed
        and breed.name == currentBreed then
      label =
          "|c"
          .. qualityHex
          .. label
          .. "|r"
    end

    labels[#labels + 1] = label
  end

  self.Breeds:SetText(
    table.concat(
      labels,
      "   "
    )
  )

  self.Frame:Show()
  self:UpdateHeight()

  return true
end

function BreedSection:UpdateHeight()
  if not self.Frame:IsShown() then
    return
  end

  local width =
      self.Frame:GetWidth()

  if width and width > 0 then
    self.Breeds:SetWidth(width)
    self.HelpText:SetWidth(width)
  end

  local breedHeight =
      math.ceil(
        self.Breeds:GetStringHeight()
        or 0
      )

  local helpHeight =
      math.ceil(
        self.HelpText:GetStringHeight()
        or 0
      )

  local height =
      TITLE_HEIGHT
      + 5
      + BREED_TOP_SPACING
      + breedHeight
      + HELP_TOP_SPACING
      + helpHeight
      + BOTTOM_PADDING

  self.Frame:SetHeight(
    math.max(
      1,
      height
    )
  )
end

function BreedSection:GetFrame()
  return self.Frame
end

addon.UI.PetCard.BreedSection = BreedSection
