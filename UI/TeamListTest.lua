local addonName, addon = ...

local frame = CreateFrame("Frame", "PetMatchTeamListTest", UIParent)
frame:SetSize(400, 500)
frame:SetPoint("CENTER")
local list = addon.UI.Components.TeamList:Create(frame)
list:SetPoint("CENTER")
frame:Show()
