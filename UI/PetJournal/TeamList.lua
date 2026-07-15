local addonName, addon = ...

local TeamList = {}

function TeamList:Create(parent)
  local frame = addon.UI.Components.ScrollBox:Create(parent, { width = 320, height = 450 })
  frame.cards = {}
  self.Frame = frame
  if not self.SelectionListenerRegistered then
    self.SelectionListenerRegistered = true

    addon.EventBus:Register(
      addon.Events.TEAM_SELECTED,
      function(team, selectedCard)
        if not self.Frame then
          return
        end

        for _, card in ipairs(
          self.Frame.cards or {}
        ) do
          card:SetSelected(
            card == selectedCard
          )
        end
      end
    )
  end
  addon.EventBus:Fire(
    "TEAM_SELECTED",
    frame.team
  )
  frame.cards = {}
  self:Refresh()
  frame:Show()
  return frame
end

function TeamList:Refresh()
  if not self.Frame then
    return
  end
  -- oude cards verwijderen
  for _, card in ipairs(self.Frame.cards) do
    card:Hide()
  end

  wipe(self.Frame.cards)
  local teams = addon.Services.Team:GetAllTeams()
  local cardCount = 0

  for _, team in pairs(teams) do
    cardCount = cardCount + 1

    local card =
        addon.UI.Components.TeamCard:Create(
          self.Frame.Content,
          team
        )

    card:SetPoint(
      "TOP",
      self.Frame.Content,
      "TOP",
      0,
      -8 - ((cardCount - 1) * 124)
    )

    table.insert(
      self.Frame.cards,
      card
    )
  end

  self.Frame.Content:SetHeight(
    math.max(
      1,
      8 + (cardCount * 124)
    )
  )
end

addon.UI.Views = addon.UI.Views or {}
addon.UI.Views.TeamList = TeamList
