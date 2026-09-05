local _, addon = ...

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
        team.name or "Team"
      )

      rootDescription:CreateButton(
        hasNotes
        and "Edit Notes"
        or "Add Notes",
        function()
          addon.UI.Dialogs.TeamNotesDialog:Show(
            team
          )
        end
      )

      rootDescription:CreateButton(
        hasScript
        and "Edit Script"
        or "Add Script",
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
            "Move Up",
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
            "Move Down",
            function()
              teamService:MoveDown(team.id)
            end
          )

      moveDown:SetEnabled(
        index ~= nil
        and index < #teams
      )

      rootDescription:CreateButton(
        "Move To Folder",
        function()
          addon.UI.Dialogs.MoveTeamDialog:Show(team)
        end
      )

      rootDescription:CreateDivider()

      rootDescription:CreateButton(
        "Edit Team",
        function()
          addon.UI.Dialogs.EditTeamDialog:Show(team)
        end
      )

      rootDescription:CreateButton(
        "Export Team",
        function()
          addon.UI.Dialogs.ExportDialog:Show(team)
        end
      )

      rootDescription:CreateButton(
        "Delete Team",
        function()
          addon.UI.Dialogs.DeleteTeamDialog:Show(team)
        end
      )
    end
  )
end

addon.UI.Actions.TeamContextMenu = TeamContextMenu
