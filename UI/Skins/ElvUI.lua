local _, addon = ...

local ElvUISkin = {}

function ElvUISkin:IsAvailable()
  return C_AddOns.IsAddOnLoaded("ElvUI")
end

-- background of the frames
function ElvUISkin:SkinBackdrop(frame)
  if not frame or not self:IsAvailable() then
    return
  end

  frame:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    tile = false,
    edgeSize = 1,
    insets = {
      left = 1,
      right = 1,
      top = 1,
      bottom = 1,
    },
  })

  frame:SetBackdropColor(0.06, 0.06, 0.06, 0.75)
  frame:SetBackdropBorderColor(0, 0, 0, 1)
end

-- main frame
function ElvUISkin:SkinMainFrame(frame)
  if not frame or not self:IsAvailable() then
    return
  end

  -- Hide Blizzard's decorative border textures
  if frame.NineSlice then
    frame.NineSlice:SetAlpha(0)
  end

  -- Hide Blizzard's original background textures
  local background = _G[frame:GetName() .. "Bg"]
  local topStreaks = _G[frame:GetName() .. "TopTileStreaks"]

  if background then
    background:SetAlpha(0)
  end

  if topStreaks then
    topStreaks:SetAlpha(0)
  end

  -- Hide the original title artwork
  if frame.TitleContainer then
    for _, region in ipairs({
      frame.TitleContainer:GetRegions()
    }) do
      if region:IsObjectType("Texture") then
        region:SetAlpha(0)
      end
    end
  end

  -- Create an independent backdrop
  if not frame.PetMatchSkinBackdrop then
    local backdrop = CreateFrame(
      "Frame",
      nil,
      frame,
      "BackdropTemplate"
    )

    backdrop:SetAllPoints(frame)
    backdrop:SetFrameLevel(
      math.max(0, frame:GetFrameLevel() - 1)
    )

    self:SkinBackdrop(backdrop)

    frame.PetMatchSkinBackdrop = backdrop
  end
end

function ElvUISkin:PositionMainFrame(frame)
  if not frame or not self:IsAvailable() then
    return
  end

  frame:ClearAllPoints()

  frame:SetPoint(
    "TOPLEFT",
    PetJournal,
    "TOPRIGHT",
    -1,
    0
  )
end

-- scrollbars
function ElvUISkin:SkinScrollBar(scrollBar)
  if not scrollBar or not self:IsAvailable() then
    return
  end

  local bar = scrollBar.ScrollBar or scrollBar

  if bar.PetMatchElvUIScrollSkinned then
    return
  end

  local normal = { 0.15, 0.55, 1, 1 }
  local hover = { 0.2, 0.65, 1, 1 }

  --------------------------------------------------
  -- Shared arrow styling
  --------------------------------------------------
  local function SkinArrow(button, direction)
    if not button then
      return
    end

    if button.PetMatchSkinArrowLeft then
      return
    end

    --------------------------------------------------
    -- Hide original Blizzard artwork
    --------------------------------------------------
    local function HideTexture(texture)
      if texture then
        texture:SetAlpha(0)
      end
    end

    HideTexture(button:GetNormalTexture())
    HideTexture(button:GetPushedTexture())
    HideTexture(button:GetHighlightTexture())
    HideTexture(button:GetDisabledTexture())

    -- MinimalScrollBar uses its own Texture region.
    HideTexture(button.Texture)

    --------------------------------------------------
    -- Create white chevron
    --------------------------------------------------
    local left = button:CreateTexture(nil, "OVERLAY")
    local right = button:CreateTexture(nil, "OVERLAY")

    left:SetColorTexture(1, 1, 1, 1)
    right:SetColorTexture(1, 1, 1, 1)

    left:SetSize(9, 3)
    right:SetSize(9, 3)

    local angle = math.rad(40)

    if direction == "UP" then
      left:SetRotation(angle)
      right:SetRotation(-angle)
    else
      left:SetRotation(-angle)
      right:SetRotation(angle)
    end

    left:SetPoint("CENTER", button, "CENTER", -3, 0)
    right:SetPoint("CENTER", button, "CENTER", 3, 0)

    button.PetMatchSkinArrowLeft = left
    button.PetMatchSkinArrowRight = right

    --------------------------------------------------
    -- Hover
    --------------------------------------------------
    button:HookScript("OnEnter", function()
      left:SetColorTexture(0.2, 0.65, 1, 1)
      right:SetColorTexture(0.2, 0.65, 1, 1)
    end)

    button:HookScript("OnLeave", function()
      left:SetColorTexture(1, 1, 1, 1)
      right:SetColorTexture(1, 1, 1, 1)
    end)
  end

  --------------------------------------------------
  -- Modern scrollbar (MinimalScrollBar)
  --------------------------------------------------
  local thumb = bar.Track and bar.Track.Thumb

  if thumb then
    bar.PetMatchElvUIScrollSkinned = true

    --------------------------------------------------
    -- Hide track background
    --------------------------------------------------
    local track = bar.Track

    for _, region in ipairs({ track:GetRegions() }) do
      if region:IsObjectType("Texture") then
        region:SetAlpha(0)
      end
    end

    --------------------------------------------------
    -- Custom thumb texture
    --------------------------------------------------
    local function SetThumbColor(color)
      if thumb.PetMatchThumbTexture then
        thumb.PetMatchThumbTexture:SetColorTexture(
          color[1], color[2], color[3], color[4]
        )
      end
    end

    -- Hide Blizzard thumb artwork
    for _, texture in ipairs({
      thumb.Begin,
      thumb.Middle,
      thumb.End,
    }) do
      if texture then
        texture:SetAlpha(0)
      end
    end

    -- Create custom thumb
    local customThumb = thumb:CreateTexture(nil, "OVERLAY")

    customThumb:SetPoint("TOP", thumb, "TOP", 0, 0)
    customThumb:SetPoint("BOTTOM", thumb, "BOTTOM", 0, 0)
    customThumb:SetWidth(5)

    thumb.PetMatchThumbTexture = customThumb

    SetThumbColor(normal)

    --------------------------------------------------
    -- Hover
    --------------------------------------------------
    thumb:HookScript("OnEnter", function()
      SetThumbColor(hover)
    end)

    thumb:HookScript("OnLeave", function()
      SetThumbColor(normal)
    end)

    --------------------------------------------------
    -- Arrow buttons
    --------------------------------------------------
    SkinArrow(bar.Back or bar.ScrollUpButton, "UP")
    SkinArrow(bar.Forward or bar.ScrollDownButton, "DOWN")

    return
  end

  --------------------------------------------------
  -- Classic scrollbar
  --------------------------------------------------
  local scrollThumb = bar.ThumbTexture

  if not scrollThumb and bar.GetThumbTexture then
    scrollThumb = bar:GetThumbTexture()
  end

  if not scrollThumb then
    return
  end

  bar.PetMatchElvUIScrollSkinned = true

  scrollThumb:SetTexture(
    "Interface\\Buttons\\WHITE8X8"
  )

  scrollThumb:SetVertexColor(
    normal[1],
    normal[2],
    normal[3],
    normal[4]
  )

  --------------------------------------------------
  -- Hide Blizzard track artwork
  --------------------------------------------------
  for _, region in ipairs({ bar:GetRegions() }) do
    if region:IsObjectType("Texture")
        and region ~= scrollThumb then
      region:SetAlpha(0)
    end
  end

  --------------------------------------------------
  -- Classic arrow buttons
  --------------------------------------------------
  SkinArrow(bar.ScrollUpButton, "UP")
  SkinArrow(bar.ScrollDownButton, "DOWN")

  --------------------------------------------------
  -- Thumb hover
  --------------------------------------------------
  bar:HookScript("OnEnter", function()
    scrollThumb:SetVertexColor(
      hover[1],
      hover[2],
      hover[3],
      hover[4]
    )
  end)

  bar:HookScript("OnLeave", function()
    scrollThumb:SetVertexColor(
      normal[1],
      normal[2],
      normal[3],
      normal[4]
    )
  end)
