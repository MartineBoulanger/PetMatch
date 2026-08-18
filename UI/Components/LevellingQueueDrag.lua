local _, addon = ...

local LevellingQueueDrag = {
  PetGUID = nil,
  Source = nil,
  SourceIndex = nil,
}

function LevellingQueueDrag:Start(petGUID, source, sourceIndex)
  if type(petGUID) ~= "string"
      or petGUID == "" then
    return false
  end

  self.PetGUID = petGUID
  self.Source = source
  self.SourceIndex = sourceIndex

  if addon.UI.Components.DragCursor then
    addon.UI.Components.DragCursor:Start()
  end

  return true
end

function LevellingQueueDrag:GetPetGUID()
  return self.PetGUID
end

function LevellingQueueDrag:GetSource()
  return self.Source
end

function LevellingQueueDrag:GetSourceIndex()
  return self.SourceIndex
end

function LevellingQueueDrag:IsDragging()
  return self.PetGUID ~= nil
end

function LevellingQueueDrag:Clear()
  self.PetGUID = nil
  self.Source = nil
  self.SourceIndex = nil
  if addon.UI.Components.DragCursor then
    addon.UI.Components.DragCursor:Stop()
  end
end

addon.UI.Components.LevellingQueueDrag = LevellingQueueDrag
