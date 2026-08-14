local _, addon = ...

local Details = {}
Details.__index = Details

local SECTION_HEIGHT = 140

local MODEL_WIDTH = 150
local MODEL_HEIGHT = 120

local INNER_PADDING = 10
local COLUMN_SPACING = 6

function Details:Create(parent)
  local instance =
      setmetatable(
        {},
        Details
      )

  --------------------------------------------------
  -- Section
  --------------------------------------------------
  instance.Frame =
      CreateFrame(
        "Frame",
        nil,
        parent,
        "BackdropTemplate"
      )

  instance.Frame:SetHeight(
    SECTION_HEIGHT
  )

  --------------------------------------------------
  -- Background
  --------------------------------------------------
  instance.Frame:SetBackdrop({
    bgFile = "Interface\\FrameGeneral\\UI-Background-Marble",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",

    tile = true,
    tileSize = 128,
    edgeSize = 10,

    insets = {
      left = 2,
      right = 2,
      top = 2,
      bottom = 2,
    },
  })

  instance.Frame:SetBackdropColor(
    0.55,
    0.55,
    0.55,
    0.95
  )

  instance.Frame:SetBackdropBorderColor(
    0.28,
    0.28,
    0.28,
    1
  )

  --------------------------------------------------
  -- Pet model
  --------------------------------------------------
  instance.Model =
      CreateFrame(
        "PlayerModel",
        nil,
        instance.Frame
      )

  instance.Model:SetSize(
    MODEL_WIDTH,
    MODEL_HEIGHT
  )

  instance.Model:SetPoint(
    "RIGHT",
    instance.Frame,
    "RIGHT",
    -6,
    -2
  )

  instance.Model:SetFrameLevel(
    instance.Frame:GetFrameLevel() + 1
  )

  instance.Model:EnableMouse(false)
  instance.Model:Hide()

  --------------------------------------------------
  -- Stats
  --------------------------------------------------
  instance.Stats =
      addon.UI.PetCard.Stats:Create(
        instance.Frame
      )

  instance.StatsFrame =
      instance.Stats:GetFrame()

  instance.StatsFrame:ClearAllPoints()

  instance.StatsFrame:SetPoint(
    "TOPLEFT",
    instance.Frame,
    "TOPLEFT",
    INNER_PADDING,
    -INNER_PADDING
  )

  instance.StatsFrame:SetPoint(
    "RIGHT",
    instance.Model,
    "LEFT",
    -COLUMN_SPACING,
    0
  )

  return instance
end

function Details:SetPet(pet)
  if not pet then
    self:SetPetModel(nil)
    self.Stats:SetPet(nil)
    return
  end

  self:SetPetModel(
    pet.displayID
  )

  self.Stats:SetPet(
    pet
  )
end

function Details:SetPetModel(displayID)
  displayID = tonumber(displayID)

  if not displayID then
    self.Model:ClearModel()
    self.Model:Hide()
    return
  end

  local success =
      pcall(
        self.Model.SetDisplayInfo,
        self.Model,
        displayID
      )

  if not success then
    self.Model:ClearModel()
    self.Model:Hide()
    return
  end

  if self.Model.SetFacing then
    self.Model:SetFacing(
      math.rad(-25)
    )
  end

  if self.Model.SetCamDistanceScale then
    self.Model:SetCamDistanceScale(
      0.95
    )
  end

  self.Model:Show()
end

function Details:GetFrame()
  return self.Frame
end

addon.UI.PetCard.Details = Details
