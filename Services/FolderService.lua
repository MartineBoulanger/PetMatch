local _, addon = ...

local FolderService = {}

FolderService.UNSORTED = "__UNSORTED__"
FolderService.FAVORITES = "__FAVORITES__"

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

function FolderService:Delete(folderID, deleteTeams)
  local folders = self:GetFolders()
  local folder = folders[folderID]

  if not folder then
    return false, "Folder not found"
  end

  for id, team in pairs(
    addon.Services.Team:GetTeams()
  ) do
    if team.folderID == folderID then
      if deleteTeams then
        addon.Services.Team:Delete(id)
      else
        team.folderID = nil
        team.modified = time()

        addon.EventBus:Fire(
          addon.Events.TEAM_UPDATED,
          team
        )
      end
    end
  end

  folders[folderID] = nil

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

  local isVirtualFolder =
      folderKey == self.ALL
      or folderKey == self.UNSORTED
      or folderKey == self.FAVORITES

  if not isVirtualFolder
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

function FolderService:Move(folderID, newIndex)
  local folder = self:Get(folderID)

  if not folder then
    return false, "Folder not found"
  end

  local folders = self:GetSortedFolders()

  local currentIndex

  for index, currentFolder in ipairs(
    folders
  ) do
    if currentFolder.id == folderID then
      currentIndex = index
      break
    end
  end

  if not currentIndex then
    return false, "Folder not found"
  end

  newIndex = tonumber(newIndex)

  if not newIndex then
    return false, "Invalid folder position"
  end

  newIndex = math.floor(newIndex)

  newIndex =
      math.max(
        1,
        math.min(
          #folders,
          newIndex
        )
      )

  if currentIndex == newIndex then
    return true
  end

  --------------------------------------------------
  -- Reorder
  --------------------------------------------------
  local movedFolder =
      table.remove(
        folders,
        currentIndex
      )

  table.insert(
    folders,
    newIndex,
    movedFolder
  )

  --------------------------------------------------
  -- Normalize persistent order
  --------------------------------------------------
  for index, currentFolder in ipairs(
    folders
  ) do
    currentFolder.order = index
  end

  movedFolder.modified = time()

  addon.EventBus:Fire(
    addon.Events.FOLDER_UPDATED,
    movedFolder
  )

  return true
end

function FolderService:GetIndex(folderID)
  if not folderID then
    return nil
  end

  local folders = self:GetSortedFolders()

  for index, folder in ipairs(folders) do
    if folder.id == folderID then
      return index
    end
  end

  return nil
end

function FolderService:MoveUp(folderID)
  local index = self:GetIndex(folderID)

  if not index or index <= 1 then
    return false
  end

  return self:Move(folderID, index - 1)
end

function FolderService:MoveDown(folderID)
  local folders = self:GetSortedFolders()
  local index = self:GetIndex(folderID)

  if not index or index >= #folders then
    return false
  end

  return self:Move(folderID, index + 1)
end

function FolderService:GetSelectedKey()
  local selectedKey =
      addon.Settings:GetUI(
        "selectedFolderKey"
      )

  if selectedKey == self.ALL
      or selectedKey == self.UNSORTED
      or selectedKey == self.FAVORITES then
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

function FolderService:GetSelectedStorageFolderID()
  local selectedKey = self:GetSelectedKey()

  if selectedKey == self.ALL
      or selectedKey == self.FAVORITES
      or selectedKey == self.UNSORTED then
    return nil
  end

  if self:Get(selectedKey) then
    return selectedKey
  end

  return nil
end

function FolderService:FindByName(name)
  local normalizedName = string.lower(addon.Utils:Trim(name or ""))

  if normalizedName == "" then
    return nil
  end

  for _, folder in pairs(self:GetFolders()) do
    if string.lower(folder.name or "") == normalizedName then
      return folder
    end
  end

  return nil
end

addon.Services.Folder = FolderService
