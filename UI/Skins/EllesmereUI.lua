local _, addon = ...

local EllesmereUISkin = {}
local skinAPI

function EllesmereUISkin:IsAvailable()
  return C_AddOns.IsAddOnLoaded("EllesmereUI")
end

function EllesmereUISkin:GetAPI()
  return skinAPI
end

-- background of the frames
function EllesmereUISkin:SkinBackdrop(frame)
  local S = self:GetAPI()

  if not frame or not S then
    return
  end

  S.Panel(frame)
end

-- main frame
function EllesmereUISkin:SkinMainFrame(frame)
  local S = self:GetAPI()

  if not frame or not S then
    return
  end

  S.Shell(frame)
end

function EllesmereUISkin:PositionMainFrame(frame)
  if not frame or not self:IsAvailable() then
    return
  end

  frame:ClearAllPoints()

  frame:SetPoint(
    "TOPLEFT",
    PetJournal,
    "TOPRIGHT",
    0,
    0
  )
end

function EllesmereUISkin:SkinListPanel(background)
  if not background then
    return
  end

  if background.SetBackdrop then
    background:SetBackdrop(nil)
  end
end

-- scrollbars
function EllesmereUISkin:SkinScrollBar(scrollBar)
  local S = self:GetAPI()

  if not scrollBar or not S then
    return
  end

  local bar = scrollBar.ScrollBar or scrollBar

  if bar.PetMatchEllesmereUIScrollSkinned then
    return
  end

  --------------------------------------------------
  -- MinimalScrollBar: EllesmereUI API
  --------------------------------------------------
  if bar.Track and bar.Track.Thumb then
    S.ScrollBar(bar)

    bar.PetMatchEllesmereUIScrollSkinned = true
    return
  end

  --------------------------------------------------
  -- Classic ScrollBar colors
  --------------------------------------------------
  local normal = { 0, 0.8, 0.7, 1 }
  local hover = { 0.25, 0.95, 0.85, 1 }

  --------------------------------------------------
  -- Find Blizzard thumb
  --------------------------------------------------
  local thumb = bar.ThumbTexture

  if not thumb and bar.GetThumbTexture then
    thumb = bar:GetThumbTexture()
  end

  if not thumb then
    return
  end

  --------------------------------------------------
  -- Hide Blizzard track artwork
  --------------------------------------------------
  for i = 1, bar:GetNumRegions() do
    local region = select(i, bar:GetRegions())

    if region:IsObjectType("Texture") then
      region:SetAlpha(0)
    end
  end

  --------------------------------------------------
  -- Create custom EllesmereUI thumb
  --------------------------------------------------
  local customThumb = bar:CreateTexture(nil, "OVERLAY")

  customThumb:SetAllPoints(thumb)
  customThumb:SetColorTexture(unpack(normal))

  bar.PetMatchEllesmereUIThumb = customThumb

  --------------------------------------------------
  -- Hide Blizzard arrow artwork
  --------------------------------------------------
  local function HideArrowArtwork(button)
    if not button then
      return
    end

    local function HideTexture(texture)
      if texture then
        texture:SetAlpha(0)
      end
    end

    HideTexture(button:GetNormalTexture())
    HideTexture(button:GetPushedTexture())
    HideTexture(button:GetHighlightTexture())
    HideTexture(button:GetDisabledTexture())
    HideTexture(button.Texture)
  end

  HideArrowArtwork(bar.ScrollUpButton)
  HideArrowArtwork(bar.ScrollDownButton)

  --------------------------------------------------
  -- Thumb hover
  --------------------------------------------------
  bar:HookScript("OnEnter", function()
    customThumb:SetColorTexture(unpack(hover))
  end)

  bar:HookScript("OnLeave", function()
    customThumb:SetColorTexture(unpack(normal))
  end)

  --------------------------------------------------
  -- Mark as skinned
  --------------------------------------------------
  bar.PetMatchEllesmereUIScrollSkinned = true
end

-- buttons
function EllesmereUISkin:SkinButton(button)
  local S = self:GetAPI()

  if not button or not S then
    return
  end

  if button.PetMatchEllesmereUISkinned then
    return
  end

  S.Button(button)

  button.PetMatchEllesmereUISkinned = true
end

