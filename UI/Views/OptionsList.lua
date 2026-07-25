local _, addon = ...

addon.UI = addon.UI or {}
addon.UI.Views = addon.UI.Views or {}

local OptionsList = {}

local CONTENT_WIDTH = 238
local CONTENT_HEIGHT = 545

local SECTION_SPACING = 0
local CONTENT_PADDING = 0

local DUPLICATE_SECTION_HEIGHT = 104
local BREED_SECTION_HEIGHT = 126

function OptionsList:Create(parent)
  local frame =
      addon.UI.Components.ScrollBox:Create(
        parent,
        {
          width = CONTENT_WIDTH,
          height = CONTENT_HEIGHT,
        }
      )

  self.Frame = frame

  frame.items = {}

  self.ExpandedSections = {
    duplicateTeams = true,
    petBreeds = true,
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

  self.DuplicateAccordion = nil
  self.SkipButton = nil
  self.ReplaceButton = nil
  self.KeepButton = nil

  self.BreedAccordion = nil
  self.RightBreedButton = nil
  self.AfterNameBreedButton = nil
  self.HiddenBreedButton = nil
end

function OptionsList:GetSections()
  return {
    {
      key = "duplicateTeams",
      title = "Duplicate Teams",
      contentHeight =
          DUPLICATE_SECTION_HEIGHT,

      build = function(content)
        self:BuildDuplicateTeamOptions(
          content
        )
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
  }
end

function OptionsList:CreateSection(
    section,
    currentOffset
)
  local expanded =
      self.ExpandedSections[
      section.key
      ] == true

  local accordion =
      addon.UI.Components.Accordion:Create(
        self.Frame.Content,
        {
          title = section.title,
          width = CONTENT_WIDTH,
          expanded = expanded,

          contentHeight =
              section.contentHeight,

          contentPadding = 8,

          onToggle = function(
              control,
              isExpanded
          )
            self.ExpandedSections[
            section.key
            ] = isExpanded

            self:UpdateContentHeight()
          end,
        }
      )

  accordion.SectionKey =
      section.key

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
    self.DuplicateAccordion =
        accordion
  end

  if section.key == "petBreeds" then
    self.BreedAccordion = accordion
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

function OptionsList:BuildDuplicateTeamOptions(
    parent
)
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

function OptionsList:RefreshDuplicateMode()
  if not self.SkipButton
      or not self.ReplaceButton
      or not self.KeepButton then
    return
  end

  local mode =
      addon.Settings:Get(
        "duplicateTeamMode"
      )

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

function OptionsList:UpdateContentHeight()
  if not self.Frame then
    return
  end

  local currentOffset =
      CONTENT_PADDING

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

  local sections =
      self:GetSections()

  local currentOffset =
      CONTENT_PADDING

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

function OptionsList:RefreshBreedMode()
  if not self.RightBreedButton then
    return
  end

  local mode =
      addon.Settings:Get(
        "petListBreedPosition"
      )

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

addon.UI.Views.OptionsList =
    OptionsList
