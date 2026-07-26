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

      rootDescription:CreateDivider()

      rootDescription:CreateButton(
        "Edit Team",
        function()
          addon.UI.Dialogs.EditTeamDialog:Show(team)
        end
      )

      rootDescription:CreateButton(
        "Move Team",
        function()
          addon.UI.Dialog.MoveTeamDialog:Show(team)
        end
      )

      rootDescription:CreateButton(
        "Export Team",
        function()
          addon.UI.Dialogs.ExportDialog:Show(team)
        end
      )

      rootDescription:CreateDivider()

      rootDescription:CreateButton(
        "Delete Team",
        function()
          StaticPopup_Show(
            "PETMATCH_DELETE_TEAM",
            team.name,
            nil,
            team
          )
        end
      )
    end
  )
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

addon.UI.Actions.TeamContextMenu = TeamContextMenu
