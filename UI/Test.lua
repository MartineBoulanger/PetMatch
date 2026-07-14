local addonName, addon = ...

local frame =
    CreateFrame(
      "Frame",
      "PetMatchUITest",
      UIParent,
      "BackdropTemplate"
    )

frame:SetSize(400, 250)
frame:SetPoint("CENTER")

local panel =
    addon.UI.Components.Panel:Create(
      frame,
      {
        width = 400,
        height = 250
      }
    )

local title =
    addon.UI.Components.Label:Create(
      frame,
      {
        text = "PetMatch UI Test",
        font = addon.UI.Theme.Fonts.Header
      }
    )

title:SetPoint("TOP", 0, -20)

local button =
    addon.UI.Components.Button:Create(
      frame,
      {
        text = "Hello PetMatch",
        onClick = function()
          print("[PetMatch] Button works!")
        end
      }
    )

button:SetPoint("CENTER")
frame:Show()
