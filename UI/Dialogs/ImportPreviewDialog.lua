local _, addon = ...

local ImportPreviewDialog = {}

local DIALOG_WIDTH = 460
local PREVIEW_HEIGHT = 270

local CONTENT_MARGIN = {
  left = -12,
  right = 12,
  top = 4,
  bottom = 8,
}

local CONTENT_PADDING = 14

local dialogInstance

--------------------------------------------------
-- Filtered document
--------------------------------------------------
local function CreateFilteredDocument(dialog)
  local filteredDocument = {
    format = dialog.document.format,
    groups = {},
    warnings = dialog.document.warnings or {},
  }

  for groupIndex, groupData in ipairs(
    dialog.document.groups
    or {}
  ) do
    local groupControls = dialog.GroupControls[groupIndex]
    local filteredGroup = {
      name = groupData.name,
      teams = {},
    }

    if groupControls then
      for teamIndex, teamData in ipairs(
        groupData.teams
        or {}
      ) do
        local teamControl = groupControls.teams[teamIndex]

        if teamControl
            and teamControl.checkbox:
            GetChecked() then
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

--------------------------------------------------
-- Selection
--------------------------------------------------
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
  local selectedCount = CountSelectedTeams(dialog)

  dialog.ImportButton:SetEnabled(selectedCount > 0)
  dialog.Status:SetTextColor(unpack(addon.UI.Theme.Colors.TextMuted))

  if selectedCount == 1 then
    dialog.Status:SetText("1 team selected")
  else
    dialog.Status:SetText(
      tostring(selectedCount)
      .. " teams selected"
    )
  end
end

local function UpdateGroupCheckbox(dialog, groupControls)
  local selectedCount = 0
  local teamCount = #groupControls.teams

  for _, teamControl in ipairs(groupControls.teams) do
    if teamControl.checkbox:GetChecked() then
      selectedCount = selectedCount + 1
    end
  end

  groupControls.checkbox:SetChecked(selectedCount > 0)

  groupControls.checkbox.Label:
      SetText(
        groupControls.name
        .. " ("
        .. tostring(selectedCount)
        .. "/"
        .. tostring(teamCount)
        .. ")"
      )

  UpdateImportButton(dialog)
end

--------------------------------------------------
-- Clear preview
--------------------------------------------------
local function ClearPreview(dialog)
  for _, control in ipairs(dialog.CreatedControls) do
    control:Hide()
    control:SetParent(nil)
  end

  dialog.CreatedControls = {}
  dialog.GroupControls = {}

  if dialog.PreviewContent then
    dialog.PreviewContent:SetHeight(1)
  end
end

