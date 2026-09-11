--!strict
-- ASTRO MINER | Server/Services/MiningService.luau
-- Milestone 1: server-authoritative asteroid mining.
-- Client sends (asteroidId); server validates rate limit, cooldown, distance,
-- then applies equipment damage, rolls rewards, and fires Fx + StateSync.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Shared.Constants)
local Equipment = require(ReplicatedStorage.Shared.Config.Equipment)
local Resources = require(ReplicatedStorage.Shared.Config.Resources)
local Zones = require(ReplicatedStorage.Shared.Config.Zones)
local PlayerDataService = require(script.Parent.PlayerDataService)
local EconomyService = require(script.Parent.EconomyService)
local MissionService = require(script.Parent.MissionService)
local PrestigeService = require(script.Parent.PrestigeService)
local MonetizationService = require(script.Parent.MonetizationService)
local StateService = require(script.Parent.StateService)

type Asteroid = {
	Id: string,
	Position: Vector3,
	MaxHealth: number,
	Health: number,
	Alive: boolean,
}

local MiningService = {}
MiningService.Asteroids = {} :: { [string]: Asteroid }
MiningService.Revision = 0 -- bumped on damage/destroy/respawn; visual loops skip when clean

local function bumpRevision()
	MiningService.Revision += 1
end

-- Per-player anti-exploit state
local lastMine: { [number]: number } = {} -- userId -> os.clock()
local mineTimestamps: { [number]: { number } } = {} -- sliding window for rate limit

local remotes: { [string]: RemoteEvent | RemoteFunction } = {}

function MiningService.bindRemotes(r: { [string]: RemoteEvent | RemoteFunction })
	remotes = r
end

-- Spawns (or respawns) N asteroids in a ring around `center` for the MVP field.
function MiningService.spawnField(center: Vector3, count: number, zoneId: number)
	local zoneDef = Zones.Definitions[zoneId] or Zones.Definitions[1]
	table.clear(MiningService.Asteroids)
	for i = 1, count do
		local angle = (i / count) * math.pi * 2
		local radius = 25 + (i % 3) * 12
		local pos = center + Vector3.new(math.cos(angle) * radius, 5 + (i % 4) * 2, math.sin(angle) * radius)
		local id = "AST_" .. tostring(i)
		MiningService.Asteroids[id] = {
			Id = id,
			Position = pos,
			MaxHealth = zoneDef.AsteroidHealth,
			Health = zoneDef.AsteroidHealth,
			Alive = true,
		}
	end
end

local function checkRateLimit(userId: number): boolean
	local now = os.clock()
	local window = mineTimestamps[userId]
	if not window then
		window = {}
		mineTimestamps[userId] = window
	end
	-- Prune entries older than 1s
	local fresh: { number } = {}
	for _, t in ipairs(window) do
		if now - t < 1 then
			table.insert(fresh, t)
		end
	end
	mineTimestamps[userId] = fresh
	if #fresh >= Constants.MINE_RATE_LIMIT then
		return false
	end
	table.insert(fresh, now)
	return true
end