end

-- buttons
function ElvUISkin:SkinButton(button)
  if not button or not self:IsAvailable() then
    return
  end

  if button.PetMatchElvUISkinned then
    return
  end

  button.PetMatchElvUISkinned = true

  --------------------------------------------------
  -- Remove Blizzard button textures
  --------------------------------------------------
  local function ClearTexture(texture)
    if texture then
      texture:SetTexture(nil)
      texture:SetAlpha(0)
    end
  end

  ClearTexture(button:GetNormalTexture())
  ClearTexture(button:GetPushedTexture())
  ClearTexture(button:GetHighlightTexture())
  ClearTexture(button:GetDisabledTexture())

  --------------------------------------------------
  -- Hide Blizzard button background pieces
  --------------------------------------------------
  local function HideBlizzardTexture(texture)
    if texture then
      texture:SetAlpha(0)
    end
  end

  HideBlizzardTexture(button.Left)
  HideBlizzardTexture(button.Middle)
  HideBlizzardTexture(button.Right)

  --------------------------------------------------
  -- ElvUI-style backdrop and border
  --------------------------------------------------
  local backdrop = CreateFrame(
    "Frame",
    nil,
    button,
    "BackdropTemplate"
  )

  backdrop:SetAllPoints(button)
  backdrop:SetFrameLevel(button:GetFrameLevel())

  backdrop:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    tile = false,
    edgeSize = 1,
    insets = {
      left = 1,
      right = 1,
      top = 1,
      bottom = 1,
    },
  })

  backdrop:SetBackdropColor(0.06, 0.06, 0.06, 0.98)
  backdrop:SetBackdropBorderColor(0, 0, 0, 1)

  button.PetMatchSkinBackdrop = backdrop

  --------------------------------------------------
  -- Text styling
  --------------------------------------------------
  local text = button:GetFontString()

  if text then
    text:SetTextColor(1, 0.82, 0, 1)
  end

  --------------------------------------------------
  -- Hover
  --------------------------------------------------
  button:HookScript("OnEnter", function(self)
    backdrop:SetBackdropBorderColor(
      0.15, 0.55, 1, 1
    )

    if text then
      text:SetTextColor(1, 1, 1, 1)
    end
  end)

  button:HookScript("OnLeave", function(self)
    backdrop:SetBackdropBorderColor(
      0, 0, 0, 1
    )

    if text then
      text:SetTextColor(1, 0.82, 0, 1)
    end
  end)
end

-- close buttons
function ElvUISkin:SkinCloseButton(button)
  if not button or not self:IsAvailable() then
    return
  end

  if button.PetMatchElvUICloseSkinned then
    return
  end

  button.PetMatchElvUICloseSkinned = true

  --------------------------------------------------
  -- Hide Blizzard artwork
  --------------------------------------------------
  local function HideTexture(texture)
    if texture then
      texture:SetAlpha(0)
    end
  end

  HideTexture(button:GetNormalTexture())
  HideTexture(button:GetPushedTexture())
  HideTexture(button:GetHighlightTexture())
  HideTexture(button:GetDisabledTexture())

  for _, region in ipairs({ button:GetRegions() }) do
    if region:IsObjectType("Texture") then
      region:SetAlpha(0)
    end
  end

  --------------------------------------------------
  -- White close icon
  --------------------------------------------------
  local icon = button:CreateFontString(
    nil,
    "OVERLAY",
    "GameFontNormalLarge"
  )

  icon:SetFont(
    STANDARD_TEXT_FONT,
    30,
    "OUTLINE"
  )

  icon:SetPoint("CENTER", button, "CENTER", 0, 1)
  icon:SetText("×")
  icon:SetTextColor(1, 1, 1, 1)

  button.PetMatchCloseIcon = icon

  --------------------------------------------------
  -- Hover
  --------------------------------------------------
  button:HookScript("OnEnter", function()
    icon:SetTextColor(0.2, 0.65, 1, 1)
  end)

  button:HookScript("OnLeave", function()
    icon:SetTextColor(1, 1, 1, 1)
  end)
end

