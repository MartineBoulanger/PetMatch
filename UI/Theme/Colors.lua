local _, addon = ...

addon.UI = addon.UI or {}
addon.UI.Theme = addon.UI.Theme or {}
addon.UI.Theme.Colors = {
  Background   = { 0.05, 0.05, 0.05, 0.85 }, -- black with opacity
  Border       = { 0.25, 0.25, 0.25, 1 },    -- greyish
  Accent       = { 0.1, 0.7, 1, 1 },         -- blue color
  Header       = { 1.00, 0.82, 0.00, 1.00 }, -- yellow color
  Text         = { 1, 1, 1, 1 },             -- white
  TextMuted    = { 0.70, 0.70, 0.70, 1.00 },
  TextDisabled = { 0.50, 0.50, 0.50, 1.00 },
}
