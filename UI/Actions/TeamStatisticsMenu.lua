local _, addon = ...

local TeamStatisticsMenu = {}

function TeamStatisticsMenu:Show(rootDescription, team)
  if not rootDescription
      or not team then
    return
  end

  rootDescription:CreateButton(
    "Statistics",
    function()
      addon.UI.Dialogs.TeamStatisticsDialog:Show(team)
    end
  )
end

addon.UI.Actions.TeamStatisticsMenu = TeamStatisticsMenu
