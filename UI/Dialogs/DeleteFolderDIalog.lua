local _, addon = ...

local DeleteFolderDialog = {}
addon.DeleteFolderDialog = DeleteFolderDialog

local frame

local function CountFolderTeams(folderID)
  local count = 0

  for _, team in pairs(
    addon.Services.Team:GetTeams()
  ) do
    if team.folderID == folderID then
      count = count + 1
    end
  end

  return count
end

local function DeleteFolder(
    folder,
    deleteTeams
)
  if not folder then
    return
  end

  local success, errorMessage =
      addon.Services.Folder:Delete(
        folder.id,
        deleteTeams
      )

  if not success then
    addon.Logger:Warn(
      errorMessage
      or "Unable to delete folder"
    )

    return
  end

  addon.Services.Folder:Select(
    addon.Services.Folder.UNSORTED
  )
end

local function CreateDialog()
  local dialog = CreateFrame(
    "Frame",
    "PetMatchDeleteFolderDialog",
    UIParent,
    "BackdropTemplate"
  )

  dialog:SetSize(460, 190)
  dialog:SetPoint("CENTER")
  dialog:SetFrameStrata("DIALOG")
  dialog:SetClampedToScreen(true)
  dialog:EnableMouse(true)
  dialog:SetMovable(true)
  dialog:RegisterForDrag("LeftButton")

  dialog:SetScript(
    "OnDragStart",
    dialog.StartMoving
  )

  dialog:SetScript(
    "OnDragStop",
    dialog.StopMovingOrSizing
  )

  dialog:SetBackdrop({
    bgFile =
    "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile =
    "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = {
      left = 11,
      right = 12,
      top = 12,
      bottom = 11,
    },
  })

  dialog:SetBackdropColor(
    0,
    0,
    0,
    1
  )

  dialog.Title = dialog:CreateFontString(
    nil,
    "OVERLAY",
    "GameFontNormalLarge"
  )

  dialog.Title:SetPoint(
    "TOP",
    0,
    -22
  )

  dialog.Title:SetText(
    "Delete Folder"
  )

  dialog.Message = dialog:CreateFontString(
    nil,
    "OVERLAY",
    "GameFontHighlight"
  )

  dialog.Message:SetPoint(
    "TOPLEFT",
    30,
    -55
  )

  dialog.Message:SetPoint(
    "TOPRIGHT",
    -30,
    -55
  )

  dialog.Message:SetJustifyH("CENTER")
  dialog.Message:SetJustifyV("TOP")

  dialog.MoveButton = CreateFrame(
    "Button",
    nil,
    dialog,
    "UIPanelButtonTemplate"
  )

  dialog.MoveButton:SetSize(165, 26)
  dialog.MoveButton:SetPoint(
    "BOTTOMLEFT",
    18,
    22
  )

  dialog.MoveButton:SetText(
    "Move to Unsorted"
  )

  dialog.DeleteButton = CreateFrame(
    "Button",
    nil,
    dialog,
    "UIPanelButtonTemplate"
  )

  dialog.DeleteButton:SetSize(165, 26)
  dialog.DeleteButton:SetPoint(
    "LEFT",
    dialog.MoveButton,
    "RIGHT",
    5,
    0
  )

  dialog.DeleteButton:SetText(
    "Delete Teams"
  )

  dialog.CancelButton = CreateFrame(
    "Button",
    nil,
    dialog,
    "UIPanelButtonTemplate"
  )

  dialog.CancelButton:SetSize(80, 26)
  dialog.CancelButton:SetPoint(
    "LEFT",
    dialog.DeleteButton,
    "RIGHT",
    5,
    0
  )

  dialog.CancelButton:SetText(
    "Cancel"
  )

  dialog.MoveButton:SetScript(
    "OnClick",
    function()
      local folder = dialog.folder

      dialog:Hide()

      DeleteFolder(
        folder,
        false
      )
    end
  )

  dialog.DeleteButton:SetScript(
    "OnClick",
    function()
      local folder = dialog.folder

      dialog:Hide()

      DeleteFolder(
        folder,
        true
      )
    end
  )

  dialog.CancelButton:SetScript(
    "OnClick",
    function()
      dialog:Hide()
    end
  )

  dialog:SetScript(
    "OnHide",
    function()
      dialog.folder = nil
    end
  )

  dialog:Hide()

  return dialog
end

function DeleteFolderDialog:Show(folder)
  if not folder then
    return
  end

  if not frame then
    frame = CreateDialog()
  end

  local teamCount =
      CountFolderTeams(folder.id)

  local teamText

  if teamCount == 1 then
    teamText = "1 team"
  else
    teamText =
        tostring(teamCount)
        .. " teams"
  end

  frame.folder = folder

  frame.Message:SetText(
    "Delete folder \""
    .. folder.name
    .. "\"?\n\n"
    .. "This folder contains "
    .. teamText
    .. ".\n"
    .. "You can move them to Unsorted "
    .. "or delete them permanently."
  )

  frame.DeleteButton:SetEnabled(
    teamCount > 0
  )

  frame:Show()
  frame:Raise()
end

function DeleteFolderDialog:Hide()
  if frame then
    frame:Hide()
  end
end
