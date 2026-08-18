local _, addon = ...

local DragDrop = {
  ActiveTeam = nil,
  SourceFrame = nil,
  FolderTargets = {},
}

-- function DragDrop:CreateGhost()
--   if self.Ghost then
--     return self.Ghost
--   end

--   local frame = CreateFrame(
--     "Frame",
--     nil,
--     UIParent,
--     "BackdropTemplate"
--   )

--   frame:SetSize(180, 32)
--   frame:SetFrameStrata("TOOLTIP")
--   frame:EnableMouse(false)

--   frame:SetBackdrop({
--     bgFile = "Interface/Buttons/WHITE8X8",
--     edgeFile = "Interface/Buttons/WHITE8X8",
--     edgeSize = 1,
--   })

--   frame:SetBackdropColor(0.03, 0.03, 0.03, 0.9)
--   frame:SetBackdropBorderColor(0.7, 0.6, 0.3, 1)

--   frame.Text = frame:CreateFontString(
--     nil,
--     "OVERLAY",
--     "GameFontHighlight"
--   )

--   frame.Text:SetPoint("LEFT", frame, "LEFT", 8, 0)
--   frame.Text:SetPoint("RIGHT", frame, "RIGHT", -8, 0)
--   frame.Text:SetJustifyH("LEFT")
--   frame.Text:SetWordWrap(false)

--   frame:SetScript("OnUpdate", function(self)
--     local x, y = GetCursorPosition()
--     local scale = UIParent:GetEffectiveScale()

--     self:ClearAllPoints()
--     self:SetPoint(
--       "BOTTOMLEFT",
--       UIParent,
--       "BOTTOMLEFT",
--       (x / scale) + 14,
--       (y / scale) + 14
--     )
--   end)

--   frame:Hide()

--   self.Ghost = frame

--   return frame
-- end

function DragDrop:StartTeam(team, sourceFrame)
  if not team or not sourceFrame then
    return
  end

  self.ActiveTeam = team
  self.SourceFrame = sourceFrame

  sourceFrame:SetAlpha(0.45)

  addon.UI.Components.DragCursor:Start()

  self:RefreshTargetHighlights()
end

function DragDrop:IsDraggingTeam()
  return self.ActiveTeam ~= nil
end

function DragDrop:ClearFolderTargets()
  for _, target in ipairs(self.FolderTargets) do
    if target.Frame then
      target.Frame:UnlockHighlight()
    end
  end

  self.FolderTargets = {}
end

function DragDrop:RegisterFolderTarget(frame, folderKey)
  if not frame or not folderKey then
    return
  end

  table.insert(self.FolderTargets, {
    Frame = frame,
    FolderKey = folderKey,
  })

  frame:HookScript("OnEnter", function(button)
    if self:IsDraggingTeam() then
      button:LockHighlight()
    end
  end)

  frame:HookScript("OnLeave", function(button)
    if self:IsDraggingTeam() then
      button:UnlockHighlight()
    end
  end)
end

function DragDrop:RefreshTargetHighlights()
  for _, target in ipairs(self.FolderTargets) do
    if target.Frame then
      target.Frame:UnlockHighlight()
    end
  end
end

function DragDrop:GetHoveredFolderTarget()
  for _, target in ipairs(self.FolderTargets) do
    local frame = target.Frame

    if frame
        and frame:IsShown()
        and frame:IsMouseOver() then
      return target
    end
  end

  return nil
end

function DragDrop:GetTeam()
  return self.DraggedTeam or self.ActiveTeam
end

function DragDrop:IsTeamDragging()
  return self:GetTeam() ~= nil
end

function DragDrop:Reset()
  if self.SourceFrame then
    self.SourceFrame:SetAlpha(1)
  end

  addon.UI.Components.DragCursor:Stop()

  self:RefreshTargetHighlights()

  self.ActiveTeam = nil
  self.SourceFrame = nil
end

function DragDrop:StopTeam()
  local team = self.ActiveTeam
  local target = self:GetHoveredFolderTarget()

  if not team or not target then
    self:Reset()
    return false
  end

  local folderKey = target.FolderKey
  local folderID = folderKey

  if folderKey == addon.Services.Folder.UNSORTED then
    folderID = nil
  end

  -- Eerst de drag visueel beëindigen.
  self:Reset()

  local movedTeam, errorMessage =
      addon.Services.Team:MoveToFolder(
        team.id,
        folderID
      )

  if not movedTeam then
    addon.Logger:Warn(
      errorMessage or "Unable to move team"
    )

    return false
  end

  addon.Services.Folder:Select(folderKey)

  addon.EventBus:Fire(
    addon.Events.TEAM_SELECTED,
    nil,
    nil
  )

  return true
end

addon.UI.Components.DragDrop = DragDrop
