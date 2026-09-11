--!strict
-- ASTRO MINER | Server/Services/LeaderboardService.luau
-- Global boards (Spec §37), none gated on spending. OrderedDataStores with
-- throttled submits (leave + 2min interval) and 60s-cached top-10 reads.
-- All DataStore calls are pcall-wrapped: Studio without API access serves
-- empty boards instead of erroring.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local Passive = require(game.ReplicatedStorage.Shared.Config.Passive)
local PlayerDataService = require(script.Parent.PlayerDataService)
local DroneService = require(script.Parent.DroneService)

export type BoardEntry = { name: string, value: number }

local Boards = {
	{ Key = "credits", Store = "AM_LBCredits_v1", Title = "💰 Lifetime Credits" },
	{ Key = "asteroids", Store = "AM_LBAsteroids_v1", Title = "⛏ Asteroids Mined" },
	{ Key = "prestige", Store = "AM_LBPrestige_v1", Title = "🌌 Cosmic Resets" },
	{ Key = "production", Store = "AM_LBProduction_v1", Title = "⚙ Credits/sec" },
	{ Key = "rare", Store = "AM_LBRare_v1", Title = "💎 Rare Finds" },
}

local LeaderboardService = {}

local lastSubmit: { [number]: number } = {}
local topCache: { [string]: { entries: { BoardEntry }, at: number } } = {}
local nameCache: { [number]: string } = {}
local SUBMIT_INTERVAL = 120
local CACHE_TTL = 60

local function stores(): { [string]: OrderedDataStore }
	local out: { [string]: OrderedDataStore } = {}
	for _, b in ipairs(Boards) do
		local ok, store = pcall(function()
			return DataStoreService:GetOrderedDataStore(b.Store)
		end)
		if ok and store then
			out[b.Key] = store
		end
	end
	return out
end

local lazyStores: { [string]: OrderedDataStore }? = nil
local function getStores(): { [string]: OrderedDataStore }
	if not lazyStores then
		lazyStores = stores()
	end
	return lazyStores
end

function LeaderboardService.defs(): any
	local out: { any } = {}
	for _, b in ipairs(Boards) do
		table.insert(out, { key = b.Key, title = b.Title })
	end
	return out
end

local function boardValue(player: Player, key: string): number
	local data = PlayerDataService.get(player)
	if not data then
		return 0
	end
	if key == "credits" then
		return data.Statistics.LifetimeCredits
	elseif key == "asteroids" then
		return data.Statistics.AsteroidsMined
	elseif key == "prestige" then
		return data.Progression.PrestigeCount
	elseif key == "production" then
		return math.floor(Passive.rateFor(data.Progression.EquipmentLevel) + Passive.extraFor(player) + DroneService.offlineRate(player))
	elseif key == "rare" then
		return data.Statistics.RareFound
	end
	return 0
end

function LeaderboardService.submit(player: Player, force: boolean?)
	local now = os.clock()
	if not force and lastSubmit[player.UserId] and now - lastSubmit[player.UserId] < SUBMIT_INTERVAL then
		return
	end
	lastSubmit[player.UserId] = now
	local all = getStores()
	for _, b in ipairs(Boards) do
		local store = all[b.Key]
		if store then
			pcall(function()
				store:UpdateAsync("u_" .. player.UserId, function(_old)
					return boardValue(player, b.Key)
				end)
			end)
		end
	end
end

function LeaderboardService.submitAll()
	for _, player in ipairs(Players:GetPlayers()) do
		LeaderboardService.submit(player)
	end
end

function LeaderboardService.clear(player: Player)
	lastSubmit[player.UserId] = nil
end

local function resolveName(userId: number): string
	if nameCache[userId] then
		return nameCache[userId]
	end
	local ok, name = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	nameCache[userId] = if ok and typeof(name) == "string" then name else "Miner" .. tostring(userId % 10000)
	return nameCache[userId]
end

-- Returns cached top-10 for a board key. Unknown keys yield {}.
function LeaderboardService.top(boardKey: string): { BoardEntry }
	local now = os.clock()
	local hit = topCache[boardKey]
	if hit and now - hit.at < CACHE_TTL then
		return hit.entries
	end
	local entries: { BoardEntry } = {}
	local all = getStores()
	local store = all[boardKey]
	if store then
		local ok, pages = pcall(function()
			return store:GetSortedAsync(false, 10)
		end)
		if ok and pages then
			local ok2, items = pcall(function()
				return pages:GetCurrentPage()
			end)
			if ok2 and typeof(items) == "table" then
				for _, item in ipairs(items) do
					local uid = tonumber(string.match(tostring(item.key), "u_(%d+)"))
					if uid then
						table.insert(entries, {
							name = resolveName(uid),
							value = if typeof(item.value) == "number" then math.floor(item.value) else 0,
						})
					end
				end
			end
		end
	end
	topCache[boardKey] = { entries = entries, at = now }
	return entries
end

return LeaderboardService
