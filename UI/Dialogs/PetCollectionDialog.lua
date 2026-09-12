local _, addon = ...

local PetCollectionDialog = {}

local DIALOG_WIDTH = 560

local STAT_HEIGHT = 54

local TAB_HEIGHT = 26
local TAB_SPACING = 4

local CONTENT_MARGIN = {
  left = -12,
  right = 12,
  top = 4,
  bottom = 8,
}

local CONTENT_PADDING = 12

local dialogInstance

local TAB_ORDER = {
  {
    key = "general",
    text = "General",
  },
  {
    key = "families",
    text = "Families",
  },
  {
    key = "sources",
    text = "Sources",
  },
  {
    key = "expansions",
    text = "Expansions",
  },
  {
    key = "breeds",
    text = "Breeds",
  },
}

local ROW_SPACING = 3

--------------------------------------------------
-- Helpers
--------------------------------------------------
local function CreateTabButton(parent, text)
  local button =
      CreateFrame(
        "Button",
        nil,
        parent,
        "UIPanelButtonTemplate"
      )

  button:SetHeight(TAB_HEIGHT)
  button:SetText(text)

  return button
end

local function GetQualityColor(quality)
  local color = addon.Constants.PET_RARITY_COLORS[quality]

  if color then
    return {
      r = color.r,
      g = color.g,
      b = color.b,
      a = 1,
    }
  end

  return {
    r = 1,
    g = 1,
    b = 1,
    a = 1,
  }
end

local function CreateStatRow(parent, labelText)
  local row =
      CreateFrame(
        "Frame",
        nil,
        parent
      )

  row:SetHeight(24)

  row.Label = addon.UI.Base.Label:Create(
    row,
    {
      text = labelText,
      justify = "LEFT",
      color = addon.UI.Theme.Colors.Text,
    }
  )

  row.Label:SetPoint(
    "LEFT",
    row,
    "LEFT",
    0,
    0
  )

  row.Value = addon.UI.Base.Label:Create(
    row,
    {
      text = "",
      justify = "RIGHT",
      color = addon.UI.Theme.Colors.Text,
    }
  )

  row.Value:SetPoint(
    "RIGHT",
    row,
    "RIGHT",
    0,
    0
  )

  return row
end

