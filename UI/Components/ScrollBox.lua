local _, addon = ...

local ScrollBox = {}

function ScrollBox:Create(parent, options)
  options = options or {}

  local width = options.width or 10
  local height = options.height or 320
  local contentGap = options.contentGap or 3
  local scrollBarWidth = options.scrollBarWidth or 8

  --------------------------------------------------
  -- Container
  --------------------------------------------------
  local container = CreateFrame(
    "Frame",
    nil,
    parent
  )

  container:SetSize(width, height)

  --------------------------------------------------
  -- ScrollFrame fills content area
  --------------------------------------------------
  local frame = CreateFrame(
    "ScrollFrame",
    nil,
    container
  )

  frame:SetAllPoints(container)

  --------------------------------------------------
  -- Content
  --------------------------------------------------
  local content = CreateFrame(
    "Frame",
    nil,
    frame
  )

  content:SetWidth(width)
  content:SetHeight(1)

  frame:SetScrollChild(content)

  --------------------------------------------------
  -- Scrollbar OUTSIDE content/container
  --------------------------------------------------
  local scrollBar = CreateFrame(
    "EventFrame",
    nil,
    container,
    "MinimalScrollBar"
  )

  scrollBar:SetWidth(scrollBarWidth)

  scrollBar:SetPoint(
    "TOPLEFT",
    container,
    "TOPRIGHT",
    contentGap + 5,
    0
  )

  scrollBar:SetPoint(
    "BOTTOMLEFT",
    container,
    "BOTTOMRIGHT",
    contentGap + 5,
    0
  )

  scrollBar:SetHideIfUnscrollable(false)
  scrollBar:Show()

  --------------------------------------------------
  -- State
  --------------------------------------------------
  local updatingFromFrame = false

  --------------------------------------------------
  -- Update range
  --------------------------------------------------
  local function UpdateScrollRange()
    local contentHeight = content:GetHeight()
    local frameHeight = frame:GetHeight()

    local maxScroll = math.max(
      0,
      contentHeight - frameHeight
    )

    frame.MaxScroll = maxScroll

    local visiblePercentage = 1

    if contentHeight > 0 then
      visiblePercentage = math.min(
        1,
        frameHeight / contentHeight
      )
    end

    scrollBar:Init(
      visiblePercentage,
      0.10
    )

    local offset = math.min(
      frame:GetVerticalScroll(),
      maxScroll
    )

    frame:SetVerticalScroll(offset)

    updatingFromFrame = true

    scrollBar:SetScrollPercentage(
      maxScroll > 0 and offset / maxScroll or 0,
      true
    )

    updatingFromFrame = false
  end

  --------------------------------------------------
  -- Scrollbar -> ScrollFrame
  --------------------------------------------------
  scrollBar:RegisterCallback(
    ScrollBarMixin.Event.OnScroll,
    function(_, percentage)
      if updatingFromFrame then
        return
      end

      local maxScroll = frame.MaxScroll or 0

      frame:SetVerticalScroll(
        maxScroll * percentage
      )
    end
  )

  --------------------------------------------------
  -- Mouse wheel
  --------------------------------------------------
  frame:EnableMouseWheel(true)

  frame:SetScript(
    "OnMouseWheel",
    function(_, delta)
      local maxScroll = frame.MaxScroll or 0

      if maxScroll <= 0 then
        return
      end

      local offset = frame:GetVerticalScroll()

      offset = offset - (delta * 30)

      offset = math.max(
        0,
        math.min(offset, maxScroll)
      )

      frame:SetVerticalScroll(offset)

      updatingFromFrame = true

      scrollBar:SetScrollPercentage(
        offset / maxScroll,
        true
      )

      updatingFromFrame = false
    end
  )

  --------------------------------------------------
  -- Updates
  --------------------------------------------------
  content:HookScript(
    "OnSizeChanged",
    UpdateScrollRange
  )

  frame:HookScript(
    "OnSizeChanged",
    UpdateScrollRange
  )

  container:HookScript(
    "OnShow",
    UpdateScrollRange
  )

  --------------------------------------------------
  -- Public
  --------------------------------------------------
  container.ScrollFrame = frame
  container.ScrollBar = scrollBar
  container.Content = content
  container.UpdateScrollRange = UpdateScrollRange

  return container
end

addon.UI.Components.ScrollBox = ScrollBox
