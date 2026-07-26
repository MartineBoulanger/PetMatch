local _, addon = ...

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
