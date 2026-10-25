local _, addon = ...

local PetConfirmation = {}

--------------------------------------------------
-- Helpers
--------------------------------------------------
local function GetPetID(owner)
  local petID = owner and owner.petID

  if type(petID) ~= "string" or petID == "" then
    return nil
  end

  return petID
end

local function CanReleasePet(petID)
  return C_PetJournal.PetCanBeReleased(petID)
      and not C_PetJournal.PetIsSlotted(petID)
      and not C_PetBattles.IsInBattle()
      and C_PetJournal.IsJournalUnlocked()
end

local function CanCagePet(petID)
  return C_PetJournal.PetIsTradable(petID)
      and not C_PetJournal.PetIsSlotted(petID)
      and not C_PetJournal.PetIsHurt(petID)
end

local function UpdatePetCard(petID)
  if PetJournalPetCard and PetJournalPetCard.petID == petID then
    PetJournal_ShowPetCard(1)
  end
end

local function FindMenuItem(rootDescription, text)
  for _, description in
  rootDescription:EnumerateElementDescriptions() do
    if MenuUtil.GetElementText(description) == text then
      return description
    end
  end

  return nil
end

--------------------------------------------------
-- Release Confirmation
--------------------------------------------------
local function HandleReleaseConfirmation(petID, rootDescription)
  if addon.Settings:Get("releaseConfirmationMode") ~= "skip" then
    return
  end

  if not CanReleasePet(petID) then
    return
  end

  local description = FindMenuItem(
    rootDescription,
    BATTLE_PET_RELEASE
  )

  if not description then
    return
  end

  description:SetResponder(function()
    if not CanReleasePet(petID) then
      return MenuResponse.CloseAll
    end

    C_PetJournal.ReleasePetByID(petID)
    UpdatePetCard(petID)

    return MenuResponse.CloseAll
  end)
end

--------------------------------------------------
-- Cage Confirmation
--------------------------------------------------
local function HandleCageConfirmation(petID, rootDescription)
  if addon.Settings:Get("cageConfirmationMode") ~= "skip" then
    return
  end

  if not CanCagePet(petID) then
    return
  end

  local description = FindMenuItem(
    rootDescription,
    BATTLE_PET_PUT_IN_CAGE
  )

  if not description then
    return
  end

  description:SetResponder(function()
    if not CanCagePet(petID) then
      return MenuResponse.CloseAll
    end

    PetJournal_SetPendingCage(petID)
    C_PetJournal.CagePetByID(petID)

    UpdatePetCard(petID)

    return MenuResponse.CloseAll
  end)
end

--------------------------------------------------
-- Initialize
--------------------------------------------------
function PetConfirmation:Initialize()
  if self.Initialized then
    return
  end

  if not Menu or type(Menu.ModifyMenu) ~= "function" then
    return
  end

  self.Initialized = true

  Menu.ModifyMenu(
    "MENU_PET_COLLECTION_PET",
    function(owner, rootDescription)
      local petID = GetPetID(owner)

      if not petID then
        return
      end

      HandleReleaseConfirmation(petID, rootDescription)
      HandleCageConfirmation(petID, rootDescription)
    end
  )
end

--------------------------------------------------
-- Register
--------------------------------------------------
addon.ModuleManager:Register(
  "PetConfirmation",
  PetConfirmation
)
