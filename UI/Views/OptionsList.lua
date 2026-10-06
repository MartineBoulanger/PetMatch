local _, addon = ...

local L = addon.L
local OptionsList = {}

local CONTENT_WIDTH = 235
local CONTENT_HEIGHT = 545

local SECTION_SPACING = 0
local CONTENT_PADDING = 0

local DUPLICATE_SECTION_HEIGHT = 104
local BREED_SECTION_HEIGHT = 104
local PET_LIST_SECTION_HEIGHT = 86
local PET_CARD_SECTION_HEIGHT = 104
local PET_CARD_VISIBILITY_SECTION_HEIGHT = 126
local LEVELLING_QUEUE_SECTION_HEIGHT = 96
local SUMMONED_PET_SECTION_HEIGHT = 104
local PET_TYPE_FILTER_SECTION_HEIGHT = 104
local STATUS_BAR_SECTION_HEIGHT = 86
local TEAM_CARD_SECTION_HEIGHT = 86
local PVE_BATTLE_SECTION_HEIGHT = 86
local TARGETS_SECTION_HEIGHT = 126

function OptionsList:Create(parent)
  local frame =
      addon.UI.Components.ScrollBox:Create(
        parent,
        {
          width = CONTENT_WIDTH,
          height = CONTENT_HEIGHT,
          contentGap = 4
        }
      )

  frame:SetPoint("TOPLEFT")

  self.Frame = frame

  frame.items = {}

  self.ExpandedSections = {
    duplicateTeams = false,
    petBreeds = false,
    petList = false,
    teamCards = false,
    petCard = false,
    petCardVisibility = false,
    levellingQueue = false,
    summonedPet = false,
    petTypeFilters = false,
    statusBar = false,
    petBattles = false,
    targets = false,
  }

  self:RegisterEvents()
  self:Refresh()

  frame:Show()

  return frame
end

function OptionsList:RegisterEvents()
  if self.EventsRegistered then
    return
  end

  self.EventsRegistered = true

  addon.EventBus:Register(
    addon.Events.SETTINGS_CHANGED,
    function(key)
      if not self.Frame then
        return
      end

      if key == "duplicateTeamMode" then
        self:RefreshDuplicateMode()
      elseif key == "petListBreedPosition" then
        self:RefreshBreedMode()
      elseif key == "compactPetListRows" then
        self:RefreshPetListMode()
      elseif key == "teamCardHeightMode" then
        self:RefreshTeamCardHeightMode()
      elseif key == "petCardInteractionMode" then
        self:RefreshPetCardMode()
      elseif key == "petCardPetListEnabled"
          or key == "petCardTeamsEnabled"
          or key == "petCardLevellingQueueEnabled"
          or key == "petCardTargetEnabled" then
        self:RefreshPetCardVisibilityMode()
      elseif key == "levellingQueueAutoAddMode" then
        self:RefreshLevellingQueueAutoAddMode()
      elseif key == "summonedPetMode" then
        self:RefreshSummonedPetMode()
      elseif key == "petTypeFilterDisplayMode" then
        self:RefreshPetTypeFilterMode()
      elseif key == "statusBarClearMode" then
        self:RefreshStatusBarMode()
      elseif key == "autoOpenNotesOnPvEBattle"
          or key == "autoOpenPetJournalAfterBattle" then
        self:RefreshPetBattlesMode()
      elseif key == "targetTeamLoadMode" then
        self:RefreshTargetTeamLoadMode()
      end
    end
  )
end

function OptionsList:ClearItems()
  if not self.Frame then
    return
  end

  for _, item in ipairs(
    self.Frame.items or {}
  ) do
    item:Hide()
    item:ClearAllPoints()
    item:SetParent(nil)
  end

  self.Frame.items = {}

  -- Duplicate Teams Option
  self.DuplicateAccordion = nil
  self.SkipButton = nil
  self.ReplaceButton = nil
  self.KeepButton = nil

  -- Pet Breeds Option
  self.BreedAccordion = nil
  self.RightBreedButton = nil
  self.AfterNameBreedButton = nil
  self.HiddenBreedButton = nil

  -- Pet List Option
  self.PetListAccordion = nil
  self.NormalRowsButton = nil
  self.CompactRowsButton = nil

  -- Team Card Option
  self.TeamCardAccordion = nil
  self.TeamCardNormalHeightButton = nil
  self.TeamCardLargeHeightButton = nil

  -- Pet Card Option
  self.PetCardAccordion = nil
  self.PetCardHoverButton = nil
  self.PetCardClickButton = nil
  self.PetCardBothButton = nil

  -- Pet Card Visibility Option
  self.PetCardVisibilityAccordion = nil
  self.PetCardPetListCheckbox = nil
  self.PetCardTeamsCheckbox = nil
  self.PetCardLevellingQueueCheckbox = nil
  self.PetCardTargetsCheckbox = nil

  -- Levelling Queue Option
  self.LevellingQueueAccordion = nil
  self.LevellingQueueAutoAddEnabledButton = nil
  self.LevellingQueueAutoAddDisabledButton = nil

  -- Summoned Pet Option
  self.SummonedPetAccordion = nil
  self.AutoDismissPetButton = nil
  self.KeepSummonedPetButton = nil
  self.RestorePreviousPetButton = nil

  -- Pet Type Filter Option
  self.PetTypeFilterAccordion = nil
  self.PetTypeFilterBothButton = nil
  self.PetTypeFilterMenuButton = nil
  self.PetTypeFilterBarButton = nil

  -- Status Bar Option
  self.StatusBarAccordion = nil
  self.StatusBarAllButton = nil
  self.StatusBarFiltersButton = nil

  -- Pet Battles Option
  self.PetBattlesAccordion = nil
  self.AutoOpenPvENotesCheckbox = nil
  self.AutoOpenPetJournalCheckbox = nil

  -- Targets Option
  self.TargetsAccordion = nil
  self.TargetDisabledModeButton = nil
  self.TargetButtonModeButton = nil
  self.TargetAutoModeButton = nil
  self.TargetConfirmModeButton = nil
