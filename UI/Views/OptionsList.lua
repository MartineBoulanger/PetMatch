local _, addon = ...

local OptionsList = {}

local CONTENT_WIDTH = 235
local CONTENT_HEIGHT = 545

local SECTION_SPACING = 0
local CONTENT_PADDING = 0

local DUPLICATE_SECTION_HEIGHT = 104
local BREED_SECTION_HEIGHT = 104
local PET_LIST_SECTION_HEIGHT = 86
local PET_CARD_SECTION_HEIGHT = 104
local PET_CARD_VISIBILITY_SECTION_HEIGHT = 104
local LEVELLING_QUEUE_SECTION_HEIGHT = 96
local SUMMONED_PET_SECTION_HEIGHT = 86
local PET_TYPE_FILTER_SECTION_HEIGHT = 104
local TEAM_CARD_SECTION_HEIGHT = 86

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
    petCard = false,
    petCardVisibility = false,
    levellingQueue = false,
    summonedPet = false,
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
          or key == "petCardLevellingQueueEnabled" then
        self:RefreshPetCardVisibilityMode()
      elseif key == "levellingQueueAutoAddMode" then
        self:RefreshLevellingQueueAutoAddMode()
      elseif key == "summonedPetMode" then
        self:RefreshSummonedPetMode()
      elseif key == "petTypeFilterDisplayMode" then
        self:RefreshPetTypeFilterMode()
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

  -- Levelling Queue Option
  self.LevellingQueueAccordion = nil
  self.LevellingQueueAutoAddEnabledButton = nil
  self.LevellingQueueAutoAddDisabledButton = nil

  -- Summoned Pet Option
  self.SummonedPetAccordion = nil
  self.AutoDismissPetButton = nil
  self.KeepSummonedPetButton = nil

  -- Pet Type Filter Option
  self.PetTypeFilterAccordion = nil
  self.PetTypeFilterBothButton = nil
  self.PetTypeFilterMenuButton = nil
  self.PetTypeFilterBarButton = nil
end

function OptionsList:GetSections()
  return {
    {
      key = "duplicateTeams",
      title = "Duplicate Teams",
      contentHeight = DUPLICATE_SECTION_HEIGHT,
      build = function(content)
        self:BuildDuplicateTeamOptions(content)
      end,
    },
    {
      key = "petBreeds",
      title = "Pet Breeds",
      contentHeight = BREED_SECTION_HEIGHT,
      build = function(content)
        self:BuildBreedOptions(content)
      end,
    },
    {
      key = "petList",
      title = "Pet List",
      contentHeight = PET_LIST_SECTION_HEIGHT,
      build = function(content)
        self:BuildPetListOptions(content)
      end,
    },
    {
      key = "teamCards",
      title = "Team Cards",
      contentHeight = TEAM_CARD_SECTION_HEIGHT,
      build = function(content)
        self:BuildTeamCardOptions(content)
      end,
    },
    {
      key = "petCard",
      title = "Pet Card",
      contentHeight = PET_CARD_SECTION_HEIGHT,
      build = function(content)
        self:BuildPetCardOptions(content)
      end,
    },
    {
      key = "petCardVisibility",
      title = "Pet Card Visibility",
      contentHeight = PET_CARD_VISIBILITY_SECTION_HEIGHT,
      build = function(content)
        self:BuildPetCardVisibilityOptions(content)
      end,
    },
    {
      key = "levellingQueue",
      title = "Levelling Queue",
      contentHeight = LEVELLING_QUEUE_SECTION_HEIGHT,
      build = function(content)
        self:BuildLevellingQueueOptions(content)
      end,
    },
    {
      key = "summonedPet",
      title = "Summoned Pet",
      contentHeight = SUMMONED_PET_SECTION_HEIGHT,
      build = function(content)
        self:BuildSummonedPetOptions(content)
      end,
    },
    {
      key = "petTypeFilters",
      title = "Pet Type Filters",
      contentHeight = PET_TYPE_FILTER_SECTION_HEIGHT,
      build = function(content)
        self:BuildPetTypeFilterOptions(content)
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
    "Choose what happens when an imported team already exists."
  )

  self.SkipButton =
      self:CreateRadioButton(
        parent,
        "Skip existing teams",
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
        "Replace existing teams",
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
        "Keep both",
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
    "Choose how pet breeds are displayed in the Pet Journal."
  )

  self.RightBreedButton =
      self:CreateRadioButton(
        parent,
        "Right side (PetMatch)",
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
        "After pet name (BattlePetBreedID)",
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
        "Hidden",
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
    "Choose the row size used in the Pet Journal pet list."
  )

  self.NormalRowsButton =
      self:CreateRadioButton(
        parent,
        "Normal rows",
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
        "Compact rows",
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
    "Choose the height used for team cards."
  )

  self.TeamCardNormalHeightButton =
      self:CreateRadioButton(
        parent,
        "Normal height",
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
        "Large height",
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
    "Choose how the Pet Card opens in the Pet Journal."
  )

  self.PetCardHoverButton =
      self:CreateRadioButton(
        parent,
        "Show on hover",
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
        "Show on click",
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
        "Show on hover and click",
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
    "Choose where the Pet Card will be visible."
  )

  self.PetCardPetListCheckbox =
      self:CreateCheckbox(
        parent,
        "Pet Journal list",
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
        "Team pets",
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
        "Levelling Queue pets",
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
    "Choose whether newly acquired battle pets below level 25 are automatically added to the Levelling Queue."
  )

  self.LevellingQueueAutoAddEnabledButton =
      self:CreateRadioButton(
        parent,
        "Automatically add new pets",
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
        "Do not automatically add new pets",
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
    "Choose what happens to your currently summoned pet."
  )

  self.AutoDismissPetButton =
      self:CreateRadioButton(
        parent,
        "Auto Dismiss Pet",
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
        "Keep Summoned Pet",
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
    "Choose where the pet type matchup filters are shown."
  )

  self.PetTypeFilterBothButton =
      self:CreateRadioButton(
        parent,
        "Filter Bar and Filter Menu",
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
        "Filter Menu Only",
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
        "Filter Bar Only",
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
      or not self.KeepSummonedPetButton then
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
