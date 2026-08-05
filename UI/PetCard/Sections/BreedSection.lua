local _, addon = ...

local BreedSection = {}
BreedSection.__index = BreedSection

local TITLE_HEIGHT = 18
local BREED_TOP_SPACING = 9
local HELP_TOP_SPACING = 8
local BOTTOM_PADDING = 4

local BREED_TOOLTIP_OFFSET_X = 8
local BREED_TOOLTIP_OFFSET_Y = -8

local PET_RARITY_COLORS = {
  [1] = ITEM_QUALITY_COLORS[0],
  [2] = ITEM_QUALITY_COLORS[1],
  [3] = ITEM_QUALITY_COLORS[2],
  [4] = ITEM_QUALITY_COLORS[3],
  [5] = ITEM_QUALITY_COLORS[4],
  [6] = ITEM_QUALITY_COLORS[5]
}

local function GetQualityHex(quality)
  quality =
      tonumber(quality)
      or 0

  local color =
      PET_RARITY_COLORS[
      quality
      ]

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
    math.floor(
      (color.r or 1) * 255
    ),
    math.floor(
      (color.g or 1) * 255
    ),
    math.floor(
      (color.b or 1) * 255
    )
  )
end

local function IsBattlePetBreedIDLoaded()
  if C_AddOns
      and type(C_AddOns.IsAddOnLoaded)
      == "function" then
    return C_AddOns.IsAddOnLoaded(
      "BattlePetBreedID"
    )
  end

  if type(IsAddOnLoaded)
      == "function" then
    return IsAddOnLoaded(
      "BattlePetBreedID"
    )
  end

  return false
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

  -- parent is PetCard.Content.
  instance.CardFrame =
      parent
      and parent:GetParent()
      or nil

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
    "Hover the possible breeds to view detailed breed and base-stat information."
  )

  instance.HoverFrame =
      CreateFrame(
        "Frame",
        nil,
        instance.Frame
      )

  instance.HoverFrame:SetFrameLevel(
    instance.Frame:GetFrameLevel() + 10
  )

  instance.HoverFrame:EnableMouse(true)

  instance.HoverFrame:SetScript(
    "OnEnter",

    function()
      instance:ShowBreedTooltip()
    end
  )

  instance.HoverFrame:SetScript(
    "OnLeave",

    function()
      instance:HideBreedTooltip()
    end
  )

  instance.HoverFrame:Hide()

  return instance
end

function BreedSection:SetPet(pet)
  local breedService =
      addon.Services.Breed

  if not breedService
      or not pet
      or not pet.speciesID then
    self.Pet = nil
    self.HoverFrame:Hide()
    self.Frame:Hide()

    return false
  end

  local possibleBreeds =
      breedService:GetPossibleBreeds(
        pet.speciesID
      )

  if type(possibleBreeds) ~= "table"
      or #possibleBreeds == 0 then
    self.Pet = nil
    self.Breeds:SetText("")
    self.HoverFrame:Hide()
    self.Frame:Hide()

    return false
  end

  self.Pet = pet

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
    local label =
        breed.name

    if currentBreed
        and breed.name
        == currentBreed then
      label =
          "|c"
          .. qualityHex
          .. label
          .. "|r"
    end

    labels[#labels + 1] =
        label
  end

  self.Breeds:SetText(
    table.concat(
      labels,
      "   "
    )
  )

  if IsBattlePetBreedIDLoaded() then
    self.HelpText:SetText(
      "Hover the possible breeds to view detailed breed and base-stat information."
    )
  else
    self.HelpText:SetText(
      "Install BattlePetBreedID to view detailed breed and base-stat information."
    )
  end

  self.Frame:Show()
  self:UpdateHeight()

  return true
end

function BreedSection:PositionTooltip()
  local tooltip =
      GameTooltip

  local cardFrame =
      self.CardFrame

  if not tooltip
      or not cardFrame then
    return
  end

  tooltip:ClearAllPoints()

  tooltip:SetPoint(
    "TOPLEFT",
    cardFrame,
    "TOPRIGHT",
    BREED_TOOLTIP_OFFSET_X,
    BREED_TOOLTIP_OFFSET_Y
  )

  tooltip:SetClampedToScreen(true)
end

function BreedSection:ShowBreedTooltip()
  local pet =
      self.Pet

  if not pet then
    return
  end

  local petGUID =
      pet.petGUID
      or pet.petID
      or pet.guid

  if type(petGUID) ~= "string"
      or petGUID == "" then
    return
  end

  local battlePetBreedIDLoaded =
      IsBattlePetBreedIDLoaded()

  --------------------------------------------------
  -- BattlePetBreedID hooks Blizzard's PetInfo frame.
  -- Running that frame's OnEnter causes Blizzard's
  -- normal pet tooltip and BPBID's extra breed lines
  -- to be built together.
  --------------------------------------------------

  local blizzardPetInfo =
      _G.PetJournalPetCardPetInfo
      or (
        _G.PetJournalPetCard
        and _G.PetJournalPetCard.PetInfo
      )

  local blizzardPetCard =
      _G.PetJournalPetCard

  if battlePetBreedIDLoaded
      and blizzardPetInfo
      and blizzardPetCard
      and type(blizzardPetInfo.RunScript)
      == "function" then
    local previousPetID =
        blizzardPetCard.petID

    local previousSpeciesID =
        blizzardPetCard.speciesID

    blizzardPetCard.petID =
        petGUID

    blizzardPetCard.speciesID =
        pet.speciesID

    blizzardPetInfo:RunScript(
      "OnEnter"
    )

    blizzardPetCard.petID =
        previousPetID

    blizzardPetCard.speciesID =
        previousSpeciesID

    self:PositionTooltip()
    GameTooltip:Show()

    return
  end

  --------------------------------------------------
  -- Fallback without BattlePetBreedID.
  --------------------------------------------------

  GameTooltip:SetOwner(
    self.HoverFrame,
    "ANCHOR_NONE"
  )

  GameTooltip:SetCompanionPet(
    petGUID
  )

  self:PositionTooltip()
  GameTooltip:Show()
end

function BreedSection:HideBreedTooltip()
  local blizzardPetInfo =
      _G.PetJournalPetCardPetInfo
      or (
        _G.PetJournalPetCard
        and _G.PetJournalPetCard.PetInfo
      )

  if blizzardPetInfo
      and type(blizzardPetInfo.RunScript)
      == "function" then
    blizzardPetInfo:RunScript(
      "OnLeave"
    )
  end

  GameTooltip:Hide()
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

  --------------------------------------------------
  -- Alleen de breedtekst is hoverbaar.
  --------------------------------------------------

  self.HoverFrame:ClearAllPoints()

  self.HoverFrame:SetPoint(
    "TOPLEFT",
    self.Breeds,
    "TOPLEFT",
    0,
    2
  )

  self.HoverFrame:SetPoint(
    "BOTTOMRIGHT",
    self.Breeds,
    "BOTTOMRIGHT",
    0,
    -2
  )

  self.HoverFrame:SetShown(
    self.Pet ~= nil
  )
end

function BreedSection:GetFrame()
  return self.Frame
end

addon.UI.PetCard.BreedSection = BreedSection
