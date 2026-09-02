local _, addon = ...

local PetJournalToolbar = {}

local BUTTON_SIZE = 40
local BUTTON_SPACING = 5
local SAFARI_HAT_TOY_ID = 92738
local SAFARI_HAT_BUFF_ID = 158486
local BATTLE_PET_BANDAGE_ITEM_ID = 86143

local function FindHealButton()
  return PetJournal
      and (
        PetJournal.HealPetSpellFrame
        or PetJournal.HealPetButton
        or PetJournal.HealButton
      )
      or _G.PetJournalHealPetSpellFrame
      or _G.PetJournalHealPetButton
      or _G.PetJournalHealButton
end

local function FindRandomFavoriteButton()
  return PetJournal
      and (
        PetJournal.SummonRandomPetSpellFrame
        or PetJournal.SummonRandomFavoritePetButton
        or PetJournal.SummonRandomFavoriteButton
        or PetJournal.SummonRandomPetButton
      )
      or _G.PetJournalSummonRandomPetSpellFrame
      or _G.PetJournalSummonRandomFavoritePetButton
      or _G.PetJournalSummonRandomFavoriteButton
      or _G.PetJournalSummonRandomPetButton
end

local function HideFontStrings(frame)
  if not frame then
    return
  end

  for _, region in ipairs({
    frame:GetRegions()
  }) do
    if region
        and region:GetObjectType()
        == "FontString" then
      region:Hide()
    end
  end

  for _, child in ipairs({
    frame:GetChildren()
  }) do
    HideFontStrings(child)
  end
end

local function FindHealIconButton()
  local healFrame = FindHealButton()
  return healFrame
      and healFrame.Button
end

local function GetToolbarButtonSize()
  local sourceButton = FindHealIconButton()

  if sourceButton then
    local width = sourceButton:GetWidth()
    local height = sourceButton:GetHeight()

    if width
        and width > 0
        and height
        and height > 0 then
      return width, height
    end
  end

  return 32, 32
end

local function CreateToolbarIconButton(parent, options)
  options = options or {}

  local width,
  height = GetToolbarButtonSize()

  options.width = options.width or width
  options.height = options.height or height
  options.styleSource = FindHealIconButton()

  return addon.UI.Components.ToolbarIconButton:Create(parent, options)
end

local function AddBlizzardBorder(button)
  if not button then
    return
  end

  local healFrame = FindHealButton()
  local sourceBorder = healFrame and healFrame.Border

  if not sourceBorder then
    -- addon.Logger:Warn("Heal Pet border was not found")
    return
  end

  local border =
      button:CreateTexture(
        nil,
        "OVERLAY",
        nil,
        7
      )

  local atlas =
      sourceBorder.GetAtlas
      and sourceBorder:GetAtlas()

  if atlas then
    border:SetAtlas(
      atlas,
      false
    )
  else
    local texture = sourceBorder:GetTexture()

    if texture then
      border:SetTexture(texture)
    end

    border:SetTexCoord(
      sourceBorder:GetTexCoord()
    )
  end

  local borderWidth = sourceBorder:GetWidth()
  local borderHeight = sourceBorder:GetHeight()

  if borderWidth
      and borderWidth > 0
      and borderHeight
      and borderHeight > 0 then
    border:SetSize(
      borderWidth,
      borderHeight
    )
  else
    border:SetSize(
      button:GetWidth() + 8,
      button:GetHeight() + 8
    )
  end

  border:ClearAllPoints()
  border:SetPoint(
    "CENTER",
    button,
    "CENTER",
    0,
    0
  )

  border:SetVertexColor(
    sourceBorder:GetVertexColor()
  )

  border:SetAlpha(
    sourceBorder:GetAlpha()
  )

  border:Show()

  button.Border = border
end

local function IsSafariHatActive()
  return C_UnitAuras.GetPlayerAuraBySpellID(
    SAFARI_HAT_BUFF_ID
  ) ~= nil
end

local function GetSafariHatIcon()
  local spellInfo =
      C_Spell.GetSpellInfo(
        SAFARI_HAT_BUFF_ID
      )

  if spellInfo then
    return spellInfo.iconID
  end

  local _, _, toyIcon =
      C_ToyBox.GetToyInfo(
        SAFARI_HAT_TOY_ID
      )

  return toyIcon
end

local function GetSafariHatName()
  local spellInfo =
      C_Spell.GetSpellInfo(
        SAFARI_HAT_BUFF_ID
      )

  if spellInfo then
    return spellInfo.name
  end

  return "Safari Hat"