-- dropdowns
function ElvUISkin:SkinDropdown(dropdown)
  if not dropdown or not self:IsAvailable() then
    return
  end

  if dropdown.PetMatchElvUISkinned then
    return
  end

  dropdown.PetMatchElvUISkinned = true

  --------------------------------------------------
  -- Hide Blizzard dropdown artwork
  --------------------------------------------------
  for i = 1, dropdown:GetNumRegions() do
    local region = select(i, dropdown:GetRegions())

    if region:IsObjectType("Texture")
        and region:GetAtlas() == "common-dropdown-b-button" then
      region:SetAlpha(0)
    end
  end

  --------------------------------------------------
  -- Background and border
  --------------------------------------------------
  local backdrop = CreateFrame(
    "Frame",
    nil,
    dropdown,
    "BackdropTemplate"
  )

  backdrop:SetAllPoints(dropdown)
  backdrop:SetFrameLevel(dropdown:GetFrameLevel())

  backdrop:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
    insets = {
      left = 1,
      right = 1,
      top = 1,
      bottom = 1,
    },
  })

  backdrop:SetBackdropColor(0.06, 0.06, 0.06, 0.98)
  backdrop:SetBackdropBorderColor(0, 0, 0, 1)

  dropdown.PetMatchSkinBackdrop = backdrop

  --------------------------------------------------
  -- Static white chevron
  --------------------------------------------------
  local arrow = dropdown:CreateFontString(
    nil,
    "OVERLAY",
    "GameFontNormal"
  )

  arrow:SetFont(
    STANDARD_TEXT_FONT,
    14,
    "OUTLINE"
  )

  arrow:SetText(">")

  arrow:SetTextColor(1, 1, 1, 1)

  arrow:SetPoint(
    "RIGHT",
    dropdown,
    "RIGHT",
    -1,
    0
  )

  dropdown.PetMatchSkinArrow = arrow

  --------------------------------------------------
  -- Hover
  --------------------------------------------------

  dropdown:HookScript("OnEnter", function()
    backdrop:SetBackdropBorderColor(0.15, 0.55, 1, 1)
  end)

  dropdown:HookScript("OnLeave", function()
    backdrop:SetBackdropBorderColor(0, 0, 0, 1)
  end)
end

function ElvUISkin:SkinBlizzardDropdown(dropdown)
  if not dropdown or not self:IsAvailable() then
    return
  end

  if dropdown.PetMatchElvUIBlizzardDropdownSkinned then
    return
  end

  dropdown.PetMatchElvUIBlizzardDropdownSkinned = true

  --------------------------------------------------
  -- Hide original Blizzard artwork
  --------------------------------------------------
  local function HideTextures(frame)
    if not frame then
      return
    end

    for i = 1, frame:GetNumRegions() do
      local region = select(i, frame:GetRegions())

      if region and region:IsObjectType("Texture") then
        region:SetAlpha(0)
      end
    end
  end

  HideTextures(dropdown)

  --------------------------------------------------
  -- Background and border
  --------------------------------------------------
  local backdrop = CreateFrame(
    "Frame",
    nil,
    dropdown,
    "BackdropTemplate"
  )

  backdrop:SetAllPoints(dropdown)
  backdrop:SetFrameLevel(dropdown:GetFrameLevel())

  backdrop:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
    insets = {
      left = 1,
      right = 1,
      top = 1,
      bottom = 1,
    },
  })

  backdrop:SetBackdropColor(0.06, 0.06, 0.06, 0.98)
  backdrop:SetBackdropBorderColor(0, 0, 0, 1)

  dropdown.PetMatchSkinBackdrop = backdrop

  --------------------------------------------------
  -- White downward chevron
  --------------------------------------------------
  local arrow = CreateFrame("Frame", nil, dropdown)
  arrow:SetSize(20, 20)
  arrow:SetPoint("RIGHT", dropdown, "RIGHT", -8, 0)
  arrow:SetFrameLevel(dropdown:GetFrameLevel() + 2)

  local left = arrow:CreateTexture(nil, "OVERLAY")
  local right = arrow:CreateTexture(nil, "OVERLAY")

  left:SetColorTexture(1, 1, 1, 1)
  right:SetColorTexture(1, 1, 1, 1)

  left:SetSize(9, 3)
  right:SetSize(9, 3)

  left:SetRotation(math.rad(-40))
  right:SetRotation(math.rad(40))

  left:SetPoint("CENTER", arrow, "CENTER", -3, 0)
  right:SetPoint("CENTER", arrow, "CENTER", 3, 0)

  dropdown.PetMatchSkinArrow = arrow

  --------------------------------------------------
  -- Hover
  --------------------------------------------------
  dropdown:HookScript("OnEnter", function()
    backdrop:SetBackdropBorderColor(0.15, 0.55, 1, 1)
  end)

  dropdown:HookScript("OnLeave", function()
    backdrop:SetBackdropBorderColor(0, 0, 0, 1)
  end)
end

-- check and radio buttons
function ElvUISkin:SkinCheckButton(button)
  if not button or not self:IsAvailable() then
    return
  end

  if button.PetMatchElvUICheckSkinned then
    return
  end

  button.PetMatchElvUICheckSkinned = true

  --------------------------------------------------
  -- Hide Blizzard artwork
  --------------------------------------------------
  local function HideTexture(texture)
    if texture then
      texture:SetAlpha(0)
    end
  end

  HideTexture(button:GetNormalTexture())
  HideTexture(button:GetPushedTexture())
  HideTexture(button:GetHighlightTexture())
  HideTexture(button:GetDisabledTexture())
  HideTexture(button:GetCheckedTexture())
  HideTexture(button:GetDisabledCheckedTexture())

  --------------------------------------------------
  -- Background
  --------------------------------------------------
  local backdrop = CreateFrame(
    "Frame",
    nil,
    button,
    "BackdropTemplate"
  )

  backdrop:SetSize(14, 14)
  backdrop:SetPoint("CENTER", button, "CENTER", 0, 0)
  backdrop:SetFrameLevel(button:GetFrameLevel())

  backdrop:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
  })

  backdrop:SetBackdropColor(0.15, 0.15, 0.15, 1)
  backdrop:SetBackdropBorderColor(0.06, 0.06, 0.06, 1)

  button.PetMatchSkinBackdrop = backdrop

  --------------------------------------------------
  -- Selection indicator
  --------------------------------------------------
  local indicator = button:CreateTexture(nil, "OVERLAY")

  indicator:SetColorTexture(0.15, 0.55, 1, 1)

  indicator:SetPoint("TOPLEFT", backdrop, "TOPLEFT", 1, -1)
  indicator:SetPoint("BOTTOMRIGHT", backdrop, "BOTTOMRIGHT", -1, 1)

  indicator:Hide()

  button.PetMatchSkinIndicator = indicator

  --------------------------------------------------
  -- Update checked state
  --------------------------------------------------
  local function Refresh()
    indicator:SetShown(button:GetChecked() == true)
  end

  button:HookScript("OnClick", Refresh)
  button:HookScript("OnShow", Refresh)

  hooksecurefunc(button, "SetChecked", Refresh)

  Refresh()
