local _, addon = ...

addon.L = addon.L or {}

local L = addon.L

function addon:GetLocalizedString(key)
  return L[key] or key
end
