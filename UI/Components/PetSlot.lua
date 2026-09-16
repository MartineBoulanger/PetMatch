local _, addon = ...

local L = addon.L
local PetSlot = {}
PetSlot.__index = PetSlot

local ICON_WIDTH = 24
local ICON_HEIGHT = 24

local RANDOM_PET_ICON = "Interface\\Icons\\INV_Misc_Dice_02"
local LEVELING_PET_ICON = "Interface\\AddOns\\PetMatch\\Media\\levelingicon"

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
      return addon.Constants.PET_FAMILY_ICONS[petType], nil
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

  frame:SetSize(
    ICON_WIDTH,
    ICON_HEIGHT
  )

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
    Team = nil,
    SlotIndex = nil,
  }, PetSlot)

  instance.Icon = frame:CreateTexture(nil, "ARTWORK")
  instance.Icon:SetAllPoints(frame)
  instance.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

  instance.EmptyIcon = frame:CreateTexture(nil, "ARTWORK")
  instance.EmptyIcon:SetAllPoints(frame)
  instance.EmptyIcon:SetTexture("Interface/PaperDoll/UI-Backpack-EmptySlot")
  instance.EmptyIcon:SetVertexColor(0.45, 0.45, 0.45, 0.55)

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
  self.Frame.petGUID = nil

  self.EmptyIcon:Hide()

  local texture, atlas = GetSpecialSlotIcon(specialSlot)

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
  self.PetGUID = nil
  self.Team = nil
  self.SlotIndex = nil

  self.Frame.petGUID = nil
  self.Frame.Team = nil
  self.Frame.SlotIndex = nil

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