end

-- tabs
function ElvUISkin:SkinTab(tab)
  if not tab or not self:IsAvailable() then
    return
  end

  if tab.PetMatchElvUISkinned then
    return
  end

  tab.PetMatchElvUISkinned = true

  --------------------------------------------------
  -- ElvUI-specific positioning
  --------------------------------------------------
  local point, relativeTo, relativePoint, x, y = tab:GetPoint(1)

  if point == "BOTTOMRIGHT" and relativePoint == "BOTTOMRIGHT" then
    tab:ClearAllPoints()

    tab:SetPoint(
      point,
      relativeTo,
      relativePoint,
      x + 12,
      y - 4
    )
  end

  --------------------------------------------------
  -- Hide Blizzard tab artwork
  --------------------------------------------------
  for i = 1, tab:GetNumRegions() do
    local region = select(i, tab:GetRegions())

    if region:IsObjectType("Texture") then
      region:SetAlpha(0)
    end
  end

  -- Hide inherited button textures
  local function HideTexture(texture)
    if texture then
      texture:SetAlpha(0)
    end
  end

  HideTexture(tab:GetNormalTexture())
  HideTexture(tab:GetHighlightTexture())
  HideTexture(tab:GetPushedTexture())
  HideTexture(tab:GetDisabledTexture())

  --------------------------------------------------
  -- ElvUI-style background
  --------------------------------------------------
  local backdrop = CreateFrame(
    "Frame",
    nil,
    tab,
    "BackdropTemplate"
  )

  backdrop:SetAllPoints(tab)
  backdrop:SetFrameLevel(tab:GetFrameLevel())

  backdrop:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    tile = false,
    edgeSize = 1,
    insets = {
      left = 1,
      right = 1,
      top = 1,
      bottom = 1,
    },
  })

  backdrop:SetBackdropColor(0.13, 0.13, 0.13, 1)
  backdrop:SetBackdropBorderColor(0.06, 0.06, 0.06, 1)

  tab.PetMatchSkinBackdrop = backdrop

  --------------------------------------------------
  -- Text styling
  --------------------------------------------------
  local text = tab:GetFontString()

  --------------------------------------------------
  -- Keep tab text centered in all states
  --------------------------------------------------
  if text then
    text:ClearAllPoints()
    text:SetPoint("CENTER", tab, "CENTER", 0, 0)
  end

  local function UpdateTextColor(selected)
    if not text then
      return
    end

    text:SetFontObject(GameFontNormal)

    -- Blizzard may reposition the selected tab text
    text:ClearAllPoints()
    text:SetPoint("CENTER", tab, "CENTER", 0, 0)

    if selected or tab:IsMouseOver() then
      text:SetTextColor(1, 1, 1, 1)
    else
      text:SetTextColor(1, 0.82, 0, 1)
    end
  end

  --------------------------------------------------
  -- Called by Panels:SelectTab()
  --------------------------------------------------
  function tab:PetMatchUpdateSkin(selected)
    self.PetMatchSelected = selected
    UpdateTextColor(selected)
  end

  --------------------------------------------------
  -- Hover
  --------------------------------------------------
  tab:HookScript("OnEnter", function()
    UpdateTextColor(tab.PetMatchSelected)
  end)

  tab:HookScript("OnLeave", function()
    UpdateTextColor(tab.PetMatchSelected)
  end)

  UpdateTextColor(false)
end

-- edit boxes
function ElvUISkin:SkinEditBox(editBox, isSearch)
  if not editBox or not self:IsAvailable() then
    return
  end

  if editBox.PetMatchElvUISkinned then
    return
  end

  editBox.PetMatchElvUISkinned = true

  --------------------------------------------------
  -- Hide Blizzard input artwork
  --------------------------------------------------
  for _, region in ipairs({ editBox:GetRegions() }) do
    if region:IsObjectType("Texture") then
      region:SetAlpha(0)
    end
  end

  --------------------------------------------------
  -- ElvUI background
  --------------------------------------------------
  local backdrop = CreateFrame(
    "Frame",
    nil,
    editBox,
    "BackdropTemplate"
  )

  local topInset = isSearch and 0 or 3
  local bottomInset = isSearch and 0 or 5

  backdrop:ClearAllPoints()

  backdrop:SetPoint(
    "TOPLEFT",
    editBox,
    "TOPLEFT",
    0,
    -topInset
  )

  backdrop:SetPoint(
    "BOTTOMRIGHT",
    editBox,
    "BOTTOMRIGHT",
    0,
    bottomInset
  )

  backdrop:SetFrameLevel(
    math.max(0, editBox:GetFrameLevel() - 1)
  )

  backdrop:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
    insets = {
      left = 1,
      right = 1,
      top = 1,
      bottom = 1,
    },
  })

  backdrop:SetBackdropColor(0.12, 0.12, 0.12, 1)
  backdrop:SetBackdropBorderColor(0, 0, 0, 1)

  editBox.PetMatchSkinBackdrop = backdrop

  --------------------------------------------------
  -- Search icon (only for search fields)
  --------------------------------------------------
  if isSearch then
    local searchIcon = editBox:CreateTexture(
      nil,
      "OVERLAY"
    )

    searchIcon:SetSize(10, 10)
    searchIcon:SetPoint("LEFT", editBox, "LEFT", 8, 0)
    searchIcon:SetAtlas("common-search-magnifyingglass")
    searchIcon:SetVertexColor(0.55, 0.55, 0.55, 1)

    editBox.PetMatchSearchIcon = searchIcon
  end

  --------------------------------------------------
  -- Text positioning
  --------------------------------------------------
  local textOffset = isSearch and 28 or 8

  editBox:SetTextInsets(textOffset, 6, 0, 0)

  if editBox.Instructions then
    editBox.Instructions:ClearAllPoints()
    editBox.Instructions:SetPoint(
      "LEFT",
      editBox,
      "LEFT",
      textOffset,
      0
    )

    editBox.Instructions:SetTextColor(
      0.55, 0.55, 0.55, 1
    )
  end

  --------------------------------------------------
  -- Focus border
  --------------------------------------------------
  editBox:HookScript("OnEditFocusGained", function()
    backdrop:SetBackdropBorderColor(0.15, 0.55, 1, 1)
  end)

  editBox:HookScript("OnEditFocusLost", function()
    backdrop:SetBackdropBorderColor(0, 0, 0, 1)
  end)
