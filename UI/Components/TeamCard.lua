local addonName, addon = ...

addon.UI = addon.UI or {}
addon.UI.Components = addon.UI.Components or {}

local TeamCard = {}

local CARD_WIDTH = 270
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

local function CreateActionButton(
    parent,
    texture,
    tooltip,
    onClick
)
  local button =
      CreateFrame(
        "Button",
        nil,
        parent
      )

  button:SetSize(18, 18)

  button.Icon =
      button:CreateTexture(
        nil,
        "ARTWORK"
      )

  button.Icon:SetAllPoints()
  button.Icon:SetTexture(texture)

  button:SetScript("OnClick", function(self)
    onClick(parent.Team)
  end)

  button:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(
      self,
      "ANCHOR_RIGHT"
    )

    GameTooltip:SetText(tooltip)
    GameTooltip:Show()
  end)

  button:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  return button
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

  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", function(self)
    self.WasDragged = true
    addon.UI.DragDrop:StartTeam(
      self.Team,
      self
    )
  end)

  frame:SetScript("OnDragStop", function(self)
    addon.UI.DragDrop:StopTeam()
    C_Timer.After(0, function()
      self.WasDragged = false
    end)
  end)

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

  frame.Title:ClearAllPoints()
  frame.Title:SetPoint(
    "TOPLEFT",
    frame,
    "TOPLEFT",
    10,
    -9
  )

  frame.Title:SetWidth(
    CARD_WIDTH - 110
  )


  frame.Title:SetJustifyH("LEFT")
  frame.Title:SetWordWrap(false)

  frame.FavoriteButton =
      CreateFrame(
        "Button",
        nil,
        frame
      )

  frame.FavoriteButton:SetSize(
    24,
    24
  )

  frame.FavoriteButton:SetPoint(
    "TOPRIGHT",
    frame,
    "TOPRIGHT",
    -2,
    -5
  )

  frame.FavoriteButton.Icon =
      frame.FavoriteButton:CreateTexture(
        nil,
        "ARTWORK"
      )

  frame.FavoriteButton.Icon:SetSize(
    30,
    30
  )

  frame.FavoriteButton.Icon:SetPoint(
    "CENTER"
  )

  frame.FavoriteButton.Icon:SetTexture(
    addon.UI.Theme.Icons.Favorite
  )

  frame.FavoriteButton.Text =
      frame.FavoriteButton:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontNormalLarge"
      )

  frame.FavoriteButton.Text:SetPoint(
    "CENTER"
  )

  frame.FavoriteButton:SetScript(
    "OnClick",
    function()
      local team = frame.Team

      if not team then
        return
      end

      local updatedTeam, errorMessage =
          addon.Services.Team:ToggleFavorite(
            team.id
          )

      if not updatedTeam then
        addon.Logger:Warn(
          errorMessage
          or "Unable to update favorite"
        )

        return
      end

      frame:SetTeam(updatedTeam)
    end
  )

  frame.FavoriteButton:SetScript(
    "OnEnter",
    function(button)
      GameTooltip:SetOwner(
        button,
        "ANCHOR_RIGHT"
      )

      if frame.Team
          and frame.Team.favorite then
        GameTooltip:SetText(
          "Remove from Favorites"
        )
      else
        GameTooltip:SetText(
          "Add to Favorites"
        )
      end

      GameTooltip:Show()
    end
  )

  frame.FavoriteButton:SetScript(
    "OnLeave",
    function()
      GameTooltip:Hide()
    end
  )

  frame.EditButton =
      CreateActionButton(
        frame,
        addon.UI.Theme.Icons.Edit,
        "Edit Team",
        function(team)
          addon.UI.Views.EditTeamDialog:Show(team)
        end
      )

  frame.EditButton:SetPoint(
    "TOPRIGHT",
    frame.FavoriteButton,
    "TOPLEFT",
    -3,
    0
  )

  frame.MoveButton =
      CreateActionButton(
        frame,
        addon.UI.Theme.Icons.Move,
        "Move Team",
        function(team)
          addon.UI.Views.MoveTeamDialog:Show(team)
        end
      )

  frame.MoveButton:SetPoint(
    "RIGHT",
    frame.EditButton,
    "LEFT",
    -3,
    0
  )

  frame.DeleteButton =
      CreateActionButton(
        frame,
        addon.UI.Theme.Icons.Delete,
        "Delete Team",
        function(team)
          StaticPopup_Show(
            "PETMATCH_DELETE_TEAM",
            team.name,
            nil,
            team
          )
        end
      )

  frame.DeleteButton:SetPoint(
    "RIGHT",
    frame.MoveButton,
    "LEFT",
    -3,
    0
  )

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

    self.Title:SetText(
      newTeam.name or "Unnamed Team"
    )

    if newTeam.favorite then
      self.FavoriteButton.Icon:SetDesaturated(false)
      self.FavoriteButton.Icon:SetVertexColor(
        1,
        0.82,
        0
      )
      self.FavoriteButton.Icon:SetAlpha(1)
    else
      self.FavoriteButton.Icon:SetDesaturated(true)
      self.FavoriteButton.Icon:SetVertexColor(
        0.7,
        0.7,
        0.7
      )
      self.FavoriteButton.Icon:SetAlpha(0.45)
    end

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

  frame:SetScript("OnClick", function(self, button)
    if self.WasDragged then
      return
    end

    if button ~= "LeftButton" then
      return
    end

    local team = self.Team

    if not team then
      return
    end

    local success, errorMessage =
        addon.Services.Team:Load(team.id)

    if not success then
      addon.Logger:Warn(
        errorMessage or "Unable to load team"
      )

      return
    end

    addon.Settings:SetUI(
      "selectedTeamID",
      team.id
    )

    addon.EventBus:Fire(
      addon.Events.TEAM_SELECTED,
      team,
      self
    )

    addon.Logger:Info(
      "Loaded team:",
      team.name
    )
  end)

  frame:SetTeam(team)
  ApplyVisualState(frame)

  return frame
end

StaticPopupDialogs.PETMATCH_DELETE_TEAM = {
  text = "Delete team \"%s\"?",
  button1 = "Delete",
  button2 = "Cancel",

  OnAccept = function(_, team)
    if not team then
      return
    end

    local deleted =
        addon.Services.Team:Delete(
          team.id
        )

    if not deleted then
      addon.Logger:Warn(
        "Unable to delete team"
      )
    end
  end,

  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

addon.UI.Components.TeamCard = TeamCard
