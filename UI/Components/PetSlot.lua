local _, addon = ...

local L = addon.L
local PetSlot = {}
PetSlot.__index = PetSlot

local ICON_WIDTH = 24
local ICON_HEIGHT = 24

local RANDOM_PET_ICON = "Interface\\Icons\\INV_Misc_Dice_02"
local LEVELING_PET_ICON = "Interface\\AddOns\\PetMatch\\Media\\levelingicon"

local function CreateFamilyIconBackground(parent)
  local background = CreateFrame(
    "Frame",
    nil,
    parent,
    "BackdropTemplate"
  )

  if addon.Settings and addon.Settings:GetUI("teamCardHeightMode") == "large" then
    background:SetSize(ICON_WIDTH + 4, ICON_HEIGHT + 4)
  else
    background:SetSize(ICON_WIDTH + 1, ICON_HEIGHT + 1)
  end

  background:SetPoint("CENTER", parent, "CENTER", 0, 0)

  background:SetBackdrop({
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 8,
    insets = {
      left = 0,
      right = 0,
      top = 0,
      bottom = 0,
    },
  })

  background:SetBackdropBorderColor(0.45, 0.45, 0.45, 1)

  background:Hide()

  return background
end

local function CreatePetIcon(parent, PetSlot)
  local instance = setmetatable({
    Frame = parent,
    PetGUID = nil,
    Team = nil,
    SlotIndex = nil,
  }, PetSlot)

  parent:SetSize(ICON_WIDTH, ICON_HEIGHT)

  local icon = parent:CreateTexture(nil, "ARTWORK")
  icon:SetAllPoints()

  local EmptyIcon = parent:CreateTexture(nil, "ARTWORK")
  EmptyIcon:SetAllPoints()
  EmptyIcon:SetTexture("Interface/PaperDoll/UI-Backpack-EmptySlot")
  EmptyIcon:SetVertexColor(0.45, 0.45, 0.45, 0.65)

  --------------------------------------------------
  -- Rarity border for normal pets
  --------------------------------------------------
  local rarityBorder = CreateFrame(
    "Frame",
    nil,
    parent,
    "BackdropTemplate"
  )

  rarityBorder:SetAllPoints(parent)

  rarityBorder:SetBackdrop({
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 8,
    insets = {
      left = 0,
      right = 0,
      top = 0,
      bottom = 0,
    },
  })

  rarityBorder:SetFrameLevel(parent:GetFrameLevel() + 1)
  rarityBorder:EnableMouse(false)
  rarityBorder:Hide()

  instance.RarityBorder = rarityBorder

  instance.FamilyBackground = CreateFamilyIconBackground(parent)
  local FamilyIcon = instance.FamilyBackground:CreateTexture(
    nil,
    "ARTWORK"
  )
  FamilyIcon:SetAllPoints()

  instance.Icon = icon
  instance.EmptyIcon = EmptyIcon
  instance.FamilyIcon = FamilyIcon

  return instance
end

function PetSlot:SetFamilyIcon(texture)
  self.Icon:Hide()
  self.EmptyIcon:Hide()

  self.FamilyIcon:SetTexture(texture)
  self.FamilyIcon:SetTexCoord(0, 1, 0, 1)

  self.FamilyBackground:Show()
end

function PetSlot:SetRarityBorder(quality)
  local color = addon.Constants.PET_RARITY_COLORS[quality]

  if not color then
    self.RarityBorder:Hide()
    return
  end

  self.RarityBorder:SetBackdropBorderColor(
    color.r,
    color.g,
    color.b,
    1
  )

  self.RarityBorder:Show()
end

local function GetSpecialSlotIcon(specialSlot)
  if type(specialSlot) ~= "table" then
    return nil, nil
  end

  if specialSlot.type == "leveling"
      or specialSlot.type == "levelingQueue" then
    return LEVELING_PET_ICON, nil
  end

  if specialSlot.type == "random" then
    local petType = tonumber(specialSlot.petType) or 0

    if petType > 0 then
      local icon = addon.Constants.PET_FAMILY_ICONS[petType]
      if icon then
        return tostring(icon), nil
      end
    end

    return RANDOM_PET_ICON, nil
  end

  return nil, nil
