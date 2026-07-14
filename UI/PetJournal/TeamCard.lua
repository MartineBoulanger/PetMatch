local addonName, addon = ...

local TeamCard = {}

function TeamCard:Create(parent, team)
  local frame = CreateFrame("Button", nil, parent, "BackdropTemplate")
  frame:SetSize(300, 90)
  frame.team = team
  frame.selected = false
  frame:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    edgeSize = 12,
  })
  frame:SetBackdropColor(0, 0, 0, 0.65)
  self:CreateText(frame)
  self:Update(frame)
  frame:SetScript(
    "OnClick",
    function()
      addon.EventBus:Fire(
        "TEAM_SELECTED",
        frame
      )
    end
  )
  frame:SetScript(
    "OnEnter",
    function()
      frame:SetAlpha(0.8)
    end
  )
  frame:SetScript(
    "OnLeave",
    function()
      frame:SetAlpha(1)
    end
  )
  return frame
end

function TeamCard:CreateText(frame)
  frame.Title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  frame.Title:SetPoint("TOPLEFT", 10, -10)
  frame.Pets = {}
  for i = 1, 3 do
    local text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("TOPLEFT", 10, -10 - (i * 18))
    frame.Pets[i] = text
  end
end

function TeamCard:Update(frame)
  local team = frame.team
  frame.Title:SetText("⭐ " .. team.name)
  for i = 1, 3 do
    local pet = team.pets[i]
    if pet then
      local name = addon.Services.PetJournal:GetPetName(pet)
      frame.Pets[i]:SetText("🐾 " .. (name or pet))
    else
      frame.Pets[i]:SetText("🐾 Empty")
    end
  end
end

function TeamCard:SetSelected(frame, selected)
  frame.selected = selected
  if selected then
    frame:SetBackdropColor(0.2, 0.2, 0.2, 1)
  else
    frame:SetBackdropColor(0, 0, 0, 0.65)
  end
end

addon.UI.Components = addon.UI.Components or {}
addon.UI.Components.TeamCard = TeamCard
