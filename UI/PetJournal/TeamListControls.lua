local addonName, addon = ...

addon.UI = addon.UI or {}
addon.UI.Views = addon.UI.Views or {}

local TeamListControls = {}

local SORT_LABELS = {
  name = "Name",
  modified = "Recent",
  favorites = "Favorites",
}

function TeamListControls:Create(parent)
  local frame =
      addon.UI.Components.Panel:Create(
        parent,
        {
          width = 295,
          height = 70,
        }
      )

  self.Frame = frame
  self.SortButtons = {}

  self.SearchInput =
      CreateFrame(
        "EditBox",
        nil,
        frame,
        "InputBoxTemplate"
      )

  self.SearchInput:SetSize(
    270,
    26
  )

  self.SearchInput:SetPoint(
    "TOPLEFT",
    frame,
    "TOPLEFT",
    15,
    -10
  )

  self.SearchInput:SetAutoFocus(false)
  self.SearchInput:SetMaxLetters(80)

  self.SearchInput.Instructions =
      self.SearchInput:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontDisableSmall"
      )

  self.SearchInput.Instructions:SetPoint(
    "LEFT",
    self.SearchInput,
    "LEFT",
    8,
    0
  )

  self.SearchInput.Instructions:SetText(
    "Search teams or pets..."
  )

  self.SearchInput:SetScript(
    "OnTextChanged",
    function(editBox)
      local value =
          editBox:GetText() or ""

      editBox.Instructions:SetShown(
        value == ""
        and not editBox:HasFocus()
      )

      addon.Services.Search:SetQuery(
        value
      )
    end
  )

  self.SearchInput:SetScript(
    "OnEditFocusGained",
    function(editBox)
      editBox.Instructions:Hide()
    end
  )

  self.SearchInput:SetScript(
    "OnEditFocusLost",
    function(editBox)
      editBox.Instructions:SetShown(
        editBox:GetText() == ""
      )
    end
  )

  self.SearchInput:SetScript(
    "OnEscapePressed",
    function(editBox)
      editBox:SetText("")
      editBox:ClearFocus()
    end
  )

  local previousButton = nil

  local sortModes = {
    "name",
    "modified",
    "favorites",
  }

  for _, sortMode in ipairs(sortModes) do
    local button =
        addon.UI.Components.Button:Create(
          frame,
          {
            text = SORT_LABELS[sortMode],
            width = 90,
            height = 24,

            onClick = function()
              addon.Services.Team:SetSortMode(
                sortMode
              )
            end,
          }
        )

    if previousButton then
      button:SetPoint(
        "LEFT",
        previousButton,
        "RIGHT",
        4,
        0
      )
    else
      button:SetPoint(
        "BOTTOMLEFT",
        frame,
        "BOTTOMLEFT",
        10,
        10
      )
    end

    button.SortMode = sortMode

    self.SortButtons[sortMode] =
        button

    previousButton = button
  end

  if not self.EventsRegistered then
    self.EventsRegistered = true

    addon.EventBus:Register(
      addon.Events.TEAM_SORT_CHANGED,
      function()
        self:RefreshSortButtons()
      end
    )
  end

  self:RefreshSortButtons()

  return frame
end

function TeamListControls:RefreshSortButtons()
  if not self.Frame then
    return
  end

  local activeMode =
      addon.Services.Team:GetSortMode()

  for sortMode, button in pairs(
    self.SortButtons
  ) do
    if sortMode == activeMode then
      button:Disable()
    else
      button:Enable()
    end
  end
end

addon.UI.Views.TeamListControls =
    TeamListControls
