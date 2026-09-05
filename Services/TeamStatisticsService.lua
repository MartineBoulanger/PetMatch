local _, addon = ...

local TeamStatisticsService = {}
TeamStatisticsService.ActiveBattle = nil
TeamStatisticsService.Initialized = false

local VALID_BATTLE_TYPES = {
  pve = true,
  pvp = true,
}

local VALID_RESULTS = {
  win = true,
  loss = true,
  draw = true,
}

local function CopyStatsBucket(source)
  source = source or {}

  return {
    wins = tonumber(source.wins) or 0,
    losses = tonumber(source.losses) or 0,
    draws = tonumber(source.draws) or 0,
  }
end

local function GetBattleType()
  local opponentIsNPC = C_PetBattles.IsPlayerNPC(2)

  if opponentIsNPC then
    return "pve"
  end

  return "pvp"
end

local function HasLivingPets(owner)
  local numPets = C_PetBattles.GetNumPets(owner)

  for petIndex = 1, numPets do
    local health =
        C_PetBattles.GetHealth(
          owner,
          petIndex
        )

    if health and health > 0 then
      return true
    end
  end

  return false
end

function TeamStatisticsService:GetBattleResult(winner)
  winner = tonumber(winner)

  if winner == 1 then
    return "win"
  end

  if winner == 2 then
    return "loss"
  end

  local allyAlive = HasLivingPets(1)
  local enemyAlive = HasLivingPets(2)

  if not allyAlive and not enemyAlive then
    return "draw"
  end

  return nil
end

function TeamStatisticsService:EnsureStats(team)
  if type(team) ~= "table" then
    return nil
  end

  team.stats = team.stats or {}
  team.stats.pve = CopyStatsBucket(team.stats.pve)
  team.stats.pvp = CopyStatsBucket(team.stats.pvp)

  return team.stats
end

function TeamStatisticsService:GetStats(team)
  local stats = self:EnsureStats(team)

  if not stats then
    return nil
  end

  return {
    pve = CopyStatsBucket(stats.pve),
    pvp = CopyStatsBucket(stats.pvp),
  }
end

function TeamStatisticsService:GetOverall(team)
  local stats = self:EnsureStats(team)

  if not stats then
    return nil
  end

  return {
    wins = stats.pve.wins + stats.pvp.wins,
    losses = stats.pve.losses + stats.pvp.losses,
    draws = stats.pve.draws + stats.pvp.draws,
  }
end

function TeamStatisticsService:GetWinRate(stats)
  if type(stats) ~= "table" then
    return 0
  end

  local wins = tonumber(stats.wins) or 0
  local losses = tonumber(stats.losses) or 0
  local ratedBattles = wins + losses

  if ratedBattles <= 0 then
    return 0
  end

  return wins / ratedBattles * 100
end

function TeamStatisticsService:GetLossRate(stats)
  if type(stats) ~= "table" then
    return 0
  end

  local wins = tonumber(stats.wins) or 0
  local losses = tonumber(stats.losses) or 0
  local ratedBattles = wins + losses

  if ratedBattles <= 0 then
    return 0
  end

  return losses / ratedBattles * 100
end

function TeamStatisticsService:RecordResult(team, battleType, result)
  if type(team) ~= "table" then
    return false
  end

  if not VALID_BATTLE_TYPES[battleType] then
    return false
  end

  if not VALID_RESULTS[result] then
    return false
  end

  local stats = self:EnsureStats(team)

  if not stats then
    return false
  end

  local bucket = stats[battleType]

  if result == "win" then
    bucket.wins = bucket.wins + 1
  elseif result == "loss" then
    bucket.losses = bucket.losses + 1
  elseif result == "draw" then
    bucket.draws = bucket.draws + 1
  end

  team.modified = time()

  addon.EventBus:Fire(
    addon.Events.TEAM_UPDATED,
    team
  )

  return true
end

function TeamStatisticsService:StartBattle()
  local team =
      addon.Services.Team:GetActive()

  if not team then
    self.ActiveBattle = nil
    return false
  end

  self.ActiveBattle = {
    teamID = team.id,
    battleType = GetBattleType(),
    result = nil,
  }

  return true
end

function TeamStatisticsService:SetBattleResult(winner)
  if not self.ActiveBattle then
    return
  end

  local result = self:GetBattleResult(winner)

  self.ActiveBattle.result = result
end

function TeamStatisticsService:EndBattle()
  if not self.ActiveBattle then
    return
  end

  local battle = self.ActiveBattle

  self.ActiveBattle = nil

  if not battle.result then
    return
  end

  local team =
      addon.Services.Team:Get(battle.teamID)

  if not team then
    return
  end

  self:RecordResult(
    team,
    battle.battleType,
    battle.result
  )
end

addon.Services.TeamStatistics = TeamStatisticsService