-- close buttons
function EllesmereUISkin:SkinCloseButton(button)
  local S = self:GetAPI()

  if not button or not S then
    return
  end

  if button.PetMatchEllesmereUICloseSkinned then
    return
  end

  S.CloseButton(button)

  button.PetMatchEllesmereUICloseSkinned = true
end

-- dropdowns
function EllesmereUISkin:SkinDropdown(dropdown)
  local S = self:GetAPI()

  if not dropdown or not S then
    return
  end

  if dropdown.PetMatchEllesmereUISkinned then
    return
  end

  S.Dropdown(dropdown)

  dropdown.PetMatchEllesmereUISkinned = true
end

function EllesmereUISkin:SkinBlizzardDropdown(dropdown)
  self:SkinDropdown(dropdown)
end

-- check and radio buttons
function EllesmereUISkin:SkinRadioButton(button)
  if not button then
    return
  end

  if button.PetMatchEllesmereUIRadioSkinned then
    return
  end

  --------------------------------------------------
  -- Hide Blizzard radio artwork
  --------------------------------------------------
  local function HideTexture(texture)
    if texture then
      texture:SetAlpha(0)
    end
  end

  HideTexture(button:GetNormalTexture())
  HideTexture(button:GetPushedTexture())
  HideTexture(button:GetHighlightTexture())
  HideTexture(button:GetCheckedTexture())
  HideTexture(button:GetDisabledCheckedTexture())

  --------------------------------------------------
  -- Circular background
  --------------------------------------------------
  local background = button:CreateTexture(nil, "BACKGROUND")
  background:SetSize(14, 14)
  background:SetPoint("CENTER", button, "CENTER")
  background:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask")
  background:SetVertexColor(0.28, 0.28, 0.28, 1)

  --------------------------------------------------
  -- Inner dark circle
  --------------------------------------------------
  local inner = button:CreateTexture(nil, "ARTWORK")
  inner:SetSize(10, 10)
  inner:SetPoint("CENTER", background, "CENTER")
  inner:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask")
  inner:SetVertexColor(0.05, 0.05, 0.05, 1)

  --------------------------------------------------
  -- Turquoise selection indicator
  --------------------------------------------------
  local indicator = button:CreateTexture(nil, "OVERLAY")
  indicator:SetSize(6, 6)
  indicator:SetPoint("CENTER", background, "CENTER")
  indicator:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask")
  indicator:SetVertexColor(0, 0.8, 0.7, 1)

  --------------------------------------------------
  -- Update state
  --------------------------------------------------
  local function UpdateState()
    indicator:SetShown(button:GetChecked() == true)
  end

  button:HookScript("OnClick", UpdateState)
  button:HookScript("OnShow", UpdateState)

  hooksecurefunc(button, "SetChecked", UpdateState)

  --------------------------------------------------
  -- Hover effect
  --------------------------------------------------
  button:HookScript("OnEnter", function()
    background:SetVertexColor(0.4, 0.4, 0.4, 1)
  end)

  button:HookScript("OnLeave", function()
    background:SetVertexColor(0.28, 0.28, 0.28, 1)
  end)

  --------------------------------------------------
  -- Mark as skinned
  --------------------------------------------------
  button.PetMatchEllesmereUIRadioSkinned = true

  UpdateState()
end

