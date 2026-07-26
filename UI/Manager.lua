local _, addon = ...

local Manager = {}

function Manager:Show()
  if addon.UI.Views.Panels then
    addon.UI.Views.Panels:Show()
  end
end

function Manager:Hide()
  if addon.UI.Views.Panels then
    addon.UI.Views.Panels:Hide()
  end
end

addon.UI.Manager = Manager