--------------------------------------------------
-- Create
--------------------------------------------------
function PetCollectionDialog:Create()
  if dialogInstance then
    return dialogInstance
  end

  local dialog =
      addon.UI.Base.Dialog:Create({
        name = "PetMatchPetCollectionDialog",
        title = "Pet Collection",
        width = DIALOG_WIDTH,
        contentMargin = CONTENT_MARGIN,
        padding = CONTENT_PADDING,
        bottomSpacing = 0,
        onClose =
            function()
              self.Stats = nil
            end,
      })

  local content = dialog:GetContentFrame()

  content:SetHeight(250)

  ------------------------------------------------
  -- Statistics header
  ------------------------------------------------
  self.StatBlocks = {}

  local availableWidth = DIALOG_WIDTH - 54

  ------------------------------------------------
  -- Tabs
  ------------------------------------------------
  self.Tabs = {}

  self.TabBar =
      CreateFrame(
        "Frame",
        nil,
        content
      )

  self.TabBar:SetPoint(
    "TOPLEFT",
    content,
    "TOPLEFT",
    0,
    0
  )

  self.TabBar:SetPoint(
    "TOPRIGHT",
    content,
    "TOPRIGHT",
    0,
    0
  )

  self.TabBar:SetHeight(TAB_HEIGHT)

  local tabCount = #TAB_ORDER
  local totalSpacing = (tabCount - 1) * TAB_SPACING
  local tabWidth = (availableWidth - totalSpacing) / tabCount

  for index, tabInfo in ipairs(TAB_ORDER) do
    local button =
        CreateTabButton(
          self.TabBar,
          tabInfo.text
        )

    button:SetWidth(tabWidth)

    if index == 1 then
      button:SetPoint(
        "LEFT",
        self.TabBar,
        "LEFT",
        0,
        0
      )
    else
      button:SetPoint(
        "LEFT",
        self.Tabs[TAB_ORDER[index - 1].key],
        "RIGHT",
        TAB_SPACING,
        0
      )
    end

    button.TabKey = tabInfo.key

    button:SetScript(
      "OnClick",
      function(control)
        self:SetActiveTab(control.TabKey)
      end
    )

    self.Tabs[tabInfo.key] = button
  end

  local breedService = addon.Services and addon.Services.Breed

  local breedEnabled = breedService
      and breedService:IsAvailable()
      and addon.Settings:Get("petListBreedPosition") ~= "hidden"

  if not breedEnabled and self.Tabs.breeds then
    self.Tabs.breeds:Hide()
  end

  ------------------------------------------------
  -- Tab content
  ------------------------------------------------
  self.TabContent =
      CreateFrame(
        "Frame",
        nil,
        content
      )

  self.TabContent:SetPoint(
    "TOPLEFT",
    self.TabBar,
    "BOTTOMLEFT",
    0,
    -10
  )

  self.TabContent:SetPoint(
    "BOTTOMRIGHT",
    content,
    "BOTTOMRIGHT",
    0,
    0
  )

  ------------------------------------------------
  -- General tab
  ------------------------------------------------
  self.GeneralContent =
      CreateFrame(
        "Frame",
        nil,
        self.TabContent
      )

  self.GeneralContent:SetAllPoints(self.TabContent)

  self.GeneralRows = {}

  local rowDefinitions = {
    {
      key = "totalOwned",
      text = "Total Owned Pets",
    },
    {
      key = "uniqueOwned",
      text = "Unique Owned Pets",
    },
    {
      key = "missing",
      text = "Missing Pets",
    },
  }

  local previousRow

  for _, definition in ipairs(rowDefinitions) do
    local row =
        CreateStatRow(
          self.GeneralContent,
          definition.text
        )

    row:SetPoint(
      "LEFT",
      self.GeneralContent,
      "LEFT",
      0,
      0
    )

    row:SetPoint(
      "RIGHT",
      self.GeneralContent,
      "RIGHT",
      0,
      0
    )

    if previousRow then
      row:SetPoint(
        "TOP",
        previousRow,
        "BOTTOM",
        0,
        0
      )
    else
      row:SetPoint(
        "TOP",
        self.GeneralContent,
        "TOP",
        0,
        0
      )
    end

    self.GeneralRows[definition.key] = row

    previousRow = row
  end

  self.GeneralSeparator =
      self.GeneralContent:
      CreateTexture(
        nil,
        "ARTWORK"
      )

  self.GeneralSeparator:SetHeight(1)

  self.GeneralSeparator:SetPoint(
    "TOPLEFT",
    previousRow,
    "BOTTOMLEFT",
    0,
    -5
  )

  self.GeneralSeparator:SetPoint(
    "TOPRIGHT",
    previousRow,
    "BOTTOMRIGHT",
    0,
    -5
  )

  self.GeneralSeparator:SetColorTexture(
    0.18,
    0.18,
    0.18,
    0.63
  )

  local secondaryRows = {
    {
      key = "duplicates",
      text = "Duplicated Pets",
    },
    {
      key = "rare",
      text = "Rare Quality Pets",
    },
    {
      key = "maxLevel",
      text = "Max Level Pets",
    },
  }

  previousRow = nil

  for index, definition in ipairs(secondaryRows) do
    local row = CreateStatRow(
      self.GeneralContent,
      definition.text
    )

    row:SetPoint(
      "LEFT",
      self.GeneralContent,
      "LEFT",
      0,
      0
    )

    row:SetPoint(
      "RIGHT",
      self.GeneralContent,
      "RIGHT",
      0,
      0
    )

    if index == 1 then
      row:SetPoint(
        "TOP",
        self.GeneralSeparator,
        "BOTTOM",
        0,
        -5
      )
    else
      row:SetPoint(
        "TOP",
        previousRow,
        "BOTTOM",
        0,
        0
      )
    end

    self.GeneralRows[definition.key] = row

    previousRow = row
  end

  ------------------------------------------------
  -- Collection progress title
  ------------------------------------------------
  self.CollectionProgressTitle =
      addon.UI.Base.Label:Create(
        self.GeneralContent,
        {
          text = "Collection Progress",
          justify = "LEFT",
          color = addon.UI.Theme.Colors.Text,
        }
      )

  self.CollectionProgressTitle:SetPoint(
    "BOTTOMLEFT",
    previousRow,
    "BOTTOMLEFT",
    0,
    -TAB_HEIGHT - 4
  )

  ------------------------------------------------
  -- Collection progress bar
  ------------------------------------------------
  self.CollectionProgress =
      addon.UI.Components.CollectionProgressBar:Create(
        self.GeneralContent,
        {
          height = 24,
        }
      )

  local collectionProgressFrame = self.CollectionProgress:GetFrame()

  collectionProgressFrame:SetPoint(
    "TOPLEFT",
    self.CollectionProgressTitle,
    "BOTTOMLEFT",
    0,
    -4
  )

  collectionProgressFrame:SetPoint(
    "TOPRIGHT",
    self.GeneralContent,
    "TOPRIGHT",
    0,
    -4
  )

  ------------------------------------------------
  -- Families tab
  ------------------------------------------------
  self.FamiliesContent =
      CreateFrame(
        "Frame",
        nil,
        self.TabContent
      )

  self.FamiliesContent:SetAllPoints(
    self.TabContent
  )

  self.FamilyRows = {}

  local previousFamilyRow

  for familyID = 1, 10 do
    local row =
        addon.UI.Components.CollectionStatRow:Create(self.FamiliesContent)
    local rowFrame = row:GetFrame()

    rowFrame:SetPoint(
      "LEFT",
      self.FamiliesContent,
      "LEFT",
      0,
      0
    )

    rowFrame:SetPoint(
      "RIGHT",
      self.FamiliesContent,
      "RIGHT",
      0,
      0
    )

    if previousFamilyRow then
      rowFrame:SetPoint(
        "TOP",
        previousFamilyRow,
        "BOTTOM",
        0,
        ROW_SPACING
      )
    else
      rowFrame:SetPoint(
        "TOP",
        self.FamiliesContent,
        "TOP",
        0,
        0
      )
    end

    self.FamilyRows[familyID] = row

    previousFamilyRow = rowFrame
  end

  ------------------------------------------------
  -- Sources tab
  ------------------------------------------------
  self.SourcesContent =
      CreateFrame(
        "Frame",
        nil,
        self.TabContent
      )

  self.SourcesContent:SetAllPoints(
    self.TabContent
  )

  self.SourceRows = {}

  local numSources = C_PetJournal.GetNumPetSources()

  local previousSourceRow

  for sourceID = 1, numSources do
    local row =
        addon.UI.Components.CollectionStatRow:Create(
          self.SourcesContent,
          {
            height = 21,
            iconSize = 15,
            barHeight = 17,
          }
        )

    local rowFrame = row:GetFrame()

    rowFrame:SetPoint(
      "LEFT",
      self.SourcesContent,
      "LEFT",
      0,
      0
    )

    rowFrame:SetPoint(
      "RIGHT",
      self.SourcesContent,
      "RIGHT",
      0,
      0
    )

    if previousSourceRow then
      rowFrame:SetPoint(
        "TOP",
        previousSourceRow,
        "BOTTOM",
        0,
        ROW_SPACING
      )
    else
      rowFrame:SetPoint(
        "TOP",
        self.SourcesContent,
        "TOP",
        0,
        0
      )
    end

    self.SourceRows[sourceID] = row

    previousSourceRow = rowFrame
  end

  ------------------------------------------------
  -- Expansions tab
  ------------------------------------------------
  self.ExpansionsContent =
      CreateFrame(
        "Frame",
        nil,
        self.TabContent
      )

  self.ExpansionsContent:SetAllPoints(
    self.TabContent
  )

  self.ExpansionRows = {}

  local previousExpansionRow

  for expansionID = 0, 11 do
    local row =
        addon.UI.Components.CollectionStatRow:Create(
          self.ExpansionsContent,
          {
            height = 21,
            iconSize = 17,
            barHeight = 17,
          }
        )

    local rowFrame = row:GetFrame()

    rowFrame:SetPoint(
      "LEFT",
      self.ExpansionsContent,
      "LEFT",
      0,
      0
    )

    rowFrame:SetPoint(
      "RIGHT",
      self.ExpansionsContent,
      "RIGHT",
      0,
      0
    )

    if previousExpansionRow then
      rowFrame:SetPoint(
        "TOP",
        previousExpansionRow,
        "BOTTOM",
        0,
        ROW_SPACING
      )
    else
      rowFrame:SetPoint(
        "TOP",
        self.ExpansionsContent,
        "TOP",
        0,
        0
      )
    end

    self.ExpansionRows[expansionID] = row

    previousExpansionRow = rowFrame
  end

  ------------------------------------------------
  -- Breeds tab
  ------------------------------------------------
  self.BreedsContent =
      CreateFrame(
        "Frame",
        nil,
        self.TabContent
      )

  self.BreedsContent:SetAllPoints(
    self.TabContent
  )

  self.BreedRows = {}

  local previousBreedRow

  for breedID = 3, 12 do
    local row = addon.UI.Components.CollectionStatRow:Create(
      self.BreedsContent,
      {
        height = 24,
        iconSize = 28,
        barHeight = 18,
      }
    )

    local rowFrame = row:GetFrame()

    rowFrame:SetPoint(
      "LEFT",
      self.BreedsContent,
      "LEFT",
      0,
      0
    )

    rowFrame:SetPoint(
      "RIGHT",
      self.BreedsContent,
      "RIGHT",
      0,
      0
    )

    if previousBreedRow then
      rowFrame:SetPoint(
        "TOP",
        previousBreedRow,
        "BOTTOM",
        0,
        ROW_SPACING
      )
    else
      rowFrame:SetPoint(
        "TOP",
        self.BreedsContent,
        "TOP",
        0,
        0
      )
    end

    self.BreedRows[breedID] = row

    previousBreedRow = rowFrame
  end

  ------------------------------------------------
  -- Footer
  ------------------------------------------------
  self.CloseButton =
      dialog:AddCancelButton({
        text = "Close",
        width = 80,
      })

  ------------------------------------------------
  -- State
  ------------------------------------------------
  self.Dialog = dialog
  self.Frame = dialog:GetFrame()
  self.Stats = nil

  ------------------------------------------------
  -- Layout
  ------------------------------------------------
  dialog:RefreshLayout()

  dialogInstance = dialog

  return dialog
