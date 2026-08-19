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
        "ModelScene",
        nil,
        instance.Frame,
        "NoCameraControlModelSceneMixinTemplate"
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

  instance.Model:SetIsFrameBuffer(
    true
  )

  instance.Model:SetFrameLevel(
    instance.Frame:GetFrameLevel() + 100
  )

  instance.Model:SetViewInsets(
    0,
    0,
    0,
    0
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
    pet.displayID,
    pet.speciesID
  )

  self.Stats:SetPet(
    pet
  )
end

function Details:SetPetModel(displayID, speciesID)
  displayID = tonumber(displayID)
  speciesID = tonumber(speciesID)

  if not self.Model
      or not displayID
      or not speciesID then
    if self.Model then
      self.Model:ClearScene()
      self.Model:Hide()
    end

    return
  end

  --------------------------------------------------
  -- Get Blizzard's ModelScene for this species
  --------------------------------------------------
  local _, modelSceneID =
      C_PetJournal.GetPetModelSceneInfoBySpeciesID(speciesID)

  if not modelSceneID then
    self.Model:ClearScene()
    self.Model:Hide()
    return
  end

  --------------------------------------------------
  -- Reset previous scene
  --------------------------------------------------
  self.Model:ClearScene()

  self.Model:SetViewInsets(
    0,
    0,
    0,
    0
  )

  --------------------------------------------------
  -- Load pet scene
  --------------------------------------------------
  self.Model:TransitionToModelSceneID(
    modelSceneID,
    CAMERA_TRANSITION_TYPE_IMMEDIATE,
    CAMERA_MODIFICATION_TYPE_DISCARD,
    true
  )

  --------------------------------------------------
  -- Get Blizzard's pet actor
  --------------------------------------------------
  local actor = self.Model:GetActorByTag("pet")

  if not actor then
    self.Model:Hide()
    return
  end

  --------------------------------------------------
  -- Set requested pet display
  --------------------------------------------------

  local success =
      actor:SetModelByCreatureDisplayID(
        displayID,
        true
      )

  if not success then
    self.Model:ClearScene()
    self.Model:Hide()
    return
  end

  if actor.SetAnimationBlendOperation then
    actor:SetAnimationBlendOperation(
      Enum.ModelBlendOperation.None
    )
  end

  self.Model:Show()
end

function Details:GetFrame()
  return self.Frame
end

addon.UI.PetCard.Details = Details