function EllesmereUISkin:SkinCheckbox(button)
  if not button then
    return
  end

  if button.PetMatchEllesmereUICheckboxSkinned then
    return
  end

  --------------------------------------------------
  -- Colors
  --------------------------------------------------
  local normal = { 0.28, 0.28, 0.28, 1 }
  local hover = { 0.4, 0.4, 0.4, 1 }
  local accent = { 0.25, 1, 0.85, 1 }

  --------------------------------------------------
  -- Hide Blizzard checkbox artwork
  --------------------------------------------------
  local function HideTexture(texture)
    if texture then
      texture:SetAlpha(0)
    end
  end

  HideTexture(button:GetNormalTexture())
  HideTexture(button:GetPushedTexture())
  HideTexture(button:GetHighlightTexture())
  HideTexture(button:GetCheckedTexture())
  HideTexture(button:GetDisabledCheckedTexture())

  --------------------------------------------------
  -- Outer border
  --------------------------------------------------
  local border = button:CreateTexture(nil, "BACKGROUND")
  border:SetSize(14, 14)
  border:SetPoint("CENTER", button, "CENTER")
  border:SetColorTexture(unpack(normal))

  --------------------------------------------------
  -- Inner background
  --------------------------------------------------
  local background = button:CreateTexture(nil, "ARTWORK")
  background:SetSize(12, 12)
  background:SetPoint("CENTER", border, "CENTER")
  background:SetColorTexture(0.05, 0.05, 0.05, 1)

  --------------------------------------------------
  -- Turquoise checkmark
  --------------------------------------------------
  -- local checkmark = button:CreateTexture(nil, "OVERLAY")
  -- checkmark:SetSize(20, 20)
  -- checkmark:SetPoint("CENTER", border, "CENTER", 2, 0)
  -- checkmark:SetTexture("Interface\\Buttons\\UI-CheckBox-Check-disabled")
  -- checkmark:SetVertexColor(unpack(accent))
  local checkmark = CreateFrame("Frame", nil, button)
  checkmark:SetSize(16, 16)
  checkmark:SetPoint("CENTER", border, "CENTER")
  checkmark:SetFrameLevel(button:GetFrameLevel() + 1)

  local function CreateStroke(width, angle, x, y)
    local stroke = checkmark:CreateTexture(nil, "OVERLAY")
    stroke:SetColorTexture(unpack(accent))
    stroke:SetSize(width, 3)
    stroke:SetPoint("CENTER", checkmark, "CENTER", x, y)
    stroke:SetRotation(math.rad(angle))

    return stroke
  end

  -- Short descending stroke
  CreateStroke(7, -45, -2, -1)

  -- Long ascending stroke
  CreateStroke(14, 45, 4, 1)

  --------------------------------------------------
  -- Update checked state
  --------------------------------------------------
  local function UpdateState()
    checkmark:SetShown(button:GetChecked() == true)
  end

  button:HookScript("OnClick", UpdateState)
  button:HookScript("OnShow", UpdateState)

  hooksecurefunc(button, "SetChecked", UpdateState)

  --------------------------------------------------
  -- Hover
  --------------------------------------------------
  button:HookScript("OnEnter", function()
    border:SetColorTexture(unpack(hover))
  end)

  button:HookScript("OnLeave", function()
    border:SetColorTexture(unpack(normal))
  end)

  --------------------------------------------------
  -- Mark as skinned
  --------------------------------------------------
  button.PetMatchEllesmereUICheckboxSkinned = true

  UpdateState()
end

function EllesmereUISkin:SkinCheckButton(button)
  if not button then
    return
  end

  if button.PetMatchEllesmereUICheckSkinned then
    return
  end

  if button.PetMatchIsRadioButton then
    self:SkinRadioButton(button)
  else
    self:SkinCheckbox(button)
  end

  button.PetMatchEllesmereUICheckSkinned = true
end

-- tabs
function EllesmereUISkin:SkinTab(tab)
  local S = self:GetAPI()

  if not tab or not S then
    return
  end

  if tab.PetMatchEllesmereUISkinned then
    return
  end

  tab.PetMatchEllesmereUISkinned = true

  --------------------------------------------------
  -- EllesmereUI-specific positioning
  --------------------------------------------------
  local point, relativeTo, relativePoint, x, y = tab:GetPoint(1)

  if point == "BOTTOMRIGHT" and relativePoint == "BOTTOMRIGHT" then
    tab:ClearAllPoints()

    tab:SetPoint(
      point,
      relativeTo,
      relativePoint,
      x,
      y - 3
    )
  end

  --------------------------------------------------
  -- Apply EllesmereUI styling
  --------------------------------------------------
  S.Tab(tab)

  --------------------------------------------------
  -- Called by Panels:SelectTab()
  --------------------------------------------------
  function tab:PetMatchUpdateSkin(selected)
    self.PetMatchSelected = selected

    if S.SetTabSelection then
      S.SetTabSelection(self, selected)
    end
  end

  --------------------------------------------------
  -- Initial selection
  --------------------------------------------------
  tab:PetMatchUpdateSkin(tab.PetMatchSelected or false)
end

