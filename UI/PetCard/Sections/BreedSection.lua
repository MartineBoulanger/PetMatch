local _, addon = ...

local BreedSection = {}
BreedSection.__index = BreedSection

local TITLE_HEIGHT = 18
local BREED_TOP_SPACING = 9
local HELP_TOP_SPACING = 8
local BOTTOM_PADDING = 4

local BREED_TOOLTIP_OFFSET_X = 8
local BREED_TOOLTIP_OFFSET_Y = 0
local BREED_TOOLTIP_WIDTH = 240

local PET_RARITY_COLORS = addon.Constants.PET_RARITY_COLORS

local BREED_NAME_TO_ID = {
  ["B/B"] = 3,
  ["P/P"] = 4,
  ["S/S"] = 5,
  ["H/H"] = 6,
  ["H/P"] = 7,
  ["P/S"] = 8,
  ["H/S"] = 9,
  ["P/B"] = 10,
  ["S/B"] = 11,
  ["H/B"] = 12,
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

local function GetCurrentBreedID(pet)
  if type(pet) ~= "table" then
    return nil
  end

  local breedID =
      tonumber(
        pet.breedID
      )

  if breedID then
    return breedID
  end

  local breedName =
      pet.breedName

  if not breedName then
    local petGUID =
        pet.petGUID
        or pet.petID
        or pet.guid

    local breedService =
        addon.Services
        and addon.Services.Breed

    if petGUID
        and breedService
        and type(
          breedService.GetJournalBreed
        ) == "function" then
      breedName =
          breedService:GetJournalBreed(
            petGUID
          )
    end
  end

  return breedName
      and BREED_NAME_TO_ID[breedName]
      or nil
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

  instance.Frame:SetHeight(0)

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
    -HELP_TOP_SPACING,
    -4
  )

  instance.Divider:SetPoint(
    "RIGHT",
    instance.Frame,
    "RIGHT",
    HELP_TOP_SPACING,
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
    HELP_TOP_SPACING,
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

  instance.HoverButton =
      CreateFrame(
        "Button",
        nil,
        instance.Frame
      )

  instance.HoverButton:SetFrameStrata(
    "TOOLTIP"
  )

  instance.HoverButton:SetFrameLevel(
    500
  )

  instance.HoverButton:EnableMouse(true)

  instance.HoverButton:SetScript(
    "OnEnter",

    function()
      instance:ShowBreedTooltip()
    end
  )

  instance.HoverButton:SetScript(
    "OnLeave",

    function()
      instance:HideBreedTooltip()
    end
  )

  instance.HoverButton:Hide()

  return instance
end

function BreedSection:PositionBreedTooltip()
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

  tooltip:SetClampedToScreen(
    true
  )

  tooltip:SetFrameStrata(
    "TOOLTIP"
  )

  tooltip:SetFrameLevel(
    math.max(
      300,
      cardFrame:GetFrameLevel() + 100
    )
  )
end

function BreedSection:ShowBreedTooltip()
  local pet =
      self.Pet

  if not pet
      or not pet.speciesID then
    return
  end

  local setBreedTooltip = _G.BPBID_SetBreedTooltip

  if type(setBreedTooltip)
      ~= "function" then
    return
  end

  local speciesID =
      tonumber(
        pet.speciesID
      )

  if not speciesID then
    return
  end

  local petGUID =
      pet.petGUID
      or pet.petID
      or pet.guid

  local quality =
      tonumber(
        pet.quality
      )

  if not quality
      and petGUID then
    local _, _, _, _, petQuality =
        C_PetJournal.GetPetStats(
          petGUID
        )

    quality = petQuality
  end

  quality = quality or 1

  local tooltip = GameTooltip

  tooltip:Hide()

  tooltip:SetOwner(
    self.HoverButton,
    "ANCHOR_NONE"
  )

  tooltip:ClearLines()

  tooltip:SetMinimumWidth(
    BREED_TOOLTIP_WIDTH
  )

  tooltip:SetText(
    "BattlePetBreedID"
  )

  local currentBreedID = GetCurrentBreedID(pet)
  local currentBreedIDs

  if currentBreedID then
    currentBreedIDs = {
      currentBreedID,
    }
  end

  setBreedTooltip(
    tooltip,
    speciesID,
    currentBreedIDs,
    quality
  )

  tooltip:SetMinimumWidth(
    BREED_TOOLTIP_WIDTH
  )

  local cardFrame = self.CardFrame

  if cardFrame then
    tooltip:ClearAllPoints()

    tooltip:SetPoint(
      "TOPLEFT",
      cardFrame,
      "TOPRIGHT",
      0,
      0
    )

    tooltip:SetFrameStrata(
      "TOOLTIP"
    )

    tooltip:SetFrameLevel(
      math.max(
        1000,
        cardFrame:GetFrameLevel()
        + 100
      )
    )
  end

  tooltip:Show()
end

function BreedSection:HideBreedTooltip()
  if GameTooltip:GetOwner()
      == self.HoverButton then
    GameTooltip:Hide()
  end
end

function BreedSection:SetPet(pet)
  if addon.Settings:Get(
        "petListBreedPosition"
      ) == "hidden" then
    self.Pet = nil
    self.Breeds:SetText("")
    self.HoverButton:Hide()
    self.Frame:Hide()

    return false
  end

  local breedService = addon.Services.Breed

  if not breedService
      or not pet
      or pet.canBattle ~= true
      or not pet.speciesID then
    self.Pet = nil
    self.Breeds:SetText("")
    self.HoverButton:Hide()
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
    self.HoverButton:Hide()
    self.Frame:Hide()

    return false
  end

  self.Pet = pet

  local currentBreed = pet.breedName

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

    labels[#labels + 1] =
        label
  end

  self.Breeds:SetText(
    table.concat(
      labels,
      "  "
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
  end

  local breedHeight =
      math.ceil(
        self.Breeds:GetStringHeight()
        or 0
      )

  local height =
      TITLE_HEIGHT
      + BREED_TOP_SPACING
      + breedHeight

  self.Frame:SetHeight(
    math.max(
      1,
      height
    )
  )

  self.HoverButton:ClearAllPoints()

  self.HoverButton:SetPoint(
    "TOPLEFT",
    self.Breeds,
    "TOPLEFT",
    -4,
    4
  )

  self.HoverButton:SetPoint(
    "BOTTOMRIGHT",
    self.Breeds,
    "BOTTOMRIGHT",
    4,
    -4
  )

  self.HoverButton:SetShown(
    self.Pet ~= nil
    and self.Frame:IsShown()
  )
end

function BreedSection:GetFrame()
  return self.Frame
end

addon.UI.PetCard.BreedSection = BreedSection