end

function OptionsList:GetSections()
  return {
    {
      key = "duplicateTeams",
      title = L["DUPLICATE_TEAMS"],
      contentHeight = DUPLICATE_SECTION_HEIGHT,
      build = function(content)
        self:BuildDuplicateTeamOptions(content)
      end,
    },
    {
      key = "petBreeds",
      title = L["PET_BREEDS"],
      contentHeight = BREED_SECTION_HEIGHT,
      build = function(content)
        self:BuildBreedOptions(content)
      end,
    },
    {
      key = "petList",
      title = L["PET_LIST"],
      contentHeight = PET_LIST_SECTION_HEIGHT,
      build = function(content)
        self:BuildPetListOptions(content)
      end,
    },
    {
      key = "teamCards",
      title = L["TEAM_CARDS"],
      contentHeight = TEAM_CARD_SECTION_HEIGHT,
      build = function(content)
        self:BuildTeamCardOptions(content)
      end,
    },
    {
      key = "petCard",
      title = L["PET_CARD"],
      contentHeight = PET_CARD_SECTION_HEIGHT,
      build = function(content)
        self:BuildPetCardOptions(content)
      end,
    },
    {
      key = "petCardVisibility",
      title = L["PET_CARD_VISIBILITY"],
      contentHeight = PET_CARD_VISIBILITY_SECTION_HEIGHT,
      build = function(content)
        self:BuildPetCardVisibilityOptions(content)
      end,
    },
    {
      key = "levellingQueue",
      title = L["LEVELLING_QUEUE"],
      contentHeight = LEVELLING_QUEUE_SECTION_HEIGHT,
      build = function(content)
        self:BuildLevellingQueueOptions(content)
      end,
    },
    {
      key = "summonedPet",
      title = L["SUMMONED_PET"],
      contentHeight = SUMMONED_PET_SECTION_HEIGHT,
      build = function(content)
        self:BuildSummonedPetOptions(content)
      end,
    },
    {
      key = "petTypeFilters",
      title = L["PET_TYPE_FILTERS"],
      contentHeight = PET_TYPE_FILTER_SECTION_HEIGHT,
      build = function(content)
        self:BuildPetTypeFilterOptions(content)
      end,
    },
    {
      key = "statusBar",
      title = L["STATUS_BAR"],
      contentHeight = STATUS_BAR_SECTION_HEIGHT,
      build = function(content)
        self:BuildStatusBarOptions(content)
      end,
    },
    {
      key = "petBattles",
      title = L["PET_BATTLES"],
      contentHeight = PVE_BATTLE_SECTION_HEIGHT,
      build = function(content)
        self:BuildPetBattlesOptions(content)
      end,
    },
    {
      key = "targets",
      title = L["TARGETS"],
      contentHeight = TARGETS_SECTION_HEIGHT,
      build = function(content)
        self:BuildTargetOptions(content)
      end,
    },
  }
end

