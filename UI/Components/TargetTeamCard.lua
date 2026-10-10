local _, addon = ...

local L = addon.L

local TargetTeamCard = {}

TargetTeamCard.Frame = nil

local function CreatePetIcon(parent)
  local button = CreateFrame("Button", nil, parent)

  button:SetSize(24, 24)

  local icon = button:CreateTexture(nil, "ARTWORK")
  icon:SetAllPoints()

  button.Icon = icon

  --------------------------------------------------
  -- Rarity border
  --------------------------------------------------
  local rarityBorder = CreateFrame(
    "Frame",
    nil,
    button,
    "BackdropTemplate"
  )

  rarityBorder:SetAllPoints(button)

  rarityBorder:SetBackdrop({
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 8,
    insets = {
      left = 0,
      right = 0,
      top = 0,
      bottom = 0,
    },
  })

  rarityBorder:SetFrameLevel(button:GetFrameLevel() + 1)
  rarityBorder:EnableMouse(false)
  rarityBorder:Hide()

  button.RarityBorder = rarityBorder

  return button
end

local function SetPetRarityBorder(button, quality)
  local color = addon.Constants.PET_RARITY_COLORS[quality]

  if not color then
    button.RarityBorder:Hide()
    return
  end

  button.RarityBorder:SetBackdropBorderColor(
    color.r,
    color.g,
    color.b,
    1
  )

  button.RarityBorder:Show()
end

function TargetTeamCard:Initialize()
  if self.Frame then
    return
  end

  if not PetJournalLoadoutBorder then
    return
  end

  local frame = CreateFrame(
    "Frame",
    "PetMatchTargetTeamCard",
    PetJournalLoadoutBorder,
    "BackdropTemplate"
  )

  frame:SetSize(330, 28)

  frame:SetPoint(
    "BOTTOM",
    PetJournalLoadoutBorder,
    "TOP",
    0,
    12
  )

  frame:SetBackdrop({
    bgFile = "Interface\\FrameGeneral\\UI-Background-Marble",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 128,
    edgeSize = 8,
    insets = {
      left = 1,
      right = 1,
      top = 1,
      bottom = 1,
    },
  })

  frame:SetBackdropBorderColor(0.35, 0.35, 0.35, 1.00)

  --------------------------------------------------
  -- Enemy pets
  --------------------------------------------------
  frame.EnemyPets = {}

  for index = 1, 3 do
    local pet = CreatePetIcon(frame)

    pet:SetPoint(
      "LEFT",
      frame,
      "LEFT",
      2 + ((index - 1) * 24),
      0
    )

    frame.EnemyPets[index] = pet
  end

  for index = 1, 3 do
    local button = frame.EnemyPets[index]

    addon.UI.Components.PetTooltip:Attach(
      button,
      function(control)
        if not control.speciesID then
          return nil
        end

        return "speciesID", control.speciesID
      end,
      "ANCHOR_RIGHT",
      "targets"
    )
  end

  --------------------------------------------------
  -- Target name
  --------------------------------------------------
  local targetName = frame:CreateFontString(
    nil, "OVERLAY", "GameFontNormal"
  )

  targetName:SetPoint(
    "CENTER",
    frame,
    "CENTER",
    0,
    0
  )

  targetName:SetText(L["TEST_NPC"])
  frame.TargetName = targetName

  local suggestedHint = frame:CreateFontString(
    nil,
    "OVERLAY",
    "GameFontHighlightSmall"
  )

  suggestedHint:SetPoint(
    "TOPRIGHT",
    frame,
    "TOPRIGHT",
    -2,
    -27
  )

  suggestedHint:SetWidth(72)
  suggestedHint:SetJustifyH("CENTER")
  suggestedHint:SetText(L['CLICK_TO_LOAD'])
  suggestedHint:Hide()

  frame.SuggestedHint = suggestedHint

  --------------------------------------------------
  -- Team pets
  --------------------------------------------------
  frame.TeamPets = {}

  for index = 1, 3 do
    local pet = CreatePetIcon(frame)

    pet:SetPoint(
      "RIGHT",
      frame,
      "RIGHT",
      -2 - ((index - 1) * 24),
      0
    )

    frame.TeamPets[index] = pet
  end

  for index = 1, 3 do
    local button = frame.TeamPets[index]

    --------------------------------------------------
    -- Pet Card
    --------------------------------------------------
    addon.UI.Components.PetTooltip:Attach(
      button,
      function(control)
        if not control.petGUID then
          return nil
        end

        return "petGUID", control.petGUID
      end,
      "ANCHOR_LEFT",
      "targets",
      function()
        if TargetTeamCard.Mode == "suggested" then
          local pet = TargetTeamCard.SuggestedPets
              and TargetTeamCard.SuggestedPets[index]

          return pet and pet.suggestedAbilities or nil
        end

        local team = TargetTeamCard.SavedTeam

        if team and type(team.abilities) == "table" then
          return team.abilities[index]
        end

        local abilities = TargetTeamCard.LoadedSuggestedAbilities

        return abilities and abilities[index] or nil
      end
    )

    --------------------------------------------------
    -- Suggested pets use left click to load team,
    -- so PetTooltip may not pin on that click.
    --------------------------------------------------
    addon.UI.Components.PetTooltip:SetClickBlocker(
      button,
      function()
        return TargetTeamCard.Mode == "suggested"
      end
    )

    --------------------------------------------------
    -- Load suggested team
    --------------------------------------------------
    button:SetScript(
      "OnClick",
      function()
        if TargetTeamCard.Mode ~= "suggested" then
          return
        end
        TargetTeamCard:LoadSuggestedTeam()
      end
    )
  end

  self.Frame = frame

  addon.EventBus:Register(
    addon.Events.TEAM_LOADED,
    function(team)
      TargetTeamCard:SetSavedTeam(team)
    end
  )

  addon.EventBus:Register(
    addon.Events.DATABASE_READY,
    function()
      TargetTeamCard:RefreshActiveTeam()
    end
  )
