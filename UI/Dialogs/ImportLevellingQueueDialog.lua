local _, addon = ...

local ImportLevellingQueueDialog = {}

local DIALOG_WIDTH = 400
local INPUT_HEIGHT = 130
local STATUS_HEIGHT = 52

local CONTENT_MARGIN = {
  left = -12,
  right = 12,
  top = 4,
  bottom = 8,
}

local CONTENT_PADDING = 14

local dialogInstance

--------------------------------------------------
-- State
--------------------------------------------------
function ImportLevellingQueueDialog:ClearState()
  self.Preview = nil
  self.SortMode = "original"

  if self.Input then
    self.Input:ClearFocus()
  end
end

--------------------------------------------------
-- Status
--------------------------------------------------
function ImportLevellingQueueDialog:SetStatus(message, isError)
  if not self.Status then
    return
  end

  self.Status:SetText(message or "")

  local color

  if isError then
    color = addon.UI.Theme.Colors.Error
  else
    color = addon.UI.Theme.Colors.Success
  end

  self.Status:SetTextColor(
    color[1],
    color[2],
    color[3],
    color[4]
  )
end

function ImportLevellingQueueDialog:ClearStatus()
  if not self.Status then
    return
  end

  self.Status:SetText("")
end

--------------------------------------------------
-- Sort
--------------------------------------------------
function ImportLevellingQueueDialog:SetSortMode(mode)
  self.SortMode = mode or "original"

  self:RefreshSortDropdown()

  if self.Preview then
    addon.Services.ImportExport:SortLevellingQueueImport(self.Preview, self.SortMode)

    self:RefreshPreview()
  end
end

function ImportLevellingQueueDialog:RefreshSortDropdown()
  if not self.SortDropdown then
    return
  end

  local options = {
    {
      id = "original",
      name = "Keep imported order",
    },
    {
      id = "rarityHigh",
      name = "Highest rarity first",
    },
    {
      id = "rarityLow",
      name = "Lowest rarity first",
    },
    {
      id = "levelHigh",
      name = "Highest level first",
    },
    {
      id = "levelLow",
      name = "Lowest level first",
    },
    {
      id = "petType",
      name = "Pet type",
    },
  }

  local selectedText = "Keep imported order"

  for _, option in ipairs(options) do
    if option.id == self.SortMode then
      selectedText = option.name
      break
    end
  end

  self.SortDropdown:SetDefaultText(
    selectedText
  )

  self.SortDropdown:SetupMenu(
    function(_dropdown, rootDescription)
      for _, option in ipairs(options) do
        local optionID = option.id
        local optionName = option.name

        rootDescription:CreateRadio(
          optionName,

          function()
            return self.SortMode == optionID
          end,

          function()
            self:SetSortMode(optionID)
          end
        )
      end
    end
  )
end

--------------------------------------------------
-- Preview
--------------------------------------------------
function ImportLevellingQueueDialog:RefreshPreview()
  if not self.Preview then
    self:ClearStatus()
    return
  end

  local preview = self.Preview
  local total = tonumber(preview.total) or 0
  local addable = tonumber(preview.addable) or 0
  local unavailable = tonumber(preview.unavailable) or 0
  local invalid = tonumber(preview.invalid) or 0
  local unavailableTotal = unavailable + invalid

  local message

  if total == 0 then
    message = "No pets were found in the import."
  elseif addable == total then
    message =
        string.format(
          "%d pet%s found. All %d can be added.",
          total,
          total == 1 and "" or "s",
          total
        )
  elseif addable == 0 then
    message = string.format(
      "%d pet%s found. None can be added.",
      total,
      total == 1 and "" or "s"
    )

    if unavailableTotal > 0 then
      message = message .. string.format(
        "\n%d pet%s already queued or unavailable.",
        unavailableTotal,
        unavailableTotal == 1 and " is" or "s are"
      )
    end
  else
    message =
        string.format(
          "%d pets found. %d can be added.",
          total,
          addable
        )

    if unavailableTotal > 0 then
      message = message .. string.format(
        "\n%d pet%s already queued or unavailable.",
        unavailableTotal,
        unavailableTotal == 1 and " is" or "s are"
      )
    end
  end

  self:SetStatus(message, addable == 0)

  self:UpdateButtons()
end