end

local function CreateSafariHatButton(
    parent,
    name,
    texture
)
  local button =
      CreateFrame(
        "Button",
        name,
        parent,
        "SecureActionButtonTemplate"
      )

  local width, height =
      GetToolbarButtonSize()

  button:SetSize(width, height)

  button:RegisterForClicks(
    "AnyUp",
    "AnyDown"
  )

  button:SetAttribute(
    "useOnKeyDown",
    false
  )

  button.Icon =
      button:CreateTexture(
        nil,
        "ARTWORK"
      )

  button.Icon:SetAllPoints(button)
  button.Icon:SetTexture(texture)
  button.Icon:SetTexCoord(0, 1, 0, 1)

  addon.UI.Components.ToolbarIconButton:ApplyStyle(
    button,
    FindHealIconButton()
  )

  AddBlizzardBorder(button)

  button.RemoveOverlay =
      button:CreateTexture(
        nil,
        "OVERLAY"
      )

  button.RemoveOverlay:SetAtlas(
    "common-icon-redx"
  )

  button.RemoveOverlay:SetSize(25, 25)

  button.RemoveOverlay:SetPoint(
    "TOPRIGHT",
    -4,
    -4
  )

  button.RemoveOverlay:Hide()

  button:SetScript(
    "OnEnter",
    function(self)
      addon.UI.Components.ToolbarIconButton:ShowTooltip(
        self,
        self.TooltipTitle,
        self.TooltipDescription
      )
    end
  )

  button:SetScript(
    "OnLeave",
    function()
      GameTooltip:Hide()
    end
  )

  return button
end

local function CreateBandageButton(
    parent,
    name,
    texture
)
  local button =
      CreateFrame(
        "Button",
        name,
        parent,
        "SecureActionButtonTemplate"
      )

  local width, height =
      GetToolbarButtonSize()

  button:SetSize(width, height)

  button:RegisterForClicks(
    "AnyUp",
    "AnyDown"
  )

  button:SetAttribute(
    "useOnKeyDown",
    false
  )

  button:SetAttribute(
    "type",
    "item"
  )

  button:SetAttribute(
    "item",
    "item:" .. BATTLE_PET_BANDAGE_ITEM_ID
  )

  button.Icon =
      button:CreateTexture(
        nil,
        "ARTWORK"
      )

  button.Icon:SetAllPoints(button)
  button.Icon:SetTexture(texture)
  button.Icon:SetTexCoord(0, 1, 0, 1)

  addon.UI.Components.ToolbarIconButton:ApplyStyle(
    button,
    FindHealIconButton()
  )

  AddBlizzardBorder(button)

  button.Count =
      button:CreateFontString(
        nil,
        "OVERLAY",
        "NumberFontNormal"
      )

  button.Count:SetPoint(
    "BOTTOMRIGHT",
    button,
    "BOTTOMRIGHT",
    -2,
    2
  )

  button.TooltipTitle = "Battle Pet Bandage"
  button.TooltipDescription = "Heals and resurrects all of your battle pets to 100% health."

  button:SetScript(
    "OnEnter",
    function(self)
      addon.UI.Components.ToolbarIconButton:ShowTooltip(
        self,
        self.TooltipTitle,
        self.TooltipDescription
      )
    end
  )

  button:SetScript(
    "OnLeave",
    function()
      GameTooltip:Hide()
    end
  )

  return button
end

function PetJournalToolbar:SetButtonEnabled(
    button,
    enabled
)
  if not button then
    return
  end

  local canToggle =
      not (button:IsProtected()
        and InCombatLockdown())

  if enabled then
    if canToggle then
      button:Enable()
    end

    if button.Icon then
      button.Icon:SetDesaturated(false)
      button.Icon:SetVertexColor(
        1,
        1,
        1
      )
      button.Icon:SetAlpha(1)
    end

    if button.Border then
      button.Border:SetDesaturated(false)
      button.Border:SetVertexColor(
        1,
        1,
        1
      )
      button.Border:SetAlpha(1)
    end
  else
    if canToggle then
      button:Disable()
    end

    if button.Icon then
      button.Icon:SetDesaturated(true)
      button.Icon:SetVertexColor(
        0.6,
        0.6,
        0.6
      )
      button.Icon:SetAlpha(0.65)
    end

    if button.Border then
      button.Border:SetDesaturated(true)
      button.Border:SetVertexColor(
        0.65,
        0.65,
        0.65
      )
      button.Border:SetAlpha(0.75)
    end
  end

  return canToggle