local function rollRewards(zoneId: number, isCrit: boolean, rareBonus: number): ({ [string]: number }, boolean)
	local zoneDef = Zones.Definitions[zoneId] or Zones.Definitions[1]
	local pool = zoneDef.Resources
	-- Weighted: earlier (cheaper) ores more common.
	local weights = { 50, 30, 15, 5 } -- aligns with 4-entry MVP pool
	local total = 0
	for i = 1, math.min(#pool, #weights) do
		total += weights[i]
	end
	local roll = math.random() * total
	local picked = pool[1]
	local acc = 0
	for i = 1, math.min(#pool, #weights) do
		acc += weights[i]
		if roll <= acc then
			picked = pool[i]
			break
		end
	end
	-- Rare upgrade: bump one tier up.
	local foundRare = false
	if math.random() < (Constants.BASE_RARE_CHANCE + rareBonus) then
		for i, id in ipairs(pool) do
			if id == picked and i < #pool then
				picked = pool[i + 1]
				foundRare = true
				break
			end
		end
	end
	local qty = if isCrit then math.random(3, 5) else math.random(1, 2)
	return { [picked] = qty }, foundRare
end

local function getCharacterPosition(player: Player): Vector3?
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root.Position
	end
	return nil
end

-- Returns: ok, payload-or-error
function MiningService.mine(player: Player, asteroidId: unknown): (boolean, any)
	if typeof(asteroidId) ~= "string" then
		return false, "bad-request"
	end
	local data = PlayerDataService.get(player)
	if not data then
		return false, "no-profile"
	end
	if not checkRateLimit(player.UserId) then
		return false, "rate-limited"
	end
	local equip = Equipment.getDef(data.Progression.EquipmentLevel) or Equipment.Definitions[1]
	local now = os.clock()
	if lastMine[player.UserId] and now - lastMine[player.UserId] < equip.Cooldown - 0.05 then
		return false, "too-fast" -- server-side cooldown (small tolerance for latency)
	end
	lastMine[player.UserId] = now

	local asteroid = MiningService.Asteroids[asteroidId]
	if not asteroid or not asteroid.Alive then
		return false, "invalid-target"
	end
	local charPos = getCharacterPosition(player)
	if charPos and (charPos - asteroid.Position).Magnitude > Constants.MAX_MINE_DISTANCE + 20 then
		return false, "too-far" -- distance check (generous to avoid false positives)
	end

	local isCrit = math.random() < equip.CritChance
	local damage = equip.Damage * (if isCrit then equip.CritMultiplier else 1)
	damage *= PrestigeService.damageMultiplier(player)
	damage *= MonetizationService.damageMultiplier(player)
	asteroid.Health -= damage
	bumpRevision()

	local fx = remotes[Constants.REMOTES.Fx] :: RemoteEvent?
	local destroyed = asteroid.Health <= 0
	local rewards: { [string]: number } = {}
	local foundRareFinal = false

	if destroyed then
		asteroid.Alive = false
		asteroid.Health = 0
		local rareBonus = equip.RareBonus + PrestigeService.rareBonus(player) + MonetizationService.rareBonus(player)
		local foundRare: boolean
		rewards, foundRare = rollRewards(data.Progression.Zone, isCrit, rareBonus)
		EconomyService.addOre(player, rewards)
		data.Statistics.AsteroidsMined += 1
		MissionService.onEvent(player, "asteroid", 1)
		if foundRare then
			data.Statistics.RareFound += 1
			MissionService.onEvent(player, "rare", 1)
			foundRareFinal = true
		end
		-- Respawn after zone delay (non-blocking)
		local zoneDef = Zones.Definitions[data.Progression.Zone] or Zones.Definitions[1]
		task.delay(zoneDef.AsteroidRespawn, function()
			asteroid.Health = asteroid.MaxHealth
			asteroid.Alive = true
			bumpRevision()
			if fx then
				fx:FireAllClients("asteroidRespawned", { id = asteroid.Id, health = asteroid.Health })
			end
		end)
	end

	if fx then
		fx:FireClient(player, "mineHit", {
			id = asteroid.Id,
			damage = math.floor(damage),
			health = math.max(0, math.floor(asteroid.Health)),
			maxHealth = asteroid.MaxHealth,
			crit = isCrit,
			destroyed = destroyed,
			rewards = rewards,
			rare = foundRareFinal,
		})
	end

	MiningService.pushState(player)
	return true, {
		damage = math.floor(damage),
		crit = isCrit,
		destroyed = destroyed,
		rewards = rewards,
	}
end

function MiningService.pushState(player: Player)
	-- Full payload (credits, dailies, missions, offline) via StateService.
	StateService.push(player)
end

Players.PlayerRemoving:Connect(function(player)
	lastMine[player.UserId] = nil
	mineTimestamps[player.UserId] = nil
end)

return MiningService
