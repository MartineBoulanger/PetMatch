local addonName, addon = ...

local Toolbar = {}

function Toolbar:Create(parent)
  local frame = addon.UI.Components.Panel:Create(parent, { width = 320, height = 40 })
  self.Frame = frame
  local saveButton =
      addon.UI.Components.Button:Create(frame, {
        text = "Save Current Team",
        width = 180,
        onClick = function()
          addon.UI.Views.SaveTeamDialog:Show()
        end
      })
  saveButton:SetPoint("TOP", 0, -7)
  self.SaveButton = saveButton
  return frame
end

addon.UI.Views.Toolbar = Toolbar