end

function PetJournalToolbar:UpdateSafariHatButton()
  local button = self.SafariHatButton

  if not button then
    return
  end

  local hasToy =
      PlayerHasToy(
        SAFARI_HAT_TOY_ID
      )

  local isActive =
      IsSafariHatActive()

  local safariHatName =
      GetSafariHatName()

  local stateApplied =
      self:SetButtonEnabled(
        button,
        hasToy
      )

  if isActive then
    button.RemoveOverlay:Show()

    button.TooltipTitle =
        "Remove " .. safariHatName

    button.TooltipDescription =
    "Remove the active Safari Hat buff."
  else
    button.RemoveOverlay:Hide()

    button.TooltipTitle =
        "Use " .. safariHatName

    if hasToy then
      button.TooltipDescription =
      "Use the Safari Hat toy."
    else
      button.TooltipDescription =
      "You have not collected the Safari Hat toy."
    end
  end

  if not stateApplied
      or InCombatLockdown() then
    self.SafariHatUpdatePending = true
    return
  end

  self.SafariHatUpdatePending = false

  if isActive then
    button:SetAttribute(
      "type",
      "cancelaura"
    )

    button:SetAttribute(
      "unit",
      "player"
    )

    button:SetAttribute(
      "spell",
      safariHatName
    )

    button:SetAttribute(
      "toy",
      nil
    )
  else
    button:SetAttribute(
      "type",
      "toy"
    )

    button:SetAttribute(
      "toy",
      SAFARI_HAT_TOY_ID
    )

    button:SetAttribute(
      "spell",
      nil
    )

    button:SetAttribute(
      "unit",
      nil
    )
  end
end

function PetJournalToolbar:UpdateDismissButton()
  if not self.DismissButton then
    return
  end

  local summonedPetGUID = C_PetJournal.GetSummonedPetGUID()

  self:SetButtonEnabled(
    self.DismissButton,
    type(summonedPetGUID) == "string"
    and summonedPetGUID ~= ""
  )
end

function PetJournalToolbar:AutoDismissPet(expectedPetGUID, attempt, generation)
  local mode =
      addon.Settings:Get("summonedPetMode")
      or "keep"

  if mode ~= "dismiss" then
    return
  end

  if not expectedPetGUID or expectedPetGUID == "" then
    return
  end

  --------------------------------------------------
  -- Stop if another team has been loaded meanwhile
  --------------------------------------------------
  if generation
      and addon.Services.BattleSlot
      and addon.Services.BattleSlot.LoadGeneration
      ~= generation then
    return
  end

  attempt = attempt or 1

  local summonedPetGUID = C_PetJournal.GetSummonedPetGUID()

  --------------------------------------------------
  -- Correct pet is now actually summoned
  --------------------------------------------------
  if summonedPetGUID == expectedPetGUID then
    local function FinalDismiss(attempt)
      local currentSummonedPetGUID = C_PetJournal.GetSummonedPetGUID()

      if currentSummonedPetGUID ~= expectedPetGUID then
        return
      end

      C_PetJournal.DismissSummonedPet(
        currentSummonedPetGUID
      )

      self:UpdateDismissButton()

      if attempt >= 3 then
        return
      end

      C_Timer.After(
        0.25,
        function()
          FinalDismiss(attempt + 1)
        end
      )
    end

    C_Timer.After(
      0.3,
      function()
        FinalDismiss(1)
      end
    )

    return
  end

  --------------------------------------------------
  -- Give Blizzard up to 3 seconds
  --------------------------------------------------
  if attempt >= 30 then
    return
  end

  C_Timer.After(
    0.1,
    function()
      self:AutoDismissPet(
        expectedPetGUID,
        attempt + 1,
        generation
      )
    end
  )
end

function PetJournalToolbar:DismissPet()
  local summonedPetGUID = C_PetJournal.GetSummonedPetGUID()

  if not summonedPetGUID then
    self:UpdateDismissButton()
    return
  end

  C_PetJournal.SummonPetByGUID(summonedPetGUID)

  C_Timer.After(
    0.1,
    function()
      self:UpdateDismissButton()
    end
  )
end

function PetJournalToolbar:HandleManualSlotChange(slot, petGUID)
  if slot ~= 1 then
    return
  end

  if not petGUID or petGUID == "" then
    return
  end

  self:AutoDismissPet(
    petGUID,
    1
  )
end

