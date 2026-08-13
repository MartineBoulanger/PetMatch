local _, addon = ...

addon.UI.PetCard = addon.UI.PetCard or {}

local PetCard = {}
PetCard.__index = PetCard

local CARD_WIDTH = 300
local CONTENT_PADDING = 0
local CONTENT_TOP_SPACING = 0
local SECTION_SPACING = 5

function PetCard:Create(parent)
  assert(
    parent,
    "PetCard requires a parent frame"
  )

  local instance =
      setmetatable(
        {},
        PetCard
      )

  --------------------------------------------------
  -- Frame
  --------------------------------------------------
  instance.Frame =
      CreateFrame(
        "Frame",
        nil,
        parent,
        "DefaultPanelTemplate"
      )

  instance.Frame:SetWidth(
    CARD_WIDTH
  )

  instance.Frame:SetFrameStrata(
    "TOOLTIP"
  )

  instance.Frame:SetFrameLevel(
    100
  )

  instance.Frame:SetClampedToScreen(
    true
  )

  --------------------------------------------------
  -- Blizzard title
  --------------------------------------------------

  if instance.Frame.TitleContainer
      and instance.Frame.TitleContainer.TitleText then
    instance.Frame.TitleContainer.TitleText:SetText(
      ""
    )
  elseif type(instance.Frame.SetTitle) == "function" then
    instance.Frame:SetTitle("Pet Card")
  end

  --------------------------------------------------
  -- Components
  --------------------------------------------------

  instance:CreatePetModel()
  instance:CreateContent()
  instance:CreateCloseButton()

  instance:CreateHeader()
  instance:CreateStats()
  instance:CreateSource()
  instance:CreateDescription()
  instance:CreateAbilityGrid()
  instance:CreateBreedSection()

  instance:SetPinned(false)

  instance.Frame:Hide()

  return instance
end

--------------------------------------------------
-- Content
--------------------------------------------------
function PetCard:CreateContent()
  self.Content =
      CreateFrame(
        "Frame",
        nil,
        self.Frame
      )

  --------------------------------------------------
  -- Start underneath Blizzard title container
  --------------------------------------------------
  if self.Frame.TitleContainer then
    self.Content:SetPoint(
      "TOPLEFT",
      self.Frame.TitleContainer,
      "BOTTOMLEFT",
      CONTENT_PADDING,
      -CONTENT_TOP_SPACING
    )
  else
    self.Content:SetPoint(
      "TOPLEFT",
      self.Frame,
      "TOPLEFT",
      CONTENT_PADDING,
      -CONTENT_PADDING
    )
  end

  self.Content:SetPoint(
    "TOPRIGHT",
    self.Frame,
    "TOPRIGHT",
    -CONTENT_PADDING,
    0
  )

  self.Content:SetHeight(1)
  self.Content:EnableMouse(false)
end

--------------------------------------------------
-- Close button
--------------------------------------------------
function PetCard:CreateCloseButton()
  local parent =
      self.Frame.TitleContainer
      or self.Frame

  self.CloseButton =
      CreateFrame(
        "Button",
        nil,
        parent,
        "UIPanelCloseButton"
      )

  self.CloseButton:SetPoint(
    "TOPRIGHT",
    self.Frame,
    "TOPRIGHT",
    0,
    0
  )

  --------------------------------------------------
  -- Make sure the button stays above the panel
  --------------------------------------------------
  self.CloseButton:SetFrameStrata(
    self.Frame:GetFrameStrata()
  )

  self.CloseButton:SetFrameLevel(
    parent:GetFrameLevel() + 20
  )

  --------------------------------------------------
  -- Click
  --------------------------------------------------
  self.CloseButton:SetScript(
    "OnClick",
    function()
      if self.CloseHandler then
        self.CloseHandler()
      else
        self:SetPinned(false)
        self:Hide()
      end
    end
  )

  self.CloseButton:Hide()
end

function PetCard:SetCloseHandler(handler)
  if handler ~= nil
      and type(handler) ~= "function" then
    error(
      "PetCard: SetCloseHandler requires a function or nil."
    )
  end

  self.CloseHandler = handler
end

--------------------------------------------------
-- Pinning
--------------------------------------------------
function PetCard:SetPinned(pinned)
  self.Pinned =
      pinned == true

  if self.CloseButton then
    self.CloseButton:SetShown(
      self.Pinned
    )
  end

  self.Frame:EnableMouse(
    self.Pinned
  )

  self.Content:EnableMouse(
    self.Pinned
  )

  if self.Header
      and self.Header.SetInteractive then
    self.Header:SetInteractive(
      self.Pinned
    )
  end
end

function PetCard:IsPinned()
  return self.Pinned == true
end

--------------------------------------------------
-- Sections
--------------------------------------------------
function PetCard:CreateHeader()
  self.Header =
      addon.UI.PetCard.Header:Create(
        self.Content
      )
end

function PetCard:CreateStats()
  self.Stats =
      addon.UI.PetCard.Stats:Create(
        self.Content
      )
end

function PetCard:CreateSource()
  self.Source =
      addon.UI.PetCard.Source:Create(
        self.Content
      )
end

function PetCard:CreateDescription()
  self.Description =
      addon.UI.PetCard.Description:Create(
        self.Content
      )
end

function PetCard:CreateAbilityGrid()
  self.AbilityGrid =
      addon.UI.PetCard.AbilityGrid:Create(
        self.Content
      )
