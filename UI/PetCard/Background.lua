local _, addon = ...

addon.UI.PetCard = addon.UI.PetCard or {}

local Background = {}
Background.__index = Background

local function ApplyCover(texture, frame, sourceWidth, sourceHeight)
  local frameWidth = frame:GetWidth()
  local frameHeight = frame:GetHeight()

  if frameWidth <= 0 or frameHeight <= 0 then
    return
  end

  sourceWidth = sourceWidth or 1
  sourceHeight = sourceHeight or 1

  local frameRatio = frameWidth / frameHeight
  local sourceRatio = sourceWidth / sourceHeight

  if frameRatio > sourceRatio then
    -- Frame is breder: snijd boven- en onderkant bij
    local visibleHeight = sourceRatio / frameRatio
    local offset = (1 - visibleHeight) / 2

    texture:SetTexCoord(0, 1, offset, 1 - offset)
  else
    -- Frame is smaller: snijd linker- en rechterkant bij
    local visibleWidth = frameRatio / sourceRatio
    local offset = (1 - visibleWidth) / 2

    texture:SetTexCoord(offset, 1 - offset, 0, 1)
  end
end

function Background:ShowMarble()
  self.Frame:SetBackdropColor(0.55, 0.55, 0.55, 0.95)
end

function Background:ShowPetIcon()
  self.Frame:SetBackdropColor(0, 0, 0, 1)

  self.Texture:SetTexture(self.Pet.icon)

  ApplyCover(self.Texture, self.Frame)

  self.Texture:SetVertexColor(0.35, 0.35, 0.35, 0.55)
  self.Texture:Show()
end

function Background:ShowPetPortrait()
  local pet = self.Pet

  if not pet or not tonumber(pet.displayID) then
    self:ShowMarble()
    return
  end

  self.Frame:SetBackdropColor(0, 0, 0, 1)

  SetPortraitTextureFromCreatureDisplayID(
    self.Portrait,
    tonumber(pet.displayID)
  )

  ApplyCover(self.Portrait, self.Frame)

  self.Portrait:SetVertexColor(0.35, 0.35, 0.35, 0.60)
  self.Portrait:Show()
end

function Background:ShowPetFamily()
  local pet = self.Pet

  if not pet or not pet.petType then
    self:ShowMarble()
    return
  end

  local icon = addon.Constants.PET_FAMILY_ICONS[pet.petType]

  if not icon then
    self:ShowMarble()
    return
  end

  self.Frame:SetBackdropColor(0, 0, 0, 1)

  self.Texture:SetTexture(icon)

  ApplyCover(self.Texture, self.Frame)

  self.Texture:SetVertexColor(0.35, 0.35, 0.35, 0.35)
  self.Texture:Show()
end

function Background:ShowPetExpansion()
  local pet = self.Pet

  if not pet or pet.expansionID == nil then
    self:ShowMarble()
    return
  end

  local texture =
      addon.Constants.PET_EXPANSION_BACKGROUNDS[pet.expansionID]

  if not texture then
    self:ShowMarble()
    return
  end

  self.Frame:SetBackdropColor(0, 0, 0, 1)

  self.Texture:SetTexture(texture)

  ApplyCover(self.Texture, self.Frame, 16, 9)

  self.Texture:SetVertexColor(0.35, 0.35, 0.35, 0.55)
  self.Texture:Show()
end

function Background:Create(parent)
  local instance = setmetatable({}, Background)

  instance.Frame = parent

  -- Pet Icon Background
  instance.Texture = parent:CreateTexture(
    nil,
    "BACKGROUND",
    nil,
    1
  )

  instance.Texture:SetPoint("TOPLEFT", parent, "TOPLEFT", 2, -2)
  instance.Texture:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -2, 2)
  instance.Texture:Hide()

  -- Pet Portrait Background
  instance.Portrait = parent:CreateTexture(
    nil,
    "BACKGROUND",
    nil,
    2
  )

  instance.Portrait:SetPoint("TOPLEFT", parent, "TOPLEFT", 2, -2)
  instance.Portrait:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -2, 2)
  instance.Portrait:Hide()

  return instance
end

function Background:SetPet(pet)
  self.Pet = pet
  self:Refresh()
end

function Background:Refresh()
  local backgroundType = addon.Settings:GetUI("petCardBackground")

  self.Texture:Hide()
  self.Portrait:Hide()

  if backgroundType == "petIcon" and self.Pet and self.Pet.icon then
    self:ShowPetIcon()
  elseif backgroundType == "petPortrait" then
    self:ShowPetPortrait()
  elseif backgroundType == "petFamily" then
    self:ShowPetFamily()
  elseif backgroundType == "petExpansion" then
    self:ShowPetExpansion()
  else
    self:ShowMarble()
  end
end

addon.UI.PetCard.Background = Background
