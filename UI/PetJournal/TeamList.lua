local addonName, addon = ...

local TeamList = {}

function TeamList:Create(parent)
  local frame =
      addon.UI.Components.Panel:Create(
        parent,
        {
          width = 320,
          height = 400
        }
      )
  frame.cards = {}
  self.Frame = frame
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
    local card =
        addon.UI.Components.TeamCard:Create(
          self.Frame,
          team
        )
    card:SetPoint("TOP", 0, offset)
    offset = offset - 100
    table.insert(
      self.Frame.cards,
      card
    )
  end
end

addon.UI.Views = addon.UI.Views or {}
addon.UI.Views.TeamList = TeamList
