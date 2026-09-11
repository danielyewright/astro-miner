--!strict
-- ASTRO MINER | Server/Services/MissionService.luau
-- Daily missions (Spec §19). Server tracks progress via onEvent hooks called
-- from Mining/Economy/Upgrade services. All validation server-side.

local Missions = require(game.ReplicatedStorage.Shared.Config.Missions)
local PlayerDataService = require(script.Parent.PlayerDataService)
local EconomyService = require(script.Parent.EconomyService)

export type MissionView = {
	defId: string,
	name: string,
	kind: string,
	progress: number,
	target: number,
	completed: boolean,
	claimed: boolean,
	credits: number,
	stardust: number,
}

local MissionService = {}

local function todayStr(): string
	return os.date("!%Y-%m-%d") :: string
end

local function defById(id: string): any
	for _, t in ipairs(Missions.Templates) do
		if t.Id == id then
			return t
		end
	end
	return nil
end

-- Ensures the player has today's 3 missions; rolls over on a new day.
function MissionService.ensure(player: Player)
	local data = PlayerDataService.get(player)
	if not data then
		return
	end
	local today = todayStr()
	if data.Missions.Date == today and #data.Missions.List == 3 then
		return
	end
	data.Missions.Date = today
	table.clear(data.Missions.List)
	for _, def in ipairs(Missions.forDate(today)) do
		table.insert(data.Missions.List, { DefId = def.Id, Progress = 0, Claimed = false })
	end
end

function MissionService.view(player: Player): { MissionView }
	local data = PlayerDataService.get(player)
	if not data then
		return {}
	end
	MissionService.ensure(player)
	local out: { MissionView } = {}
	for _, entry in ipairs(data.Missions.List) do
		local def = defById(entry.DefId)
		if def then
			table.insert(out, {
				defId = def.Id,
				name = def.Name,
				kind = def.Kind,
				progress = math.min(entry.Progress, def.Target),
				target = def.Target,
				completed = entry.Progress >= def.Target,
				claimed = entry.Claimed,
				credits = def.Credits,
				stardust = def.Stardust,
			})
		end
	end
	return out
end

-- kind: "asteroid" | "rare" | "credits" | "upgrade". amount defaults to 1.
function MissionService.onEvent(player: Player, kind: string, amount: number?)
	local data = PlayerDataService.get(player)
	if not data then
		return
	end
	MissionService.ensure(player)
	local delta = amount or 1
	if delta <= 0 then
		return
	end
	for _, entry in ipairs(data.Missions.List) do
		local def = defById(entry.DefId)
		if def and def.Kind == kind and not entry.Claimed and entry.Progress < def.Target then
			entry.Progress = math.min(entry.Progress + math.floor(delta), def.Target)
		end
	end
end

-- Returns: ok, message
function MissionService.claim(player: Player, defId: unknown): (boolean, string)
	if typeof(defId) ~= "string" then
		return false, "bad-request"
	end
	local data = PlayerDataService.get(player)
	if not data then
		return false, "no-profile"
	end
	MissionService.ensure(player)
	for _, entry in ipairs(data.Missions.List) do
		if entry.DefId == defId then
			local def = defById(defId)
			if not def then
				return false, "unknown-mission"
			end
			if entry.Claimed then
				return false, "already-claimed"
			end
			if entry.Progress < def.Target then
				return false, "not-complete"
			end
			entry.Claimed = true
			if def.Credits > 0 then
				EconomyService.addCredits(player, def.Credits)
			end
			if def.Stardust > 0 then
				data.Currencies.Stardust = math.min(data.Currencies.Stardust + def.Stardust, 9e12)
			end
			return true, def.Name
		end
	end
	return false, "not-found"
end

return MissionService