--------------------------------------------------
-- Prepare
--------------------------------------------------
function ImportLevellingQueueDialog:PrepareImport()
  local value = addon.Utils:Trim(self.Input:GetText() or "")

  self.Preview = nil

  if value == "" then
    self:ClearStatus()
    self:UpdateButtons()
    return
  end

  local preview, errorMessage =
      addon.Services.ImportExport:PrepareLevellingQueueImport(value)

  if not preview then
    self:SetStatus(
      errorMessage
      or "Invalid levelling queue.",
      true
    )

    self:UpdateButtons()
    return
  end

  self.Preview = preview

  addon.Services.ImportExport:SortLevellingQueueImport(preview, self.SortMode)

  self:RefreshPreview()
end

--------------------------------------------------
-- Import
--------------------------------------------------
function ImportLevellingQueueDialog:Import()
  if not self.Preview then
    self:PrepareImport()
  end

  if not self.Preview or (self.Preview.addable or 0) == 0 then
    return
  end

  --------------------------------------------------
  -- Apply the currently selected ordering.
  --------------------------------------------------
  addon.Services.ImportExport:SortLevellingQueueImport(self.Preview, self.SortMode)

  local added, errorMessage =
      addon.Services.ImportExport:ImportLevellingQueue(self.Preview)

  if not added then
    self:SetStatus(
      errorMessage
      or "Unable to import levelling queue.",
      true
    )

    return
  end

  if added == 0 then
    self:SetStatus(
      "No pets were added.",
      true
    )

    return
  end

  addon.Logger:Info(
    string.format(
      "%d pet%s added to the levelling queue.",
      added,
      added == 1 and "" or "s"
    )
  )

  self:Hide()
end

--------------------------------------------------
-- Buttons
--------------------------------------------------
function ImportLevellingQueueDialog:UpdateButtons()
  local hasText = addon.Utils:Trim(self.Input
    and self.Input:GetText() or "") ~= ""

  local canImport = self.Preview ~= nil
      and (self.Preview.addable or 0) > 0

  if self.ImportButton then
    self.ImportButton:SetEnabled(hasText and canImport)
  end
end

--------------------------------------------------
-- Create content
--------------------------------------------------
function ImportLevellingQueueDialog:CreateContent(dialog)
  local content = dialog:GetContentFrame()

  --------------------------------------------------
  -- Description
  --------------------------------------------------
  self.Description =
      addon.UI.Base.Label:Create(
        content,
        {
          text = "Paste a PetMatch levelling queue "
              .. "export string below.",
          justify = "LEFT",
          color = addon.UI.Theme.Colors.Text,
        }
      )

  self.Description:SetPoint(
    "TOPLEFT",
    content,
    "TOPLEFT",
    0,
    0
  )

  self.Description:SetPoint(
    "TOPRIGHT",
    content,
    "TOPRIGHT",
    0,
    0
  )

  --------------------------------------------------
  -- Input background
  --------------------------------------------------
  self.InputBackground =
      CreateFrame(
        "Frame",
        nil,
        content,
        "BackdropTemplate"
      )

  self.InputBackground:SetPoint(
    "TOPLEFT",
    self.Description,
    "BOTTOMLEFT",
    -2,
    -10
  )

  self.InputBackground:SetPoint(
    "TOPRIGHT",
    self.Description,
    "BOTTOMRIGHT",
    2,
    -10
  )

  self.InputBackground:SetHeight(
    INPUT_HEIGHT
  )

  self.InputBackground:SetBackdrop({
    bgFile = "Interface\\FrameGeneral\\UI-Background-Marble",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 128,
    edgeSize = 12,
    insets = {
      left = 3,
      right = 3,
      top = 3,
      bottom = 3,
    },
  })

  self.InputBackground:
      SetBackdropColor(
        0.48,
        0.48,
        0.48,
        0.55
      )

  self.InputBackground:
      SetBackdropBorderColor(
        0.35,
        0.35,
        0.35,
        1
      )

  --------------------------------------------------
  -- Scroll frame
  --------------------------------------------------
  self.ScrollFrame =
      CreateFrame(
        "ScrollFrame",
        nil,
        self.InputBackground,
        "UIPanelScrollFrameTemplate"
      )

  self.ScrollFrame:SetPoint(
    "TOPLEFT",
    self.InputBackground,
    "TOPLEFT",
    8,
    -8
  )

  self.ScrollFrame:SetPoint(
    "BOTTOMRIGHT",
    self.InputBackground,
    "BOTTOMRIGHT",
    -26,
    8
  )

  --------------------------------------------------
  -- Input
  --------------------------------------------------
  self.Input =
      CreateFrame(
        "EditBox",
        nil,
        self.ScrollFrame
      )

  self.Input:SetMultiLine(true)
  self.Input:SetAutoFocus(false)
  self.Input:SetMaxLetters(0)
  self.Input:SetFontObject("ChatFontNormal")
  self.Input:SetJustifyH("LEFT")
  self.Input:SetJustifyV("TOP")

  self.Input:SetTextInsets(
    4,
    4,
    4,
    4
  )

  self.Input:SetWidth(
    DIALOG_WIDTH - 88
  )

  self.Input:SetHeight(
    INPUT_HEIGHT - 20
  )

  self.Input:SetScript(
    "OnEscapePressed",
    function()
      dialog:Cancel()
    end
  )

  self.Input:SetScript(
    "OnTextChanged",
    function(_editBox, userInput)
      if self.ScrollFrame
          and type(self.ScrollFrame.UpdateScrollChildRect)
          == "function" then
        self.ScrollFrame:UpdateScrollChildRect()
      end

      if not userInput then
        return
      end

      ------------------------------------------------
      -- Parse after the paste has reached the editbox.
      ------------------------------------------------
      C_Timer.After(
        0,
        function()
          if self.Input then
            self:PrepareImport()
          end
        end
      )
    end
  )

  self.ScrollFrame:SetScrollChild(
    self.Input
  )

  --------------------------------------------------
  -- Sort dropdown
  --------------------------------------------------
  self.SortDropdown =
      CreateFrame(
        "DropdownButton",
        nil,
        content,
        "WowStyle1DropdownTemplate"
      )

  self.SortDropdown:SetPoint(
    "TOPLEFT",
    self.InputBackground,
    "BOTTOMLEFT",
    2,
    -10
  )

  self.SortDropdown:SetPoint(
    "TOPRIGHT",
    self.InputBackground,
    "BOTTOMRIGHT",
    -2,
    -10
  )

  self.SortDropdown:SetHeight(26)

  --------------------------------------------------
  -- Status
  --------------------------------------------------
  self.Status =
      addon.UI.Base.Label:Create(
        content,
        {
          text = "",
          justify = "LEFT",
          color = addon.UI.Theme.Colors.Text,
        }
      )

  self.Status:SetPoint(
    "TOPLEFT",
    self.SortDropdown,
    "BOTTOMLEFT",
    0,
    -10
  )

  self.Status:SetPoint(
    "TOPRIGHT",
    content,
    "TOPRIGHT",
    0,
    0
  )

  self.Status:SetHeight(STATUS_HEIGHT)