function PetJournalToolbar:UpdateBandageButton()
  if not self.BandageButton then
    return
  end

  local count =
      C_Item.GetItemCount(
        BATTLE_PET_BANDAGE_ITEM_ID,
        false,
        false,
        false
      )

  if self.BandageButton.Count then
    if count > 0 then
      self.BandageButton.Count:SetText(count)
      self.BandageButton.Count:Show()
    else
      self.BandageButton.Count:SetText("")
      self.BandageButton.Count:Hide()
    end
  end

  self:SetButtonEnabled(
    self.BandageButton,
    count > 0
  )
end

function PetJournalToolbar:PositionButtons()
  if not self.SafariHatButton
      or not self.ImportButton
      or not self.ExportButton
      or not self.DismissButton
      or not self.BandageButton then
    return
  end

  local healButton = FindHealButton()
  local randomFavoriteButton = FindRandomFavoriteButton()
  randomFavoriteButton:SetSize(32, 32)
  healButton:SetSize(32, 32)

  self.SafariHatButton:ClearAllPoints()
  self.ImportButton:ClearAllPoints()
  self.ExportButton:ClearAllPoints()
  self.DismissButton:ClearAllPoints()
  self.BandageButton:ClearAllPoints()

  if randomFavoriteButton and healButton then
    self.DismissButton:SetPoint(
      "RIGHT",
      randomFavoriteButton,
      "LEFT",
      -BUTTON_SPACING,
      0
    )

    self.SafariHatButton:SetPoint(
      "RIGHT",
      self.DismissButton,
      "LEFT",
      -BUTTON_SPACING,
      0
    )

    self.BandageButton:SetPoint(
      "RIGHT",
      healButton,
      "LEFT",
      -BUTTON_SPACING,
      0
    )

    self.ImportButton:SetPoint(
      "RIGHT",
      self.BandageButton,
      "LEFT",
      -BUTTON_SPACING,
      0
    )

    self.ExportButton:SetPoint(
      "RIGHT",
      self.ImportButton,
      "LEFT",
      -BUTTON_SPACING,
      0
    )

    return
  end

  if randomFavoriteButton then
    self.DismissButton:SetPoint(
      "RIGHT",
      randomFavoriteButton,
      "LEFT",
      -BUTTON_SPACING,
      0
    )

    self.SafariHatButton:SetPoint(
      "RIGHT",
      self.DismissButton,
      "LEFT",
      -BUTTON_SPACING,
      0
    )

    self.BandageButton:SetPoint(
      "RIGHT",
      healButton,
      "LEFT",
      -BUTTON_SPACING,
      0
    )

    self.ImportButton:SetPoint(
      "RIGHT",
      self.BandageButton,
      "LEFT",
      -BUTTON_SPACING,
      0
    )

    self.ExportButton:SetPoint(
      "RIGHT",
      self.ImportButton,
      "LEFT",
      -BUTTON_SPACING,
      0
    )

    return
  end

  self.DismissButton:SetPoint(
    "RIGHT",
    randomFavoriteButton,
    "LEFT",
    -BUTTON_SPACING,
    0
  )


  self.SafariHatButton:SetPoint(
    "RIGHT",
    self.DismissButton,
    "LEFT",
    -BUTTON_SPACING,
    0
  )

  self.BandageButton:SetPoint(
    "RIGHT",
    healButton,
    "LEFT",
    -BUTTON_SPACING,
    0
  )

  self.ImportButton:SetPoint(
    "RIGHT",
    self.BandageButton,
    "LEFT",
    -BUTTON_SPACING,
    0
  )

  self.ExportButton:SetPoint(
    "RIGHT",
    self.ImportButton,
    "LEFT",
    -BUTTON_SPACING,
    0
  )
end

