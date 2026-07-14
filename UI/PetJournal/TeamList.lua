local addonName, addon = ...

local TeamList = {}

function TeamList:Create(parent)
  local frame = addon.UI.Components.ScrollBox:Create(parent, { width = 320, height = 360 })
  frame.cards = {}
  self.Frame = frame
  addon.EventBus:Register(
    "TEAM_SELECTED",
    function(card)
      for _, item in ipairs(
        self.Frame.cards
      ) do
        if item.SetSelected then
          item:SetSelected(item, item == card
          )
        end
      end
    end
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
  local offset = -15
  for _, team in pairs(teams) do
    local card = addon.UI.Components.TeamCard:Create(self.Frame.Content, team)
    card:SetPoint("TOP", 0, offset)
    offset = offset - 100
    table.insert(self.Frame.cards, card)
  end

  self.Frame.Content:SetHeight(
    math.abs(offset) + 20
  )
end

addon.UI.Views = addon.UI.Views or {}
addon.UI.Views.TeamList = TeamList