-- edit boxes
function EllesmereUISkin:SkinEditBox(editBox, isSearch)
  local S = self:GetAPI()

  if not editBox or not S then
    return
  end

  if editBox.PetMatchEllesmereUISkinned then
    return
  end

  --------------------------------------------------
  -- Apply EllesmereUI styling
  --------------------------------------------------
  S.EditBox(editBox, {
    padInput = false,
  })

  --------------------------------------------------
  -- Text positioning (EditBox only)
  --------------------------------------------------
  if editBox:IsObjectType("EditBox") then
    local textOffset = isSearch and 10 or 8

    editBox:SetTextInsets(textOffset, 6, 0, 0)

    --------------------------------------------------
    -- Placeholder positioning
    --------------------------------------------------
    local instructions = editBox.Instructions

    if instructions then
      instructions:ClearAllPoints()
      instructions:SetPoint(
        "LEFT",
        editBox,
        "LEFT",
        8,
        0
      )

      instructions:SetTextColor(0.65, 0.65, 0.65, 1)
    end
  end

  editBox.PetMatchEllesmereUISkinned = true
end

function EllesmereUISkin:SkinMultiLineEditBox(editBox, scrollBar)
  local S = self:GetAPI()

  if not editBox or not S then
    return
  end

  self:SkinEditBox(editBox)

  if scrollBar then
    self:SkinScrollBar(scrollBar)
  end
end

-- dialogs
function EllesmereUISkin:SkinDialog(dialog)
  local S = self:GetAPI()

  if not dialog or not dialog.Frame or not S then
    return
  end

  local frame = dialog.Frame
  local contentFrame = dialog.ContentFrame

  if frame.PetMatchEllesmereUIDialogSkinned then
    return
  end

  --------------------------------------------------
  -- Apply EllesmereUI dialog styling
  --------------------------------------------------
  S.Shell(frame)

  --------------------------------------------------
  -- Hide original content artwork
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

  --------------------------------------------------
  -- Mark as skinned
  --------------------------------------------------
  frame.PetMatchEllesmereUIDialogSkinned = true
end

-- accordions
function EllesmereUISkin:SkinAccordionHeader(button)
  if not button or button.PetMatchEllesmereUIAccordionSkinned then
    return
  end

  button.PetMatchEllesmereUIAccordionSkinned = true

  local function UpdateBorder()
    if button.Expanded then
      button:SetBackdropBorderColor(0.25, 1, 0.85, 1)
    else
      button:SetBackdropBorderColor(0.35, 0.30, 0.20, 0.85)
    end
  end

  hooksecurefunc(button, "SetExpanded", UpdateBorder)

  UpdateBorder()
end

function EllesmereUISkin:SkinTeamCard(frame)
  if not frame then
    return
  end

  frame.PetMatchEllesmereUITeamCardSkinned = true
end

-- tabs in dialogs
function EllesmereUISkin:SkinDialogTab(button)
  if not button then
    return
  end

  if button.PetMatchEllesmereUIDialogTabSkinned then
    return
  end

  local S = self:GetAPI()

  if not S then
    return
  end

  --------------------------------------------------
  -- Hide original Blizzard button textures
  --------------------------------------------------
  local function HideTexture(texture)
    if texture then
      texture:SetAlpha(0)
    end
  end

  HideTexture(button.Left)
  HideTexture(button.Middle)
  HideTexture(button.Right)

  HideTexture(button:GetNormalTexture())
  HideTexture(button:GetPushedTexture())
  HideTexture(button:GetDisabledTexture())
  HideTexture(button:GetHighlightTexture())

  -- Hide existing decorative textures before
  -- applying EllesmereUI styling
  for _, region in ipairs({ button:GetRegions() }) do
    if region:IsObjectType("Texture") then
      region:SetAlpha(0)
    end
  end

  --------------------------------------------------
  -- Apply EllesmereUI styling
  --------------------------------------------------
  S.Tab(button)

  local normalFont = button:GetNormalFontObject()

  if normalFont then
    button:SetDisabledFontObject(normalFont)
  end

  --------------------------------------------------
  -- Update active/inactive appearance
  --------------------------------------------------
  local function UpdateAppearance()
    local selected = not button:IsEnabled()

    S.SetTabSelection(button, selected)
  end

  button:HookScript("OnEnable", UpdateAppearance)
  button:HookScript("OnDisable", UpdateAppearance)

  UpdateAppearance()

  button.PetMatchEllesmereUIDialogTabSkinned = true
end

-- target team card
function EllesmereUISkin:SkinTargetTeamCard(frame)
  if not frame then
    return
  end

  local S = self:GetAPI()

  if not S then
    return
  end

  S.Panel(frame)