function PetJournalToolbar:Create()
  if self.Frame then
    return self.Frame
  end

  if not PetJournal then
    return nil
  end

  local frame =
      CreateFrame(
        "Frame",
        "PetMatchPetJournalToolbar",
        PetJournal
      )

  frame:SetSize(
    1,
    BUTTON_SIZE
  )

  self.Frame = frame

  self.BandageButton =
      CreateBandageButton(
        PetJournal,
        "PetMatchBattlePetBandageButton",
        C_Item.GetItemIconByID(
          BATTLE_PET_BANDAGE_ITEM_ID
        )
      )

  self.SafariHatButton =
      CreateSafariHatButton(
        PetJournal,
        "PetMatchSafariHatButton",
        GetSafariHatIcon()
      )

  local importControl =
      CreateToolbarIconButton(
        PetJournal,
        {
          name = "PetMatchImportButton",
          texture = "Interface\\AddOns\\PetMatch\\Media\\Import",
          tooltipTitle = "Import Team(s)",
          tooltipDescription = "Import Rematch team or a backup you made with Export.",
          onClick = function()
            addon.UI.Dialogs.ImportDialog:Show()
          end,
        }
      )

  self.ImportButton = importControl:GetFrame()

  local exportControl =
      CreateToolbarIconButton(
        PetJournal,
        {
          name = "PetMatchExportButton",
          texture = "Interface\\AddOns\\PetMatch\\Media\\Export",
          tooltipTitle = "Export Everything",
          tooltipDescription = "Export all folders with all teams - good for backup.",
          onClick = function()
            addon.UI.Dialogs.ExportDialog:ShowAll()
          end,
        }
      )

  self.ExportButton = exportControl:GetFrame()

  local dismissControl =
      CreateToolbarIconButton(
        PetJournal,
        {
          name = "PetMatchDismissPetButton",
          texture = "Interface\\AddOns\\PetMatch\\Media\\Dismiss",
          tooltipTitle = "Dismiss Pet",
          tooltipDescription = "Dismiss the pet that is currently summoned.",
          onClick = function()
            self:DismissPet()
          end,
        }
      )

  self.DismissButton = dismissControl:GetFrame()

  self:HideBlizzardButtonText()
  self:PositionButtons()
  self:UpdateSafariHatButton()
  self:UpdateDismissButton()
  self:UpdateBandageButton()

  self.SafariHatButton:Hide()
  self.ImportButton:Hide()
  self.ExportButton:Hide()
  self.DismissButton:Hide()
  self.BandageButton:Hide()
  frame:Hide()

  self.EventFrame =
      CreateFrame(
        "Frame",
        "PetMatchPetJournalToolbarEvents"
      )

  self.EventFrame:RegisterEvent(
    "COMPANION_UPDATE"
  )

  self.EventFrame:RegisterUnitEvent(
    "UNIT_AURA",
    "player"
  )

  self.EventFrame:RegisterEvent(
    "PLAYER_REGEN_ENABLED"
  )

  self.EventFrame:RegisterEvent(
    "NEW_TOY_ADDED"
  )

  self.EventFrame:RegisterEvent(
    "TOYS_UPDATED"
  )

  self.EventFrame:RegisterEvent(
    "BAG_UPDATE_DELAYED"
  )

  self.EventFrame:SetScript(
    "OnEvent",
    function(
        eventFrame,
        eventName,
        companionType
    )
      if eventName == "UNIT_AURA" then
        C_Timer.After(
          0,
          function()
            self:UpdateSafariHatButton()
          end
        )

        return
      end

      if eventName == "PLAYER_REGEN_ENABLED" then
        if self.SafariHatUpdatePending then
          self:UpdateSafariHatButton()
        end

        return
      end

      if eventName == "COMPANION_UPDATE" then
        if companionType
            and companionType ~= "CRITTER" then
          return
        end

        C_Timer.After(
          0,
          function()
            self:UpdateDismissButton()
          end
        )

        return
      end

      if eventName == "BAG_UPDATE_DELAYED" then
        self:UpdateBandageButton()
        return
      end

      self:UpdateSafariHatButton()
    end
  )

  return frame
end

function PetJournalToolbar:Show()
  local frame = self:Create()

  if not frame then
    return
  end

  self:HideBlizzardButtonText()
  self:PositionButtons()
  self:UpdateSafariHatButton()
  self:UpdateDismissButton()
  self:UpdateBandageButton()

  frame:Show()
  self.SafariHatButton:Show()
  self.ImportButton:Show()
  self.ExportButton:Show()
  self.DismissButton:Show()
  self.BandageButton:Show()
end

function PetJournalToolbar:Hide()
  if self.SafariHatButton then
    self.SafariHatButton:Hide()
  end

  if self.ImportButton then
    self.ImportButton:Hide()
  end

  if self.ExportButton then
    self.ExportButton:Hide()
  end

  if self.DismissButton then
    self.DismissButton:Hide()
  end

  if self.BandageButton then
    self.BandageButton:Hide()
  end

  if self.Frame then
    self.Frame:Hide()
  end
end

function PetJournalToolbar:HideBlizzardButtonText()
  HideFontStrings(
    FindHealButton()
  )

  HideFontStrings(
    FindRandomFavoriteButton()
  )
end

addon.UI.Actions.PetJournalToolbar = PetJournalToolbar