end

function PetCard:CreateBreedSection()
  self.BreedSection =
      addon.UI.PetCard.BreedSection:Create(
        self.Content
      )
end

--------------------------------------------------
-- Pet
--------------------------------------------------
function PetCard:SetPet(pet)
  if not pet then
    self:Hide()
    return
  end

  self.Pet = pet

  self:SetPetModel(
    pet.displayID
  )

  self.Header:SetPet(pet)
  self.Stats:SetPet(pet)
  self.Source:SetPet(pet)
  self.Description:SetPet(pet)
  self.AbilityGrid:SetPet(pet)
  self.BreedSection:SetPet(pet)

  self:Layout()

  self.Source:UpdateHeight()
  self.Description:UpdateHeight()

  if self.BreedSection:GetFrame():IsShown() then
    self.BreedSection:UpdateHeight()
  end

  if self.AbilityGrid:GetFrame():IsShown() then
    self.AbilityGrid:Layout()
  end

  self:Layout()
end

--------------------------------------------------
-- Layout
--------------------------------------------------
function PetCard:Layout()
  local sections = {
    self.Header,
    self.Stats,
    self.Source,
    self.Description,
    self.AbilityGrid,
    self.BreedSection,
  }

  local offsetY = 0

  for _, section in ipairs(sections) do
    if section
        and type(section.GetFrame)
        == "function" then
      local frame =
          section:GetFrame()

      if frame:IsShown() then
        frame:ClearAllPoints()

        frame:SetPoint(
          "TOPLEFT",
          self.Content,
          "TOPLEFT",
          0,
          -offsetY
        )

        frame:SetPoint(
          "TOPRIGHT",
          self.Content,
          "TOPRIGHT",
          0,
          -offsetY
        )

        local height =
            math.max(
              1,
              frame:GetHeight() or 0
            )

        offsetY =
            offsetY
            + height
            + SECTION_SPACING
      end
    end
  end

  if offsetY > 0 then
    offsetY =
        offsetY
        - SECTION_SPACING
  end

  --------------------------------------------------
  -- Content height
  --------------------------------------------------
  self.Content:SetHeight(
    math.max(
      1,
      offsetY
    )
  )

  --------------------------------------------------
  -- Total card height
  --------------------------------------------------
  local titleHeight = 0
  if self.Frame.TitleContainer then
    titleHeight =
        self.Frame.TitleContainer:GetHeight()
        or 0
  end

  self.Frame:SetHeight(
    titleHeight
    + CONTENT_TOP_SPACING
    + offsetY
    + CONTENT_PADDING
  )
end

--------------------------------------------------
-- Owner / anchor
--------------------------------------------------
function PetCard:SetOwner(
    owner,
    anchor
)
  if not owner then
    return
  end

  self.Owner = owner

  local frame =
      self.Frame

  frame:ClearAllPoints()

  anchor =
      anchor
      or "ANCHOR_RIGHT"

  if anchor == "ANCHOR_LEFT" then
    frame:SetPoint(
      "RIGHT",
      owner,
      "LEFT",
      -8,
      0
    )
  elseif anchor == "ANCHOR_TOP" then
    frame:SetPoint(
      "BOTTOM",
      owner,
      "TOP",
      0,
      8
    )
  elseif anchor == "ANCHOR_BOTTOM" then
    frame:SetPoint(
      "TOP",
      owner,
      "BOTTOM",
      0,
      -8
    )
  elseif anchor == "ANCHOR_CURSOR" then
    local scale =
        UIParent:GetEffectiveScale()

    local x, y =
        GetCursorPosition()

    x = x / scale
    y = y / scale

    frame:SetPoint(
      "BOTTOMLEFT",
      UIParent,
      "BOTTOMLEFT",
      x + 16,
      y + 16
    )
  else
    frame:SetPoint(
      "LEFT",
      owner,
      "RIGHT",
      8,
      0
    )
  end
end

--------------------------------------------------
-- Accessors
--------------------------------------------------
function PetCard:GetFrame()
  return self.Frame
end

function PetCard:GetContentFrame()
  return self.Content
end

--------------------------------------------------
-- Show / Hide
--------------------------------------------------
function PetCard:Show()
  self.Frame:Show()
end

function PetCard:Hide(
    owner,
    force
)
  if self.Pinned
      and force ~= true then
    return
  end

  if owner
      and self.Owner
      and owner ~= self.Owner then
    return
  end

  self.Frame:Hide()
  self.Owner = nil
end

function PetCard:IsOwnedBy(owner)
  return self.Owner == owner
end

--------------------------------------------------
-- Pet model
--------------------------------------------------
function PetCard:CreatePetModel()
  self.Model =
      CreateFrame(
        "PlayerModel",
        nil,
        self.Frame
      )

  self.Model:SetPoint(
    "TOPRIGHT",
    self.Frame,
    "TOPRIGHT",
    -20,
    -55
  )

  self.Model:SetSize(
    130,
    120
  )

  self.Model:SetFrameLevel(
    self.Frame:GetFrameLevel() + 2
  )

  self.Model:EnableMouse(false)
  self.Model:Hide()
end

function PetCard:SetPetModel(displayID)
  displayID =
      tonumber(displayID)

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
      1.05
    )
  end

  self.Model:Show()
end

addon.UI.PetCard.Card = PetCard