function OptionsList:CreateSection(section, currentOffset)
  local expanded =
      self.ExpandedSections[section.key] == true

  local accordion =
      addon.UI.Components.Accordion:Create(
        self.Frame.Content,
        {
          title = section.title,
          width = CONTENT_WIDTH,
          expanded = expanded,
          contentHeight = section.contentHeight,
          contentPadding = 8,
          onToggle = function(
              control,
              isExpanded
          )
            self.ExpandedSections[
            section.key
            ] = isExpanded

            C_Timer.After(
              0,
              function()
                if self.Frame then
                  self:UpdateContentHeight()
                end
              end
            )
          end,
        }
      )

  accordion.SectionKey = section.key
  accordion:ClearAllPoints()

  accordion:SetPoint(
    "TOPLEFT",
    self.Frame.Content,
    "TOPLEFT",
    0,
    -currentOffset
  )

  accordion:SetPoint(
    "TOPRIGHT",
    self.Frame.Content,
    "TOPRIGHT",
    0,
    -currentOffset
  )

  table.insert(
    self.Frame.items,
    accordion
  )

  section.build(
    accordion:GetContentFrame()
  )

  if section.key == "duplicateTeams" then
    self.DuplicateAccordion = accordion
  end

  if section.key == "petBreeds" then
    self.BreedAccordion = accordion
  end

  if section.key == "petList" then
    self.PetListAccordion = accordion
  end

  if section.key == "teamCards" then
    self.TeamCardAccordion = accordion
  end

  if section.key == "petCard" then
    self.PetCardAccordion = accordion
  end

  if section.key == "petCardVisibility" then
    self.PetCardVisibilityAccordion = accordion
  end

  if section.key == "levellingQueue" then
    self.LevellingQueueAccordion = accordion
  end

  if section.key == "summonedPet" then
    self.SummonedPetAccordion = accordion
  end

  if section.key == "petTypeFilters" then
    self.PetTypeFilterAccordion = accordion
  end

  if section.key == "statusBar" then
    self.StatusBarAccordion = accordion
  end

  if section.key == "petBattles" then
    self.PetBattlesAccordion = accordion
  end

  if section.key == "targets" then
    self.TargetsAccordion = accordion
  end

  return currentOffset
      + accordion:GetHeight()
      + SECTION_SPACING
end

function OptionsList:CreateRadioButton(
    parent,
    label,
    settingKey,
    mode,
    refreshCallback
)
  local button = CreateFrame(
    "CheckButton",
    nil,
    parent,
    "UIRadioButtonTemplate"
  )

  button.text:SetText(label)

  button:SetScript(
    "OnClick",
    function()
      addon.Settings:Set(
        settingKey,
        mode
      )

      if refreshCallback then
        refreshCallback(self)
      end
    end
  )

  return button
end

function OptionsList:CreateCheckbox(
    parent,
    label,
    settingKey,
    refreshCallback
)
  local button =
      CreateFrame(
        "CheckButton",
        nil,
        parent,
        "UICheckButtonTemplate"
      )

  button:SetSize(24, 24)

  button.text:SetText(
    label
  )

  button.text:SetPoint(
    "LEFT",
    button,
    "LEFT",
    28,
    0
  )

  button:SetScript(
    "OnClick",
    function()
      addon.Settings:Set(
        settingKey,
        button:GetChecked() == true
      )

      if refreshCallback then
        refreshCallback(self)
      end
    end
  )

  return button
end

function OptionsList:BuildDuplicateTeamOptions(parent)
  local description =
      parent:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlightSmall"
      )

  description:SetPoint(
    "TOPLEFT",
    parent,
    "TOPLEFT",
    0,
    0
  )

  description:SetPoint(
    "RIGHT",
    parent,
    "RIGHT",
    0,
    0
  )

  description:SetJustifyH("LEFT")
  description:SetJustifyV("TOP")
  description:SetWordWrap(true)

  description:SetText(
    L["DUPLICATED_TEAMS_DESCRIPTION"]
  )

  self.SkipButton =
      self:CreateRadioButton(
        parent,
        L["SKIP_EXISTING"],
        "duplicateTeamMode",
        "skip",
        self.RefreshDuplicateMode
      )

  self.SkipButton:SetPoint(
    "TOPLEFT",
    description,
    "BOTTOMLEFT",
    0,
    -7
  )

  self.ReplaceButton =
      self:CreateRadioButton(
        parent,
        L["REPLACE_EXISTING"],
        "duplicateTeamMode",
        "replace",
        self.RefreshDuplicateMode
      )

  self.ReplaceButton:SetPoint(
    "TOPLEFT",
    self.SkipButton,
    "BOTTOMLEFT",
    0,
    -2
  )

  self.KeepButton =
      self:CreateRadioButton(
        parent,
        L["KEEP_BOTH"],
        "duplicateTeamMode",
        "keep",
        self.RefreshDuplicateMode
      )

  self.KeepButton:SetPoint(
    "TOPLEFT",
    self.ReplaceButton,
    "BOTTOMLEFT",
    0,
    -2
  )

  self:RefreshDuplicateMode()
end

function OptionsList:BuildBreedOptions(parent)
  local description =
      parent:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlightSmall"
      )

  description:SetPoint(
    "TOPLEFT",
    parent,
    "TOPLEFT",
    0,
    0
  )

  description:SetPoint(
    "RIGHT",
    parent,
    "RIGHT",
    0,
    0
  )

  description:SetJustifyH("LEFT")
  description:SetJustifyV("TOP")
  description:SetWordWrap(true)

  description:SetText(
    L["PET_BREEDS_DESCRIPTION"]
  )

  self.RightBreedButton =
      self:CreateRadioButton(
        parent,
        L["RIGHT_SIDE"],
        "petListBreedPosition",
        "right",
        self.RefreshBreedMode
      )

  self.RightBreedButton:SetPoint(
    "TOPLEFT",
    description,
    "BOTTOMLEFT",
    0,
    -7
  )

  self.AfterNameBreedButton =
      self:CreateRadioButton(
        parent,
        L["AFTER_NAME"],
        "petListBreedPosition",
        "afterName",
        self.RefreshBreedMode
      )

  self.AfterNameBreedButton:SetPoint(
    "TOPLEFT",
    self.RightBreedButton,
    "BOTTOMLEFT",
    0,
    -2
  )

  self.HiddenBreedButton =
      self:CreateRadioButton(
        parent,
        L["HIDDEN"],
        "petListBreedPosition",
        "hidden",
        self.RefreshBreedMode
      )

  self.HiddenBreedButton:SetPoint(
    "TOPLEFT",
    self.AfterNameBreedButton,
    "BOTTOMLEFT",
    0,
    -2
  )

  self:RefreshBreedMode()
