--!strict
-- ASTRO MINER | Shared/Types.luau
-- Versioned player data schema (Spec §31).

export type Currencies = {
	Credits: number,
	Stardust: number,
	Research: number,
}

export type Progression = {
	Zone: number,
	EquipmentLevel: number,
	PrestigeCount: number,
}

export type Statistics = {
	LifetimeCredits: number,
	AsteroidsMined: number,
	ResourcesCollected: number,
	RareFound: number,
}

export type DailyRewards = {
	Day: number,
	LastClaim: number, -- os.time()
}

export type PlayerData = {
	DataVersion: number,
	Currencies: Currencies,
	Ore: { [string]: number }, -- unsold resource inventory
	Progression: Progression,
	Buildings: { [string]: number },
	Drones: { [string]: number },
	Upgrades: { [string]: boolean },
	Statistics: Statistics,
	DailyRewards: DailyRewards,
	LastLogout: number,
}

export type MineResult = {
	DamageDealt: number,
	WasCrit: boolean,
	AsteroidDestroyed: boolean,
	Rewards: { [string]: number },
	CreditsEarned: number, -- 0 for manual mine (ore goes to inventory, sold separately)
}

return {}
