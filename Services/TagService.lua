local addonName, addon = ...

local TagService = {}

local function GetProfile()
  return addon.Profiles:GetCurrentProfile()
end

local function Normalize(value)
  return string.lower(
    addon.Utils:Trim(value or "")
  )
end

function TagService:GetTags()
  local profile = GetProfile()

  profile.tags = profile.tags or {}

  return profile.tags
end

function TagService:Get(tagID)
  if not tagID then
    return nil
  end

  return self:GetTags()[tagID]
end

function TagService:FindByName(name)
  local normalizedName = Normalize(name)

  if normalizedName == "" then
    return nil
  end

  for _, tag in pairs(self:GetTags()) do
    if Normalize(tag.name) == normalizedName then
      return tag
    end
  end

  return nil
end

function TagService:Create(name)
  name = addon.Utils:Trim(name or "")

  if name == "" then
    return nil, "Enter a tag name"
  end

  if self:FindByName(name) then
    return nil, "A tag with that name already exists"
  end

  local tag = addon.Models.Tag:Create(name)

  local highestOrder = 0

  for _, existingTag in pairs(self:GetTags()) do
    highestOrder = math.max(
      highestOrder,
      existingTag.order or 0
    )
  end

  tag.order = highestOrder + 1

  self:GetTags()[tag.id] = tag

  addon.EventBus:Fire(
    addon.Events.TAG_CREATED,
    tag
  )

  return tag
end

function TagService:Rename(tagID, name)
  local tag = self:Get(tagID)

  if not tag then
    return nil, "Tag not found"
  end

  name = addon.Utils:Trim(name or "")

  if name == "" then
    return nil, "Enter a tag name"
  end

  local existingTag = self:FindByName(name)

  if existingTag and existingTag.id ~= tagID then
    return nil, "A tag with that name already exists"
  end

  tag.name = name
  tag.modified = time()

  addon.EventBus:Fire(
    addon.Events.TAG_UPDATED,
    tag
  )

  return tag
end

function TagService:Delete(tagID)
  local tags = self:GetTags()
  local tag = tags[tagID]

  if not tag then
    return false, "Tag not found"
  end

  for _, team in pairs(
    addon.Services.Team:GetTeams()
  ) do
    if team.tags and team.tags[tagID] then
      team.tags[tagID] = nil
      team.modified = time()

      addon.EventBus:Fire(
        addon.Events.TEAM_TAGS_CHANGED,
        team
      )

      addon.EventBus:Fire(
        addon.Events.TEAM_UPDATED,
        team
      )
    end
  end

  tags[tagID] = nil

  addon.EventBus:Fire(
    addon.Events.TAG_DELETED,
    tag
  )

  return true
end

function TagService:GetSortedTags()
  local result = {}

  for _, tag in pairs(self:GetTags()) do
    table.insert(result, tag)
  end

  table.sort(result, function(left, right)
    local leftOrder = left.order or 0
    local rightOrder = right.order or 0

    if leftOrder ~= rightOrder then
      return leftOrder < rightOrder
    end

    return Normalize(left.name)
        < Normalize(right.name)
  end)

  return result
end

function TagService:GetTagsForTeam(team)
  local result = {}

  if not team or not team.tags then
    return result
  end

  for tagID, enabled in pairs(team.tags) do
    if enabled then
      local tag = self:Get(tagID)

      if tag then
        table.insert(result, tag)
      end
    end
  end

  table.sort(result, function(left, right)
    return Normalize(left.name)
        < Normalize(right.name)
  end)

  return result
end

addon.Services.Tag = TagService