end

function OptionsList:BuildPetListOptions(parent)
  local description =
      parent:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlightSmall"
      )

  description:SetPoint(
    "TOPLEFT",
    parent,
    "TOPLEFT",
    0,
    0
  )

  description:SetPoint(
    "RIGHT",
    parent,
    "RIGHT",
    0,
    0
  )

  description:SetJustifyH("LEFT")
  description:SetJustifyV("TOP")
  description:SetWordWrap(true)

  description:SetText(
    L["PET_LIST_DESCRIPTION"]
  )

  self.NormalRowsButton =
      self:CreateRadioButton(
        parent,
        L["NORMAL_ROWS"],
        "compactPetListRows",
        false,
        self.RefreshPetListMode
      )

  self.NormalRowsButton:SetPoint(
    "TOPLEFT",
    description,
    "BOTTOMLEFT",
    0,
    -7
  )

  self.CompactRowsButton =
      self:CreateRadioButton(
        parent,
        L["COMPACT_ROWS"],
        "compactPetListRows",
        true,
        self.RefreshPetListMode
      )

  self.CompactRowsButton:SetPoint(
    "TOPLEFT",
    self.NormalRowsButton,
    "BOTTOMLEFT",
    0,
    -2
  )

  self:RefreshPetListMode()
end

function OptionsList:BuildTeamCardOptions(parent)
  local description =
      parent:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlightSmall"
      )

  description:SetPoint(
    "TOPLEFT",
    parent,
    "TOPLEFT",
    0,
    0
  )

  description:SetPoint(
    "RIGHT",
    parent,
    "RIGHT",
    0,
    0
  )

  description:SetJustifyH("LEFT")
  description:SetJustifyV("TOP")
  description:SetWordWrap(true)

  description:SetText(
    L["TEAM_CARDS_DESCRIPTION"]
  )

  self.TeamCardNormalHeightButton =
      self:CreateRadioButton(
        parent,
        L["NORMAL_HEIGHT"],
        "teamCardHeightMode",
        "normal",
        self.RefreshTeamCardHeightMode
      )

  self.TeamCardNormalHeightButton:SetPoint(
    "TOPLEFT",
    description,
    "BOTTOMLEFT",
    0,
    -7
  )

  self.TeamCardLargeHeightButton =
      self:CreateRadioButton(
        parent,
        L["LARGE_HEIGHT"],
        "teamCardHeightMode",
        "large",
        self.RefreshTeamCardHeightMode
      )

  self.TeamCardLargeHeightButton:SetPoint(
    "TOPLEFT",
    self.TeamCardNormalHeightButton,
    "BOTTOMLEFT",
    0,
    -2
  )

  self:RefreshTeamCardHeightMode()
end

function OptionsList:BuildPetCardOptions(parent)
  local description =
      parent:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlightSmall"
      )

  description:SetPoint(
    "TOPLEFT",
    parent,
    "TOPLEFT",
    0,
    0
  )

  description:SetPoint(
    "RIGHT",
    parent,
    "RIGHT",
    0,
    0
  )

  description:SetJustifyH("LEFT")
  description:SetJustifyV("TOP")
  description:SetWordWrap(true)

  description:SetText(
    L["PET_CARD_DESCRIPTION"]
  )

  self.PetCardHoverButton =
      self:CreateRadioButton(
        parent,
        L["SHOW_ON_HOVER"],
        "petCardInteractionMode",
        "hover",
        self.RefreshPetCardMode
      )

  self.PetCardHoverButton:SetPoint(
    "TOPLEFT",
    description,
    "BOTTOMLEFT",
    0,
    -7
  )

  self.PetCardClickButton =
      self:CreateRadioButton(
        parent,
        L["SHOW_ON_CLICK"],
        "petCardInteractionMode",
        "click",
        self.RefreshPetCardMode
      )

  self.PetCardClickButton:SetPoint(
    "TOPLEFT",
    self.PetCardHoverButton,
    "BOTTOMLEFT",
    0,
    -2
  )

  self.PetCardBothButton =
      self:CreateRadioButton(
        parent,
        L["SHOW_ON_BOTH"],
        "petCardInteractionMode",
        "both",
        self.RefreshPetCardMode
      )

  self.PetCardBothButton:SetPoint(
    "TOPLEFT",
    self.PetCardClickButton,
    "BOTTOMLEFT",
    0,
    -2
  )

  self:RefreshPetCardMode()
end

