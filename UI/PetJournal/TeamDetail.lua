local addonName, addon = ...

local TeamDetails = {}

function TeamDetails:Create(parent)
  local frame = addon.UI.Components.Panel:Create(parent, { width = 250, height = 360 })
  self.Frame = frame
  self.Title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  self.Title:SetPoint("TOPLEFT", 15, -15)
  self.Pets = {}
  for i = 1, 3 do
    local text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("TOPLEFT", 15, -30 - ((i - 1) * 25))
    self.Pets[i] = text
  end
  self.SelectedTeam = nil
  return frame
end

function TeamDetails:ShowTeam(team)
  self.SelectedTeam = team
  if not team then
    self.Title:SetText("No team selected")
    for i = 1, 3 do
      self.Pets[i]:SetText("")
    end
    return
  end
  self.Title:SetText("⭐ " .. team.name)
  for i = 1, 3 do
    local petGUID = team.pets[i]
    if petGUID then
      local speciesID,
      customName,
      level,
      favorite,
      isRevoked,
      name,
      icon,
      petType,
      creatureID,
      sourceText,
      description,
      isWild,
      canBattle,
      tradable,
      uniqueID = C_PetJournal.GetPetInfoByPetID(petGUID)
      if icon then
        self.PetIcons[i]:SetTexture(icon)
        self.PetIcons[i]:Show()
      end
      local displayName = customName or name or "Unknown"
      self.Pets[i]:SetText(displayName)
    else
      self.PetIcons[i]:SetTexture(nil)
      self.PetIcons[i]:Hide()
      self.Pets[i]:SetText("Empty")
    end
  end
end

addon.UI.Views = addon.UI.Views or {}
addon.UI.Views.TeamDetails = TeamDetails
