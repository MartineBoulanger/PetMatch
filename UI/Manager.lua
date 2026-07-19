local addonName, addon = ...

addon.UI = addon.UI or {}

local Manager = {}

function Manager:Show()
  if addon.UI.Views.TeamPanel then
    addon.UI.Views.TeamPanel:Show()
  end
end

function Manager:Hide()
  if addon.UI.Views.TeamPanel then
    addon.UI.Views.TeamPanel:Hide()
  end
end

addon.UI.Manager = Manager
