local addonName, addon = ...

local TeamPanel = {}
TeamPanel.Rows = {}

function TeamPanel:Create()
  local frame = addon.UI.Components.Panel:Create(PetJournal, { width = 360, height = 600 })
  self.Frame = frame
  frame:ClearAllPoints()
  frame:SetPoint("TOPLEFT", PetJournal, "TOPRIGHT", 1, -1)
  frame:Show()
  self.Toolbar = addon.UI.Views.Toolbar:Create(frame)
  self.Toolbar:SetPoint("TOP", 0, -10)
  self.Title = addon.UI.Components.Label:Create(frame, { text = "PetMatch" })
  self.Title:SetPoint("TOPLEFT", 5, -60)
  self.TeamList = addon.UI.Views.TeamList:Create(frame)
  self.TeamList:SetPoint("TOPLEFT", 10, -90)
  self.TeamDetails = addon.UI.Views.TeamDetails:Create(frame)
  self.TeamDetails:SetPoint("TOPRIGHT", -10, -90)
  addon.EventBus:Register(
    "TEAM_SELECTED",
    function(team)
      self.TeamDetails:ShowTeam(
        team
      )
    end
  )
  return frame
end

function TeamPanel:Update()
  print("[PetMatch DEBUG] Updating TeamPanel")
  if not self.Frame then
    return
  end

  local team = addon.Services.Team:GetActive()

  if team then
    print(
      "[PetMatch DEBUG] Active team:",
      team.name
    )
  else
    print(
      "[PetMatch DEBUG] No active team"
    )
  end

  if team then
    for i = 1, 3 do
      print(
        "[PetMatch DEBUG] Slot",
        i,
        team.pets[i]
      )
    end
  end

  if not team then
    self.Title:SetText(
      "PetMatch\nNo active team"
    )
    return
  end

  self.Title:SetText(
    "PetMatch\n" .. team.name
  )

  for slot = 1, 3 do
    local petGUID = team.pets[slot]

    local text =
        "Slot " .. slot .. ": Empty"

    if petGUID then
      local name =
          addon.Services.PetJournal:GetPetName(
            petGUID
          )
      if name then
        text =
            "Slot " .. slot .. ": "
            .. name
      else
        text =
            "Slot " .. slot .. ": "
            .. petGUID
      end
    end
    print(
      "[PetMatch DEBUG] Setting row",
      slot,
      text
    )
    if self.Rows
        and self.Rows[slot] then
      self.Rows[slot]:SetText(
        text
      )
    end
  end
end

function TeamPanel:Show()
  print("[PetMatch DEBUG] TeamPanel Show")
  self:Create()
  self.Frame:Show()
  if self.Update then
    self:Update()
  end
end

function TeamPanel:Hide()
  if self.Frame then
    self.Frame:Hide()
  end
end

function TeamPanel:Initialize()
  print("[PetMatch DEBUG] Initialize called")
  if self.Frame then
    self.Frame:Show()
    return
  end

  self:Create()

  print("[PetMatch DEBUG] Frame created")

  print(
    "[PetMatch] TeamPanel shown:",
    self.Frame:IsShown()
  )

  if self.Update then
    self:Update()
  else
    print(
      "[PetMatch DEBUG] Update function missing"
    )
  end

  addon.Logger:Info(
    "PetMatch TeamPanel initialized"
  )

  self.Frame:Hide()
end

addon.UI.Views = addon.UI.Views or {}
addon.UI.Views.TeamPanel = TeamPanel
