local addonName, addon = ...

local SearchService = {}

SearchService.Query = ""

---@param value string?
---@return string
local function Normalize(value)
  value = addon.Utils:Trim(value or "")
  return string.lower(value)
end

function SearchService:SetQuery(query)
  local normalizedQuery = Normalize(query)

  if self.Query == normalizedQuery then
    return
  end

  self.Query = normalizedQuery

  addon.EventBus:Fire(
    addon.Events.SEARCH_CHANGED,
    normalizedQuery
  )
end

function SearchService:GetQuery()
  return self.Query or ""
end

function SearchService:Clear()
  self:SetQuery("")
end

function SearchService:MatchesTeam(team)
  local query = self:GetQuery()

  if query == "" then
    return true
  end

  if not team then
    return false
  end

  local teamName =
      Normalize(team.name)

  if string.find(
        teamName,
        query,
        1,
        true
      ) then
    return true
  end

  local description =
      Normalize(team.description)

  if string.find(
        description,
        query,
        1,
        true
      ) then
    return true
  end

  local notes =
      Normalize(team.notes)

  if string.find(
        notes,
        query,
        1,
        true
      ) then
    return true
  end

  -- Ook zoeken op de namen van opgeslagen pets.
  for slot = 1, 3 do
    local petGUID =
        team.pets
        and team.pets[slot]

    if petGUID then
      local pet =
          addon.Services.PetJournal:GetPet(
            petGUID
          )

      if pet then
        local petName =
            Normalize(pet.name)

        if string.find(
              petName,
              query,
              1,
              true
            ) then
          return true
        end
      end
    end
  end

  return false
end

addon.Services.Search = SearchService