end

--------------------------------------------------
-- Create
--------------------------------------------------
function ImportLevellingQueueDialog:Create()
  if dialogInstance then
    return dialogInstance
  end

  local dialog =
      addon.UI.Base.Dialog:Create({
        name = "PetMatchImportLevellingQueueDialog",
        title = "Import Levelling Queue",
        width = DIALOG_WIDTH,
        contentMargin = CONTENT_MARGIN,
        padding = CONTENT_PADDING,
        bottomSpacing = 0,
        onCancel =
            function()
              self:ClearState()
              return true
            end,
        onClose =
            function()
              self:ClearState()
            end,
      })

  self:CreateContent(dialog)

  --------------------------------------------------
  -- Footer
  --------------------------------------------------
  self.CancelButton =
      dialog:AddCancelButton({
        text = "Cancel",
        width = 95,
      })

  self.ImportButton =
      dialog:AddFooterButton({
        text = "Import",
        width = 95,
        onClick =
            function()
              self:Import()
            end,
      })

  dialogInstance = dialog

  self.Dialog = dialog
  self.Frame = dialog:GetFrame()

  dialog:RefreshLayout()

  return dialog
end

--------------------------------------------------
-- Show
--------------------------------------------------
function ImportLevellingQueueDialog:Show()
  local dialog = self:Create()

  self.Preview = nil
  self.SortMode = "original"

  self.Input:SetText("")

  self:ClearStatus()
  self:RefreshSortDropdown()
  self:UpdateButtons()

  dialog:Show()
  dialog:RefreshLayout()

  self.Input:SetFocus()
end

--------------------------------------------------
-- Hide
--------------------------------------------------
function ImportLevellingQueueDialog:Hide()
  if dialogInstance then
    dialogInstance:Hide()
  end
end

--------------------------------------------------
-- Register
--------------------------------------------------
addon.UI.Dialogs.ImportLevellingQueueDialog = ImportLevellingQueueDialog
