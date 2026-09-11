--!strict
-- ASTRO MINER | Server/Services/PlayerDataService.luau
-- Minimal versioned store for Milestone 1. In-memory authoritative + DataStore
-- persistence hooks (safe save, never trusts client values).

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local Constants = require(game.ReplicatedStorage.Shared.Constants)

export type MissionState = {
	DefId: string,
	Progress: number,
	Claimed: boolean,
}

export type PlayerData = {
	DataVersion: number,
	Currencies: { Credits: number, Stardust: number, Research: number },
	Ore: { [string]: number },
	Progression: { Zone: number, EquipmentLevel: number, PrestigeCount: number },
	Buildings: { [string]: number },
	Drones: { [string]: number },
	Upgrades: { [string]: boolean },
	Statistics: { LifetimeCredits: number, AsteroidsMined: number, ResourcesCollected: number, RareFound: number, RunCredits: number, TotalDailyClaims: number },
	DailyRewards: { Day: number, LastClaim: number },
	Missions: { Date: string, List: { MissionState } },
	Boosts: { [string]: number }, -- boostId -> os.time() end
	LastLogout: number,
}

local PlayerDataService = {}
PlayerDataService.__index = PlayerDataService

local profiles: { [Player]: PlayerData } = {}
local store: DataStore? = nil

do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(Constants.DATASTORE_NAME)
	end)
	if ok then
		store = result
	else
		warn("[AstroMiner] DataStore unavailable (Studio/no access). Using session-only data.")
	end
end

function PlayerDataService.defaultData(): PlayerData
	return {
		DataVersion = Constants.DATA_VERSION,
		Currencies = { Credits = 0, Stardust = 0, Research = 0 },
		Ore = { Stone = 0, Iron = 0, Titanium = 0, Gold = 0 },
		Progression = { Zone = 1, EquipmentLevel = 1, PrestigeCount = 0 },
		Buildings = {},
		Drones = {},
		Upgrades = {},
		Statistics = { LifetimeCredits = 0, AsteroidsMined = 0, ResourcesCollected = 0, RareFound = 0, RunCredits = 0, TotalDailyClaims = 0 },
		DailyRewards = { Day = 1, LastClaim = 0 },
		Missions = { Date = "", List = {} },
		Boosts = {},
		LastLogout = 0,
	}
end

local function sanitize(raw: any): PlayerData
	local d = PlayerDataService.defaultData()
	if typeof(raw) ~= "table" then
		return d
	end
	if raw.DataVersion ~= Constants.DATA_VERSION then
		-- Version mismatch: start fresh (future: migrate). Never trust shape blindly.
		return d
	end
	local function num(v: any, fallback: number): number
		if typeof(v) == "number" and v == v and math.abs(v) ~= math.huge then
			return math.max(0, math.floor(v))
		end
		return fallback
	end
	d.Currencies.Credits = num(raw.Currencies and raw.Currencies.Credits, 0)
	d.Currencies.Stardust = num(raw.Currencies and raw.Currencies.Stardust, 0)
	d.Currencies.Research = num(raw.Currencies and raw.Currencies.Research, 0)
	if typeof(raw.Ore) == "table" then
		for k, v in pairs(raw.Ore) do
			if typeof(k) == "string" and typeof(v) == "number" then
				d.Ore[k] = num(v, 0)
			end
		end
	end
	if typeof(raw.Progression) == "table" then
		d.Progression.Zone = math.clamp(num(raw.Progression.Zone, 1), 1, 3)
		d.Progression.EquipmentLevel = math.clamp(num(raw.Progression.EquipmentLevel, 1), 1, 5)
		d.Progression.PrestigeCount = num(raw.Progression.PrestigeCount, 0)
	end
	for _, key in ipairs({ "Buildings", "Drones" }) do
		local slot = (d as any)[key] as { [string]: number }
		local rawSlot = (raw as any)[key]
		if typeof(rawSlot) == "table" then
			for k, v in pairs(rawSlot) do
				if typeof(k) == "string" and typeof(v) == "number" then
					slot[string.sub(k, 1, 32)] = math.clamp(num(v, 0), 0, 9999)
				end
			end
		end
	end
	if typeof(raw.Upgrades) == "table" then
		for k, v in pairs(raw.Upgrades) do
			if typeof(k) == "string" and v == true then
				d.Upgrades[string.sub(k, 1, 32)] = true
			end
		end
	end
	if typeof(raw.Statistics) == "table" then
		for k, _ in pairs(d.Statistics) do
			d.Statistics[k] = num(raw.Statistics[k], 0)
		end
	end
	if typeof(raw.DailyRewards) == "table" then
		d.DailyRewards.Day = math.clamp(num(raw.DailyRewards.Day, 1), 1, 7)
		d.DailyRewards.LastClaim = num(raw.DailyRewards.LastClaim, 0)
	end
	if typeof(raw.Missions) == "table" then
		if typeof(raw.Missions.Date) == "string" then
			d.Missions.Date = string.sub(raw.Missions.Date, 1, 10)
		end
		if typeof(raw.Missions.List) == "table" then
			for _, entry in ipairs(raw.Missions.List) do
				if typeof(entry) == "table" and typeof(entry.DefId) == "string" then
					table.insert(d.Missions.List, {
						DefId = string.sub(entry.DefId, 1, 32),
						Progress = num(entry.Progress, 0),
						Claimed = entry.Claimed == true,
					})
					if #d.Missions.List >= 3 then
						break
					end
				end
			end
		end
	end
	d.LastLogout = num(raw.LastLogout, 0)
	if typeof(raw.Boosts) == "table" then
		local now = os.time()
		for k, v in pairs(raw.Boosts) do
			if typeof(k) == "string" and typeof(v) == "number" then
				local ends = num(v, 0)
				if ends > now then -- drop expired boosts on load
					d.Boosts[string.sub(k, 1, 32)] = math.min(ends, now + 30 * 24 * 3600)
				end
			end
		end
	end
	return d
end

function PlayerDataService.get(player: Player): PlayerData?
	return profiles[player]
end

function PlayerDataService.load(player: Player): PlayerData
	local data = PlayerDataService.defaultData()
	if store then
		local ok, raw = pcall(function()
			return store:GetAsync("player_" .. player.UserId)
		end)
		if ok and raw ~= nil then
			data = sanitize(raw)
		end
	end
	profiles[player] = data
	return data
end

function PlayerDataService.save(player: Player): boolean
	local data = profiles[player]
	if not data then
		return false
	end
	data.LastLogout = os.time()
	if not store then
		return true -- session-only (Studio without API access)
	end
	local ok, err = pcall(function()
		store:SetAsync("player_" .. player.UserId, data)
	end)
	if not ok then
		warn("[AstroMiner] Save failed for " .. player.Name .. ": " .. tostring(err))
	end
	return ok
end

function PlayerDataService.remove(player: Player)
	profiles[player] = nil
end

-- Autosave loop, called once from ServerMain.
function PlayerDataService.startAutosave()
	task.spawn(function()
		while true do
			task.wait(Constants.AUTOSAVE_INTERVAL)
			for _, player in ipairs(Players:GetPlayers()) do
				PlayerDataService.save(player)
			end
		end
	end)
end

return PlayerDataService
