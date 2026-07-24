local addonName, addon = ...

local ImportPreviewDialog = {}
addon.ImportPreviewDialog = ImportPreviewDialog

local frame

local function CreateFilteredDocument(dialog)
  local filteredDocument = {
    format = dialog.document.format,
    groups = {},
    warnings = dialog.document.warnings or {},
  }

  for groupIndex, groupData in ipairs(
    dialog.document.groups or {}
  ) do
    local groupControls =
        dialog.GroupControls[groupIndex]

    local filteredGroup = {
      name = groupData.name,
      teams = {},
    }

    if groupControls then
      for teamIndex, teamData in ipairs(
        groupData.teams or {}
      ) do
        local teamControl =
            groupControls.teams[teamIndex]

        if teamControl
            and teamControl.checkbox:GetChecked() then
          filteredGroup.teams[
          #filteredGroup.teams + 1
          ] = teamData
        end
      end
    end

    if #filteredGroup.teams > 0 then
      filteredDocument.groups[
      #filteredDocument.groups + 1
      ] = filteredGroup
    end
  end

  return filteredDocument
end

local function CountSelectedTeams(dialog)
  local count = 0

  for _, groupControls in ipairs(
    dialog.GroupControls
  ) do
    for _, teamControl in ipairs(
      groupControls.teams
    ) do
      if teamControl.checkbox:GetChecked() then
        count = count + 1
      end
    end
  end

  return count
end

local function UpdateImportButton(dialog)
  local selectedCount =
      CountSelectedTeams(dialog)

  dialog.ImportButton:SetEnabled(
    selectedCount > 0
  )

  if selectedCount == 1 then
    dialog.Status:SetText(
      "1 team selected"
    )
  else
    dialog.Status:SetText(
      tostring(selectedCount)
      .. " teams selected"
    )
  end
end

local function UpdateGroupCheckbox(
    dialog,
    groupControls
)
  local selectedCount = 0
  local teamCount = #groupControls.teams

  for _, teamControl in ipairs(
    groupControls.teams
  ) do
    if teamControl.checkbox:GetChecked() then
      selectedCount = selectedCount + 1
    end
  end

  groupControls.checkbox:SetChecked(
    selectedCount > 0
  )

  groupControls.checkbox.Label:SetText(
    groupControls.name
    .. " ("
    .. tostring(selectedCount)
    .. "/"
    .. tostring(teamCount)
    .. ")"
  )

  UpdateImportButton(dialog)
end

local function ClearPreview(dialog)
  for _, control in ipairs(
    dialog.CreatedControls
  ) do
    control:Hide()
    control:SetParent(nil)
  end

  dialog.CreatedControls = {}
  dialog.GroupControls = {}
end

local function CreateCheckButton(
    parent,
    label,
    level
)
  local checkbox = CreateFrame(
    "CheckButton",
    nil,
    parent,
    "UICheckButtonTemplate"
  )

  checkbox:SetSize(24, 24)

  local text = checkbox:CreateFontString(
    nil,
    "OVERLAY",
    level == 0
    and "GameFontNormal"
    or "GameFontHighlight"
  )

  text:SetPoint(
    "LEFT",
    checkbox,
    "RIGHT",
    3,
    0
  )

  text:SetJustifyH("LEFT")
  text:SetText(label or "")
  text:SetWidth(
    level == 0 and 390 or 365
  )

  checkbox.Label = text

  return checkbox
end

