--!strict
-- ASTRO MINER | Server/Services/BoostService.luau
-- Temporary boosts (Spec §21). End-times persist in `data.Boosts` as os.time
-- so they tick down in real time, including across sessions.

local PlayerDataService = require(script.Parent.PlayerDataService)

local BoostService = {}

function BoostService.grant(player: Player, boostId: string, minutes: number): boolean
	if typeof(boostId) ~= "string" or typeof(minutes) ~= "number" or minutes <= 0 then
		return false
	end
	local data = PlayerDataService.get(player)
	if not data then
		return false
	end
	local id = string.sub(boostId, 1, 32)
	local current = data.Boosts[id] or 0
	data.Boosts[id] = math.max(current, os.time() + math.floor(minutes * 60))
	return true
end

function BoostService.remaining(player: Player, boostId: string): number
	local data = PlayerDataService.get(player)
	if not data then
		return 0
	end
	return math.max(0, (data.Boosts[boostId] or 0) - os.time())
end

function BoostService.active(player: Player, boostId: string): boolean
	return BoostService.remaining(player, boostId) > 0
end

return BoostService