end

function ElvUISkin:SkinMultiLineEditBox(editBox, scrollBar)
  if not editBox or not self:IsAvailable() then
    return
  end

  if editBox.PetMatchElvUIMultiLineSkinned then
    return
  end

  editBox.PetMatchElvUIMultiLineSkinned = true

  --------------------------------------------------
  -- Background
  --------------------------------------------------
  local backdrop = CreateFrame(
    "Frame",
    nil,
    editBox,
    "BackdropTemplate"
  )

  backdrop:SetAllPoints(editBox)

  backdrop:SetFrameLevel(
    math.max(0, editBox:GetFrameLevel() - 1)
  )

  editBox:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    tile = false,
    edgeSize = 1,
    insets = {
      left = 0,
      right = 0,
      top = 0,
      bottom = 0,
    },
  })

  editBox:SetBackdropColor(0.06, 0.06, 0.06, 0.65)
  editBox:SetBackdropBorderColor(0, 0, 0, 1)

  editBox.PetMatchSkinBackdrop = backdrop

  --------------------------------------------------
  -- Scrollbar
  --------------------------------------------------
  if scrollBar then
    addon.SkinManager:ApplyScrollBar(scrollBar)
  end
end

-- dialogs
function ElvUISkin:SkinDialog(dialog)
  if not dialog or not self:IsAvailable() then
    return
  end

  local frame = dialog.Frame
  local contentFrame = dialog.ContentFrame

  if not frame then
    return
  end

  --------------------------------------------------
  -- Hide Blizzard frame artwork
  --------------------------------------------------
  if frame.NineSlice then
    frame.NineSlice:SetAlpha(0)
  end

  if frame.Bg then
    frame.Bg:SetAlpha(0)
  end

  if frame.TopTileStreaks then
    frame.TopTileStreaks:SetAlpha(0)
  end

  --------------------------------------------------
  -- Hide Blizzard title artwork
  --------------------------------------------------
  if frame.TitleContainer then
    for _, region in ipairs({
      frame.TitleContainer:GetRegions()
    }) do
      if region:IsObjectType("Texture") then
        region:SetAlpha(0)
      end
    end
  end

  --------------------------------------------------
  -- ElvUI dialog background
  --------------------------------------------------
  if not frame.PetMatchSkinBackdrop then
    local backdrop = CreateFrame(
      "Frame",
      nil,
      frame,
      "BackdropTemplate"
    )

    backdrop:SetAllPoints(frame)

    backdrop:SetFrameLevel(
      math.max(0, frame:GetFrameLevel() - 1)
    )

    self:SkinBackdrop(backdrop)

    frame.PetMatchSkinBackdrop = backdrop
  end

  --------------------------------------------------
  -- Hide Blizzard content artwork
  --------------------------------------------------
  if contentFrame then
    if contentFrame.NineSlice then
      contentFrame.NineSlice:SetAlpha(0)
    end

    if contentFrame.Bg then
      contentFrame.Bg:SetAlpha(0)
    end

    if contentFrame.Inset then
      contentFrame.Inset:SetAlpha(0)
    end

    if contentFrame.SetBackdrop then
      contentFrame:SetBackdrop(nil)
    end
  end
end

-- accordions
function ElvUISkin:SkinAccordionIcon(header)
  if not header or not self:IsAvailable() then
    return
  end

  local icon = header.Icon

  if not icon then
    return
  end

  -- Crop the icon to match ElvUI styling
  icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

  -- Create a thin border around the icon
  if not header.PetMatchIconBorder then
    local border = CreateFrame(
      "Frame",
      nil,
      header,
      "BackdropTemplate"
    )

    border:SetPoint("TOPLEFT", icon, "TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 1, -1)

    border:SetBackdrop({
      edgeFile = "Interface\\Buttons\\WHITE8X8",
      edgeSize = 1,
    })

    border:SetBackdropBorderColor(0, 0, 0, 1)
    border:EnableMouse(false)

    header.PetMatchIconBorder = border
  end

  header.PetMatchIconBorder:SetShown(
    header.FolderIcon ~= nil
  )
end

function ElvUISkin:SkinAccordionHeader(header)
  if not header or not self:IsAvailable() then
    return
  end

  if header.PetMatchElvUIAccordionSkinned then
    return
  end

  header.PetMatchElvUIAccordionSkinned = true

  --------------------------------------------------
  -- Background
  --------------------------------------------------
  header:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
    insets = {
      left = 1,
      right = 1,
      top = 1,
      bottom = 1,
    },
  })

  header:SetBackdropColor(0.06, 0.06, 0.06, 0.35)
  header:SetBackdropBorderColor(0.06, 0.06, 0.06, 1)

  --------------------------------------------------
  -- Remove default gradient
  --------------------------------------------------
  if header.BackgroundGradient then
    header.BackgroundGradient:SetTexture(nil)
    header.BackgroundGradient:Hide()
  end

  --------------------------------------------------
  -- Remove Blizzard highlight
  --------------------------------------------------
  if header.Highlight then
    header.Highlight:SetAlpha(0)
  end

  --------------------------------------------------
  -- Border states
  --------------------------------------------------
  local function UpdateBorder()
    if header.IsMouseOver and header:IsMouseOver() then
      header:SetBackdropBorderColor(0.15, 0.55, 1, 1)
    elseif header.Expanded then
      header:SetBackdropBorderColor(0.15, 0.55, 1, 0.7)
    else
      header:SetBackdropBorderColor(0, 0, 0, 1)
    end
  end

  header:HookScript("OnEnter", UpdateBorder)
  header:HookScript("OnLeave", UpdateBorder)

  --------------------------------------------------
  -- Preserve expanded state styling
  --------------------------------------------------
  hooksecurefunc(header, "SetExpanded", UpdateBorder)

  UpdateBorder()

  self:SkinAccordionIcon(header)
end

