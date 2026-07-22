local _, addon = ...

addon.UI = addon.UI or {}
addon.UI.Components = addon.UI.Components or {}

local PetSlot = {}
PetSlot.__index = PetSlot

local ICON_SIZE = 24
local RANDOM_PET_ICON = "Interface\\Icons\\INV_Misc_Dice_02"
local LEVELING_PET_ICON = "Interface\\AddOns\\PetMatch\\Media\\levelingicon"
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

local function GetSpecialSlotIcon(specialSlot)
  if type(specialSlot) ~= "table" then
    return nil, nil
  end

  if specialSlot.type == "leveling"
      or specialSlot.type == "levelingQueue" then
    return LEVELING_PET_ICON, nil
  end

  if specialSlot.type == "random" then
    local petType =
        tonumber(specialSlot.petType) or 0

    if petType > 0 then
      return PET_FAMILY_ICONS[petType], nil
    end

    return RANDOM_PET_ICON, nil
  end

  return nil, nil
end

function PetSlot:Create(parent)
  assert(parent, "PetSlot requires a parent frame")

  local frame = CreateFrame(
    "Frame",
    nil,
    parent,
    "BackdropTemplate"
  )

  frame:SetSize(ICON_SIZE, ICON_SIZE)

  frame:SetBackdrop({
    bgFile = "Interface/Buttons/WHITE8X8",
    edgeFile = "Interface/Buttons/WHITE8X8",
    edgeSize = 1,
  })

  frame:SetBackdropColor(0.04, 0.04, 0.04, 0.35)
  frame:SetBackdropBorderColor(0.35, 0.30, 0.20, 0.8)

  local instance = setmetatable({
    Frame = frame,
    PetGUID = nil,
  }, PetSlot)

  instance.Icon = frame:CreateTexture(nil, "ARTWORK")
  instance.Icon:SetSize(ICON_SIZE, ICON_SIZE)
  instance.Icon:SetPoint("TOP", frame, "TOP", 0, 0)
  instance.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

  instance.EmptyIcon = frame:CreateTexture(nil, "ARTWORK")
  instance.EmptyIcon:SetSize(ICON_SIZE, ICON_SIZE)
  instance.EmptyIcon:SetPoint("CENTER", instance.Icon)
  instance.EmptyIcon:SetTexture("Interface/PaperDoll/UI-Backpack-EmptySlot")
  instance.EmptyIcon:SetVertexColor(0.45, 0.45, 0.45, 0.55)

  instance:Clear()

  return instance
end

function PetSlot:SetPet(petGUID)
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

  self.EmptyIcon:Hide()

  if pet.icon then
    self.Icon:SetAtlas(nil)
    self.Icon:SetTexture(pet.icon)
    self.Icon:Show()
  else
    self.Icon:SetTexture(nil)
    self.Icon:Hide()
    self.EmptyIcon:Show()
  end
end

function PetSlot:SetSpecialSlot(specialSlot)
  if type(specialSlot) ~= "table" then
    self:Clear()
    return
  end

  self.PetGUID = nil
  self.EmptyIcon:Hide()

  local texture, atlas =
      GetSpecialSlotIcon(specialSlot)

  self.Icon:SetAtlas(nil)
  self.Icon:SetTexture(nil)

  if atlas then
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

function PetSlot:Clear()
  self.PetGUID = nil

  self.Icon:SetAtlas(nil)
  self.Icon:SetTexture(nil)
  self.Icon:Hide()

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
