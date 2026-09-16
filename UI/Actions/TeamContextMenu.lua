local _, addon = ...

local L = addon.L

local TeamContextMenu = {}

function TeamContextMenu:Show(owner, team)
  if not owner or not team then
    return
  end

  local hasNotes =
      addon.Utils:Trim(
        team.notes or ""
      ) ~= ""

  local hasScript =
      addon.Utils:Trim(
        team.script or ""
      ) ~= ""

  MenuUtil.CreateContextMenu(
    owner,
    function(_, rootDescription)
      rootDescription:CreateTitle(
        team.name or L["TEAM"]
      )

      rootDescription:CreateButton(
        hasNotes
        and L["EDIT_NOTES"]
        or L["ADD_NOTES"],
        function()
          addon.UI.Dialogs.TeamNotesDialog:Show(
            team
          )
        end
      )

      rootDescription:CreateButton(
        hasScript
        and L["EDIT_SCRIPT"]
        or L["ADD_SCRIPT"],
        function()
          addon.UI.Dialogs.TeamScriptDialog:Show(
            team
          )
        end
      )

      if addon.UI.Actions.TeamStatisticsMenu then
        addon.UI.Actions.TeamStatisticsMenu:
            Show(
              rootDescription,
              team
            )
      end

      rootDescription:CreateDivider()

      local teamService = addon.Services.Team
      local index = teamService:GetIndex(team.id)
      local teams = teamService:GetTeamsInFolder(team.folderID)

      local moveUp =
          rootDescription:CreateButton(
            L["MOVE_UP"],
            function()
              teamService:MoveUp(team.id)
            end
          )

      moveUp:SetEnabled(
        index ~= nil
        and index > 1
      )

      local moveDown =
          rootDescription:CreateButton(
            L["MOVE_DOWN"],
            function()
              teamService:MoveDown(team.id)
            end
          )

      moveDown:SetEnabled(
        index ~= nil
        and index < #teams
      )

      rootDescription:CreateButton(
        L["MOVE_TO_FOLDER"],
        function()
          addon.UI.Dialogs.MoveTeamDialog:Show(team)
        end
      )

      rootDescription:CreateDivider()

      rootDescription:CreateButton(
        L["EDIT_TEAM"],
        function()
          addon.UI.Dialogs.EditTeamDialog:Show(team)
        end
      )

      rootDescription:CreateButton(
        L["EXPORT_TEAM"],
        function()
          addon.UI.Dialogs.ExportDialog:Show(team)
        end
      )

      rootDescription:CreateButton(
        L["DELETE_TEAM"],
        function()
          addon.UI.Dialogs.DeleteTeamDialog:Show(team)
        end
      )
    end
  )
end

addon.UI.Actions.TeamContextMenu = TeamContextMenu
