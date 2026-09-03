local _, addon = ...

local PetTypeFilterBar = {}
PetTypeFilterBar.__index = PetTypeFilterBar

local BAR_HEIGHT = 56

local DROPDOWN_HEIGHT = 22
local DROPDOWN_WIDTH = 216

local LEVEL_BUTTON_SIZE = 24

local TYPE_BUTTON_SIZE = 24
local TYPE_BUTTON_SPACING = 1

--------------------------------------------------
-- Pet types
--------------------------------------------------
local PET_FAMILY_ICONS = {
  [1] = "Interface\\Icons\\Pet_Type_Humanoid",
  [2] = "Interface\\Icons\\Pet_Type_Dragon",
  [3] = "Interface\\Icons\\Pet_Type_Flying",
  [4] = "Interface\\Icons\\Pet_Type_Undead",
  [5] = "Interface\\Icons\\Pet_Type_Critter",
  [6] = "Interface\\Icons\\Pet_Type_Magical",
  [7] = "Interface\\Icons\\Pet_Type_Elemental",
  [8] = "Interface\\Icons\\Pet_Type_Beast",
  [9] = "Interface\\Icons\\Pet_Type_Water",
  [10] = "Interface\\Icons\\Pet_Type_Mechanical",
}

local PET_TYPE_NAMES = {
  [1] = _G.BATTLE_PET_NAME_1 or "Humanoid",
  [2] = _G.BATTLE_PET_NAME_2 or "Dragonkin",
  [3] = _G.BATTLE_PET_NAME_3 or "Flying",
  [4] = _G.BATTLE_PET_NAME_4 or "Undead",
  [5] = _G.BATTLE_PET_NAME_5 or "Critter",
  [6] = _G.BATTLE_PET_NAME_6 or "Magic",
  [7] = _G.BATTLE_PET_NAME_7 or "Elemental",
  [8] = _G.BATTLE_PET_NAME_8 or "Beast",
  [9] = _G.BATTLE_PET_NAME_9 or "Aquatic",
  [10] = _G.BATTLE_PET_NAME_10 or "Mechanical",
}

--------------------------------------------------
-- Modes
--------------------------------------------------
local FILTER_MODES = {
  {
    key = "petType",
    label = "Pet Families",
  },
  {
    key = "strongVs",
    label = "Strong Vs",
  },
  {
    key = "weakVs",
    label = "Weak Vs",
  },
  {
    key = "takesMoreFrom",
    label = "Takes More From",
  },
  {
    key = "takesLessFrom",
    label = "Takes Less From",
  },
}

--------------------------------------------------
-- Helpers
--------------------------------------------------
local function FireChanged()
  addon.EventBus:Fire(
    addon.Events.PET_TYPE_FILTER_CHANGED
  )
end

local function GetModeLabel(mode)
  for _, config in ipairs(FILTER_MODES) do
    if config.key == mode then
      return config.label
    end
  end

  return "Pet Families"
end