end

function TargetTeamCard:RefreshActiveTeam()
  if not self.Frame or not addon.DB then
    return
  end

  local teamService = addon.Services.Team

  if teamService then
    self:SetSavedTeam(teamService:GetActive())
  end
end

function TargetTeamCard:SetTarget(npcID)
  if not self.Frame then
    return
  end

  local targetService = addon.Services.PetBattleTarget
  local target = targetService and targetService:GetByNPCID(npcID)

  if not target then
    self.Frame:Hide()
    return
  end

  --------------------------------------------------
  -- Target name
  --------------------------------------------------
  local targetName =
      targetService:GetDisplayName(npcID) or tostring(npcID)

  self.Frame.TargetName:SetText(targetName)

  --------------------------------------------------
  -- Enemy pets
  --------------------------------------------------
  local pets = targetService:GetPets(target)

  for index = 1, 3 do
    local button = self.Frame.EnemyPets[index]
    local pet = pets[index]

    if pet and pet.speciesID then
      local icon = targetService:GetPetIcon(pet.speciesID)

      button.speciesID = pet.speciesID
      button.Icon:SetTexture(icon)
      button:Show()
    else
      button.speciesID = nil
      button.Icon:SetTexture(nil)
      button:Hide()
    end
  end

  self.Frame:Show()
end

function TargetTeamCard:SetSavedTeam(team)
  if not self.Frame then
    return
  end

  self.SavedTeam = type(team) == "table" and team or nil

  self.Mode = nil
  self.SuggestedPets = nil
  self.TargetNPCID = nil
  self.LoadedSuggestedAbilities = nil

  if self.Frame.SuggestedButton then
    self.Frame.SuggestedButton:Hide()
  end

  if self.Frame.SuggestedHint then
    self.Frame.SuggestedHint:Hide()
  end

  if type(team) ~= "table" then
    self.Frame:Hide()
    return
  end

  local npcID = type(team.targetNPCIDs) == "table"
      and tonumber(team.targetNPCIDs[1])

  if not npcID then
    self.Frame:Hide()
    return
  end

  --------------------------------------------------
  -- Target
  --------------------------------------------------
  self:SetTarget(npcID)

  if not self.Frame:IsShown() then
    return
  end

  --------------------------------------------------
  -- Loaded team pets
  --------------------------------------------------
  local battleSlotService = addon.Services.BattleSlot
  local petJournalService = addon.Services.PetJournal

  for slot = 1, 3 do
    local button = self.Frame.TeamPets[slot]

    local petGUID = battleSlotService
        and battleSlotService:GetSlot(slot)

    local pet = petGUID and petJournalService
        and petJournalService:GetPet(petGUID)

    if pet and pet.icon then
      button.petGUID = petGUID
      button.speciesID = pet.speciesID
      button.pet = pet

      button.Icon:SetTexture(pet.icon)

      local _, _, _, _, quality = C_PetJournal.GetPetStats(petGUID)
      SetPetRarityBorder(button, quality)

      button:Show()
    else
      button.petGUID = nil
      button.speciesID = nil
      button.pet = nil

      button.Icon:SetTexture(nil)
      SetPetRarityBorder(button, nil)
      button:Hide()
    end
  end
end

