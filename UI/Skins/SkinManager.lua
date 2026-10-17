local _, addon = ...

local SkinManager = {}

SkinManager.skins = {}

function SkinManager:Register(name, skin)
  if not name or not skin then
    return
  end

  self.skins[name] = skin
end

function SkinManager:GetSelected()
  return addon.Settings:GetGlobal("uiSkin") or "default"
end

function SkinManager:Get(name)
  return self.skins[name]
end

function SkinManager:IsAvailable(name)
  if name == "default" then
    return true
  end

  local skin = self:Get(name)

  if not skin then
    return false
  end

  if skin.IsAvailable then
    return skin:IsAvailable()
  end

  return true
end

function SkinManager:GetActive()
  local selected = self:GetSelected()

  if self:IsAvailable(selected) then
    return selected
  end

  return "default"
end

function SkinManager:ApplyBackdrop(frame)
  if not frame then
    return
  end

  local active = self:GetActive()

  if active == "default" then
    return
  end

  local skin = self:Get(active)

  if skin and skin.SkinBackdrop then
    skin:SkinBackdrop(frame)
  end
end

function SkinManager:ApplyMainFrame(frame)
  if not frame then
    return
  end

  local skin = self:Get(self:GetActive())

  if skin and skin.SkinMainFrame then
    skin:SkinMainFrame(frame)
  end
end

function SkinManager:PositionMainFrame(frame)
  if not frame then
    return
  end

  local skin = self:Get(self:GetActive())

  if skin and skin.PositionMainFrame then
    skin:PositionMainFrame(frame)
  end
end

function SkinManager:ApplyScrollBar(scrollBar)
  if not scrollBar then
    return
  end

  local skin = self:Get(self:GetActive())

  if skin and skin.SkinScrollBar then
    skin:SkinScrollBar(scrollBar)
  end
end

function SkinManager:ApplyButton(button)
  if not button then
    return
  end

  local skin = self:Get(self:GetActive())

  if skin and skin.SkinButton then
    skin:SkinButton(button)
  end
end

function SkinManager:ApplyCloseButton(button)
  if not button then
    return
  end

  local skin = self:Get(self:GetActive())

  if skin and skin.SkinCloseButton then
    skin:SkinCloseButton(button)
  end
end

function SkinManager:ApplyDropdown(dropdown)
  if not dropdown then
    return
  end

  local skin = self:Get(self:GetActive())

  if skin and skin.SkinDropdown then
    skin:SkinDropdown(dropdown)
  end
end

function SkinManager:ApplyBlizzardDropdown(dropdown)
  if not dropdown then
    return
  end

  local skin = self:Get(self:GetActive())

  if skin and skin.SkinBlizzardDropdown then
    skin:SkinBlizzardDropdown(dropdown)
  end
end

function SkinManager:ApplyCheckButton(button)
  if not button then
    return
  end

  local skin = self:Get(self:GetActive())

  if skin and skin.SkinCheckButton then
    skin:SkinCheckButton(button)
  end
end

function SkinManager:ApplyTab(tab)
  if not tab then
    return
  end

  local skin = self:Get(self:GetActive())

  if skin and skin.SkinTab then
    skin:SkinTab(tab)
  end
end

function SkinManager:ApplyEditBox(editBox, isSearch)
  if not editBox then
    return
  end

  local skin = self:Get(self:GetActive())

  if skin and skin.SkinEditBox then
    skin:SkinEditBox(editBox, isSearch)
  end
end

function SkinManager:ApplyMultiLineEditBox(editBox, scrollBar)
  if not editBox then
    return
  end

  local skin = self:Get(self:GetActive())

  if skin and skin.SkinMultiLineEditBox then
    skin:SkinMultiLineEditBox(editBox, scrollBar)
  end
end

function SkinManager:ApplyDialog(dialog)
  if not dialog then
    return
  end

  local skin = self:Get(self:GetActive())

  if skin and skin.SkinDialog then
    skin:SkinDialog(dialog)
  end
end

function SkinManager:ApplyAccordionHeader(header)
  if not header then
    return
  end

  local skin = self:Get(self:GetActive())

  if skin and skin.SkinAccordionHeader then
    skin:SkinAccordionHeader(header)
  end
end

function SkinManager:ApplyDialogTab(button)
  if not button then
    return
  end

  local skin = self:Get(self:GetActive())

  if skin and skin.SkinDialogTab then
    skin:SkinDialogTab(button)
  end
