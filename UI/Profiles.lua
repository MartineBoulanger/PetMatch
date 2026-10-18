local _, addon = ...

local L = addon.L

local ProfileSettings = {}

function ProfileSettings:Initialize()
  if self.Initialized then
    return
  end

  local panel = CreateFrame("Frame")
  panel.name = L["PETMATCH"]

  local title = panel:CreateFontString(
    nil,
    "ARTWORK",
    "GameFontNormalLarge"
  )

  title:SetPoint("TOPLEFT", 16, -16)
  title:SetText(L["PETMATCH"])

  local subtitle = panel:CreateFontString(
    nil,
    "ARTWORK",
    "GameFontHighlight"
  )

  subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -12)
  subtitle:SetText(L["PROFILE_MANAGEMENT"])

  local currentProfile = panel:CreateFontString(
    nil,
    "ARTWORK",
    "GameFontHighlight"
  )

  currentProfile:SetPoint(
    "TOPLEFT",
    subtitle,
    "BOTTOMLEFT",
    0,
    -24
  )

  --------------------------------------------------
  -- Select profile
  --------------------------------------------------
  local profileLabel = panel:CreateFontString(
    nil,
    "ARTWORK",
    "GameFontNormal"
  )

  profileLabel:SetPoint(
    "TOPLEFT",
    currentProfile,
    "BOTTOMLEFT",
    0,
    -16
  )

  profileLabel:SetText(L["SELECT_PROFILE"])

  local dropdown = CreateFrame(
    "DropdownButton",
    nil,
    panel,
    "WowStyle1DropdownTemplate"
  )

  dropdown:SetPoint(
    "TOPLEFT",
    profileLabel,
    "BOTTOMLEFT",
    0,
    -8
  )

  dropdown:SetWidth(220)

  dropdown:SetupMenu(function(_, rootDescription)
    local profiles = addon.Profiles:GetProfiles()

    for _, profileName in ipairs(profiles) do
      rootDescription:CreateRadio(
        profileName,
        function()
          return profileName == addon.Profiles:GetCurrentProfileName()
        end,
        function()
          addon.Profiles:SetCurrentProfile(profileName)
        end
      )
    end
  end)

  local function RefreshProfileDisplay()
    local profileName = addon.Profiles:GetCurrentProfileName()

    currentProfile:SetText(
      L["CURRENT_PROFILE"] .. profileName
    )

    dropdown:SetDefaultText(profileName)
    dropdown:GenerateMenu()
  end

  dropdown:SetDefaultText(
    addon.Profiles:GetCurrentProfileName()
  )

  --------------------------------------------------
  -- Copy from profile
  --------------------------------------------------
  local copyLabel = panel:CreateFontString(
    nil,
    "ARTWORK",
    "GameFontNormal"
  )

  copyLabel:SetPoint(
    "LEFT",
    profileLabel,
    "RIGHT",
    190,
    0
  )

  copyLabel:SetText(L["COPY_FROM"])

  local copyDropdown = CreateFrame(
    "DropdownButton",
    nil,
    panel,
    "WowStyle1DropdownTemplate"
  )

  copyDropdown:SetPoint(
    "TOPLEFT",
    copyLabel,
    "BOTTOMLEFT",
    0,
    -8
  )

  copyDropdown:SetWidth(220)

  copyDropdown:SetDefaultText(L["SELECT_PROFILE_PLACEHOLDER"])

  copyDropdown:SetupMenu(function(_, rootDescription)
    local currentName = addon.Profiles:GetCurrentProfileName()

    for _, profileName in ipairs(addon.Profiles:GetProfiles()) do
      if profileName ~= currentName then
        rootDescription:CreateButton(
          profileName,
          function()
            local targetName = addon.Profiles:GetCurrentProfileName()

            StaticPopup_Show(
              "PETMATCH_COPY_PROFILE",
              profileName,
              targetName,
              {
                source = profileName,
                target = targetName,
              }
            )
          end
        )
      end
    end
  end)

  StaticPopupDialogs["PETMATCH_COPY_PROFILE"] = {
    text = L["COPY_PROFILE_CONFIRM1"] .. "\n\n"
        .. L["COPY_PROFILE_CONFIRM2"] .. "\n\n"
        .. L["COPY_PROFILE_CONFIRM3"],
    button1 = L["COPY"],
    button2 = CANCEL,
    OnAccept = function(_, data)
      if not data then
        return
      end
      if addon.Profiles:CopyFrom(data.source, data.target) then
        addon.Logger:Info(
          L["COPY_FROM_INFO1"]
          .. data.source
          .. L["COPY_FROM_INFO2"]
          .. data.target
        )
      else
        addon.Logger:Warn(L["COPY_FROM_ERROR"])
      end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
  }

  --------------------------------------------------
  -- Create profile
  --------------------------------------------------
  local createButton = CreateFrame(
    "Button",
    nil,
    panel,
    "UIPanelButtonTemplate"
  )

  createButton:SetSize(150, 25)

  createButton:SetPoint(
    "TOPLEFT",
    dropdown,
    "BOTTOMLEFT",
    0,
    -20
  )

  createButton:SetText(L["CREATE_PROFILE"])

  StaticPopupDialogs["PETMATCH_CREATE_PROFILE"] = {
    text = L["CREATE_PROFILE_PROMPT"],
    button1 = L["CREATE"],
    button2 = CANCEL,
    hasEditBox = true,
    maxLetters = 50,
    OnAccept = function(self)
      local name = self.EditBox:GetText()

      if addon.Profiles:Create(name) then
        addon.Logger:Info(L["CREATE_PROFILE_INFO"] .. name)
      else
        addon.Logger:Warn(L["CREATE_PROFILE_ERROR"])
      end
    end,
    EditBoxOnEnterPressed = function(self)
      self:GetParent():GetButton1():Click()
    end,
    EditBoxOnEscapePressed = function(self)
      self:GetParent():Hide()
    end,
    OnShow = function(self)
      self.EditBox:SetText("")
      self.EditBox:SetFocus()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
  }

  createButton:SetScript("OnClick", function()
    StaticPopup_Show("PETMATCH_CREATE_PROFILE")
  end)

  --------------------------------------------------
  -- Rename profile
  --------------------------------------------------
  local renameButton = CreateFrame(
    "Button",
    nil,
    panel,
    "UIPanelButtonTemplate"
  )

  renameButton:SetSize(150, 25)

  renameButton:ClearAllPoints()
  renameButton:SetPoint(
    "LEFT",
    createButton,
    "RIGHT",
    20,
    0
  )

  renameButton:SetText(L["RENAME_PROFILE"])

  StaticPopupDialogs["PETMATCH_RENAME_PROFILE"] = {
    text = L["RENAME_PROFILE_PROMPT"],
    button1 = L["RENAME"],
    button2 = CANCEL,
    hasEditBox = true,
    maxLetters = 50,

    OnAccept = function(self, oldName)
      local newName = self.EditBox:GetText()

      if addon.Profiles:Rename(oldName, newName) then
        addon.Logger:Info(L["RENAME_PROFILE_INFO"])
      else
        addon.Logger:Warn(L["RENAME_PROFILE_ERROR"])
      end
    end,

    OnShow = function(self, oldName)
      self.EditBox:SetText(oldName or "")
      self.EditBox:HighlightText()
      self.EditBox:SetFocus()
    end,

    EditBoxOnEnterPressed = function(self)
      self:GetParent():GetButton1():Click()
    end,

    EditBoxOnEscapePressed = function(self)
      self:GetParent():Hide()
    end,

    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
  }

  renameButton:SetScript("OnClick", function()
    local profileName = addon.Profiles:GetCurrentProfileName()

    if profileName == "Default" then
      addon.Logger:Warn(L["NO_RENAME_DEFAULT"])
      return
    end

    StaticPopup_Show(
      "PETMATCH_RENAME_PROFILE",
      profileName,
      nil,
      profileName
    )
  end)

  --------------------------------------------------
  -- Delete profile
  --------------------------------------------------
  local deleteButton = CreateFrame(
    "Button",
    nil,
    panel,
    "UIPanelButtonTemplate"
  )

  deleteButton:SetSize(150, 25)

  deleteButton:ClearAllPoints()
  deleteButton:SetPoint(
    "LEFT",
    renameButton,
    "RIGHT",
    20,
    0
  )

  deleteButton:SetText(L["DELETE_PROFILE"])

  StaticPopupDialogs["PETMATCH_DELETE_PROFILE"] = {
    text = L["DELETE_PROFILE_PROMPT"],
    button1 = DELETE,
    button2 = CANCEL,

    OnAccept = function(_, profileName)
      if addon.Profiles:Delete(profileName) then
        addon.Logger:Info(L["DELETE_PROFILE_INFO"] .. profileName)
      else
        addon.Logger:Warn(L["DELETE_PROFILE_ERROR"])
      end
    end,

    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
  }

  deleteButton:SetScript("OnClick", function()
    local profileName = addon.Profiles:GetCurrentProfileName()

    if profileName == "Default" then
      addon.Logger:Info(L["NO_DELETE_DEFAULT"])
      return
    end

    StaticPopup_Show(
      "PETMATCH_DELETE_PROFILE",
      profileName,
      nil,
      profileName
    )
  end)

  --------------------------------------------------
  -- Section divider
  --------------------------------------------------
  local divider = panel:CreateTexture(
    nil,
    "ARTWORK"
  )

  divider:SetTexture(
    "Interface\\Common\\UI-TooltipDivider-Transparent"
  )

  divider:SetHeight(16)

  divider:SetPoint(
    "TOPLEFT",
    createButton,
    "BOTTOMLEFT",
    0,
    -22
  )

  divider:SetPoint(
    "RIGHT",
    deleteButton,
    "RIGHT",
    0,
    0
  )

  --------------------------------------------------
  -- UI Skin (global setting)
  --------------------------------------------------
  local skinTitle = panel:CreateFontString(
    nil,
    "ARTWORK",
    "GameFontNormalLarge"
  )

  skinTitle:SetPoint(
    "TOPLEFT",
    divider,
    "BOTTOMLEFT",
    0,
    -12
  )

  skinTitle:SetText(L["UI_SKIN"])

  local skinDescription = panel:CreateFontString(
    nil,
    "ARTWORK",
    "GameFontHighlight"
  )

  skinDescription:SetPoint(
    "TOPLEFT",
    skinTitle,
    "BOTTOMLEFT",
    0,
    -10
  )

  skinDescription:SetText(L["UI_SKIN_DESCRIPTION"])

  local skinDropdown = CreateFrame(
    "DropdownButton",
    nil,
    panel,
    "WowStyle1DropdownTemplate"
  )

  skinDropdown:SetPoint(
    "TOPLEFT",
    skinDescription,
    "BOTTOMLEFT",
    0,
    -12
  )

  skinDropdown:SetWidth(220)

  local skins = {
    { id = "default",     label = L["UI_SKIN_DEFAULT"] },
    { id = "elvui",       label = "ElvUI" },
    { id = "ellesmereui", label = "EllesmereUI" }
  }

  local function RefreshSkinDropdown()
    local selected = addon.SkinManager:GetSelected()

    for _, skin in ipairs(skins) do
      if skin.id == selected then
        skinDropdown:SetDefaultText(skin.label)
        break
      end
    end

    skinDropdown:GenerateMenu()
  end

  skinDropdown:SetupMenu(function(_, rootDescription)
    local selected = addon.SkinManager:GetSelected()

    for _, skin in ipairs(skins) do
      local skinID = skin.id
      local skinLabel = skin.label

      local option = rootDescription:CreateRadio(
        skinLabel,
        function()
          return addon.SkinManager:GetSelected() == skinID
        end,
        function()
          addon.Settings:SetGlobal("uiSkin", skinID)
          RefreshSkinDropdown()
        end
      )

      if not addon.SkinManager:IsAvailable(skinID) then
        option:SetEnabled(false)
      end
    end
  end)

  RefreshSkinDropdown()

  --------------------------------------------------
  -- Reload UI
  --------------------------------------------------
  local reloadButton = CreateFrame(
    "Button",
    nil,
    panel,
    "UIPanelButtonTemplate"
  )

  reloadButton:SetSize(150, 25)

  reloadButton:SetPoint(
    "TOPLEFT",
    skinDropdown,
    "BOTTOMLEFT",
    0,
    -16
  )

  reloadButton:SetText(L["RELOAD_UI"])

  reloadButton:SetScript("OnClick", function()
    ReloadUI()
  end)

  --------------------------------------------------
  -- Apply UI skins
  --------------------------------------------------
  addon.SkinManager:ApplyBlizzardDropdown(dropdown)
  addon.SkinManager:ApplyBlizzardDropdown(copyDropdown)
  addon.SkinManager:ApplyBlizzardDropdown(skinDropdown)

  addon.SkinManager:ApplyButton(createButton)
  addon.SkinManager:ApplyButton(renameButton)
  addon.SkinManager:ApplyButton(deleteButton)
  addon.SkinManager:ApplyButton(reloadButton)

  --------------------------------------------------
  -- Register changes
  --------------------------------------------------
  local function RefreshProfileButtons()
    local isDefault = addon.Profiles:GetCurrentProfileName() == "Default"

    renameButton:SetEnabled(not isDefault)
    deleteButton:SetEnabled(not isDefault)
  end

  addon.EventBus:Register(
    addon.Events.PROFILE_CHANGED,
    function()
      RefreshProfileDisplay()
      RefreshProfileButtons()
    end
  )

  RefreshProfileButtons()

  --------------------------------------------------
  -- Makes sure the correct profile
  -- is shown on opening the options
  --------------------------------------------------
  panel:SetScript("OnShow", function()
    RefreshProfileDisplay()
    RefreshProfileButtons()
  end)

  local category = Settings.RegisterCanvasLayoutCategory(
    panel,
    "PetMatch"
  )

  Settings.RegisterAddOnCategory(category)

  self.Panel = panel
  self.Category = category
  self.Initialized = true
end

addon.UI = addon.UI or {}
addon.UI.Profiles = ProfileSettings
addon.ModuleManager:Register(
  "ProfileSettings",
  ProfileSettings
)