-- tabs
function ElvUISkin:SkinDialogTab(button)
  if not button or not self:IsAvailable() then
    return
  end

  if button.PetMatchElvUIDialogTabSkinned then
    return
  end

  button.PetMatchElvUIDialogTabSkinned = true

  --------------------------------------------------
  -- Hide Blizzard button textures
  --------------------------------------------------
  local function HideTexture(texture)
    if texture then
      texture:SetAlpha(0)
    end
  end

  -- UIPanelButtonTemplate decorative textures
  HideTexture(button.Left)
  HideTexture(button.Middle)
  HideTexture(button.Right)

  -- Button state textures
  HideTexture(button:GetNormalTexture())
  HideTexture(button:GetPushedTexture())
  HideTexture(button:GetDisabledTexture())
  HideTexture(button:GetHighlightTexture())

  -- Hide additional Blizzard decorative textures
  for _, region in ipairs({ button:GetRegions() }) do
    if region:IsObjectType("Texture") then
      region:SetAlpha(0)
    end
  end

  --------------------------------------------------
  -- Create ElvUI backdrop
  --------------------------------------------------
  local backdrop = CreateFrame(
    "Frame",
    nil,
    button,
    "BackdropTemplate"
  )

  backdrop:SetAllPoints(button)
  backdrop:SetFrameLevel(button:GetFrameLevel())

  self:SkinBackdrop(backdrop)

  button.PetMatchElvUIDialogTabBackdrop = backdrop

  local normalFont = button:GetNormalFontObject()

  if normalFont then
    button:SetDisabledFontObject(normalFont)
  end

  --------------------------------------------------
  -- Update active/inactive appearance
  --------------------------------------------------
  local function UpdateAppearance()
    local fontString = button:GetFontString()

    if not button:IsEnabled() then
      -- Active tab
      backdrop:SetBackdropColor(0.06, 0.06, 0.06, 0.85)
      backdrop:SetBackdropBorderColor(0.20, 0.55, 0.85, 1)

      if fontString then
        fontString:SetTextColor(1, 1, 1, 1)
      end
    else
      -- Inactive tab
      backdrop:SetBackdropColor(0.15, 0.15, 0.15, 1)
      backdrop:SetBackdropBorderColor(0, 0, 0, 1)

      if fontString then
        if button:IsMouseOver() then
          fontString:SetTextColor(1, 1, 1, 1)
        else
          fontString:SetTextColor(1, 0.82, 0, 1)
        end
      end
    end
  end

  --------------------------------------------------
  -- Keep appearance synchronized
  --------------------------------------------------
  button:HookScript("OnEnable", UpdateAppearance)
  button:HookScript("OnDisable", UpdateAppearance)

  button:HookScript("OnEnter", UpdateAppearance)
  button:HookScript("OnLeave", UpdateAppearance)

  UpdateAppearance()
end

-- team cards
function ElvUISkin:SkinTeamCard(card)
  if not card or not self:IsAvailable() then
    return
  end

  if card.PetMatchElvUITeamCardSkinned then
    return
  end

  card.PetMatchElvUITeamCardSkinned = true

  --------------------------------------------------
  -- Flat ElvUI background
  --------------------------------------------------
  card:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
    insets = {
      left = 1,
      right = 1,
      top = 1,
      bottom = 1,
    },
  })

  card:SetBackdropColor(0.06, 0.06, 0.06, 0.90)

  --------------------------------------------------
  -- Remove gradient
  --------------------------------------------------
  if card.BackgroundGradient then
    card.BackgroundGradient:Hide()
  end

  --------------------------------------------------
  -- Remove Blizzard highlight
  --------------------------------------------------
  if card.Highlight then
    card.Highlight:SetAlpha(0)
  end

  --------------------------------------------------
  -- Initial border
  --------------------------------------------------
  if card.Selected then
    card:SetBackdropBorderColor(0.15, 0.55, 1, 1)
  else
    card:SetBackdropBorderColor(0, 0, 0, 1)
  end
end

-- levelling pet rows
function ElvUISkin:SkinLevellingQueueRow(row)
  if not row or not self:IsAvailable() then
    return
  end

  if row.PetMatchElvUILevellingSkinned then
    return
  end

  row.PetMatchElvUILevellingSkinned = true

  local frame = row.Frame

  if not frame then
    return
  end

  --------------------------------------------------
  -- Flat background
  --------------------------------------------------
  frame:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
    insets = {
      left = 1,
      right = 1,
      top = 1,
      bottom = 1,
    },
  })

  frame:SetBackdropColor(0.06, 0.06, 0.06, 0.65)
  frame:SetBackdropBorderColor(0, 0, 0, 1)

  --------------------------------------------------
  -- Remove gradient
  --------------------------------------------------
  if row.BackgroundGradient then
    row.BackgroundGradient:Hide()
  end

  --------------------------------------------------
  -- Remove Blizzard highlight
  --------------------------------------------------
  if row.Highlight then
    row.Highlight:SetAlpha(0)
  end
end

function ElvUISkin:SkinLevellingXPBar(row)
  if not row or not self:IsAvailable() then
    return
  end

  local bar = row.XPBar

  if not bar or bar.PetMatchElvUISkinned then
    return
  end

  bar.PetMatchElvUISkinned = true

  --------------------------------------------------
  -- Flat status bar
  --------------------------------------------------
  bar:SetStatusBarTexture(
    "Interface\\Buttons\\WHITE8X8"
  )

  bar:SetStatusBarColor(0.15, 0.55, 1, 1)

  --------------------------------------------------
  -- Background
  --------------------------------------------------
  if row.XPBarBackground then
    row.XPBarBackground:SetColorTexture(
      0.15, 0.15, 0.15, 1
    )
  end

  --------------------------------------------------
  -- Hide Blizzard border
  --------------------------------------------------
  if row.XPBarBorder then
    row.XPBarBorder:Hide()
  end

  --------------------------------------------------
  -- Thin black border
  --------------------------------------------------
  local border = CreateFrame(
    "Frame",
    nil,
    bar,
    "BackdropTemplate"
  )

  border:SetPoint("TOPLEFT", bar, "TOPLEFT", -1, 1)
  border:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 1, -1)

  border:SetFrameLevel(bar:GetFrameLevel() + 1)

  border:SetBackdrop({
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
  })

  border:SetBackdropBorderColor(0, 0, 0, 1)

  row.PetMatchXPBarBorder = border

  --------------------------------------------------
  -- XP text above border
  --------------------------------------------------
  if row.XPText then
    row.XPText:SetDrawLayer("OVERLAY", 7)
  end
