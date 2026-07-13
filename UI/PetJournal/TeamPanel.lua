local addonName, addon = ...

local TeamPanel = {}
TeamPanel.Rows = {}

function TeamPanel:Create()
  if self.Frame then
    return
  end

  local frame =
      CreateFrame(
        "Frame",
        "PetMatchTeamPanel",
        UIParent,
        "BackdropTemplate"
      )

  frame:SetSize(
    220,
    300
  )

  frame:SetPoint(
    "CENTER",
    UIParent,
    "CENTER",
    300,
    0
  )

  frame:SetFrameStrata(
    "DIALOG"
  )

  frame:SetBackdrop({
    bgFile =
    "Interface/DialogFrame/UI-DialogBox-Background",
    edgeFile =
    "Interface/DialogFrame/UI-DialogBox-Border",
    edgeSize = 16,
  })

  local title =
      frame:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontNormal"
      )

  title:SetPoint(
    "TOP",
    0,
    -15
  )

  title:SetText(
    "PetMatch Team"
  )

  self.Title = title

  for slot = 1, 3 do
    print(
      "[PetMatch DEBUG] Slot",
      slot
    )
    local row =
        frame:CreateFontString(
          nil,
          "OVERLAY",
          "GameFontNormal"
        )

    row:SetPoint(
      "TOPLEFT",
      20,
      -50 - ((slot - 1) * 35)
    )

    row:SetText(
      "Slot " .. slot .. ": Empty"
    )

    self.Rows[slot] = row
  end

  frame:Hide()

  self.Frame = frame

  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript(
    "OnDragStart",
    frame.StartMoving
  )
  frame:SetScript(
    "OnDragStop",
    frame.StopMovingOrSizing
  )
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

  for i = 1, 3 do
    print(
      "[PetMatch DEBUG] Slot",
      i,
      team.pets[i]
    )
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
    self.Rows[slot]:SetText(
      text
    )
  end
end

function TeamPanel:Show()
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

  self.Frame:Show()

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
end

addon.UI.TeamPanel = TeamPanel
