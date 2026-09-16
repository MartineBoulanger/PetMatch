local _, addon = ...

local L = addon.L
local OptionsPanel = {}

function OptionsPanel:Create(parent)
  if self.Frame then
    return self.Frame
  end

  local frame =
      CreateFrame(
        "Frame",
        nil,
        parent
      )

  frame:SetAllPoints(parent)

  self.Frame = frame

  self:CreateGeneralSection()

  return frame
end

function OptionsPanel:RefreshDuplicateMode()
  local mode =
      addon.Settings:Get(
        "duplicateTeamMode"
      )

  self.SkipButton:SetChecked(
    mode == "skip"
  )

  self.ReplaceButton:SetChecked(
    mode == "replace"
  )

  self.KeepButton:SetChecked(
    mode == "keep"
  )
end

function OptionsPanel:SetDuplicateMode(mode)
  addon.Settings:Set(
    "duplicateTeamMode",
    mode
  )

  self:RefreshDuplicateMode()
end

function OptionsPanel:CreateGeneralSection()
  local title =
      self.Frame:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontNormalLarge"
      )

  title:SetPoint(
    "TOPLEFT",
    self.Frame,
    "TOPLEFT",
    10,
    -18
  )

  title:SetText(L["GENERAL"])

  self:CreateDuplicateSection(title)
end

function OptionsPanel:CreateDuplicateSection(anchor)
  local title =
      self.Frame:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlight"
      )

  title:SetPoint(
    "TOPLEFT",
    anchor,
    "BOTTOMLEFT",
    0,
    -20
  )

  title:SetText(L["DUPLICATE_TEAMS"])

  self.SkipButton =
      CreateFrame(
        "CheckButton",
        nil,
        self.Frame,
        "UIRadioButtonTemplate"
      )

  self.SkipButton:SetPoint(
    "TOPLEFT",
    title,
    "BOTTOMLEFT",
    0,
    -8
  )

  self.SkipButton.text:SetText(
    L["SKIP_EXISTING"]
  )

  self.SkipButton:SetScript(
    "OnClick",
    function()
      self:SetDuplicateMode("skip")
    end
  )

  self.ReplaceButton =
      CreateFrame(
        "CheckButton",
        nil,
        self.Frame,
        "UIRadioButtonTemplate"
      )

  self.ReplaceButton:SetPoint(
    "TOPLEFT",
    self.SkipButton,
    "BOTTOMLEFT",
    0,
    -4
  )

  self.ReplaceButton.text:SetText(
    L["REPLACE_EXISTING"]
  )

  self.ReplaceButton:SetScript(
    "OnClick",
    function()
      self:SetDuplicateMode("replace")
    end
  )

  self.KeepButton =
      CreateFrame(
        "CheckButton",
        nil,
        self.Frame,
        "UIRadioButtonTemplate"
      )

  self.KeepButton:SetPoint(
    "TOPLEFT",
    self.ReplaceButton,
    "BOTTOMLEFT",
    0,
    -4
  )

  self.KeepButton.text:SetText(
    L["KEEP_BOTH"]
  )

  self.KeepButton:SetScript(
    "OnClick",
    function()
      self:SetDuplicateMode("keep")
    end
  )

  self:RefreshDuplicateMode()
end

addon.UI.Views.OptionsPanel = OptionsPanel
