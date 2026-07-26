local _, addon = ...

local PetList = {}

PetList.Hooked = false
PetList.LoaderFrame = nil

local BREED_LABEL_WIDTH = 48
local BREED_LABEL_RIGHT_OFFSET = -8
local NAME_BREED_SPACING = 6

local function IsBreedVisible()
  return addon.Settings:Get(
    "showPetListBreed"
  ) ~= false
end

local function GetBreedPosition()
  return addon.Settings:Get(
    "petListBreedPosition"
  ) or "right"
end

local function UsesRightSideBreed()
  return IsBreedVisible()
      and GetBreedPosition() == "right"
end

local function GetPetGUID(elementData)
  if type(elementData) ~= "table"
      or not elementData.index then
    return nil
  end

  local petGUID =
      C_PetJournal.GetPetInfoByIndex(
        elementData.index
      )

  return petGUID
end

local function SaveNameAnchors(button)
  if button.PetMatchOriginalNameAnchors then
    return
  end

  if not button.name then
    return
  end

  local anchors = {}

  for index = 1, button.name:GetNumPoints() do
    local point,
    relativeTo,
    relativePoint,
    offsetX,
    offsetY =
        button.name:GetPoint(index)

    anchors[index] = {
      point,
      relativeTo,
      relativePoint,
      offsetX,
      offsetY,
    }
  end

  button.PetMatchOriginalNameAnchors =
      anchors
end

local function RestoreNameAnchors(button)
  if not button.name then
    return
  end

  local anchors =
      button.PetMatchOriginalNameAnchors

  if not anchors then
    return
  end

  button.name:ClearAllPoints()

  for _, anchor in ipairs(anchors) do
    button.name:SetPoint(
      anchor[1],
      anchor[2],
      anchor[3],
      anchor[4],
      anchor[5]
    )
  end
end

local function CreateBreedLabel(button)
  if button.PetMatchBreedLabel then
    return button.PetMatchBreedLabel
  end

  local label =
      button:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlightSmall"
      )

  label:SetPoint(
    "RIGHT",
    button,
    "RIGHT",
    BREED_LABEL_RIGHT_OFFSET,
    0
  )

  label:SetWidth(
    BREED_LABEL_WIDTH
  )

  label:SetJustifyH("RIGHT")
  label:SetText("")
  label:Hide()

  button.PetMatchBreedLabel =
      label

  return label
end

local function ApplyRightSideNameAnchors(
    button,
    breedLabel
)
  if not button.name then
    return
  end

  SaveNameAnchors(button)

  local originalAnchors =
      button.PetMatchOriginalNameAnchors

  local firstAnchor =
      originalAnchors
      and originalAnchors[1]

  if not firstAnchor then
    return
  end

  button.name:ClearAllPoints()

  button.name:SetPoint(
    firstAnchor[1],
    firstAnchor[2],
    firstAnchor[3],
    firstAnchor[4],
    firstAnchor[5]
  )

  button.name:SetPoint(
    "RIGHT",
    breedLabel,
    "LEFT",
    -NAME_BREED_SPACING,
    0
  )
end

local function ClearBreedLabel(button)
  if button.PetMatchBreedLabel then
    button.PetMatchBreedLabel:SetText("")
    button.PetMatchBreedLabel:Hide()
  end

  RestoreNameAnchors(button)
end

local function UpdatePetButton(
    button,
    elementData
)
  if not button then
    return
  end

  if not UsesRightSideBreed() then
    ClearBreedLabel(button)
    return
  end

  local petGUID =
      GetPetGUID(elementData)

  if not petGUID then
    ClearBreedLabel(button)
    return
  end

  local breed =
      addon.Services.Breed:
      GetJournalBreed(
        petGUID
      )

  if not breed then
    ClearBreedLabel(button)
    return
  end

  local breedLabel =
      CreateBreedLabel(button)

  breedLabel:SetText(breed)
  breedLabel:Show()

  ApplyRightSideNameAnchors(
    button,
    breedLabel
  )
end

local function RefreshPetJournal()
  if type(_G.PetJournal_UpdatePetList)
      == "function" then
    _G.PetJournal_UpdatePetList()
    return
  end

  local scrollBox =
      _G.PetJournal
      and _G.PetJournal.PetList
      and _G.PetJournal.PetList.ScrollBox

  if scrollBox
      and scrollBox.FullUpdate then
    scrollBox:FullUpdate(
      _G.ScrollBoxConstants
      and
      _G.ScrollBoxConstants.UpdateImmediately
      or nil
    )
  end
end

function PetList:ApplyBreedDisplay()
  local showBreed =
      IsBreedVisible()

  local position =
      GetBreedPosition()

  local letBattlePetBreedIDShowName =
      showBreed
      and position == "afterName"

  addon.Services.Breed:
      SetJournalNameDisplayEnabled(
        letBattlePetBreedIDShowName
      )

  RefreshPetJournal()
end

function PetList:InstallHook()
  if self.Hooked then
    return true
  end

  if type(_G.PetJournal_InitPetButton)
      ~= "function" then
    return false
  end

  hooksecurefunc(
    "PetJournal_InitPetButton",
    function(button, elementData)
      UpdatePetButton(
        button,
        elementData
      )
    end
  )

  self.Hooked = true

  return true
end

function PetList:OnAddonLoaded(name)
  if name == "Blizzard_Collections" then
    self:InstallHook()
    self:ApplyBreedDisplay()
    return
  end

  if name == "BattlePetBreedID" then
    addon.Services.Breed:
        ClearCache()

    self:ApplyBreedDisplay()
  end
end

function PetList:OnSettingChanged(key)
  if key ~= "showPetListBreed"
      and key ~= "petListBreedPosition" then
    return
  end

  self:ApplyBreedDisplay()
end

function PetList:Initialize()
  addon.EventBus:Register(
    addon.Events.SETTINGS_CHANGED,
    function(key)
      self:OnSettingChanged(key)
    end
  )

  addon.EventBus:Register(
    addon.Events.PET_JOURNAL_UPDATED,
    function()
      addon.Services.Breed:
          ClearCache()

      RefreshPetJournal()
    end
  )

  self.LoaderFrame =
      CreateFrame("Frame")

  self.LoaderFrame:RegisterEvent(
    "ADDON_LOADED"
  )

  self.LoaderFrame:SetScript(
    "OnEvent",
    function(_, _, name)
      self:OnAddonLoaded(name)
    end
  )
end

function PetList:Enable()
  self:InstallHook()
  self:ApplyBreedDisplay()
end

addon.ModuleManager:Register(
  "PetList",
  PetList
)
