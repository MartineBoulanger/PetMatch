local _, addon = ...

addon.UI.PetCard = addon.UI.PetCard or {}

local PetCard = {}
PetCard.__index = PetCard

local CARD_WIDTH = 360
local CONTENT_PADDING = 14
local SECTION_SPACING = 8

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

  instance.Frame =
      CreateFrame(
        "Frame",
        nil,
        parent
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

  instance:CreateBackground()
  instance:CreateArtwork()
  instance:CreatePetModel()
  instance:CreateOverlay()
  instance:CreateBorder()
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

function PetCard:CreateBackground()
  self.Background =
      self.Frame:CreateTexture(
        nil,
        "BACKGROUND"
      )

  self.Background:SetAllPoints()

  self.Background:SetTexture(
    "Interface\\FrameGeneral\\UI-Background-Marble"
  )

  self.Background:SetHorizTile(true)
  self.Background:SetVertTile(true)

  self.Background:SetVertexColor(
    0.28,
    0.25,
    0.20,
    1
  )
end

function PetCard:CreateArtwork()
  self.Artwork =
      self.Frame:CreateTexture(
        nil,
        "BORDER"
      )

  self.Artwork:SetPoint(
    "TOPLEFT",
    self.Frame,
    "TOPLEFT",
    12,
    -12
  )

  self.Artwork:SetPoint(
    "BOTTOMRIGHT",
    self.Frame,
    "BOTTOMRIGHT",
    -12,
    12
  )

  self.Artwork:SetTexCoord(
    0.08,
    0.92,
    0.08,
    0.92
  )

  self.Artwork:SetAlpha(0.10)
end

function PetCard:SetArtwork(icon)
  if icon then
    self.Artwork:SetTexture(icon)
    self.Artwork:Show()
  else
    self.Artwork:SetTexture(nil)
    self.Artwork:Hide()
  end
end

function PetCard:CreateOverlay()
  self.Overlay =
      self.Frame:CreateTexture(
        nil,
        "ARTWORK"
      )

  self.Overlay:SetPoint(
    "TOPLEFT",
    self.Frame,
    "TOPLEFT",
    8,
    -8
  )

  self.Overlay:SetPoint(
    "BOTTOMRIGHT",
    self.Frame,
    "BOTTOMRIGHT",
    -8,
    8
  )

  self.Overlay:SetColorTexture(
    0.02,
    0.02,
    0.02,
    0.58
  )
end

function PetCard:CreateBorder()
  self.Border =
      CreateFrame(
        "Frame",
        nil,
        self.Frame,
        "BackdropTemplate"
      )

  self.Border:SetAllPoints()

  self.Border:SetBackdrop({
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    edgeSize = 20,
    insets = {
      left = 5,
      right = 5,
      top = 5,
      bottom = 5,
    },
  })

  self.Border:SetFrameLevel(
    self.Frame:GetFrameLevel() + 20
  )

  self.Border:EnableMouse(false)
end

function PetCard:CreateContent()
  self.Content =
      CreateFrame(
        "Frame",
        nil,
        self.Frame
      )

  self.Content:SetPoint(
    "TOPLEFT",
    self.Frame,
    "TOPLEFT",
    CONTENT_PADDING,
    -CONTENT_PADDING
  )

  self.Content:SetPoint(
    "TOPRIGHT",
    self.Frame,
    "TOPRIGHT",
    -CONTENT_PADDING,
    -CONTENT_PADDING
  )

  self.Content:SetHeight(1)
end

function PetCard:CreateCloseButton()
  self.CloseButton =
      CreateFrame(
        "Button",
        nil,
        self.Frame,
        "UIPanelCloseButton"
      )

  self.CloseButton:SetPoint(
    "TOPRIGHT",
    self.Frame,
    "TOPRIGHT",
    3,
    3
  )

  self.CloseButton:SetFrameLevel(
    self.Border:GetFrameLevel() + 5
  )

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
end

function PetCard:IsPinned()
  return self.Pinned == true
end

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

function PetCard:SetPet(pet)
  if not pet then
    self:Hide()
    return
  end

  self.Pet = pet

  self:SetArtwork(
    pet.icon
  )

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

  self.Content:SetHeight(
    math.max(
      1,
      offsetY
    )
  )

  self.Frame:SetHeight(
    offsetY
    + (CONTENT_PADDING * 2)
  )
end

function PetCard:SetOwner(
    owner,
    anchor
)
  if not owner then
    return
  end

  self.Owner = owner

  local frame = self.Frame

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

function PetCard:GetFrame()
  return self.Frame
end

function PetCard:GetContentFrame()
  return self.Content
end

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

  self.Artwork:SetTexCoord(
    0.12,
    0.88,
    0.12,
    0.88
  )

  if self.Model.SetFacing then
    self.Model:SetFacing(math.rad(-25))
  end

  if self.Model.SetCamDistanceScale then
    self.Model:SetCamDistanceScale(1.05)
  end

  self.Model:Show()
end

addon.UI.PetCard.Card = PetCard