function OptionsList:BuildPetCardVisibilityOptions(parent)
  local description =
      parent:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlightSmall"
      )

  description:SetPoint(
    "TOPLEFT",
    parent,
    "TOPLEFT",
    0,
    0
  )

  description:SetPoint(
    "RIGHT",
    parent,
    "RIGHT",
    0,
    0
  )

  description:SetJustifyH("LEFT")
  description:SetJustifyV("TOP")
  description:SetWordWrap(true)

  description:SetText(
    L["PET_CARD_VISIBILITY_DESCRIPTION"]
  )

  self.PetCardPetListCheckbox =
      self:CreateCheckbox(
        parent,
        L["JOURNAL_LIST"],
        "petCardPetListEnabled",
        self.RefreshPetCardVisibility
      )

  self.PetCardPetListCheckbox:SetPoint(
    "TOPLEFT",
    description,
    "BOTTOMLEFT",
    0,
    -5
  )

  self.PetCardTeamsCheckbox =
      self:CreateCheckbox(
        parent,
        L["TEAM_PETS"],
        "petCardTeamsEnabled",
        self.RefreshPetCardVisibility
      )

  self.PetCardTeamsCheckbox:SetPoint(
    "TOPLEFT",
    self.PetCardPetListCheckbox,
    "BOTTOMLEFT",
    0,
    4
  )

  self.PetCardLevellingQueueCheckbox =
      self:CreateCheckbox(
        parent,
        L["QUEUE_PETS"],
        "petCardLevellingQueueEnabled",
        self.RefreshPetCardVisibility
      )

  self.PetCardLevellingQueueCheckbox:SetPoint(
    "TOPLEFT",
    self.PetCardTeamsCheckbox,
    "BOTTOMLEFT",
    0,
    4
  )

  self.PetCardTargetsCheckbox =
      self:CreateCheckbox(
        parent,
        L["TARGET_PETS"],
        "petCardTargetEnabled",
        self.RefreshPetCardVisibility
      )

  self.PetCardTargetsCheckbox:SetPoint(
    "TOPLEFT",
    self.PetCardLevellingQueueCheckbox,
    "BOTTOMLEFT",
    0,
    4
  )

  self:RefreshPetCardVisibilityMode()
end

function OptionsList:BuildLevellingQueueOptions(parent)
  local description =
      parent:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlightSmall"
      )

  description:SetPoint(
    "TOPLEFT",
    parent,
    "TOPLEFT",
    0,
    0
  )

  description:SetPoint(
    "RIGHT",
    parent,
    "RIGHT",
    0,
    0
  )

  description:SetJustifyH("LEFT")
  description:SetJustifyV("TOP")
  description:SetWordWrap(true)

  description:SetText(
    L["QUEUE_DESCRIPTION"]
  )

  self.LevellingQueueAutoAddEnabledButton =
      self:CreateRadioButton(
        parent,
        L["AUTO_ADD_PET"],
        "levellingQueueAutoAddMode",
        "enabled",
        self.RefreshLevellingQueueAutoAddMode
      )

  self.LevellingQueueAutoAddEnabledButton:SetPoint(
    "TOPLEFT",
    description,
    "BOTTOMLEFT",
    0,
    -7
  )

  self.LevellingQueueAutoAddDisabledButton =
      self:CreateRadioButton(
        parent,
        L["NOT_AUTO_PET_ADD"],
        "levellingQueueAutoAddMode",
        "disabled",
        self.RefreshLevellingQueueAutoAddMode
      )

  self.LevellingQueueAutoAddDisabledButton:SetPoint(
    "TOPLEFT",
    self.LevellingQueueAutoAddEnabledButton,
    "BOTTOMLEFT",
    0,
    -2
  )

  self:RefreshLevellingQueueAutoAddMode()
end

function OptionsList:BuildSummonedPetOptions(parent)
  local description =
      parent:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlightSmall"
      )

  description:SetPoint(
    "TOPLEFT",
    parent,
    "TOPLEFT",
    0,
    0
  )

  description:SetPoint(
    "RIGHT",
    parent,
    "RIGHT",
    0,
    0
  )

  description:SetJustifyH("LEFT")
  description:SetJustifyV("TOP")
  description:SetWordWrap(true)

  description:SetText(
    L["SUMMONED_PET_DESCRIPTION"]
  )

  self.AutoDismissPetButton =
      self:CreateRadioButton(
        parent,
        L["AUTO_DISMISS"],
        "summonedPetMode",
        "dismiss",
        self.RefreshSummonedPetMode
      )

  self.AutoDismissPetButton:SetPoint(
    "TOPLEFT",
    description,
    "BOTTOMLEFT",
    0,
    -7
  )

  self.KeepSummonedPetButton =
      self:CreateRadioButton(
        parent,
        L["KEEP_PET"],
        "summonedPetMode",
        "keep",
        self.RefreshSummonedPetMode
      )

  self.KeepSummonedPetButton:SetPoint(
    "TOPLEFT",
    self.AutoDismissPetButton,
    "BOTTOMLEFT",
    0,
    -2
  )

  self.RestorePreviousPetButton =
      self:CreateRadioButton(
        parent,
        L["RESTORE_PET"],
        "summonedPetMode",
        "restore",
        self.RefreshSummonedPetMode
      )

  self.RestorePreviousPetButton:SetPoint(
    "TOPLEFT",
    self.KeepSummonedPetButton,
    "BOTTOMLEFT",
    0,
    -2
  )

  self:RefreshSummonedPetMode()
