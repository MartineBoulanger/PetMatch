local _, addon = ...

local L = addon.L
local RandomPetsButton = {}

local BUTTON_SIZE = 24

local RANDOM_ICON = "Interface\\Buttons\\UI-Grouploot-Dice-Up"

local function GetRandomAbilityIDs(petGUID)
  local petService = addon.Services.PetJournal

  if not petService then
    return {}
  end

  local pet = petService:GetPet(petGUID)

  if not pet or not pet.speciesID then
    return {}
  end

  local abilityIDs = {}
  local abilityLevels = {}

  C_PetJournal.GetPetAbilityList(
    pet.speciesID,
    abilityIDs,
    abilityLevels
  )

  local result = {}

  for abilitySlot = 1, 3 do
    local first =
        abilityIDs[
        abilitySlot
        ]

    local second =
        abilityIDs[
        abilitySlot + 3
        ]

    local choices = {}

    if first then
      choices[#choices + 1] = first
    end

    if second then
      local requiredLevel =
          tonumber(
            abilityLevels[
            abilitySlot + 3
            ]
          )
          or 0

      local petLevel =
          tonumber(
            pet.level
          )
          or 0

      if petLevel >= requiredLevel then
        choices[
        #choices + 1
        ] = second
      end
    end

    if #choices > 0 then
      result[abilitySlot] =
          choices[
          math.random(
            1,
            #choices
          )
          ]
    end
  end

  return result
end

local function GetRandomPets()
  local petService = addon.Services.PetJournal

  if not petService then
    return nil, L["JOURNAL_ERROR"]
  end

  petService:EnsureIndex()

  local cache = petService:GetAll()

  if type(cache) ~= "table" then
    return nil, L["JOURNAL_ERROR"]
  end

  local candidates = {}

  for petGUID, pet in pairs(cache) do
    if type(petGUID) == "string"
        and type(pet) == "table"
        and pet.canBattle == true then
      candidates[#candidates + 1] = petGUID
    end
  end

  if #candidates < 3 then
    return nil, L["NEED_3_PETS"]
  end

  for index = 1, 3 do
    local randomIndex = math.random(index, #candidates)

    candidates[index],
    candidates[randomIndex] = candidates[randomIndex], candidates[index]
  end

  return {
    candidates[1],
    candidates[2],
    candidates[3],
  }
end

function RandomPetsButton:LoadRandomPets()
  if C_PetBattles.IsInBattle() then
    addon.Logger:Warn(
      L["CANNOT_CHANGE"]
    )

    return false
  end

  if InCombatLockdown() then
    addon.Logger:Warn(
      L["CANNOT_SWITCH"]
    )

    return false
  end

  local pets, errorMessage = GetRandomPets()

  if not pets then
    addon.Logger:Warn(
      errorMessage
      or L["UNABLE_RANDOM_PET"]
    )

    return false
  end

  local abilities = {}

  for slot = 1, 3 do
    abilities[slot] = GetRandomAbilityIDs(pets[slot])
  end

  local success, loadError =
      addon.Services.BattleSlot:LoadPets(pets, abilities, {})

  if not success then
    addon.Logger:Warn(
      loadError
      or L["UNABLE_LOAD_PET"]
    )

    return false
  end

  return true
end

function RandomPetsButton:Create()
  if self.Frame then
    return self.Frame
  end

  if not PetJournal then
    return nil
  end

  local button =
      CreateFrame(
        "Button",
        "PetMatchRandomPetsButton",
        PetJournal
      )

  button:SetSize(
    BUTTON_SIZE,
    BUTTON_SIZE
  )

  button.Icon = button:CreateTexture(nil, "ARTWORK")

  button.Icon:SetPoint(
    "CENTER"
  )

  button.Icon:SetSize(
    21,
    21
  )

  button.Icon:SetTexture(
    RANDOM_ICON
  )

  button:SetHighlightTexture(
    "Interface\\Buttons\\ButtonHilight-Square",
    "ADD"
  )

  local firstSlot = _G.PetJournalLoadoutPet1

  if firstSlot then
    button:SetPoint(
      "BOTTOMRIGHT",
      firstSlot,
      "TOPRIGHT",
      6,
      -1
    )
  else
    button:SetPoint(
      "TOPRIGHT",
      PetJournal,
      "TOPRIGHT",
      -22,
      -92
    )
  end

  button:SetScript(
    "OnClick",
    function()
      self:LoadRandomPets()
    end
  )

  button:SetScript(
    "OnEnter",
    function(control)
      GameTooltip:SetOwner(
        control,
        "ANCHOR_RIGHT"
      )

      GameTooltip:SetText(
        "Random Battle Pets"
      )

      GameTooltip:AddLine(
        "Loads three random owned battle pets with random abilities.",
        1,
        1,
        1,
        true
      )

      GameTooltip:Show()
    end
  )

  button:SetScript(
    "OnLeave",
    function()
      GameTooltip:Hide()
    end
  )

  self.Frame = button

  return button
end

function RandomPetsButton:Show()
  local button = self:Create()

  if button then
    button:Show()
  end
end

function RandomPetsButton:Hide()
  if self.Frame then
    self.Frame:Hide()
  end
end

addon.UI.Actions.RandomPetsButton = RandomPetsButton