end

function SkinManager:ApplyTeamCard(card)
  if not card then
    return
  end

  local skin = self:Get(self:GetActive())

  if skin and skin.SkinTeamCard then
    skin:SkinTeamCard(card)
  end
end

function SkinManager:ApplyLevellingQueueRow(row)
  if not row then
    return
  end

  local skin = self:Get(self:GetActive())

  if skin and skin.SkinLevellingQueueRow then
    skin:SkinLevellingQueueRow(row)
  end
end

function SkinManager:ApplyLevellingXPBar(row)
  if not row then
    return
  end

  local skin = self:Get(self:GetActive())

  if skin and skin.SkinLevellingXPBar then
    skin:SkinLevellingXPBar(row)
  end
end

function SkinManager:ApplyTargetTeamCard(frame)
  if not frame then
    return
  end

  local skin = self:Get(self:GetActive())

  if skin and skin.SkinTargetTeamCard then
    skin:SkinTargetTeamCard(frame)
  end
end

function SkinManager:ApplyTargetTeamRow(row)
  if not row then
    return
  end

  local skin = self:Get(self:GetActive())

  if skin and skin.SkinTargetTeamRow then
    skin:SkinTargetTeamRow(row)
  end
end

function SkinManager:ApplyPetIcon(petSlot)
  if not petSlot then
    return
  end

  local skin = self:Get(self:GetActive())

  if skin and skin.SkinPetIcon then
    skin:SkinPetIcon(petSlot)
  end
end

function SkinManager:ApplyToolbarIcon(button)
  if not button then
    return
  end

  local skin = self:Get(self:GetActive())

  if skin and skin.SkinToolbarIcon then
    skin:SkinToolbarIcon(button)
  end
end

function SkinManager:ApplyFolderPreview(frame, texture, cropIcon)
  if not frame then
    return
  end

  local skin = self:Get(self:GetActive())

  if skin and skin.SkinFolderPreview then
    skin:SkinFolderPreview(frame, texture, cropIcon)
  end
end

function SkinManager:ApplyIconPickerButton(button)
  if not button then
    return
  end

  local skin = self:Get(self:GetActive())

  if skin and skin.SkinIconPickerButton then
    skin:SkinIconPickerButton(button)
  end
end

function SkinManager:ApplyTeamSetup(frame)
  if not frame then
    return
  end

  local skin = self:Get(self:GetActive())

  if skin and skin.SkinTeamSetup then
    skin:SkinTeamSetup(frame)
  end
end

function SkinManager:ApplyPetCardBackground(background, isDefault)
  if not background then
    return
  end

  local skin = self:Get(self:GetActive())

  if skin and skin.SkinPetCardBackground then
    skin:SkinPetCardBackground(background, isDefault)
  end
end

function SkinManager:ApplyPetCardAbilityIcon(cell)
  if not cell then
    return
  end

  local skin = self:Get(self:GetActive())

  if skin and skin.SkinPetCardAbilityIcon then
    skin:SkinPetCardAbilityIcon(cell)
  end
end

function SkinManager:ApplyPetCardAbilityCell(cell)
  if not cell then
    return
  end

  local skin = self:Get(self:GetActive())

  if skin and skin.SkinPetCardAbilityCell then
    skin:SkinPetCardAbilityCell(cell)
  end
end

function SkinManager:ApplyPetCard(frame)
  if not frame then
    return
  end

  local skin = self:Get(self:GetActive())

  if skin and skin.SkinPetCard then
    skin:SkinPetCard(frame)
  end
end

function SkinManager:ApplyPetTypeFilterBar(filterBar)
  if not filterBar then
    return
  end

  local skin = self:Get(self:GetActive())

  if skin and skin.SkinPetTypeFilterBar then
    skin:SkinPetTypeFilterBar(filterBar)
  end
end

function SkinManager:RefreshPetTypeFilterButton(button)
  if not button then
    return
  end

  local skin = self:Get(self:GetActive())

  if skin and skin.SkinPetTypeFilterButton then
    skin:SkinPetTypeFilterButton(button)
  end
end

function SkinManager:ApplyFilterStatusBar(bar)
  if not bar then
    return
  end

  local skin = self:Get(self:GetActive())

  if skin and skin.SkinFilterStatusBar then
    skin:SkinFilterStatusBar(bar)
  end
end

addon.SkinManager = SkinManager
