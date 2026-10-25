local _, addon = ...

local SummonedPetService = {}

local MAX_DETECTION_ATTEMPTS = 30
local DETECTION_DELAY = 0.1

local MAX_DISMISS_ATTEMPTS = 5
local DISMISS_RETRY_DELAY = 0.5

SummonedPetService.OperationID = 0
SummonedPetService.PreviousPetGUID = nil
SummonedPetService.RestorePending = false

--------------------------------------------------
-- Settings
--------------------------------------------------
function SummonedPetService:GetMode()
  return addon.Settings:Get("summonedPetMode") or "keep"
end

--------------------------------------------------
-- Current summoned pet
--------------------------------------------------
function SummonedPetService:GetSummonedPetGUID()
  return C_PetJournal.GetSummonedPetGUID()
end

--------------------------------------------------
-- Cancel pending operation
--------------------------------------------------
function SummonedPetService:Cancel()
  self.OperationID = self.OperationID + 1
end

--------------------------------------------------
-- Check whether operation is still valid
--------------------------------------------------
function SummonedPetService:IsCurrent(operationID, petGUID)
  if self.OperationID ~= operationID then
    return false
  end

  if self:GetMode() ~= "dismiss" then
    return false
  end

  if InCombatLockdown() or C_PetBattles.IsInBattle() then
    return false
  end

  local currentSlotGUID = C_PetJournal.GetPetLoadOutInfo(1)

  return currentSlotGUID == petGUID
end

--------------------------------------------------
-- Check species
--------------------------------------------------
function SummonedPetService:IsSameSpecies(guidA, guidB)
  if not guidA or not guidB then
    return false
  end

  if guidA == guidB then
    return true
  end

  local speciesA = C_PetJournal.GetPetInfoByPetID(guidA)
  local speciesB = C_PetJournal.GetPetInfoByPetID(guidB)

  return speciesA ~= nil and speciesB ~= nil and speciesA == speciesB
end

--------------------------------------------------
-- Dismiss and verify
--------------------------------------------------
function SummonedPetService:TryDismiss(expectedGUID, operationID, attempt)
  if not self:IsCurrent(operationID, expectedGUID) then
    return
  end

  local summonedGUID = self:GetSummonedPetGUID()

  -- Already dismissed.
  if not summonedGUID then
    return
  end

  -- Do not dismiss an unrelated companion.
  if not self:IsSameSpecies(summonedGUID, expectedGUID) then
    return
  end

  C_PetJournal.SummonPetByGUID(summonedGUID)

  C_Timer.After(DISMISS_RETRY_DELAY, function()
    if not self:IsCurrent(operationID, expectedGUID) then
      return
    end

    local currentGUID = self:GetSummonedPetGUID()

    if not currentGUID then
      return
    end

    if not self:IsSameSpecies(currentGUID, expectedGUID) then
      return
    end

    if attempt >= MAX_DISMISS_ATTEMPTS then
      addon.Logger:Info("Auto Dismiss could not dismiss the summoned pet.")
      return
    end

    self:TryDismiss(expectedGUID, operationID, attempt + 1)
  end)
end

--------------------------------------------------
-- Wait for Blizzard to summon slot 1
--------------------------------------------------
function SummonedPetService:WaitForSummon(expectedGUID, operationID, attempt)
  if not self:IsCurrent(operationID, expectedGUID) then
    return
  end

  local summonedGUID = self:GetSummonedPetGUID()

  if summonedGUID
      and self:IsSameSpecies(summonedGUID, expectedGUID) then
    self:TryDismiss(expectedGUID, operationID, 1)
    return
  end

  if attempt >= MAX_DETECTION_ATTEMPTS then
    return
  end

  C_Timer.After(DETECTION_DELAY, function()
    self:WaitForSummon(expectedGUID, operationID, attempt + 1)
  end)
end

--------------------------------------------------
-- Remember previous summoned pet
--------------------------------------------------
function SummonedPetService:RememberPreviousPet(previousPetGUID)
  if self:GetMode() ~= "restore" then
    self.PreviousPetGUID = nil
    self.RestorePending = false
    return
  end

  -- Never overwrite the original companion
  -- while a restore operation is pending.
  if self.RestorePending then
    return
  end

  -- Remember the original companion.
  self.PreviousPetGUID = previousPetGUID
  self.RestorePending = true
end

