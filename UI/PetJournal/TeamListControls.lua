local _, addon = ...

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
          width = 285,
          height = 46,
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
    235,
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

  local sortModes = {
    "name",
    "modified",
    "favorites",
  }

  self.SortButton =
      CreateFrame(
        "Button",
        nil,
        frame
      )

  self.SortButton:SetSize(
    28,
    28
  )

  self.SortButton:SetPoint(
    "LEFT",
    self.SearchInput,
    "RIGHT",
    0,
    0
  )

  self.SortButton.Icon =
      self.SortButton:CreateTexture(
        nil,
        "ARTWORK"
      )

  self.SortButton.Icon:SetSize(
    26,
    26
  )

  self.SortButton.Icon:SetPoint(
    "CENTER"
  )

  self.SortButton.Icon:SetAtlas(
    "charactercreate-icon-customize-body-selected"
  )

  self.SortButton:SetScript(
    "OnClick",
    function(button)
      MenuUtil.CreateContextMenu(
        button,
        function(ownerRegion, rootDescription)
          rootDescription:CreateTitle(
            "Sort Teams"
          )

          local currentSortMode =
              addon.Services.Team:GetSortMode()

          for _, sortMode in ipairs(sortModes) do
            rootDescription:CreateRadio(
              SORT_LABELS[sortMode],
              function()
                return currentSortMode
                    == sortMode
              end,
              function()
                addon.Services.Team:SetSortMode(
                  sortMode
                )
              end
            )
          end
        end
      )
    end
  )

  self.SortButton:SetScript(
    "OnEnter",
    function(button)
      button.Icon:SetAlpha(1)

      GameTooltip:SetOwner(
        button,
        "ANCHOR_RIGHT"
      )

      local sortMode =
          addon.Services.Team:GetSortMode()

      GameTooltip:SetText(
        "Sort Teams"
      )

      GameTooltip:AddLine(
        SORT_LABELS[sortMode]
        or "Unknown",
        1,
        1,
        1
      )

      GameTooltip:Show()
    end
  )

  self.SortButton:SetScript(
    "OnLeave",
    function(button)
      button.Icon:SetAlpha(0.75)
      GameTooltip:Hide()
    end
  )

  self.SortButton.Icon:SetAlpha(0.75)

  return frame
end

addon.UI.Views.TeamListControls =
    TeamListControls
