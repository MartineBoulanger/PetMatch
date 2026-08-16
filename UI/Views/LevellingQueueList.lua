local _, addon = ...

local LevellingQueueList = {}

local CONTENT_WIDTH = 230
local CONTENT_HEIGHT = 535

local ROW_SPACING = 2

function LevellingQueueList:Create(parent)
  local frame =
      addon.UI.Components.ScrollBox:Create(
        parent,
        {
          width = CONTENT_WIDTH + 5,
          height = CONTENT_HEIGHT,
          contentGap = 5,
        }
      )

  self.Frame = frame
  self.Rows = {}
  frame.items = {}

  self.DropIndicator =
      self.Frame.Content:
      CreateTexture(
        nil,
        "OVERLAY"
      )

  self.DropIndicator:SetHeight(2)

  self.DropIndicator:SetColorTexture(
    1,
    0.82,
    0.25,
    1
  )

  self.DropIndicator:Hide()

  self:Refresh()

  frame:Show()

  return frame
end

function LevellingQueueList:ShowDropIndicator(
    targetIndex,
    insertAfter
)
  local row =
      self.Rows[
      targetIndex
      ]

  if not row
      or not row.Frame
      or not row.Frame:IsShown() then
    self.DropIndicator:Hide()
    return
  end

  local frame =
      row.Frame

  self.DropIndicator:
      ClearAllPoints()

  if insertAfter then
    self.DropIndicator:SetPoint(
      "TOPLEFT",
      frame,
      "BOTTOMLEFT",
      0,
      -1
    )

    self.DropIndicator:SetPoint(
      "TOPRIGHT",
      frame,
      "BOTTOMRIGHT",
      0,
      -1
    )
  else
    self.DropIndicator:SetPoint(
      "BOTTOMLEFT",
      frame,
      "TOPLEFT",
      0,
      1
    )

    self.DropIndicator:SetPoint(
      "BOTTOMRIGHT",
      frame,
      "TOPRIGHT",
      0,
      1
    )
  end

  self.DropIndicator:Show()
end

function LevellingQueueList:GetDropPosition()
  local _,
  cursorY =
      GetCursorPosition()

  local scale =
      UIParent:
      GetEffectiveScale()

  cursorY =
      cursorY / scale

  for index, row in ipairs(
    self.Rows
  ) do
    local frame =
        row.Frame

    if frame
        and frame:IsShown() then
      local top =
          frame:GetTop()

      local bottom =
          frame:GetBottom()

      if top
          and bottom
          and cursorY <= top
          and cursorY >= bottom then
        local middle =
            (
              top
              + bottom
            )
            / 2

        local insertAfter =
            cursorY < middle

        return index,
            insertAfter
      end
    end
  end

  return nil, nil
end

function LevellingQueueList:BeginRowDrag(row)
  if not row then
    return
  end

  self.DraggedRow =
      row

  row.Frame:SetAlpha(
    0.45
  )

  self.Frame:SetScript(
    "OnUpdate",
    function()
      self:
          UpdateRowDrag()
    end
  )
end

function LevellingQueueList:UpdateRowDrag()
  if not self.DraggedRow then
    return
  end

  local targetIndex,
  insertAfter =
      self:GetDropPosition()

  if not targetIndex then
    self.DropTargetIndex = nil
    self.DropInsertAfter = nil

    self.DropIndicator:Hide()
    return
  end

  self.DropTargetIndex =
      targetIndex

  self.DropInsertAfter =
      insertAfter

  self:ShowDropIndicator(
    targetIndex,
    insertAfter
  )
end

function LevellingQueueList:FinishRowDrag(row)
  self.Frame:SetScript(
    "OnUpdate",
    nil
  )

  self.DropIndicator:Hide()

  if row
      and row.Frame then
    row.Frame:SetAlpha(1)
  end

  local draggedRow =
      self.DraggedRow

  local targetIndex =
      self.DropTargetIndex

  local insertAfter =
      self.DropInsertAfter

  self.DraggedRow = nil
  self.DropTargetIndex = nil
  self.DropInsertAfter = nil

  if not draggedRow
      or not draggedRow.PetGUID
      or not targetIndex then
    return
  end

  local currentIndex =
      draggedRow.Index

  if not currentIndex then
    return
  end

  local newIndex =
      targetIndex

  if insertAfter then
    newIndex =
        newIndex + 1
  end

  --------------------------------------------------
  -- Removing the dragged entry shifts indices
  -- below it by one.
  --------------------------------------------------

  if currentIndex < newIndex then
    newIndex =
        newIndex - 1
  end

  local count =
      addon.Services.LevellingQueue:
      GetCount()

  newIndex =
      math.max(
        1,
        math.min(
          count,
          newIndex
        )
      )

  if newIndex == currentIndex then
    return
  end

  addon.Services.LevellingQueue:
      Move(
        draggedRow.PetGUID,
        newIndex
      )
end

function LevellingQueueList:EnsureRows(count)
  while #self.Rows < count do
    local row = addon.UI.Components.LevellingQueueRow:Create(self.Frame.Content, self)
    self.Rows[#self.Rows + 1] = row
    self.Frame.items[#self.Frame.items + 1] = row
  end
end

function LevellingQueueList:LayoutRows()
  if not self.Frame
      or not self.Frame.Content then
    return
  end

  local currentOffset = 0

  for _, row in ipairs(
    self.Rows
  ) do
    local frame =
        row.Frame

    if frame
        and frame:IsShown() then
      frame:ClearAllPoints()

      frame:SetPoint(
        "TOPLEFT",
        self.Frame.Content,
        "TOPLEFT",
        0,
        -currentOffset
      )

      frame:SetPoint(
        "TOPRIGHT",
        self.Frame.Content,
        "TOPRIGHT",
        0,
        -currentOffset
      )

      currentOffset =
          currentOffset
          + frame:GetHeight()
          + ROW_SPACING
    end
  end

  if currentOffset > 0 then
    currentOffset =
        currentOffset
        - ROW_SPACING
  end

  self.Frame.Content:SetHeight(
    math.max(
      1,
      currentOffset
    )
  )

  if self.Frame.UpdateScrollRange then
    self.Frame.UpdateScrollRange()
  end
end

function LevellingQueueList:Refresh()
  if not self.Frame then
    return
  end

  local service = addon.Services.LevellingQueue

  if not service then
    return
  end

  local pets = service:GetPets()

  self:EnsureRows(#pets)

  for index, row in ipairs(self.Rows) do
    local item = pets[index]

    if item then
      row:SetPet(item)
    else
      row:Clear()
    end
  end

  self:LayoutRows()
end

addon.UI.Views.LevellingQueueList = LevellingQueueList