end

-- target team card
function ElvUISkin:SkinTargetTeamCard(frame)
  if not frame or not self:IsAvailable() then
    return
  end

  if frame.PetMatchElvUITargetSkinned then
    return
  end

  frame.PetMatchElvUITargetSkinned = true

  --------------------------------------------------
  -- ElvUI background
  --------------------------------------------------
  frame:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
    insets = {
      left = 1,
      right = 1,
      top = 1,
      bottom = 1,
    },
  })

  frame:SetBackdropColor(0.06, 0.06, 0.06, 0.9)
  frame:SetBackdropBorderColor(0, 0, 0, 1)
end

-- target team rows from selection dialog
function ElvUISkin:SkinTargetTeamRow(row)
  if not row or not self:IsAvailable() then
    return
  end

  if row.PetMatchElvUITargetRowSkinned then
    return
  end

  row.PetMatchElvUITargetRowSkinned = true

  row:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
    insets = {
      left = 1,
      right = 1,
      top = 1,
      bottom = 1,
    },
  })

  row:SetBackdropColor(0.06, 0.06, 0.06, 0.65)
  row:SetBackdropBorderColor(0.06, 0.06, 0.06, 1)
end

-- pet icons
function ElvUISkin:SkinPetIcon(petSlot)
  if not petSlot or not self:IsAvailable() then
    return
  end

  if petSlot.PetMatchElvUIIconSkinned then
    return
  end

  petSlot.PetMatchElvUIIconSkinned = true

  --------------------------------------------------
  -- Crop pet icon texture
  --------------------------------------------------
  if petSlot.Icon then
    petSlot.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  end

  --------------------------------------------------
  -- Hide original Blizzard icon border
  --------------------------------------------------
  if petSlot.IconBorder then
    petSlot.IconBorder:Hide()
  end

  local border = {
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
    insets = {
      left = 0,
      right = 0,
      top = 0,
      bottom = 0,
    },
  }

  --------------------------------------------------
  -- Rarity border
  --------------------------------------------------
  if petSlot.RarityBorder then
    petSlot.RarityBorder:SetBackdrop(border)
  end

  --------------------------------------------------
  -- Levelling queue icon border
  --------------------------------------------------
  if petSlot.IconBorder and petSlot.Icon then
    petSlot.IconBorder:Hide()

    local rarityBorder = CreateFrame(
      "Frame",
      nil,
      petSlot.Frame,
      "BackdropTemplate"
    )

    rarityBorder:SetPoint("TOPLEFT", petSlot.Icon, "TOPLEFT", 0, 0)
    rarityBorder:SetPoint("BOTTOMRIGHT", petSlot.Icon, "BOTTOMRIGHT", 0, 0)

    rarityBorder:SetBackdrop({
      edgeFile = "Interface\\Buttons\\WHITE8X8",
      edgeSize = 1,
    })

    rarityBorder:SetFrameLevel(petSlot.Frame:GetFrameLevel() + 1)
    rarityBorder:EnableMouse(false)

    petSlot.RarityBorder = rarityBorder
  end

  --------------------------------------------------
  -- Family icon border
  --------------------------------------------------
  if petSlot.FamilyBackground then
    petSlot.FamilyBackground:SetBackdrop(border)
    petSlot.FamilyBackground:SetBackdropBorderColor(
      0.06, 0.06, 0.06, 0
    )
  end
end

-- toolbar icons
function ElvUISkin:SkinToolbarIcon(button)
  if not button or not self:IsAvailable() then
    return
  end

  if button.PetMatchElvUIToolbarSkinned then
    return
  end

  button.PetMatchElvUIToolbarSkinned = true

  --------------------------------------------------
  -- Expand icon to fill the button
  --------------------------------------------------
  if button.Icon then
    button.Icon:ClearAllPoints()
    button.Icon:SetAllPoints(button)
  end

  --------------------------------------------------
  -- Hover highlight
  --------------------------------------------------
  if not button.PetMatchElvUIHoverHighlight then
    local highlight = button:CreateTexture(nil, "OVERLAY")

    highlight:SetTexture("Interface\\Buttons\\WHITE8X8")
    highlight:SetAllPoints(button)
    highlight:SetVertexColor(1, 1, 1, 0.18)

    button:SetHighlightTexture(highlight)

    button.PetMatchElvUIHoverHighlight = highlight
  end
end

-- icons in icon picker
function ElvUISkin:SkinFolderPreview(frame, texture, cropIcon)
  if not frame or not self:IsAvailable() then
    return
  end

  if frame.PetMatchElvUISkinned then
    return
  end

  frame.PetMatchElvUISkinned = true

  if cropIcon and texture then
    texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  end

  local border = CreateFrame(
    "Frame",
    nil,
    frame,
    "BackdropTemplate"
  )

  border:SetAllPoints(frame)

  border:SetBackdrop({
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
  })

  border:SetBackdropBorderColor(0, 0, 0, 1)
  border:EnableMouse(false)
  border:SetFrameLevel(frame:GetFrameLevel() + 1)

  frame.PetMatchElvUIBorder = border
end

function ElvUISkin:SkinIconPickerButton(button)
  if not button or not self:IsAvailable() then
    return
  end

  if button.PetMatchElvUISkinned then
    return
  end

  button.PetMatchElvUISkinned = true

  if button.Icon then
    button.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  end

  local border = CreateFrame(
    "Frame",
    nil,
    button,
    "BackdropTemplate"
  )

  border:SetAllPoints(button)

  border:SetBackdrop({
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
  })

  border:SetBackdropBorderColor(0, 0, 0, 1)
  border:EnableMouse(false)
  border:SetFrameLevel(button:GetFrameLevel() + 1)

  button.PetMatchElvUIBorder = border
end

