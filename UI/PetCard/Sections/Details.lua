local _, addon = ...

local Details = {}
Details.__index = Details

local SECTION_HEIGHT = 140

local MODEL_WIDTH = 150
local MODEL_HEIGHT = 120

local MODEL_HOVER_DELAY = 0.15

local INNER_PADDING = 10
local COLUMN_SPACING = 6

function Details:Create(parent)
  local instance =
      setmetatable(
        {},
        Details
      )

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

  instance.Model:SetIsFrameBuffer(true)

  instance.Model:SetFrameLevel(
    instance.Frame:GetFrameLevel()
    + 100
  )

  instance.Model:SetViewInsets(
    0,
    0,
    0,
    0
  )

  instance.Model:EnableMouse(false)

  instance.Model:Hide()

  instance.ModelTimer = nil

  instance.PendingDisplayID = nil
  instance.PendingSpeciesID = nil

  instance.CurrentDisplayID = nil
  instance.CurrentSpeciesID = nil

  instance.Stats =
      addon.UI.PetCard.Stats:Create(
        instance.Frame
      )

  instance.StatsFrame = instance.Stats:GetFrame()
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

function Details:CancelModelTimer()
  if self.ModelTimer then
    self.ModelTimer:Cancel()
    self.ModelTimer = nil
  end

  self.PendingDisplayID = nil
  self.PendingSpeciesID = nil
end

function Details:SchedulePetModel(displayID, speciesID)
  displayID = tonumber(displayID)
  speciesID = tonumber(speciesID)

  self:CancelModelTimer()

  if not displayID or not speciesID then
    self:SetPetModel(nil, nil)
    return
  end

  if self.CurrentDisplayID == displayID
      and self.CurrentSpeciesID == speciesID
      and self.Model:IsShown() then
    return
  end

  self:SetPetModel(
    nil,
    nil
  )

  self.PendingDisplayID =
      displayID

  self.PendingSpeciesID = speciesID

  self.ModelTimer =
      C_Timer.NewTimer(
        MODEL_HOVER_DELAY,

        function()
          self.ModelTimer = nil

          if not self.Frame
              or not self.Frame:IsShown() then
            self.PendingDisplayID = nil
            self.PendingSpeciesID = nil

            return
          end

          if self.PendingDisplayID ~= displayID
              or self.PendingSpeciesID ~= speciesID then
            return
          end

          self.PendingDisplayID = nil
          self.PendingSpeciesID = nil

          self:SetPetModel(
            displayID,
            speciesID
          )
        end
      )
end

function Details:SetPet(pet)
  if not pet then
    self:CancelModelTimer()
    self:SetPetModel(nil, nil)
    self.Stats:SetPet(nil)
    return
  end

  self.Stats:SetPet(pet)

  self:SchedulePetModel(
    pet.displayID,
    pet.speciesID
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

    self.CurrentDisplayID = nil
    self.CurrentSpeciesID = nil

    return
  end

  local _, modelSceneID =
      C_PetJournal.GetPetModelSceneInfoBySpeciesID(speciesID)

  if not modelSceneID then
    self.Model:ClearScene()
    self.Model:Hide()

    self.CurrentDisplayID = nil
    self.CurrentSpeciesID = nil

    return
  end

  self.Model:ClearScene()

  self.Model:SetViewInsets(
    0,
    0,
    0,
    0
  )

  self.Model:
      TransitionToModelSceneID(
        modelSceneID,
        CAMERA_TRANSITION_TYPE_IMMEDIATE,
        CAMERA_MODIFICATION_TYPE_DISCARD,
        true
      )

  local actor = self.Model:GetActorByTag("pet")

  if not actor then
    self.Model:Hide()

    self.CurrentDisplayID = nil
    self.CurrentSpeciesID = nil

    return
  end

  local success = actor:SetModelByCreatureDisplayID(displayID, true)

  if not success then
    self.Model:ClearScene()
    self.Model:Hide()

    self.CurrentDisplayID = nil
    self.CurrentSpeciesID = nil

    return
  end

  if actor.SetAnimationBlendOperation then
    actor:SetAnimationBlendOperation(
      Enum.ModelBlendOperation.None
    )
  end

  self.CurrentDisplayID = displayID
  self.CurrentSpeciesID = speciesID
  self.Model:Show()
end

function Details:GetFrame()
  return self.Frame
end

addon.UI.PetCard.Details = Details
