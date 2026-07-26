local _, addon = ...

addon.UI.Actions = addon.UI.Actions or {}
addon.UI.Base = addon.UI.Base or {}
addon.UI.Components = addon.UI.Components or {}
addon.UI.Dialogs = addon.UI.Dialogs or {}
addon.UI.Theme = addon.UI.Theme or {}
addon.UI.Views = addon.UI.Views or {}

local Component = {}

function Component:Create()

end

function Component:Show()
  if self.Frame then
    self.Frame:Show()
  end
end

function Component:Hide()
  if self.Frame then
    self.Frame:Hide()
  end
end

function Component:Destroy()
  if self.Frame then
    self.Frame:Hide()
    self.Frame = nil
  end
end

addon.UI.Base.Component = Component