--------------------------------------------------
-- Level 25 button
--------------------------------------------------
local function CreateLevelButton(instance)
  local button =
      CreateFrame(
        "Button",
        nil,
        instance.Frame
      )

  button:SetSize(
    LEVEL_BUTTON_SIZE,
    LEVEL_BUTTON_SIZE
  )

  --------------------------------------------------
  -- Black round background
  --------------------------------------------------
  button.Background =
      button:CreateTexture(
        nil,
        "BACKGROUND"
      )

  button.Background:SetPoint(
    "CENTER"
  )

  button.Background:SetSize(
    LEVEL_BUTTON_SIZE - 4,
    LEVEL_BUTTON_SIZE - 4
  )

  button.Background:SetTexture(
    "Interface\\COMMON\\Indicator-Gray"
  )

  button.Background:SetVertexColor(
    0,
    0,
    0,
    1
  )

  --------------------------------------------------
  -- Gold ring
  --------------------------------------------------
  button.Ring =
      button:CreateTexture(
        nil,
        "ARTWORK"
      )

  button.Ring:SetAllPoints()

  button.Ring:SetTexture(
    "Interface\\COMMON\\goldring"
  )

  --------------------------------------------------
  -- Level text
  --------------------------------------------------
  button.Text =
      button:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontNormalSmall"
      )

  button.Text:SetPoint(
    "CENTER",
    0,
    0
  )

  button.Text:SetText("25")

  button.Text:SetTextColor(
    1,
    0.82,
    0,
    1
  )

  --------------------------------------------------
  -- Round hover highlight
  --------------------------------------------------

  button.Highlight =
      button:CreateTexture(
        nil,
        "HIGHLIGHT"
      )

  button.Highlight:SetPoint(
    "CENTER"
  )

  button.Highlight:SetSize(
    LEVEL_BUTTON_SIZE + 4,
    LEVEL_BUTTON_SIZE + 4
  )

  button.Highlight:SetTexture(
    "Interface\\COMMON\\Indicator-Grey"
  )

  button.Highlight:SetBlendMode(
    "ADD"
  )

  button.Highlight:SetAlpha(
    0.45
  )

  --------------------------------------------------
  -- Click
  --------------------------------------------------

  button:SetScript(
    "OnClick",
    function()
      addon.Services.PetTypeFilter:
          ToggleLevel25Only()

      instance:Refresh()

      FireChanged()
    end
  )

  --------------------------------------------------
  -- Tooltip
  --------------------------------------------------

  button:SetScript(
    "OnEnter",
    function(self)
      GameTooltip:SetOwner(
        self,
        "ANCHOR_RIGHT"
      )

      GameTooltip:SetText(
        "Level 25"
      )

      GameTooltip:AddLine(
        "Show only level 25 Battle Pets.",
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

  return button
end

--------------------------------------------------
-- Pet type button
--------------------------------------------------
local function CreatePetTypeButton(instance, petType)
  local button =
      CreateFrame(
        "Button",
        nil,
        instance.Frame,
        "BackdropTemplate"
      )

  button:SetSize(
    TYPE_BUTTON_SIZE,
    TYPE_BUTTON_SIZE
  )

  button.PetType = petType

  --------------------------------------------------
  -- Blizzard-style button background
  --------------------------------------------------
  button:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",

    edgeSize = 10,

    insets = {
      left = 2,
      right = 2,
      top = 2,
      bottom = 2,
    },
  })

  button:SetBackdropColor(
    0.025,
    0.025,
    0.025,
    0.95
  )

  button:SetBackdropBorderColor(
    0.30,
    0.30,
    0.30,
    1
  )

  --------------------------------------------------
  -- Pet family icon
  --------------------------------------------------

  button.Icon =
      button:CreateTexture(
        nil,
        "ARTWORK"
      )

  button.Icon:SetPoint(
    "CENTER"
  )

  button.Icon:SetSize(
    TYPE_BUTTON_SIZE - 4,
    TYPE_BUTTON_SIZE - 4
  )

  button.Icon:SetTexture(
    PET_FAMILY_ICONS[
    petType
    ]
  )

  button.Icon:SetTexCoord(
    0.08,
    0.92,
    0.08,
    0.92
  )

  --------------------------------------------------
  -- Highlight
  --------------------------------------------------

  button.Highlight =
      button:CreateTexture(
        nil,
        "HIGHLIGHT"
      )

  button.Highlight:SetPoint(
    "TOPLEFT",
    2,
    -2
  )

  button.Highlight:SetPoint(
    "BOTTOMRIGHT",
    -2,
    2
  )

  button.Highlight:SetColorTexture(
    1,
    1,
    1,
    0.10
  )

  --------------------------------------------------
  -- Click
  --------------------------------------------------
  button:SetScript(
    "OnClick",
    function(self)
      local service =
          addon.Services.PetTypeFilter

      service:ToggleType(
        self.PetType
      )

      local selectedTypes =
          service:GetSelectedTypes()

      local count = 0

      if selectedTypes then
        for _ in pairs(
          selectedTypes
        ) do
          count = count + 1
        end
      end

      instance:Refresh()

      FireChanged()
    end
  )

  --------------------------------------------------
  -- Tooltip
  --------------------------------------------------

  button:SetScript(
    "OnEnter",
    function(self)
      local service =
          addon.Services.PetTypeFilter

      local mode =
          service:GetMode()

      GameTooltip:SetOwner(
        self,
        "ANCHOR_RIGHT"
      )

      GameTooltip:SetText(
        PET_TYPE_NAMES[
        self.PetType
        ]
      )

      if mode == "petType" then
        GameTooltip:AddLine(
          "Show pets of this family.",
          1,
          1,
          1,
          true
        )
      elseif mode == "strongVs" then
        GameTooltip:AddLine(
          "Show pet families whose attacks are strong against this family.",
          1,
          1,
          1,
          true
        )
      elseif mode == "weakVs" then
        GameTooltip:AddLine(
          "Show pet families whose attacks are weak against this family.",
          1,
          1,
          1,
          true
        )
      elseif mode == "takesMoreFrom" then
        GameTooltip:AddLine(
          "Show pet families that take increased damage from this family.",
          1,
          1,
          1,
          true
        )
      elseif mode == "takesLessFrom" then
        GameTooltip:AddLine(
          "Show pet families that take reduced damage from this family.",
          1,
          1,
          1,
          true
        )
      end

      GameTooltip:Show()
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

--------------------------------------------------
-- Mode dropdown
--------------------------------------------------
local function CreateModeDropdown(instance)
  local dropdown =
      CreateFrame(
        "DropdownButton",
        nil,
        instance.Frame,
        "WowStyle1DropdownTemplate"
      )

  dropdown:SetSize(
    DROPDOWN_WIDTH,
    DROPDOWN_HEIGHT
  )

  local text = dropdown.Text

  if text then
    text:ClearAllPoints()

    text:SetPoint(
      "LEFT",
      dropdown,
      "LEFT",
      14,
      1
    )

    text:SetPoint(
      "RIGHT",
      dropdown.Arrow,
      "LEFT",
      -4,
      1
    )

    text:SetJustifyH("LEFT")
    text:SetJustifyV("MIDDLE")
  end

  dropdown:SetDefaultText(
    "Pet Type"
  )

  dropdown:SetupMenu(
    function(_, rootDescription)
      local service = addon.Services.PetTypeFilter

      for _, config in ipairs(FILTER_MODES) do
        rootDescription:CreateRadio(
          config.label,

          function(mode)
            return service:GetMode() == mode
          end,

          function(mode)
            service:SetMode(mode)
            instance:Refresh()
            FireChanged()
          end,

          config.key
        )
      end
    end
  )

  return dropdown
end

--------------------------------------------------
-- Create
--------------------------------------------------
function PetTypeFilterBar:Create(parent)
  assert(
    parent,
    "PetTypeFilterBar requires a parent"
  )

  local frame =
      CreateFrame(
        "Frame",
        nil,
        parent,
        "BackdropTemplate"
      )

  frame:SetHeight(
    BAR_HEIGHT
  )

  frame:SetBackdrop({
    bgFile = "Interface\\FrameGeneral\\UI-Background-Marble",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",

    edgeSize = 12,

    insets = {
      left = 3,
      right = 3,
      top = 3,
      bottom = 3,
    },
  })

  frame:SetBackdropColor(
    0.63,
    0.63,
    0.63,
    0.85
  )

  frame:SetBackdropBorderColor(
    0.35,
    0.35,
    0.35,
    1
  )

  local instance =
      setmetatable({
        Frame = frame,
        PetTypeButtons = {},
      }, PetTypeFilterBar)

  --------------------------------------------------
  -- Level 25
  --------------------------------------------------
  instance.Level25Button =
      CreateLevelButton(
        instance
      )

  instance.Level25Button:SetPoint(
    "TOPLEFT",
    frame,
    "TOPLEFT",
    5,
    -4
  )

  --------------------------------------------------
  -- Dropdown
  --------------------------------------------------
  instance.ModeDropdown =
      CreateModeDropdown(
        instance
      )

  instance.ModeDropdown:SetPoint(
    "TOPRIGHT",
    frame,
    "TOPRIGHT",
    -6,
    -5
  )

  --------------------------------------------------
  -- Type buttons
  --------------------------------------------------
  local previousButton = nil

  for petType = 1, 10 do
    local button =
        CreatePetTypeButton(
          instance,
          petType
        )

    if not previousButton then
      button:SetPoint(
        "BOTTOMLEFT",
        frame,
        "BOTTOMLEFT",
        3,
        3
      )
    else
      button:SetPoint(
        "LEFT",
        previousButton,
        "RIGHT",
        TYPE_BUTTON_SPACING,
        0
      )
    end

    instance.PetTypeButtons[petType] = button

    previousButton = button
  end

  instance:Refresh()

  return instance
end

--------------------------------------------------
-- Refresh
--------------------------------------------------
function PetTypeFilterBar:Refresh()
  local service = addon.Services.PetTypeFilter

  if not service then
    return
  end

  --------------------------------------------------
  -- Dropdown text
  --------------------------------------------------
  local mode = service:GetMode()

  if self.ModeDropdown then
    self.ModeDropdown:
        SetDefaultText(
          GetModeLabel(mode)
        )
  end

  --------------------------------------------------
  -- Level 25
  --------------------------------------------------
  local level25Active = service:IsLevel25Only()

  if level25Active then
    self.Level25Button.Background:
        SetVertexColor(
          1,
          0.82,
          0,
          1
        )

    self.Level25Button.Background:
        SetAlpha(1)

    self.Level25Button.Text:
        SetTextColor(
          1,
          0.82,
          0,
          1
        )
  else
    self.Level25Button.Background:
        SetVertexColor(
          0.65,
          0.55,
          0.20,
          1
        )

    self.Level25Button.Background:
        SetAlpha(0.65)

    self.Level25Button.Text:
        SetTextColor(
          0.75,
          0.70,
          0.45,
          1
        )
  end

  --------------------------------------------------
  -- Pet types
  --------------------------------------------------
  for petType = 1, 10 do
    local button = self.PetTypeButtons[petType]

    if button then
      local selected = service:IsTypeSelected(petType)

      button:SetBackdropBorderColor(
        0.30,
        0.30,
        0.30,
        1
      )

      if selected then
        button.Icon:SetDesaturated(
          false
        )

        button.Icon:SetAlpha(
          1
        )
      else
        button.Icon:SetDesaturated(
          true
        )

        button.Icon:SetAlpha(
          0.55
        )
      end
    end
  end
end

--------------------------------------------------
-- Helpers
--------------------------------------------------
function PetTypeFilterBar:GetFrame()
  return self.Frame
end

function PetTypeFilterBar:Show()
  self.Frame:Show()
end

function PetTypeFilterBar:Hide()
  self.Frame:Hide()
end

--------------------------------------------------
-- Register
--------------------------------------------------
addon.UI.Components.PetTypeFilterBar = PetTypeFilterBar
