local addonName, addon = ...

addon.UI = addon.UI or {}
addon.UI.Components = addon.UI.Components or {}

local TeamCard = {}

local CARD_WIDTH = 280
local CARD_HEIGHT = 116
local SLOT_SPACING = 8
local SLOT_START_X = 10

local function ApplyVisualState(frame)
  if frame.Selected then
    frame:SetBackdropColor(0.12, 0.22, 0.28, 0.95)
    frame:SetBackdropBorderColor(0.20, 0.70, 1.00, 1.00)
  elseif frame.Hovered then
    frame:SetBackdropColor(0.12, 0.12, 0.12, 0.90)
    frame:SetBackdropBorderColor(0.65, 0.55, 0.30, 1.00)
  else
    frame:SetBackdropColor(0.04, 0.04, 0.04, 0.70)
    frame:SetBackdropBorderColor(0.35, 0.30, 0.20, 0.85)
  end
end

function TeamCard:Create(parent, team)
  assert(parent, "TeamCard requires a parent frame")
  assert(team, "TeamCard requires a team")

  local frame = CreateFrame(
    "Button",
    nil,
    parent,
    "BackdropTemplate"
  )

  frame:SetSize(CARD_WIDTH, CARD_HEIGHT)

  frame:SetBackdrop({
    bgFile = "Interface/Buttons/WHITE8X8",
    edgeFile = "Interface/Buttons/WHITE8X8",
    edgeSize = 1,
  })

  frame.Team = team
  frame.Selected = false
  frame.Hovered = false
  frame.PetSlots = {}

  frame.Title = frame:CreateFontString(
    nil,
    "OVERLAY",
    "GameFontNormal"
  )

  frame.Title:SetPoint(
    "TOPLEFT",
    frame,
    "TOPLEFT",
    10,
    -9
  )

  frame.Title:SetPoint(
    "TOPRIGHT",
    frame,
    "TOPRIGHT",
    -10,
    -9
  )

  frame.Title:SetJustifyH("LEFT")
  frame.Title:SetWordWrap(false)

  for slotIndex = 1, 3 do
    local petSlot = addon.UI.Components.PetSlot:Create(frame)
    local petSlotFrame = petSlot:GetFrame()

    petSlotFrame:SetPoint(
      "TOPLEFT",
      frame,
      "TOPLEFT",
      SLOT_START_X
      + ((slotIndex - 1)
        * (petSlotFrame:GetWidth() + SLOT_SPACING)),
      -30
    )

    frame.PetSlots[slotIndex] = petSlot
  end

  function frame:SetTeam(newTeam)
    self.Team = newTeam

    local prefix =
        newTeam.favorite
        and "★ "
        or ""

    self.Title:SetText(
      prefix .. (newTeam.name or "Unnamed Team")
    )

    for slotIndex = 1, 3 do
      self.PetSlots[slotIndex]:SetPet(
        newTeam.pets
        and newTeam.pets[slotIndex]
        or nil
      )
    end
  end

  function frame:SetSelected(selected)
    self.Selected = selected == true
    ApplyVisualState(self)
  end

  frame:SetScript("OnEnter", function(self)
    self.Hovered = true
    ApplyVisualState(self)
  end)

  frame:SetScript("OnLeave", function(self)
    self.Hovered = false
    ApplyVisualState(self)
  end)

  frame:SetScript("OnClick", function(self)
    addon.EventBus:Fire(
      addon.Events.TEAM_SELECTED,
      self.Team,
      self
    )
  end)

  frame:SetTeam(team)
  ApplyVisualState(frame)

  return frame
end

addon.UI.Components.TeamCard = TeamCard
