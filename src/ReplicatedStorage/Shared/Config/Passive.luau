--!strict
-- ASTRO MINER | Shared/Config/Passive.luau
-- Credits/sec while online AND the basis for offline earnings (Spec §15).
-- Pre-drones: equipment-based trickle so offline is never zero.
-- DroneService (later milestone) adds via Passive.addDroneRate hook.

export type PassiveConfig = {
	BaseRate: number,
	PerEquipment: { [number]: number },
	MaxOfflineSeconds: number,
	MinAwaySeconds: number,
	LiveTickSeconds: number,
}

local Passive = {
	BaseRate = 1,
	PerEquipment = {
		[1] = 1,
		[2] = 3,
		[3] = 8,
		[4] = 20,
		[5] = 50,
	},
	MaxOfflineSeconds = 8 * 3600, -- 8h cap, Spec §15
	MinAwaySeconds = 60, -- ignore trivial absences
	LiveTickSeconds = 10, -- server accrues online passive every 10s
}

-- External systems (drones, boosts) register additive bonuses here at runtime.
local extraRates: { [string]: (player: Player) -> number } = {}

local function registerProvider(name: string, fn: (player: Player) -> number)
	extraRates[name] = fn
end

local function extraFor(player: Player): number
	local total = 0
	for _, fn in pairs(extraRates) do
		local ok, v = pcall(fn, player)
		if ok and typeof(v) == "number" and v > 0 then
			total += v
		end
	end
	return total
end

local function rateFor(equipmentLevel: number): number
	return (Passive.BaseRate + (Passive.PerEquipment[equipmentLevel] or 1))
end

return {
	Config = Passive,
	registerProvider = registerProvider,
	extraFor = extraFor,
	rateFor = rateFor,
}
