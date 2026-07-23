local _, addon = ...

addon.UI = addon.UI or {}
addon.UI.Views = addon.UI.Views or {}

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

local function ShowTooltip(
    button,
    title,
    description
)
  GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
  GameTooltip:SetText(title, 1, 1, 1)

  if description then
    GameTooltip:AddLine(
      description,
      nil,
      nil,
      nil,
      true
    )
  end

  GameTooltip:Show()
end

local function CopyBorderStyle(
    targetButton,
    sourceButton
)
  if not targetButton
      or not sourceButton
      or not sourceButton.Border then
    return
  end

  local sourceBorder = sourceButton.Border

  local border =
      targetButton:CreateTexture(
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
    local texture =
        sourceBorder:GetTexture()

    if not texture then
      return
    end

    border:SetTexture(texture)

    border:SetTexCoord(
      sourceBorder:GetTexCoord()
    )
  end

  border:ClearAllPoints()

  local buttonWidth = sourceButton:GetWidth()
  local buttonHeight = sourceButton:GetHeight()
  local borderWidth = sourceBorder:GetWidth()
  local borderHeight = sourceBorder:GetHeight()

  if buttonWidth > 0
      and buttonHeight > 0
      and borderWidth > 0
      and borderHeight > 0 then
    border:SetSize(
      targetButton:GetWidth() * borderWidth / buttonWidth,
      targetButton:GetHeight() * borderHeight / buttonHeight
    )

    border:SetPoint(
      "CENTER",
      targetButton,
      "CENTER"
    )
  else
    border:SetAllPoints(targetButton)
  end

  border:SetVertexColor(
    sourceBorder:GetVertexColor()
  )

  border:SetAlpha(
    sourceBorder:GetAlpha()
  )

  border:Show()

  targetButton.Border = border
end

local function CopyHighlightStyle(
    targetButton,
    sourceButton
)
  if not targetButton
      or not sourceButton then
    return
  end

  local sourceHighlight =
      sourceButton:GetHighlightTexture()

  if not sourceHighlight then
    return
  end

  local highlight =
      targetButton:GetHighlightTexture()

  if not highlight then
    highlight =
        targetButton:CreateTexture(
          nil,
          "HIGHLIGHT"
        )

    targetButton:SetHighlightTexture(
      highlight
    )
  end

  local atlas =
      sourceHighlight.GetAtlas
      and sourceHighlight:GetAtlas()

  if atlas then
    highlight:SetAtlas(
      atlas,
      false
    )
  else
    local texture =
        sourceHighlight:GetTexture()

    if texture then
      highlight:SetTexture(texture)
    end

    highlight:SetTexCoord(
      sourceHighlight:GetTexCoord()
    )
  end

  highlight:ClearAllPoints()

  local sourceButtonWidth =
      sourceButton:GetWidth()

  local sourceButtonHeight =
      sourceButton:GetHeight()

  local sourceWidth =
      sourceHighlight:GetWidth()

  local sourceHeight =
      sourceHighlight:GetHeight()

  if sourceButtonWidth > 0
      and sourceButtonHeight > 0
      and sourceWidth > 0
      and sourceHeight > 0 then
    highlight:SetSize(
      targetButton:GetWidth()
      * sourceWidth
      / sourceButtonWidth,
      targetButton:GetHeight()
      * sourceHeight
      / sourceButtonHeight
    )

    highlight:SetPoint(
      "CENTER",
      targetButton,
      "CENTER"
    )
  else
    highlight:SetAllPoints(
      targetButton
    )
  end

  highlight:SetBlendMode(
    sourceHighlight:GetBlendMode()
  )

  highlight:SetVertexColor(
    sourceHighlight:GetVertexColor()
  )

  highlight:SetAlpha(
    sourceHighlight:GetAlpha()
  )

  highlight:Show()
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

local function CreateIconButton(
    parent,
    name,
    texture,
    tooltipTitle,
    tooltipDescription,
    onClick
)
  local button =
      CreateFrame(
        "Button",
        name,
        parent,
        "IconButtonTemplate"
      )

  local width, height = GetToolbarButtonSize()

  button:SetSize(width, height)
  button:RegisterForClicks("LeftButtonUp")

  if button.Icon then
    button.Icon:ClearAllPoints()
    button.Icon:SetAllPoints(button)
    button.Icon:SetTexture(texture)

    button.Icon:SetTexCoord(
      0,
      1,
      0,
      1
    )
  end

  CopyBorderStyle(
    button,
    FindHealIconButton()
  )

  CopyHighlightStyle(
    button,
    FindHealIconButton()
  )

  AddBlizzardBorder(button)

  button:SetScript(
    "OnEnter",
    function(self)
      ShowTooltip(
        self,
        tooltipTitle,
        tooltipDescription
      )
    end
  )

  button:SetScript(
    "OnLeave",
    function()
      GameTooltip:Hide()
    end
  )

  button:SetScript(
    "OnClick",
    onClick
  )

  return button
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

  CopyBorderStyle(
    button,
    FindHealIconButton()
  )

  CopyHighlightStyle(
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
      ShowTooltip(
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

  CopyBorderStyle(
    button,
    FindHealIconButton()
  )

  CopyHighlightStyle(
    button,
    FindHealIconButton()
  )

  AddBlizzardBorder(button)

  -- self.BandageButton.Count:SetJustifyH(
  --   "RIGHT"
  -- )

  -- self.BandageButton.Count:SetTextColor(
  --   1,
  --   1,
  --   1
  -- )

  -- self.BandageButton.Count:SetShadowOffset(
  --   1,
  --   -1
  -- )

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
      ShowTooltip(
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

  if enabled then
    button:Enable()

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
    button:Disable()

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

  if InCombatLockdown() then
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

  self.ImportButton =
      CreateIconButton(
        PetJournal,
        "PetMatchImportButton",
        "Interface\\AddOns\\PetMatch\\Media\\Import",
        "Import Team(s)",
        "Import Rematch team or a backup you made with Export.",
        function()
          addon.UI.Views.ImportDialog:Show()
        end
      )

  self.ExportButton =
      CreateIconButton(
        PetJournal,
        "PetMatchExportButton",
        "Interface\\AddOns\\PetMatch\\Media\\Export",
        "Export Everything",
        "Export all folders with all teams - good for backup.",
        function()
          addon.UI.Views.ExportDialog:ShowAll()
        end
      )

  self.DismissButton =
      CreateIconButton(
        PetJournal,
        "PetMatchDismissPetButton",
        "Interface\\AddOns\\PetMatch\\Media\\Dismiss",
        "Dismiss Pet",
        "Dismiss the pet that is currently summoned.",
        function()
          self:DismissPet()
        end
      )

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

addon.UI.Views.PetJournalToolbar = PetJournalToolbar
