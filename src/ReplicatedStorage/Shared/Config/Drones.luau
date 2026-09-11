--!strict
-- ASTRO MINER | Shared/Config/Drones.luau
-- Collectible automation (Spec §8-9). MVP: 6 variants, Common → Legendary.
-- Mythic reserved. OrePerSec deposits zone-weighted ore into inventory;
-- selling stays manual so the core loop remains intact.

export type DroneDef = {
	Id: string,
	Name: string,
	Rarity: string,
	Cost: number,
	OrePerSec: number,
	Color: Color3,
}

local Drones: { [string]: DroneDef } = {
	RustyBot = {
		Id = "RustyBot",
		Name = "Rusty Bot",
		Rarity = "Common",
		Cost = 500,
		OrePerSec = 2,
		Color = Color3.fromRGB(150, 150, 150),
	},
	IronWasp = {
		Id = "IronWasp",
		Name = "Iron Wasp",
		Rarity = "Common",
		Cost = 2000,
		OrePerSec = 6,
		Color = Color3.fromRGB(200, 120, 70),
	},
	TitaniumHawk = {
		Id = "TitaniumHawk",
		Name = "Titanium Hawk",
		Rarity = "Uncommon",
		Cost = 8000,
		OrePerSec = 18,
		Color = Color3.fromRGB(170, 200, 230),
	},
	GoldStriker = {
		Id = "GoldStriker",
		Name = "Gold Striker",
		Rarity = "Rare",
		Cost = 30000,
		OrePerSec = 60,
		Color = Color3.fromRGB(255, 200, 50),
	},
	PlatinumVanguard = {
		Id = "PlatinumVanguard",
		Name = "Platinum Vanguard",
		Rarity = "Epic",
		Cost = 150000,
		OrePerSec = 250,
		Color = Color3.fromRGB(220, 230, 255),
	},
	QuantumWraith = {
		Id = "QuantumWraith",
		Name = "Quantum Wraith",
		Rarity = "Legendary",
		Cost = 800000,
		OrePerSec = 1200,
		Color = Color3.fromRGB(190, 120, 255),
	},
}

local Order: { string } = {
	"RustyBot",
	"IronWasp",
	"TitaniumHawk",
	"GoldStriker",
	"PlatinumVanguard",
	"QuantumWraith",
}

local BASE_CAPACITY = 2
local MAX_VISUAL = 5 -- max physical drone parts shown per player (perf)

local function getDef(id: string): DroneDef?
	return Drones[id]
end

return {
	Definitions = Drones,
	Order = Order,
	BaseCapacity = BASE_CAPACITY,
	MaxVisual = MAX_VISUAL,
	getDef = getDef,
}