end

function PetSlot:Create(parent)
  assert(parent, L["PARENT_FRAME_ERROR"])

  local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")

  frame.petGUID = nil
  addon.UI.Components.PetTooltip:Attach(
    frame,
    function(control)
      if not control.petGUID then
        return nil
      end
      return "petGUID", control.petGUID
    end,
    "ANCHOR_LEFT",
    "teams",
    function(control)
      local team = control.Team
      local slot = control.SlotIndex

      if not team or not slot or type(team.abilities) ~= "table" then
        return nil
      end

      return team.abilities[slot]
    end
  )

  local instance = CreatePetIcon(frame, PetSlot)

  instance:Clear()

  return instance
end

function PetSlot:SetPet(petGUID, team, slotIndex)
  if not petGUID then
    self:Clear()
    return
  end

  local pet = addon.Services.PetJournal:GetPet(petGUID)

  if not pet then
    self:Clear()
    return
  end

  self.PetGUID = petGUID
  self.Team = team
  self.SlotIndex = slotIndex

  self.Frame.petGUID = petGUID
  self.Frame.Team = team
  self.Frame.SlotIndex = slotIndex

  self.EmptyIcon:Hide()
  self.FamilyBackground:Hide()

  local _, _, _, _, quality = C_PetJournal.GetPetStats(petGUID)
  self:SetRarityBorder(quality)

  if pet.icon then
    self.Icon:SetAtlas(nil)
    self.Icon:SetTexture(pet.icon)
    self.Icon:Show()
  else
    self.Icon:SetTexture(nil)
    self.Icon:Hide()
    self.FamilyBackground:Hide()
    self.EmptyIcon:Show()
  end
end

function PetSlot:SetSpecialSlot(specialSlot)
  if type(specialSlot) ~= "table" then
    self:Clear()
    return
  end

  self:SetRarityBorder(nil)

  self.PetGUID = nil
  self.Frame.petGUID = nil

  self.EmptyIcon:Hide()

  local texture, atlas = GetSpecialSlotIcon(specialSlot)

  local isFamilyIcon = specialSlot.type == "random"
      and (tonumber(specialSlot.petType) or 0) > 0
      and texture ~= nil

  self.FamilyBackground:Hide()

  self.Icon:SetAtlas(nil)
  self.Icon:SetTexture(nil)

  if isFamilyIcon then
    self:SetFamilyIcon(texture)
  elseif atlas then
    self.Icon:SetAtlas(atlas)
    self.Icon:Show()
  elseif texture then
    self.Icon:SetTexture(texture)
    self.Icon:Show()
  else
    self.Icon:Hide()
    self.EmptyIcon:Show()
  end
end

function PetSlot:SetHeight(height)
  height = tonumber(height)

  if not height
      or height <= 0 then
    return
  end

  self.Frame:SetHeight(
    height
  )
end

function PetSlot:SetSize(width, height)
  width = tonumber(width)
      or self.Frame:GetWidth()

  height = tonumber(height)
      or self.Frame:GetHeight()

  self.Frame:SetSize(
    width,
    height
  )
end

function PetSlot:Clear()
  self:SetRarityBorder(nil)

  self.PetGUID = nil
  self.Team = nil
  self.SlotIndex = nil

  self.Frame.petGUID = nil
  self.Frame.Team = nil
  self.Frame.SlotIndex = nil

  self.Icon:SetAtlas(nil)
  self.Icon:SetTexture(nil)
  self.Icon:Hide()

  self.FamilyBackground:Hide()

  self.EmptyIcon:Show()
end

function PetSlot:GetFrame()
  return self.Frame
end

function PetSlot:Show()
  self.Frame:Show()
end

function PetSlot:Hide()
  self.Frame:Hide()
end

addon.UI.Components.PetSlot = PetSlot