end

--------------------------------------------------
-- Active tab
--------------------------------------------------
function PetCollectionDialog:SetActiveTab(tabKey)
  if not self.Tabs or not self.Tabs[tabKey] then
    return
  end

  self.ActiveTab = tabKey

  for key, button
  in pairs(self.Tabs) do
    if key == tabKey then
      button:Disable()
    else
      button:Enable()
    end
  end

  if self.GeneralContent then
    if tabKey == "general" then
      self.GeneralContent:Show()
    else
      self.GeneralContent:Hide()
    end
  end

  if self.FamiliesContent then
    if tabKey == "families" then
      self.FamiliesContent:Show()
    else
      self.FamiliesContent:Hide()
    end
  end

  if self.SourcesContent then
    if tabKey == "sources" then
      self.SourcesContent:Show()
    else
      self.SourcesContent:Hide()
    end
  end

  if self.ExpansionsContent then
    if tabKey == "expansions" then
      self.ExpansionsContent:Show()
    else
      self.ExpansionsContent:Hide()
    end
  end

  if self.BreedsContent then
    if tabKey == "breeds" then
      self.BreedsContent:Show()
    else
      self.BreedsContent:Hide()
    end
  end
end

--------------------------------------------------
-- Refresh
--------------------------------------------------
function PetCollectionDialog:Refresh()
  if not self.Stats or not self.StatBlocks then
    return
  end

  local stats = self.Stats

  self.GeneralRows.totalOwned.Value:SetText(
    tostring(
      stats.totalOwned
      or 0
    )
  )

  self.GeneralRows.uniqueOwned.Value:SetText(
    string.format(
      "%d / %d",
      stats.uniqueOwned
      or 0,
      stats.totalCollectible
      or 0
    )
  )

  self.GeneralRows.missing.Value:SetText(
    tostring(
      stats.missing
      or 0
    )
  )

  self.GeneralRows.duplicates.Value:SetText(
    tostring(
      stats.duplicates
      or 0
    )
  )

  self.GeneralRows.rare.Value:SetText(
    tostring(
      stats.rare
      or 0
    )
  )

  self.GeneralRows.maxLevel.Value:SetText(
    tostring(
      stats.maxLevel
      or 0
    )
  )

  ------------------------------------------------
  -- General collection progress
  ------------------------------------------------
  if self.CollectionProgress then
    local totalCollectible = tonumber(stats.totalCollectible) or 0
    local uniqueOwned = tonumber(stats.uniqueOwned) or 0
    local segments = {}

    for quality = 1, 4 do
      local count = tonumber(stats.qualities
        and stats.qualities[quality]) or 0

      local totalPercentage = 0
      local ownedPercentage = 0

      if totalCollectible > 0 then
        totalPercentage = (count / totalCollectible) * 100
      end

      if uniqueOwned > 0 then
        ownedPercentage = (count / uniqueOwned) * 100
      end

      segments[#segments + 1] = {
        value = count,
        color = GetQualityColor(quality),
        tooltipTitle = addon.Constants.PET_RARITY_NAMES[quality],
        tooltipLines = {
          tostring(count) .. " unique pets",
          string.format(
            "%.1f%% of all collectible pets",
            totalPercentage
          ),
          string.format(
            "%.1f%% of your collection",
            ownedPercentage
          ),
        },
      }
    end

    self.CollectionProgress:SetData({
      maximum = totalCollectible,
      text = string.format(
        "%d / %d  •  %.1f%%",
        uniqueOwned,
        totalCollectible,
        tonumber(
          stats.percentage
        ) or 0
      ),
      segments = segments,
    })
  end

  ------------------------------------------------
  -- Pet Families
  ------------------------------------------------
  local familyStats = addon.Services.PetCollectionStats:GetFamilyStats()

  for familyID = 1, 10 do
    local row = self.FamilyRows[familyID]
    local family = familyStats[familyID]

    if row and family then
      row:SetData({
        icon = addon.Constants.PET_FAMILY_ICONS[familyID],
        owned = family.owned or 0,
        maximum = family.maximum or 0,
        percentage = family.percentage or 0,
        color = addon.Constants.PET_FAMILY_COLORS[familyID],
        tooltipTitle = family.name,
        tooltipLines = {
          string.format(
            "%d / %d collected",
            family.owned or 0,
            family.maximum or 0
          ),
          string.format(
            "%.1f%% complete",
            family.percentage or 0
          ),
          string.format(
            "%d missing",
            family.missing or 0
          ),
        },
      })
    end
  end

  ------------------------------------------------
  -- Pet Sources
  ------------------------------------------------
  if self.SourceRows then
    local sources =
        addon.Services.PetCollectionStats:GetSourceStats()

    for sourceID, source in pairs(sources) do
      local row = self.SourceRows[sourceID]

      if row then
        row:SetData({
          icon = addon.Constants.PET_SOURCE_ICONS[sourceID],
          owned = source.owned or 0,
          maximum = source.maximum or 0,
          percentage = source.percentage or 0,
          color = addon.Constants.PET_SOURCE_COLORS[sourceID],
          tooltipTitle = source.name,
          tooltipLines = {
            string.format(
              "%d / %d collected",
              source.owned or 0,
              source.maximum or 0
            ),
            string.format(
              "%.1f%% complete",
              source.percentage or 0
            ),
            string.format(
              "%d missing",
              source.missing or 0
            ),
          },
        })
      end
    end
  end

  ------------------------------------------------
  -- Expansions
  ------------------------------------------------
  if self.ExpansionRows then
    local expansions = addon.Services.PetCollectionStats:GetExpansionStats()

    for expansionID = 0, 11 do
      local expansion = expansions[expansionID]
      local row = self.ExpansionRows[expansionID]

      if row and expansion then
        row:SetData({
          icon = addon.Constants.PET_EXPANSION_ICONS[expansionID],
          owned = expansion.owned or 0,
          maximum = expansion.maximum or 0,
          percentage = expansion.percentage or 0,
          color = addon.Constants.PET_EXPANSION_COLORS[expansionID],
          tooltipTitle = expansion.name,
          tooltipLines = {
            string.format(
              "%d / %d collected",
              expansion.owned or 0,
              expansion.maximum or 0
            ),
            string.format(
              "%.1f%% complete",
              expansion.percentage or 0
            ),
            string.format(
              "%d missing",
              expansion.missing or 0
            ),
          },
        })

        row:GetFrame():Show()
      elseif row then
        row:GetFrame():Hide()
      end
    end
  end

  ------------------------------------------------
  -- Breeds
  ------------------------------------------------
  if self.BreedRows then
    local breeds = addon.Services.PetCollectionStats:GetBreedStats()

    for breedID = 3, 12 do
      local breed = breeds[breedID]
      local row = self.BreedRows[breedID]

      if row and breed then
        row:SetData({
          label = breed.name,
          owned = breed.owned or 0,
          maximum = breed.maximum or 0,
          percentage = breed.percentage or 0,
          color = addon.Constants.PET_BREED_COLORS[breedID],
          tooltipTitle = breed.name,
          tooltipLines = {
            string.format(
              "%d / %d collected",
              breed.owned or 0,
              breed.maximum or 0
            ),
            string.format(
              "%.1f%% complete",
              breed.percentage or 0
            ),
            string.format(
              "%d missing",
              breed.missing or 0
            ),
          },
        })

        row:GetFrame():Show()
      elseif row then
        row:GetFrame():Hide()
      end
    end
  end
end

--------------------------------------------------
-- Show
--------------------------------------------------
function PetCollectionDialog:Show()
  local service = addon.Services
      and addon.Services.PetCollectionStats

  if not service then
    return
  end

  local stats = service:GetOverview()

  if not stats then
    return
  end

  local dialog = self:Create()

  self.Stats = stats

  self:Refresh()

  self:SetActiveTab(self.ActiveTab or "general")

  dialog:Show()
  dialog:RefreshLayout()

  self.Frame:Raise()
end

--------------------------------------------------
-- Hide
--------------------------------------------------
function PetCollectionDialog:Hide()
  if not dialogInstance then
    return
  end

  dialogInstance:Hide()

  self.Stats = nil
end

--------------------------------------------------
-- Register
--------------------------------------------------
addon.UI.Dialogs.PetCollectionDialog = PetCollectionDialog
