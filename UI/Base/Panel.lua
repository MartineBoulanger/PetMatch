local _, addon = ...

local Panel = {}

function Panel:Create(parent, options)
  options = options or {}

  local frame =
      CreateFrame(
        "Frame",
        nil,
        parent
      )

  frame:SetSize(
    options.width
    or addon.UI.Theme.Sizes.DefaultWidth,
    options.height
    or addon.UI.Theme.Sizes.DefaultHeight
  )

  frame.Background =
      frame:CreateTexture(
        nil,
        "BACKGROUND"
      )

  frame.Background:SetAllPoints(frame)

  frame.Background:SetTexture(
    options.background
    or "Interface\\BlackMarket\\blackmarketbackground-tile"
    or nil
  )

  frame.Background:SetTexCoord(0, 1, 0, 1)

  if options.backgroundAlpha then
    frame.Background:SetAlpha(
      options.backgroundAlpha
    )
  end

  return frame
end

addon.UI.Base.Panel = Panel
