--!strict
-- ASTRO MINER | Shared/Config/Zones.luau
-- Spec §12-13. MVP: only Zone 1 (Lunar Outpost) is built. Others are data stubs.

export type ZoneDef = {
	Id: number,
	Name: string,
	UnlockCost: number,
	Resources: { string }, -- resource IDs that can drop here
	AsteroidHealth: number,
	AsteroidRespawn: number, -- seconds
	SellMultiplier: number,
	EnabledInMVP: boolean,
}

local Zones: { [number]: ZoneDef } = {
	[1] = {
		Id = 1,
		Name = "Lunar Outpost",
		UnlockCost = 0,
		Resources = { "Stone", "Iron", "Titanium", "Gold" },
		AsteroidHealth = 100,
		AsteroidRespawn = 2,
		SellMultiplier = 1,
		EnabledInMVP = true,
	},
	[2] = {
		Id = 2,
		Name = "Asteroid Belt",
		UnlockCost = 100000,
		Resources = { "Iron", "Gold", "Platinum", "Diamond" },
		AsteroidHealth = 500,
		AsteroidRespawn = 2,
		SellMultiplier = 1,
		EnabledInMVP = false,
	},
	[3] = {
		Id = 3,
		Name = "Mars",
		UnlockCost = 10000000,
		Resources = { "Titanium", "Platinum", "Uranium" },
		AsteroidHealth = 2500,
		AsteroidRespawn = 2,
		SellMultiplier = 1,
		EnabledInMVP = false,
	},
}

return {
	Definitions = Zones,
}