local function BuildPreview(dialog)
  ClearPreview(dialog)

  local content = dialog.Content
  local y = -8

  for groupIndex, groupData in ipairs(
    dialog.document.groups or {}
  ) do
    local groupName =
        addon.Utils:Trim(
          groupData.name or ""
        )

    if groupName == "" then
      groupName = "Selected folder"
    end

    local groupCheckbox =
        CreateCheckButton(
          content,
          groupName,
          0
        )

    groupCheckbox:SetPoint(
      "TOPLEFT",
      8,
      y
    )

    groupCheckbox:SetChecked(true)

    dialog.CreatedControls[
    #dialog.CreatedControls + 1
    ] = groupCheckbox

    local groupControls = {
      name = groupName,
      checkbox = groupCheckbox,
      teams = {},
    }

    dialog.GroupControls[groupIndex] =
        groupControls

    y = y - 30

    for teamIndex, teamData in ipairs(
      groupData.teams or {}
    ) do
      local teamName =
          addon.Utils:Trim(
            teamData.name or ""
          )

      if teamName == "" then
        teamName =
            "Unnamed Team "
            .. tostring(teamIndex)
      end

      local teamCheckbox =
          CreateCheckButton(
            content,
            teamName,
            1
          )

      teamCheckbox:SetPoint(
        "TOPLEFT",
        32,
        y
      )

      teamCheckbox:SetChecked(true)

      dialog.CreatedControls[
      #dialog.CreatedControls + 1
      ] = teamCheckbox

      local teamControl = {
        checkbox = teamCheckbox,
        data = teamData,
      }

      groupControls.teams[teamIndex] =
          teamControl

      teamCheckbox:SetScript(
        "OnClick",
        function()
          UpdateGroupCheckbox(
            dialog,
            groupControls
          )
        end
      )

      y = y - 27
    end

    groupCheckbox.Label:SetText(
      groupName
      .. " ("
      .. tostring(#groupControls.teams)
      .. "/"
      .. tostring(#groupControls.teams)
      .. ")"
    )

    groupCheckbox:SetScript(
      "OnClick",
      function(self)
        local checked =
            self:GetChecked()

        for _, teamControl in ipairs(
          groupControls.teams
        ) do
          teamControl.checkbox:SetChecked(
            checked
          )
        end

        UpdateGroupCheckbox(
          dialog,
          groupControls
        )
      end
    )

    y = y - 8
  end

  content:SetHeight(
    math.max(
      1,
      math.abs(y) + 10
    )
  )

  UpdateImportButton(dialog)
end

local function ImportSelected(dialog)
  local document =
      CreateFilteredDocument(dialog)

  if #document.groups == 0 then
    dialog.Status:SetText(
      "Select at least one team."
    )

    return
  end

  dialog.ImportButton:SetEnabled(false)
  dialog.CancelButton:SetEnabled(false)

  local result, errorMessage =
      addon.Services.ImportExport:
      ImportRematchDocument(
        document,
        dialog.options or {}
      )

  dialog.ImportButton:SetEnabled(true)
  dialog.CancelButton:SetEnabled(true)

  if not result then
    dialog.Status:SetText(
      errorMessage
      or "Unable to import the selected teams."
    )

    return
  end

  dialog:Hide()
end

local function CreateDialog()
  local dialog = CreateFrame(
    "Frame",
    "PetMatchImportPreviewDialog",
    UIParent,
    "BackdropTemplate"
  )

  dialog:SetSize(320, 500)
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

  dialog.Title = dialog:CreateFontString(
    nil,
    "OVERLAY",
    "GameFontNormalLarge"
  )

  dialog.Title:SetPoint(
    "TOP",
    0,
    -20
  )

  dialog.Title:SetText(
    "Import Preview"
  )

  dialog.Description =
      dialog:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlight"
      )

  dialog.Description:SetPoint(
    "TOPLEFT",
    30,
    -50
  )

  dialog.Description:SetPoint(
    "TOPRIGHT",
    -30,
    -50
  )

  dialog.Description:SetJustifyH("LEFT")
  dialog.Description:SetText(
    "Select the teams you want to import."
  )

  dialog.ScrollFrame = CreateFrame(
    "ScrollFrame",
    nil,
    dialog,
    "UIPanelScrollFrameTemplate"
  )

  dialog.ScrollFrame:SetPoint(
    "TOPLEFT",
    24,
    -82
  )

  dialog.ScrollFrame:SetPoint(
    "BOTTOMRIGHT",
    -48,
    72
  )

  dialog.Content = CreateFrame(
    "Frame",
    nil,
    dialog.ScrollFrame
  )

  dialog.Content:SetWidth(430)
  dialog.Content:SetHeight(1)

  dialog.ScrollFrame:SetScrollChild(
    dialog.Content
  )

  dialog.Status = dialog:CreateFontString(
    nil,
    "OVERLAY",
    "GameFontHighlightSmall"
  )

  dialog.Status:SetPoint(
    "BOTTOMLEFT",
    30,
    50
  )

  dialog.Status:SetPoint(
    "BOTTOMRIGHT",
    -30,
    50
  )

  dialog.Status:SetJustifyH("CENTER")

  dialog.ImportButton = CreateFrame(
    "Button",
    nil,
    dialog,
    "UIPanelButtonTemplate"
  )

  dialog.ImportButton:SetSize(140, 26)
  dialog.ImportButton:SetPoint(
    "BOTTOMRIGHT",
    dialog,
    "BOTTOM",
    -5,
    18
  )

  dialog.ImportButton:SetText(
    "Import Selected"
  )

  dialog.CancelButton = CreateFrame(
    "Button",
    nil,
    dialog,
    "UIPanelButtonTemplate"
  )

  dialog.CancelButton:SetSize(100, 26)
  dialog.CancelButton:SetPoint(
    "BOTTOMLEFT",
    dialog,
    "BOTTOM",
    5,
    18
  )

  dialog.CancelButton:SetText(
    "Cancel"
  )

  dialog.ImportButton:SetScript(
    "OnClick",
    function()
      ImportSelected(dialog)
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
      ClearPreview(dialog)

      dialog.document = nil
      dialog.options = nil
    end
  )

  dialog.CreatedControls = {}
  dialog.GroupControls = {}

  dialog:Hide()

  table.insert(
    UISpecialFrames,
    dialog:GetName()
  )

  return dialog
end

function ImportPreviewDialog:Show(
    document,
    options
)
  if not document then
    return
  end

  if not frame then
    frame = CreateDialog()
  end

  frame.document = document
  frame.options = options or {}

  BuildPreview(frame)

  frame:Show()
  frame:Raise()
end

function ImportPreviewDialog:Hide()
  if frame then
    frame:Hide()
  end
end