end

-- target team rows from selection dialog
function EllesmereUISkin:SkinTargetTeamRow(row)
  if not row or not self:IsAvailable() then
    return
  end

  row.PetMatchEllesmereUITeamCardSkinned = true
end

--toolbar position
function EllesmereUISkin:SkinToolbarPosition(toolbar, toolbarType)
  if not toolbar then
    return
  end

  local offsetY = -4

  if toolbarType == "levellingQueue" then
    if toolbar.PetMatchEllesmereUIPositioned then
      return
    end

    toolbar.PetMatchEllesmereUIPositioned = true

    toolbar:ClearAllPoints()
    toolbar:SetPoint("TOPLEFT", toolbar:GetParent(), "TOPLEFT", -20, 2 + offsetY)
    toolbar:SetPoint("TOPRIGHT", toolbar:GetParent(), "TOPRIGHT", 0, 5 + offsetY)
  elseif toolbarType == "petJournal" then
    local offsetY = -2

    local buttons = {
      PetJournal and PetJournal.SummonRandomPetSpellFrame,
      PetJournal and PetJournal.HealPetSpellFrame,
    }

    for _, button in ipairs(buttons) do
      if button then
        local point, relativeTo, relativePoint, x, y =
            button:GetPoint(1)

        if point then
          button:ClearAllPoints()
          button:SetPoint(
            point,
            relativeTo,
            relativePoint,
            x,
            y + offsetY
          )
        end
      end
    end
  end
end

-- team setup
function EllesmereUISkin:SkinTeamSetup(frame)
  if not frame then
    return
  end

  local S = self:GetAPI()

  if not S then
    return
  end

  S.Panel(frame)

  -- Fully opaque background
  local regions = { frame:GetRegions() }

  for _, region in ipairs(regions) do
    if region:IsObjectType("Texture")
        and region:GetDrawLayer() == "BACKGROUND"
        and region:GetTexture() == "Interface\\Buttons\\WHITE8X8" then
      region:SetColorTexture(0.08, 0.08, 0.08, 1)
    end
  end

  -- Turquoise border
  local PP = EllesmereUI and EllesmereUI.PanelPP

  if PP and PP.SetBorderColor then
    PP.SetBorderColor(frame, 0.25, 1, 0.85, 1)
  end
end

-- pet card
function EllesmereUISkin:SkinPetCardAbilityCell(cell)
  if not cell or not cell.Frame or not cell.Border then
    return
  end

  if cell.PetMatchEllesmereUIAbilitySkinned then
    return
  end

  cell.PetMatchEllesmereUIAbilitySkinned = true

  -- Hide original marble background
  if cell.Background then
    cell.Background:Hide()
  end
end

function EllesmereUISkin:SkinPetCard(frame)
  if not frame then
    return
  end

  if frame.PetMatchEllesmereUIPetCardSkinned then
    return
  end

  local S = self:GetAPI()

  if not S then
    return
  end

  -- Apply EllesmereUI window styling
  S.Shell(frame)

  frame.PetMatchEllesmereUIPetCardSkinned = true
end

-- pet type filters
function EllesmereUISkin:SkinPetTypeFilterBar(filterBar)
  if not filterBar or not filterBar.Frame then
    return
  end

  local frame = filterBar.Frame

  if frame.PetMatchEllesmereUIFilterBarSkinned then
    return
  end

  frame.PetMatchEllesmereUIFilterBarSkinned = true

  if frame.SetBackdrop then
    frame:SetBackdrop(nil)
  end
end

-- status bar
function EllesmereUISkin:SkinFilterStatusBar(statusBar)
  if not statusBar then
    return
  end

  local frame = statusBar.Frame or statusBar

  if frame.PetMatchEllesmereUIStatusBarSkinned then
    return
  end

  local S = self:GetAPI()

  if not S then
    return
  end

  S.Panel(frame)

  frame.PetMatchEllesmereUIStatusBarSkinned = true

  if frame.Close then
    self:SkinCloseButton(frame.Close)
  end
end

addon.SkinManager:Register("ellesmereui", EllesmereUISkin)

if EllesmereUI and EllesmereUI.RegisterSkin then
  EllesmereUI.RegisterSkin("PetMatch", function(S)
    skinAPI = S
  end)
end