end

function OptionsList:BuildPetTypeFilterOptions(parent)
  local description =
      parent:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlightSmall"
      )

  description:SetPoint(
    "TOPLEFT",
    parent,
    "TOPLEFT",
    0,
    0
  )

  description:SetPoint(
    "RIGHT",
    parent,
    "RIGHT",
    0,
    0
  )

  description:SetJustifyH("LEFT")
  description:SetJustifyV("TOP")
  description:SetWordWrap(true)

  description:SetText(
    L["PET_TYPE_DESCRIPTION"]
  )

  self.PetTypeFilterBothButton =
      self:CreateRadioButton(
        parent,
        L["FILTER_BAR_AND_MENU"],
        "petTypeFilterDisplayMode",
        "both",
        self.RefreshPetTypeFilterMode
      )

  self.PetTypeFilterBothButton:SetPoint(
    "TOPLEFT",
    description,
    "BOTTOMLEFT",
    0,
    -7
  )

  self.PetTypeFilterMenuButton =
      self:CreateRadioButton(
        parent,
        L["FILTER_MENU_ONLY"],
        "petTypeFilterDisplayMode",
        "menu",
        self.RefreshPetTypeFilterMode
      )

  self.PetTypeFilterMenuButton:SetPoint(
    "TOPLEFT",
    self.PetTypeFilterBothButton,
    "BOTTOMLEFT",
    0,
    -2
  )

  self.PetTypeFilterBarButton =
      self:CreateRadioButton(
        parent,
        L["FILTER_BAR_ONLY"],
        "petTypeFilterDisplayMode",
        "bar",
        self.RefreshPetTypeFilterMode
      )

  self.PetTypeFilterBarButton:SetPoint(
    "TOPLEFT",
    self.PetTypeFilterMenuButton,
    "BOTTOMLEFT",
    0,
    -2
  )

  self:RefreshPetTypeFilterMode()
end

function OptionsList:BuildStatusBarOptions(parent)
  local description =
      parent:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlightSmall"
      )

  description:SetPoint(
    "TOPLEFT",
    parent,
    "TOPLEFT",
    0,
    0
  )

  description:SetPoint(
    "RIGHT",
    parent,
    "RIGHT",
    0,
    0
  )

  description:SetJustifyH("LEFT")
  description:SetJustifyV("TOP")
  description:SetWordWrap(true)

  description:SetText(
    L["STATUS_BAR_DESCRIPTION"]
  )

  self.StatusBarAllButton =
      self:CreateRadioButton(
        parent,
        L["FILTERS_AND_SORTING"],
        "statusBarClearMode",
        "all",
        self.RefreshStatusBarMode
      )

  self.StatusBarAllButton:SetPoint(
    "TOPLEFT",
    description,
    "BOTTOMLEFT",
    0,
    -7
  )

  self.StatusBarFiltersButton =
      self:CreateRadioButton(
        parent,
        L["FILTERS_ONLY"],
        "statusBarClearMode",
        "filters",
        self.RefreshStatusBarMode
      )

  self.StatusBarFiltersButton:SetPoint(
    "TOPLEFT",
    self.StatusBarAllButton,
    "BOTTOMLEFT",
    0,
    -2
  )

  self:RefreshStatusBarMode()
end

function OptionsList:BuildPetBattlesOptions(parent)
  local description =
      parent:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlightSmall"
      )

  description:SetPoint(
    "TOPLEFT",
    parent,
    "TOPLEFT",
    0,
    0
  )

  description:SetPoint(
    "RIGHT",
    parent,
    "RIGHT",
    0,
    0
  )

  description:SetJustifyH("LEFT")
  description:SetJustifyV("TOP")
  description:SetWordWrap(true)

  description:SetText(
    L["PET_BATTLES_DESCRIPTION"]
  )

  self.AutoOpenPvENotesCheckbox =
      self:CreateCheckbox(
        parent,
        L["OPEN_NOTES"],
        "autoOpenNotesOnPvEBattle",
        self.RefreshPetBattlesMode
      )

  self.AutoOpenPvENotesCheckbox:SetPoint(
    "TOPLEFT",
    description,
    "BOTTOMLEFT",
    0,
    -5
  )

  self.AutoOpenPetJournalCheckbox =
      self:CreateCheckbox(
        parent,
        L["OPEN_JOURNAL"],
        "autoOpenPetJournalAfterBattle",
        self.RefreshPetBattlesMode
      )

  self.AutoOpenPetJournalCheckbox:SetPoint(
    "TOPLEFT",
    self.AutoOpenPvENotesCheckbox,
    "BOTTOMLEFT",
    0,
    4
  )

  self:RefreshPetBattlesMode()