--------------------------------------------------
-- Restore previous companion
--------------------------------------------------
function SummonedPetService:RestorePreviousPet(operationID, attempt)
  if self.OperationID ~= operationID then
    return
  end

  if self:GetMode() ~= "restore" then
    return
  end

  local previousGUID = self.PreviousPetGUID

  if not previousGUID then
    self.RestorePending = false
    return
  end

  local currentGUID = self:GetSummonedPetGUID()

  if currentGUID == previousGUID then
    self.RestorePending = false
    return
  end

  if currentGUID then
    return
  end

  if attempt > 5 then
    self.RestorePending = false
    addon.Logger:Info(
      "Restore Previous Pet could not restore the companion."
    )
    return
  end

  C_PetJournal.SummonPetByGUID(previousGUID)

  C_Timer.After(0.5, function()
    self:RestorePreviousPet(operationID, attempt + 1)
  end)
end

--------------------------------------------------
-- Dismiss pet before restoring previous companion
--------------------------------------------------
function SummonedPetService:DismissForRestore(
    expectedGUID, operationID, attempt
)
  if self.OperationID ~= operationID then
    return
  end

  if self:GetMode() ~= "restore" then
    return
  end

  local currentGUID = self:GetSummonedPetGUID()
  local previousGUID = self.PreviousPetGUID

  if previousGUID and currentGUID == previousGUID then
    self.RestorePending = false
    return
  end

  -- The new companion has been dismissed.
  if not currentGUID then
    self:RestorePreviousPet(operationID, 1)
    return
  end

  -- Do not dismiss an unrelated companion.
  if not self:IsSameSpecies(currentGUID, expectedGUID) then
    return
  end

  if attempt > MAX_DISMISS_ATTEMPTS then
    self.RestorePending = false
    addon.Logger:Info("Restore Previous Pet could not dismiss the new companion.")
    return
  end

  -- Toggle the currently summoned companion off.
  C_PetJournal.SummonPetByGUID(currentGUID)

  C_Timer.After(DISMISS_RETRY_DELAY, function()
    if self.OperationID ~= operationID then
      return
    end

    self:DismissForRestore(expectedGUID, operationID, attempt + 1)
  end)
end

--------------------------------------------------
-- Wait for automatically summoned companion
--------------------------------------------------
function SummonedPetService:WaitForRestoreSummon(
    expectedGUID, operationID, attempt
)
  if self.OperationID ~= operationID then
    return
  end

  if self:GetMode() ~= "restore" then
    return
  end

  local currentGUID = self:GetSummonedPetGUID()
  local previousGUID = self.PreviousPetGUID

  if currentGUID
      and previousGUID
      and currentGUID == previousGUID
      and attempt >= MAX_DETECTION_ATTEMPTS then
    -- Keep the original companion protected.
    self.RestorePending = true
    return
  end

  if currentGUID and self:IsSameSpecies(currentGUID, expectedGUID) then
    self:DismissForRestore(expectedGUID, operationID, 1)
    return
  end

  if attempt >= 30 then
    self.RestorePending = false
    return
  end

  C_Timer.After(0.1, function()
    self:WaitForRestoreSummon(
      expectedGUID,
      operationID,
      attempt + 1
    )
  end)
end

--------------------------------------------------
-- Handle slot 1 change
--------------------------------------------------
function SummonedPetService:HandleSlotOneChange(petGUID)
  self:Cancel()

  if self:GetMode() ~= "dismiss" then
    return
  end

  if not petGUID or petGUID == "" then
    return
  end

  local operationID = self.OperationID

  self:WaitForSummon(
    petGUID,
    operationID,
    1
  )
end

--------------------------------------------------
-- Handle team loading
--------------------------------------------------
function SummonedPetService:HandleTeamLoad(
    petGUID, previousSummonedPetGUID
)
  local mode = self:GetMode()

  if mode == "dismiss" then
    self:HandleSlotOneChange(petGUID)
    return
  end

  self:Cancel()

  if mode ~= "restore" then
    self.PreviousPetGUID = nil
    self.RestorePending = false
    return
  end

  if not petGUID or petGUID == "" then
    self.RestorePending = false
    return
  end

  self:RememberPreviousPet(previousSummonedPetGUID)

  local operationID = self.OperationID

  self:WaitForRestoreSummon(
    petGUID,
    operationID,
    1
  )
end

--------------------------------------------------
-- Handle manual slot 1 changes
--------------------------------------------------
function SummonedPetService:HandleManualSlotChange(
    petGUID, previousSummonedPetGUID
)
  self:HandleTeamLoad(
    petGUID,
    previousSummonedPetGUID
  )
end

--------------------------------------------------
-- Register service
--------------------------------------------------
addon.Services.SummonedPet = SummonedPetService
