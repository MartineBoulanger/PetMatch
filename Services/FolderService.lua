local addonName, addon = ...

local FolderService = {}
FolderService.ALL = "__ALL__"
FolderService.UNSORTED = "__UNSORTED__"

local function GetProfile()
  return addon.Profiles:GetCurrentProfile()
end

function FolderService:GetFolders()
  local profile = GetProfile()
  profile.folders = profile.folders or {}

  return profile.folders
end

function FolderService:Get(folderID)
  if not folderID then
    return nil
  end

  return self:GetFolders()[folderID]
end

function FolderService:Create(name)
  name = addon.Utils:Trim(name or "")

  if name == "" then
    return nil, "Enter a folder name"
  end

  local normalizedName = string.lower(name)

  for _, folder in pairs(self:GetFolders()) do
    if string.lower(folder.name or "") == normalizedName then
      return nil, "A folder with that name already exists"
    end
  end

  local folder = addon.Models.Folder:Create(name)

  local highestOrder = 0

  for _, existingFolder in pairs(self:GetFolders()) do
    highestOrder = math.max(
      highestOrder,
      existingFolder.order or 0
    )
  end

  folder.order = highestOrder + 1
  self:GetFolders()[folder.id] = folder

  addon.EventBus:Fire(
    addon.Events.FOLDER_CREATED,
    folder
  )

  return folder
end

function FolderService:Rename(folderID, name)
  local folder = self:Get(folderID)

  if not folder then
    return nil, "Folder not found"
  end

  name = addon.Utils:Trim(name or "")

  if name == "" then
    return nil, "Enter a folder name"
  end

  local normalizedName = string.lower(name)

  for otherID, otherFolder in pairs(self:GetFolders()) do
    if otherID ~= folderID
        and string.lower(otherFolder.name or "") == normalizedName then
      return nil, "A folder with that name already exists"
    end
  end

  folder.name = name
  folder.modified = time()

  addon.EventBus:Fire(
    addon.Events.FOLDER_UPDATED,
    folder
  )

  return folder
end

function FolderService:Delete(folderID)
  local folders = self:GetFolders()
  local folder = folders[folderID]

  if not folder then
    return false, "Folder not found"
  end

  -- Teams blijven bestaan en worden Unsorted.
  for _, team in pairs(
    addon.Services.Team:GetTeams()
  ) do
    if team.folderID == folderID then
      team.folderID = nil
      team.modified = time()

      addon.EventBus:Fire(
        addon.Events.TEAM_UPDATED,
        team
      )
    end
  end

  folders[folderID] = nil

  local profile = GetProfile()

  -- if profile.selectedFolderKey == folderID then
  --   profile.selectedFolderKey = self.ALL
  -- end
  if self:GetSelectedKey() == folderID then
    addon.Settings:SetUI(
      "selectedFolderKey",
      self.UNSORTED
    )
  end

  addon.EventBus:Fire(
    addon.Events.FOLDER_DELETED,
    folder
  )

  return true
end

function FolderService:Select(folderKey)
  folderKey = folderKey or self.ALL

  if folderKey ~= self.ALL
      and folderKey ~= self.UNSORTED
      and not self:Get(folderKey) then
    return false
  end

  addon.Settings:SetUI(
    "selectedFolderKey",
    folderKey
  )

  addon.EventBus:Fire(
    addon.Events.FOLDER_SELECTED,
    folderKey
  )

  return true
end

function FolderService:GetSelectedKey()
  local selectedKey =
      addon.Settings:GetUI(
        "selectedFolderKey"
      )

  if selectedKey == self.ALL
      or selectedKey == self.UNSORTED then
    return selectedKey
  end

  if selectedKey
      and self:Get(selectedKey) then
    return selectedKey
  end

  return self.ALL
end

function FolderService:GetSortedFolders()
  local result = {}

  for _, folder in pairs(self:GetFolders()) do
    table.insert(result, folder)
  end

  table.sort(result, function(left, right)
    local leftOrder = left.order or 0
    local rightOrder = right.order or 0

    if leftOrder == rightOrder then
      return string.lower(left.name or "")
          < string.lower(right.name or "")
    end

    return leftOrder < rightOrder
  end)

  return result
end

addon.Services.Folder = FolderService
