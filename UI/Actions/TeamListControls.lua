local _, addon = ...

local L = addon.L
local TeamListControls = {}


local SORT_BUTTON_WIDTH = 67
local SORT_BUTTON_HEIGHT = 20

local MENU_TEMPLATES = {
  "WowStyle1FilterDropdownTemplate",
  "WowStyle1DropdownTemplate",
}

function TeamListControls:Create(parent)
  local frame =
      addon.UI.Base.Panel:Create(
        parent,
        {
          width = 238,
          height = 36,
          background = "BACKGROUND"
        }
      )

  self.Frame = frame

  self.SearchInput =
      CreateFrame(
        "EditBox",
        nil,
        frame,
        "InputBoxTemplate"
      )

  self.SearchInput:SetSize(
    170,
    30
  )

  self.SearchInput:SetPoint(
    "TOPLEFT",
    frame,
    "TOPLEFT",
    10,
    -8
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
    L["SEARCH_TEAMS"]
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

  local sortModes = {
    "name",
    "modified",
    "favorites",
  }

  local dropdown

  for _, template in ipairs(MENU_TEMPLATES) do
    local created,
    button =
        pcall(
          CreateFrame,
          "DropdownButton",
          nil,
          frame,
          template
        )

    if created and button then
      dropdown = button
      break
    end
  end

  if dropdown then
    dropdown:SetHeight(
      SORT_BUTTON_HEIGHT
    )

    dropdown:SetText(L["SORT"])

    dropdown.resizeToText = false

    dropdown:SetWidth(
      SORT_BUTTON_WIDTH
    )

    dropdown:SetPoint(
      "LEFT",
      self.SearchInput,
      "RIGHT",
      6,
      -1
    )

    dropdown:SetupMenu(
      function(_, rootDescription)
        rootDescription:CreateTitle(L["SORT_TEAMS"])

        for _, sortMode in ipairs(sortModes) do
          rootDescription:CreateRadio(
            addon.Constants.SORT_LABELS[sortMode],

            function()
              return addon.Services.Team:GetSortMode() == sortMode
            end,

            function()
              addon.Services.Team:SetSortMode(sortMode)
            end
          )
        end
      end
    )

    self.SortButton = dropdown
  end

  return frame
end

addon.UI.Actions.TeamListControls = TeamListControls