end

function OptionsList:BuildTargetOptions(parent)
  local description =
      parent:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlightSmall"
      )

  description:SetPoint(
    "TOPLEFT",
    parent,
    "TOPLEFT",
    0,
    0
  )

  description:SetPoint(
    "RIGHT",
    parent,
    "RIGHT",
    0,
    0
  )

  description:SetJustifyH("LEFT")
  description:SetJustifyV("TOP")
  description:SetWordWrap(true)

  description:SetText(
    L["TARGETS_DESCRIPTION"]
  )

  self.TargetDisabledModeButton =
      self:CreateRadioButton(
        parent,
        L["TARGETS_DISABLED"],
        "targetTeamLoadMode",
        "off",
        self.RefreshTargetTeamLoadMode
      )

  self.TargetDisabledModeButton:SetPoint(
    "TOPLEFT",
    description,
    "BOTTOMLEFT",
    0,
    -7
  )

  self.TargetButtonModeButton =
      self:CreateRadioButton(
        parent,
        L["SHOW_LOAD_TEAM"],
        "targetTeamLoadMode",
        "button",
        self.RefreshTargetTeamLoadMode
      )

  self.TargetButtonModeButton:SetPoint(
    "TOPLEFT",
    self.TargetDisabledModeButton,
    "BOTTOMLEFT",
    0,
    -2
  )

  self.TargetAutoModeButton =
      self:CreateRadioButton(
        parent,
        L["AUTO_LOAD_TEAM"],
        "targetTeamLoadMode",
        "auto",
        self.RefreshTargetTeamLoadMode
      )

  self.TargetAutoModeButton:SetPoint(
    "TOPLEFT",
    self.TargetButtonModeButton,
    "BOTTOMLEFT",
    0,
    -2
  )

  self.TargetConfirmModeButton =
      self:CreateRadioButton(
        parent,
        L["CONFIRM_LOAD_TEAM"],
        "targetTeamLoadMode",
        "confirm",
        self.RefreshTargetTeamLoadMode
      )

  self.TargetConfirmModeButton:SetPoint(
    "TOPLEFT",
    self.TargetAutoModeButton,
    "BOTTOMLEFT",
    0,
    -2
  )

  self:RefreshTargetTeamLoadMode()
end

function OptionsList:RefreshDuplicateMode()
  if not self.SkipButton
      or not self.ReplaceButton
      or not self.KeepButton then
    return
  end

  local mode =
      addon.Settings:Get("duplicateTeamMode")

  self.SkipButton:SetChecked(
    mode == "skip"
  )

  self.ReplaceButton:SetChecked(
    mode == "replace"
  )

  self.KeepButton:SetChecked(
    mode == "keep"
  )
end

function OptionsList:RefreshBreedMode()
  if not self.RightBreedButton then
    return
  end

  local mode =
      addon.Settings:Get("petListBreedPosition")

  self.RightBreedButton:SetChecked(
    mode == "right"
  )

  self.AfterNameBreedButton:SetChecked(
    mode == "afterName"
  )

  self.HiddenBreedButton:SetChecked(
    mode == "hidden"
  )
end

function OptionsList:RefreshPetListMode()
  if not self.NormalRowsButton
      or not self.CompactRowsButton then
    return
  end

  local compact =
      addon.Settings:Get("compactPetListRows") == true

  self.NormalRowsButton:SetChecked(
    not compact
  )

  self.CompactRowsButton:SetChecked(
    compact
  )
end

function OptionsList:RefreshTeamCardHeightMode()
  if not self.TeamCardNormalHeightButton
      or not self.TeamCardLargeHeightButton then
    return
  end

  local mode =
      addon.Settings:Get(
        "teamCardHeightMode"
      )
      or "normal"

  self.TeamCardNormalHeightButton:
      SetChecked(
        mode == "normal"
      )

  self.TeamCardLargeHeightButton:
      SetChecked(
        mode == "large"
      )
end

function OptionsList:RefreshPetCardMode()
  if not self.PetCardHoverButton
      or not self.PetCardClickButton
      or not self.PetCardBothButton then
    return
  end

  local mode =
      addon.Settings:Get("petCardInteractionMode")
      or "hover"

  self.PetCardHoverButton:SetChecked(
    mode == "hover"
  )

  self.PetCardClickButton:SetChecked(
    mode == "click"
  )

  self.PetCardBothButton:SetChecked(
    mode == "both"
  )
end

function OptionsList:RefreshPetCardVisibilityMode()
  if self.PetCardPetListCheckbox then
    self.PetCardPetListCheckbox:SetChecked(
      addon.Settings:Get(
        "petCardPetListEnabled"
      ) ~= false
    )
  end

  if self.PetCardTeamsCheckbox then
    self.PetCardTeamsCheckbox:SetChecked(
      addon.Settings:Get(
        "petCardTeamsEnabled"
      ) ~= false
    )
  end

  if self.PetCardLevellingQueueCheckbox then
    self.PetCardLevellingQueueCheckbox:SetChecked(
      addon.Settings:Get(
        "petCardLevellingQueueEnabled"
      ) ~= false
    )
  end

  if self.PetCardTargetsCheckbox then
    self.PetCardTargetsCheckbox:SetChecked(
      addon.Settings:Get(
        "petCardTargetEnabled"
      ) ~= false
    )
  end
