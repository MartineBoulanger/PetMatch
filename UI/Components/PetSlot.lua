local addonName, addon = ...

addon.UI = addon.UI or {}
addon.UI.Components = addon.UI.Components or {}

local PetSlot = {}
PetSlot.__index = PetSlot

local SLOT_WIDTH = 78
local SLOT_HEIGHT = 76
local ICON_SIZE = 40

---@param parent Frame
---@return PetMatchPetSlot
function PetSlot:Create(parent)
  assert(parent, "PetSlot requires a parent frame")

  local frame = CreateFrame(
    "Frame",
    nil,
    parent,
    "BackdropTemplate"
  )

  frame:SetSize(SLOT_WIDTH, SLOT_HEIGHT)

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
  instance.Icon:SetPoint("TOP", frame, "TOP", 0, -10)
  instance.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

  instance.EmptyIcon = frame:CreateTexture(nil, "ARTWORK")
  instance.EmptyIcon:SetSize(ICON_SIZE, ICON_SIZE)
  instance.EmptyIcon:SetPoint("CENTER", instance.Icon)
  instance.EmptyIcon:SetTexture("Interface/PaperDoll/UI-Backpack-EmptySlot")
  instance.EmptyIcon:SetVertexColor(0.45, 0.45, 0.45, 0.55)

  instance.Level = frame:CreateFontString(
    nil,
    "OVERLAY",
    "GameFontHighlightSmall"
  )
  instance.Level:SetPoint(
    "BOTTOMRIGHT",
    instance.Icon,
    "BOTTOMRIGHT",
    -2,
    2
  )
  instance.Level:SetTextColor(1, 0.82, 0)

  instance.Name = frame:CreateFontString(
    nil,
    "OVERLAY",
    "GameFontHighlightSmall"
  )
  instance.Name:SetPoint(
    "TOP",
    instance.Icon,
    "BOTTOM",
    0,
    -4
  )
  instance.Name:SetWidth(SLOT_WIDTH - 6)
  instance.Name:SetJustifyH("CENTER")
  instance.Name:SetWordWrap(false)

  instance:Clear()

  return instance
end

---@param petGUID string?
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
    self.Icon:SetTexture(pet.icon)
    self.Icon:Show()
  else
    self.Icon:SetTexture(nil)
    self.Icon:Hide()
    self.EmptyIcon:Show()
  end

  self.Name:SetText(pet.name)

  if pet.level and pet.level > 0 then
    self.Level:SetFormattedText("%d", pet.level)
    self.Level:Show()
  else
    self.Level:SetText("")
    self.Level:Hide()
  end
end

function PetSlot:Clear()
  self.PetGUID = nil

  self.Icon:SetTexture(nil)
  self.Icon:Hide()

  self.EmptyIcon:Show()

  self.Name:SetText("Empty")

  self.Level:SetText("")
  self.Level:Hide()
end

---@return Frame
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