-- team setup
function ElvUISkin:SkinTeamSetup(frame)
  if not frame or not self:IsAvailable() then
    return
  end

  if frame.PetMatchElvUITeamSetupSkinned then
    return
  end

  frame.PetMatchElvUITeamSetupSkinned = true

  frame:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    tile = false,
    edgeSize = 1,
    insets = {
      left = 1,
      right = 1,
      top = 1,
      bottom = 1,
    },
  })

  -- Solid dark background
  frame:SetBackdropColor(0.06, 0.06, 0.06, 1)

  -- Blue border
  frame:SetBackdropBorderColor(0.15, 0.55, 1, 1)
end

-- pet card
function ElvUISkin:SkinPetCardBackground(background, isDefault)
  if not background or not self:IsAvailable() then
    return
  end

  local frame = background.Frame

  if not frame then
    return
  end

  if isDefault then
    self:SkinBackdrop(frame)
  else
    frame:SetBackdrop({
      bgFile = "Interface\\Buttons\\WHITE8X8",
      edgeFile = "Interface\\Buttons\\WHITE8X8",
      tile = false,
      edgeSize = 1,
      insets = {
        left = 1,
        right = 1,
        top = 1,
        bottom = 1,
      },
    })

    frame:SetBackdropColor(0, 0, 0, 1)
    frame:SetBackdropBorderColor(0, 0, 0, 1)
  end
end

function ElvUISkin:SkinPetCardAbilityIcon(cell)
  if not cell or not self:IsAvailable() then
    return
  end

  if not cell.Icon or not cell.NormalBorderFrame then
    return
  end

  if cell.PetMatchElvUIAbilityIconSkinned then
    return
  end

  cell.PetMatchElvUIAbilityIconSkinned = true

  --------------------------------------------------
  -- Crop ability icon
  --------------------------------------------------
  cell.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

  --------------------------------------------------
  -- Replace Blizzard icon border
  --------------------------------------------------
  local border = cell.NormalBorderFrame

  border:SetBackdrop({
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
  })

  border:SetBackdropBorderColor(0, 0, 0, 1)
end

function ElvUISkin:SkinPetCardAbilityCell(cell)
  if not cell or not self:IsAvailable() then
    return
  end

  if cell.PetMatchElvUIAbilitySkinned then
    return
  end

  if not cell.Frame or not cell.Border then
    return
  end

  cell.PetMatchElvUIAbilitySkinned = true

  --------------------------------------------------
  -- Hide original Blizzard background
  --------------------------------------------------
  if cell.Background then
    cell.Background:Hide()
  end

  --------------------------------------------------
  -- Apply ElvUI backdrop
  --------------------------------------------------
  self:SkinBackdrop(cell.Border)

  cell.Border:SetBackdropColor(0.02, 0.02, 0.02, 0.35)

  cell.Border:SetBackdropBorderColor(
    0, 0, 0, 1
  )
end

function ElvUISkin:SkinPetCard(frame)
  if not frame or not self:IsAvailable() then
    return
  end

  if frame.PetMatchElvUISkinned then
    return
  end

  frame.PetMatchElvUISkinned = true

  --------------------------------------------------
  -- Hide Blizzard panel textures
  --------------------------------------------------
  local function HideTextures(parent)
    if not parent then
      return
    end

    for _, region in ipairs({ parent:GetRegions() }) do
      if region:IsObjectType("Texture") then
        region:SetAlpha(0)
      end
    end
  end

  HideTextures(frame)

  if frame.NineSlice then
    frame.NineSlice:Hide()
  end

  --------------------------------------------------
  -- Title container
  --------------------------------------------------
  local titleContainer = frame.TitleContainer

  if titleContainer then
    HideTextures(titleContainer)

    -- Hide additional title decorations
    for _, child in ipairs({ titleContainer:GetChildren() }) do
      HideTextures(child)
    end
  end

  if titleContainer then
    local titleBackdrop = CreateFrame(
      "Frame",
      nil,
      frame,
      "BackdropTemplate"
    )

    titleBackdrop:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
    titleBackdrop:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -1)
    titleBackdrop:SetHeight(titleContainer:GetHeight())

    titleBackdrop:SetFrameLevel(
      math.max(0, titleContainer:GetFrameLevel() - 1)
    )

    self:SkinBackdrop(titleBackdrop)

    frame.PetMatchElvUITitleBackdrop = titleBackdrop
  end

  --------------------------------------------------
  -- ElvUI background behind the content
  --------------------------------------------------
  local backdrop = CreateFrame(
    "Frame",
    nil,
    frame,
    "BackdropTemplate"
  )

  backdrop:SetAllPoints(frame)
  backdrop:SetFrameLevel(
    math.max(0, frame:GetFrameLevel() - 1)
  )

  self:SkinBackdrop(backdrop)

  backdrop:SetBackdropColor(0.02, 0.02, 0.02, 0.95)

  frame.PetMatchElvUIBackdrop = backdrop
end

-- pet type filters
function ElvUISkin:SkinPetTypeFilterBar(filterBar)
  if not filterBar or not self:IsAvailable() then
    return
  end

  if filterBar.PetMatchElvUISkinned then
    return
  end

  filterBar.PetMatchElvUISkinned = true

  --------------------------------------------------
  -- Main filter bar
  --------------------------------------------------
  self:SkinBackdrop(filterBar.Frame)

  --------------------------------------------------
  -- Mode dropdown
  --------------------------------------------------
  self:SkinBlizzardDropdown(filterBar.ModeDropdown)

  --------------------------------------------------
  -- Pet family buttons
  --------------------------------------------------
  for _, button in pairs(filterBar.PetTypeButtons) do
    self:SkinBackdrop(button)

    button:SetBackdropColor(0.06, 0.06, 0.06, 0.85)
    button:SetBackdropBorderColor(0, 0, 0, 1)
  end
end

function ElvUISkin:SkinPetTypeFilterButton(button)
  if not button or not self:IsAvailable() then
    return
  end

  self:SkinBackdrop(button)

  button:SetBackdropColor(0.06, 0.06, 0.06, 0.85)
  button:SetBackdropBorderColor(0, 0, 0, 1)
end

-- status bar
function ElvUISkin:SkinFilterStatusBar(bar)
  if not bar or not self:IsAvailable() then
    return
  end

  if bar.PetMatchElvUISkinned then
    return
  end

  bar.PetMatchElvUISkinned = true

  self:SkinBackdrop(bar)

  if bar.Close then
    self:SkinCloseButton(bar.Close)
  end
end

addon.SkinManager:Register("elvui", ElvUISkin)