function TargetTeamCard:SetSuggestedTarget(npcID)
  if not self.Frame then
    return
  end

  self.SavedTeam = nil
  self.LoadedSuggestedAbilities = nil

  npcID = tonumber(npcID)

  if not npcID then
    self.Frame:Hide()
    return
  end

  self:SetTarget(npcID)

  if not self.Frame:IsShown() then
    return
  end

  local suggestedTeamService = addon.Services.SuggestedTeam

  if not suggestedTeamService then
    return
  end

  local pets = suggestedTeamService:GetForTarget(npcID)

  for slot = 1, 3 do
    local button = self.Frame.TeamPets[slot]
    local pet = pets[slot]

    if pet and pet.icon then
      button.petGUID = pet.petGUID
      button.speciesID = pet.speciesID

      button.Icon:SetTexture(pet.icon)

      local quality

      if pet.petGUID then
        local _, _, _, _, petQuality =
            C_PetJournal.GetPetStats(pet.petGUID)

        quality = petQuality
      end

      SetPetRarityBorder(button, quality)

      button:Show()
    else
      button.petGUID = nil
      button.speciesID = nil

      button.Icon:SetTexture(nil)
      SetPetRarityBorder(button, nil)
      button:Hide()
    end
  end

  self.SuggestedPets = pets
  self.Mode = "suggested"
  self.TargetNPCID = npcID

  if self.Frame.SuggestedButton then
    self.Frame.SuggestedButton:Show()
  end

  if self.Frame.SuggestedHint then
    self.Frame.SuggestedHint:Show()
  end
end

function TargetTeamCard:HandleTargetChanged(result)
  if not self.Frame then
    return
  end

  if type(result) ~= "table" or not result.npcID then
    return
  end

  if result.type ~= "none" then
    return
  end

  local targetService = addon.Services.PetBattleTarget

  local target = targetService
      and targetService:GetByNPCID(result.npcID)

  if not target then
    self:ClearSuggestedTarget()
    return
  end

  self:SetSuggestedTarget(
    result.npcID
  )
end

function TargetTeamCard:Clear()
  if not self.Frame then
    return
  end

  self.Mode = nil
  self.TargetNPCID = nil
  self.SuggestedPets = nil
  self.SavedTeam = nil
  self.LoadedSuggestedAbilities = nil

  if self.Frame.SuggestedHint then
    self.Frame.SuggestedHint:Hide()
  end

  for index = 1, 3 do
    local enemyPet = self.Frame.EnemyPets[index]
    local teamPet = self.Frame.TeamPets[index]

    enemyPet.speciesID = nil
    enemyPet.Icon:SetTexture(nil)
    enemyPet:Hide()

    teamPet.petGUID = nil
    teamPet.speciesID = nil
    teamPet.pet = nil
    teamPet.Icon:SetTexture(nil)
    SetPetRarityBorder(enemyPet, nil)
    SetPetRarityBorder(teamPet, nil)
    teamPet:Hide()
  end

  self.Frame:Hide()
end

function TargetTeamCard:ClearSuggestedTarget()
  if not self.Frame then
    return
  end

  if self.Mode ~= "suggested" then
    return
  end

  self.Mode = nil
  self.TargetNPCID = nil
  self.SuggestedPets = nil

  if self.Frame.SuggestedButton then
    self.Frame.SuggestedButton:Hide()
  end

  if self.Frame.SuggestedHint then
    self.Frame.SuggestedHint:Hide()
  end

  self.Frame:Hide()
end

function TargetTeamCard:LoadSuggestedTeam()
  if self.Mode ~= "suggested" then
    return
  end

  local suggestedPets = self.SuggestedPets

  if type(suggestedPets) ~= "table" then
    return
  end

  local battleSlotService = addon.Services.BattleSlot
  local teamSetupService = addon.Services.TeamSetup

  if not battleSlotService then
    return
  end

  local pets = {}
  local abilities = {}

  for slot = 1, 3 do
    local pet = suggestedPets[slot]

    if pet and pet.petGUID then
      pets[slot] = pet.petGUID
      abilities[slot] = pet.suggestedAbilities or {}
    end
  end

  local success, errorMessage =
      battleSlotService:LoadPets(pets, abilities, nil, false)

  if not success then
    if errorMessage then
      addon.Logger:Warn(errorMessage)
    end
    return
  end

  self.LoadedSuggestedAbilities = abilities

  --------------------------------------------------
  -- Suggested team is now loaded
  --------------------------------------------------
  if self.Frame.SuggestedHint then
    self.Frame.SuggestedHint:Hide()
  end

  self.Mode = nil
  self.SuggestedPets = nil
  self.TargetNPCID = nil

  addon.Blizzard:UpdateLoadoutTitle(nil)

  --------------------------------------------------
  -- Suggested pets are concrete physical pets.
  --
  -- Remove any previous random / levelling state
  -- from the Team Setup slots.
  --------------------------------------------------
  if teamSetupService then
    for slot = 1, 3 do
      teamSetupService:SetNormalSlot(slot)
    end
  end
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")

loader:SetScript(
  "OnEvent",
  function(self, _, addonName)
    if addonName ~= "Blizzard_Collections" then
      return
    end

    TargetTeamCard:Initialize()
    TargetTeamCard:RefreshActiveTeam()

    self:UnregisterEvent("ADDON_LOADED")
  end
)

if C_AddOns.IsAddOnLoaded("Blizzard_Collections") then
  TargetTeamCard:Initialize()
  TargetTeamCard:RefreshActiveTeam()
end

addon.UI.Components.TargetTeamCard = TargetTeamCard
