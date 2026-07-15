local addonName, addon = ...

addon.UI = addon.UI or {}
addon.UI.Views = addon.UI.Views or {}

local TeamDetail = {}

function TeamDetail:Create(parent)
  local frame =
      addon.UI.Components.Panel:Create(
        parent,
        {
          width = 280,
          height = 210,
        }
      )

  self.Frame = frame
  self.SelectedTeam = nil
  self.PetSlots = {}

  self.Title =
      addon.UI.Components.Label:Create(
        frame,
        {
          text = "No team selected",
          font = addon.UI.Theme.Fonts.Header,
          width = 250,
          justify = "LEFT",
        }
      )

  self.Title:SetPoint(
    "TOPLEFT",
    frame,
    "TOPLEFT",
    12,
    -12
  )

  self.FavoriteButton =
      addon.UI.Components.Button:Create(
        frame,
        {
          text = "Add Favorite",
          width = 110,

          onClick = function()
            self:ToggleSelectedFavorite()
          end,
        }
      )

  self.FavoriteButton:SetPoint(
    "TOPRIGHT",
    frame,
    "TOPRIGHT",
    -12,
    -10
  )

  for slot = 1, 3 do
    local petSlot =
        addon.UI.Components.PetSlot:Create(frame)

    petSlot:GetFrame():SetPoint(
      "TOPLEFT",
      frame,
      "TOPLEFT",
      12 + ((slot - 1) * 86),
      -45
    )

    self.PetSlots[slot] = petSlot
  end

  self.LoadButton =
      addon.UI.Components.Button:Create(
        frame,
        {
          text = "Load Team",
          width = 90,
          onClick = function()
            self:LoadSelectedTeam()
          end,
        }
      )

  self.LoadButton:SetPoint(
    "BOTTOMLEFT",
    frame,
    "BOTTOMLEFT",
    12,
    12
  )

  self.DeleteButton =
      addon.UI.Components.Button:Create(
        frame,
        {
          text = "Delete",
          width = 80,
          onClick = function()
            self:DeleteSelectedTeam()
          end,
        }
      )

  self.DeleteButton:SetPoint(
    "LEFT",
    self.LoadButton,
    "RIGHT",
    8,
    0
  )

  self.EditButton =
      addon.UI.Components.Button:Create(
        frame,
        {
          text = "Edit",
          width = 70,

          onClick = function()
            self:EditSelectedTeam()
          end,
        }
      )

  self.EditButton:SetPoint(
    "LEFT",
    self.DeleteButton,
    "RIGHT",
    8,
    0
  )

  self.MoveButton =
      addon.UI.Components.Button:Create(
        frame,
        {
          text = "Move",
          width = 100,

          onClick = function()
            self:MoveSelectedTeam()
          end,
        }
      )

  self.MoveButton:SetPoint(
    "BOTTOMLEFT",
    self.LoadButton,
    "TOPLEFT",
    0,
    6
  )

  if not self.TeamSelectionRegistered then
    self.TeamSelectionRegistered = true

    addon.EventBus:Register(
      addon.Events.TEAM_SELECTED,
      function(team)
        self:SetTeam(team)
      end
    )
  end

  if not self.FavoriteEventRegistered then
    self.FavoriteEventRegistered = true

    addon.EventBus:Register(
      addon.Events.TEAM_FAVORITE_CHANGED,
      function(team)
        if self.SelectedTeam
            and team
            and self.SelectedTeam.id == team.id then
          self:SetTeam(team)
        end
      end
    )
  end

  self:SetTeam(
    addon.Services.Team:GetSelected()
  )

  return frame
end

function TeamDetail:SetTeam(team)
  self.SelectedTeam = team

  if not team then
    self.Title:SetText(
      "No team selected"
    )

    for slot = 1, 3 do
      self.PetSlots[slot]:Clear()
    end

    self.LoadButton:Disable()
    self.DeleteButton:Disable()
    self.EditButton:Disable()
    self.MoveButton:Disable()
    self.FavoriteButton:Disable()

    return
  end

  self.Title:SetText(
    team.name or "Unnamed Team"
  )

  for slot = 1, 3 do
    self.PetSlots[slot]:SetPet(
      team.pets
      and team.pets[slot]
      or nil
    )
  end

  if team.favorite then
    self.FavoriteButton:SetText(
      "Remove Favorite"
    )
  else
    self.FavoriteButton:SetText(
      "Add Favorite"
    )
  end

  self.LoadButton:Enable()
  self.DeleteButton:Enable()
  self.EditButton:Enable()
  self.MoveButton:Enable()
  self.FavoriteButton:Enable()
end

function TeamDetail:LoadSelectedTeam()
  local team = self.SelectedTeam

  if not team then
    addon.Logger:Warn(
      "Select a team first"
    )
    return
  end

  local success, errorMessage =
      addon.Services.Team:Load(
        team.id
      )

  if not success then
    addon.Logger:Error(
      errorMessage or "Unable to load team"
    )
    return
  end

  addon.Logger:Info(
    "Loaded team:",
    team.name
  )
end

function TeamDetail:DeleteSelectedTeam()
  local team = self.SelectedTeam

  if not team then
    return
  end

  local deleted =
      addon.Services.Team:Delete(
        team.id
      )

  if not deleted then
    addon.Logger:Error(
      "Unable to delete team:",
      team.name
    )

    return
  end

  addon.Logger:Info(
    "Deleted team:",
    team.name
  )

  self.FavoriteButton:SetText(
    "Add Favorite"
  )

  self.FavoriteButton:Disable()
end

function TeamDetail:EditSelectedTeam()
  if not self.SelectedTeam then
    addon.Logger:Warn(
      "Select a team first"
    )
    return
  end
  addon.UI.Views.EditTeamDialog:Show(
    self.SelectedTeam
  )
end

function TeamDetail:MoveSelectedTeam()
  if not self.SelectedTeam then
    addon.Logger:Warn(
      "Select a team first"
    )
    return
  end

  addon.UI.Views.MoveTeamDialog:Show(
    self.SelectedTeam
  )
end

function TeamDetail:ToggleSelectedFavorite()
  local team = self.SelectedTeam

  if not team then
    addon.Logger:Warn(
      "Select a team first"
    )

    return
  end

  local updatedTeam, errorMessage =
      addon.Services.Team:ToggleFavorite(
        team.id
      )

  if not updatedTeam then
    addon.Logger:Warn(
      errorMessage
      or "Unable to update favorite"
    )

    return
  end

  self:SetTeam(updatedTeam)
end

addon.UI.Views.TeamDetail = TeamDetail
