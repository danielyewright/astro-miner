--!strict
-- ASTRO MINER | Shared/Config/Equipment.luau
-- Spec §7. MVP implements first 5 tiers. Rest reserved for config-only expansion.

export type EquipmentDef = {
	Level: number,
	Name: string,
	Cost: number, -- credits to purchase/upgrade TO this level
	Damage: number, -- per manual mine action
	Cooldown: number, -- seconds between manual mines (server-enforced)
	CritChance: number, -- 0..1
	CritMultiplier: number,
	RareBonus: number, -- additive rare-resource chance
}

-- Tuned for MVP journey: first upgrade in 1-2 min, drone by ~min 5 (Spec §42).
local Equipment: { [number]: EquipmentDef } = {
	[1] = {
		Level = 1,
		Name = "Basic Drill",
		Cost = 0,
		Damage = 5,
		Cooldown = 0.35,
		CritChance = 0.05,
		CritMultiplier = 2,
		RareBonus = 0,
	},
	[2] = {
		Level = 2,
		Name = "Industrial Drill",
		Cost = 100,
		Damage = 15,
		Cooldown = 0.32,
		CritChance = 0.07,
		CritMultiplier = 2,
		RareBonus = 0.01,
	},
	[3] = {
		Level = 3,
		Name = "Plasma Cutter",
		Cost = 1000,
		Damage = 50,
		Cooldown = 0.30,
		CritChance = 0.10,
		CritMultiplier = 2.5,
		RareBonus = 0.02,
	},
	[4] = {
		Level = 4,
		Name = "Laser Miner",
		Cost = 8000,
		Damage = 200,
		Cooldown = 0.28,
		CritChance = 0.12,
		CritMultiplier = 3,
		RareBonus = 0.03,
	},
	[5] = {
		Level = 5,
		Name = "Quantum Drill",
		Cost = 50000,
		Damage = 1000,
		Cooldown = 0.25,
		CritChance = 0.15,
		CritMultiplier = 4,
		RareBonus = 0.05,
	},
	-- Reserved (post-MVP): Fusion Miner, Graviton Extractor, Dark Matter Harvester.
}

local MAX_LEVEL = 5

local function getDef(level: number): EquipmentDef?
	return Equipment[level]
end

return {
	Definitions = Equipment,
	MaxLevel = MAX_LEVEL,
	getDef = getDef,
}