end

function OptionsList:RefreshLevellingQueueAutoAddMode()
  if not self.LevellingQueueAutoAddEnabledButton
      or not self.LevellingQueueAutoAddDisabledButton then
    return
  end

  local mode =
      addon.Settings:Get("levellingQueueAutoAddMode")
      or "disabled"

  self.LevellingQueueAutoAddEnabledButton:SetChecked(
    mode == "enabled"
  )

  self.LevellingQueueAutoAddDisabledButton:SetChecked(
    mode == "disabled"
  )
end

function OptionsList:RefreshSummonedPetMode()
  if not self.AutoDismissPetButton
      or not self.KeepSummonedPetButton
      or not self.RestorePreviousPetButton then
    return
  end

  local mode =
      addon.Settings:Get("summonedPetMode")
      or "keep"

  self.AutoDismissPetButton:SetChecked(
    mode == "dismiss"
  )

  self.KeepSummonedPetButton:SetChecked(
    mode == "keep"
  )

  self.RestorePreviousPetButton:SetChecked(
    mode == "restore"
  )
end

function OptionsList:RefreshPetTypeFilterMode()
  if not self.PetTypeFilterBothButton
      or not self.PetTypeFilterMenuButton
      or not self.PetTypeFilterBarButton then
    return
  end

  local mode =
      addon.Settings:Get("petTypeFilterDisplayMode")
      or "both"

  self.PetTypeFilterBothButton:SetChecked(mode == "both")
  self.PetTypeFilterMenuButton:SetChecked(mode == "menu")
  self.PetTypeFilterBarButton:SetChecked(mode == "bar")
end

function OptionsList:RefreshStatusBarMode()
  if not self.StatusBarAllButton
      or not self.StatusBarFiltersButton then
    return
  end

  local mode =
      addon.Settings:Get("statusBarClearMode")
      or "all"

  self.StatusBarAllButton:SetChecked(
    mode == "all"
  )

  self.StatusBarFiltersButton:SetChecked(
    mode == "filters"
  )
end

function OptionsList:RefreshPetBattlesMode()
  if self.AutoOpenPvENotesCheckbox then
    self.AutoOpenPvENotesCheckbox:SetChecked(
      addon.Settings:Get(
        "autoOpenNotesOnPvEBattle"
      ) == true
    )
  end

  if self.AutoOpenPetJournalCheckbox then
    self.AutoOpenPetJournalCheckbox:SetChecked(
      addon.Settings:Get(
        "autoOpenPetJournalAfterBattle"
      ) ~= false
    )
  end
end

function OptionsList:RefreshTargetTeamLoadMode()
  if not self.TargetDisabledModeButton
      or not self.TargetButtonModeButton
      or not self.TargetAutoModeButton
      or not self.TargetConfirmModeButton then
    return
  end

  local mode =
      addon.Settings:Get("targetTeamLoadMode")
      or "off"

  self.TargetDisabledModeButton:
      SetChecked(
        mode == "off"
      )

  self.TargetButtonModeButton:
      SetChecked(
        mode == "button"
      )

  self.TargetAutoModeButton:
      SetChecked(
        mode == "auto"
      )

  self.TargetConfirmModeButton:
      SetChecked(
        mode == "confirm"
      )
end

function OptionsList:UpdateContentHeight()
  if not self.Frame then
    return
  end

  local currentOffset = CONTENT_PADDING

  for _, item in ipairs(
    self.Frame.items or {}
  ) do
    item:ClearAllPoints()

    item:SetPoint(
      "TOPLEFT",
      self.Frame.Content,
      "TOPLEFT",
      0,
      -currentOffset
    )

    item:SetPoint(
      "TOPRIGHT",
      self.Frame.Content,
      "TOPRIGHT",
      0,
      -currentOffset
    )

    currentOffset =
        currentOffset
        + item:GetHeight()
        + SECTION_SPACING
  end

  self.Frame.Content:SetHeight(
    math.max(
      1,
      currentOffset
      + CONTENT_PADDING
    )
  )

  if self.Frame.RefreshScrollBar then
    self.Frame:RefreshScrollBar()
  end
end

function OptionsList:Refresh()
  if self.Refreshing then
    return
  end

  if not self.Frame then
    return
  end

  self.Refreshing = true

  self:ClearItems()

  local sections = self:GetSections()
  local currentOffset = CONTENT_PADDING

  for _, section in ipairs(sections) do
    currentOffset =
        self:CreateSection(
          section,
          currentOffset
        )
  end

  self.Frame.Content:SetHeight(
    math.max(
      1,
      currentOffset
      + CONTENT_PADDING
    )
  )

  self.Refreshing = false
end

addon.UI.Views.OptionsList = OptionsList