--------------------------------------------------
-- Checkbox
--------------------------------------------------
local function CreateCheckButton(parent, label, level)
  local checkbox =
      CreateFrame(
        "CheckButton",
        nil,
        parent,
        "UICheckButtonTemplate"
      )

  checkbox:SetSize(24, 24)

  local text =
      checkbox:CreateFontString(
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

  --------------------------------------------------
  -- The actual width is updated by BuildPreview.
  --------------------------------------------------
  text:SetWidth(300)
  checkbox.Label = text

  return checkbox
end

--------------------------------------------------
-- Build preview
--------------------------------------------------
local function BuildPreview(dialog)
  ClearPreview(dialog)

  local content = dialog.PreviewContent
  local y = -8
  local contentWidth = content:GetWidth()

  if not contentWidth or contentWidth <= 0 then
    contentWidth = DIALOG_WIDTH - 90
  end

  for groupIndex, groupData in ipairs(
    dialog.document.groups
    or {}
  ) do
    local groupName =
        addon.Utils:Trim(
          groupData.name
          or ""
        )

    if groupName == "" then
      groupName = "Selected folder"
    end

    --------------------------------------------------
    -- Group
    --------------------------------------------------
    local groupCheckbox =
        CreateCheckButton(
          content,
          groupName,
          0
        )

    groupCheckbox:SetPoint(
      "TOPLEFT",
      content,
      "TOPLEFT",
      8,
      y
    )

    groupCheckbox.Label:SetWidth(
      math.max(
        1,
        contentWidth - 45
      )
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

    dialog.GroupControls[groupIndex] = groupControls
    y = y - 30

    --------------------------------------------------
    -- Teams
    --------------------------------------------------
    for teamIndex, teamData in ipairs(
      groupData.teams
      or {}
    ) do
      local teamName =
          addon.Utils:Trim(
            teamData.name
            or ""
          )

      if teamName == "" then
        teamName =
            "Unnamed Team "
            .. tostring(
              teamIndex
            )
      end

      local teamCheckbox =
          CreateCheckButton(
            content,
            teamName,
            1
          )

      teamCheckbox:SetPoint(
        "TOPLEFT",
        content,
        "TOPLEFT",
        32,
        y
      )

      teamCheckbox.Label:SetWidth(
        math.max(
          1,
          contentWidth - 70
        )
      )

      teamCheckbox:SetChecked(true)

      dialog.CreatedControls[
      #dialog.CreatedControls + 1
      ] = teamCheckbox

      local teamControl = {
        checkbox = teamCheckbox,
        data = teamData,
      }

      groupControls.teams[teamIndex] = teamControl

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

    --------------------------------------------------
    -- Group count
    --------------------------------------------------
    groupCheckbox.Label:SetText(
      groupName
      .. " ("
      .. tostring(
        #groupControls.teams
      )
      .. "/"
      .. tostring(
        #groupControls.teams
      )
      .. ")"
    )

    --------------------------------------------------
    -- Group click
    --------------------------------------------------
    groupCheckbox:SetScript(
      "OnClick",
      function(control)
        local checked = control:GetChecked()

        for _, teamControl in ipairs(
          groupControls.teams
        ) do
          teamControl.checkbox:SetChecked(checked)
        end

        UpdateGroupCheckbox(
          dialog,
          groupControls
        )
      end
    )

    y = y - 8
  end

  --------------------------------------------------
  -- Scroll child height
  --------------------------------------------------
  content:SetHeight(
    math.max(
      1,
      math.abs(y) + 10
    )
  )

  dialog.ScrollFrame:UpdateScrollChildRect()
  dialog.ScrollFrame:SetVerticalScroll(0)

  UpdateImportButton(dialog)
end

--------------------------------------------------
-- Import
--------------------------------------------------
local function ImportSelected(dialog)
  local document = CreateFilteredDocument(dialog)

  if #document.groups == 0 then
    dialog.Status:SetText("Select at least one team.")
    dialog.Status:SetTextColor(unpack(addon.UI.Theme.Colors.Error))
    return
  end

  dialog.ImportButton:SetEnabled(false)
  dialog.CancelButton:SetEnabled(false)

  local result, errorMessage =
      addon.Services.ImportExport:ImportRematchDocument(
        document,
        dialog.options
        or {}
      )

  dialog.ImportButton:SetEnabled(true)
  dialog.CancelButton:SetEnabled(true)

  if not result then
    dialog.Status:SetText(
      errorMessage
      or "Unable to import the selected teams."
    )

    dialog.Status:SetTextColor(
      unpack(
        addon.UI.Theme.Colors.Error
      )
    )

    return
  end

  dialog:Hide()
end

--------------------------------------------------
-- Create content
--------------------------------------------------
local function CreateContent(dialog)
  local content = dialog:GetContentFrame()

  --------------------------------------------------
  -- Description
  --------------------------------------------------
  dialog.Description =
      addon.UI.Base.Label:Create(
        content,
        {
          text = "Select the teams you want to import.",
          justify = "LEFT",
          color = addon.UI.Theme.Colors.Text,
        }
      )

  dialog.Description:SetPoint(
    "TOPLEFT",
    content,
    "TOPLEFT",
    0,
    0
  )

  dialog.Description:SetPoint(
    "TOPRIGHT",
    content,
    "TOPRIGHT",
    0,
    0
  )

  --------------------------------------------------
  -- Scroll frame
  --------------------------------------------------
  dialog.ScrollFrame =
      CreateFrame(
        "ScrollFrame",
        nil,
        content,
        "UIPanelScrollFrameTemplate"
      )

  dialog.ScrollFrame:SetPoint(
    "TOPLEFT",
    dialog.Description,
    "BOTTOMLEFT",
    0,
    -10
  )

  dialog.ScrollFrame:SetPoint(
    "TOPRIGHT",
    dialog.Description,
    "BOTTOMRIGHT",
    -16,
    -8
  )

  dialog.ScrollFrame:SetHeight(PREVIEW_HEIGHT)

  --------------------------------------------------
  -- Scroll content
  --------------------------------------------------
  dialog.PreviewContent =
      CreateFrame(
        "Frame",
        nil,
        dialog.ScrollFrame
      )

  dialog.PreviewContent:SetHeight(1)
  dialog.ScrollFrame:SetScrollChild(dialog.PreviewContent)

  --------------------------------------------------
  -- Keep scroll child width aligned
  --------------------------------------------------
  local function UpdateContentWidth()
    local width = dialog.ScrollFrame:GetWidth()

    if not width or width <= 0 then
      return
    end

    dialog.PreviewContent:SetWidth(math.max(1, width))
  end

  dialog.ScrollFrame:HookScript(
    "OnSizeChanged",
    UpdateContentWidth
  )

  C_Timer.After(
    0,
    UpdateContentWidth
  )

  --------------------------------------------------
  -- Status
  --------------------------------------------------
  dialog.Status =
      addon.UI.Base.Label:Create(
        content,
        {
          text = "",
          justify = "CENTER",
          color = addon.UI.Theme.Colors.TextMuted,
        }
      )

  dialog.Status:SetPoint(
    "TOPLEFT",
    dialog.ScrollFrame,
    "BOTTOMLEFT",
    0,
    -10
  )

  dialog.Status:SetPoint(
    "TOPRIGHT",
    dialog.ScrollFrame,
    "BOTTOMRIGHT",
    16,
    -8
  )

  dialog.Status:SetHeight(22)
  dialog.Status:SetJustifyH("CENTER")
  dialog.Status:SetJustifyV("MIDDLE")
end

--------------------------------------------------
-- Create dialog
--------------------------------------------------
local function CreateDialog()
  local dialog =
      addon.UI.Base.Dialog:Create({
        name = "PetMatchImportPreviewDialog",
        title = "Import Preview",
        width = DIALOG_WIDTH,
        autoHeight = true,
        showFooter = true,
        showCloseButton = true,
        contentMargin = CONTENT_MARGIN,
        padding = CONTENT_PADDING,
        bottomSpacing = 0,
        onCancel = function() return true end,
        onClose = function() return true end,
      })

  CreateContent(dialog)

  --------------------------------------------------
  -- Footer
  --------------------------------------------------
  dialog.CancelButton =
      dialog:AddCancelButton({
        text = "Cancel",
        width = 100,
      })

  dialog.ImportButton =
      dialog:AddFooterButton({
        text = "Import Selected",
        width = 140,
        onClick = function() ImportSelected(dialog) end,
      })

  dialog.CreatedControls = {}
  dialog.GroupControls = {}

  --------------------------------------------------
  -- Cleanup
  --------------------------------------------------
  local frame = dialog:GetFrame()

  frame:HookScript(
    "OnHide",
    function()
      ClearPreview(dialog)
      dialog.document = nil
      dialog.options = nil
      dialog.Status:SetText("")
    end
  )

  dialog:RefreshLayout()

  return dialog
end

--------------------------------------------------
-- Show
--------------------------------------------------
function ImportPreviewDialog:Show(document, options)
  if not document then
    return
  end

  if not dialogInstance then
    dialogInstance = CreateDialog()
  end

  local dialog = dialogInstance
  dialog.document = document
  dialog.options = options or {}

  --------------------------------------------------
  -- Reset status color because an earlier error may
  -- have changed it to red.
  --------------------------------------------------
  dialog.Status:SetTextColor(
    unpack(
      addon.UI.Theme.Colors.TextMuted
    )
  )

  BuildPreview(dialog)

  dialog:Show()
  dialog:RefreshLayout()

  dialog:GetFrame():Raise()
end

--------------------------------------------------
-- Hide
--------------------------------------------------
function ImportPreviewDialog:Hide()
  if dialogInstance then
    dialogInstance:Hide()
  end
end

--------------------------------------------------
-- Register
--------------------------------------------------
addon.UI.Dialogs.ImportPreviewDialog = ImportPreviewDialog
