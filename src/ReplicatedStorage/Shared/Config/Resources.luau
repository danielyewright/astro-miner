--!strict
-- ASTRO MINER | Shared/Config/Resources.luau
-- Single source of truth for ore tiers. MVP: Stone, Iron, Titanium, Gold.
-- Design ref: Spec §5. Full 8-tier table included but only first 4 enabled in Zone 1.

export type ResourceDef = {
	Id: string,
	DisplayName: string,
	Tier: number,
	Value: number, -- credits per unit when sold (base, before multipliers)
	Color: Color3,
	EnabledInMVP: boolean,
}

local Resources: { [string]: ResourceDef } = {
	Stone = {
		Id = "Stone",
		DisplayName = "Stone",
		Tier = 1,
		Value = 1,
		Color = Color3.fromRGB(150, 150, 150),
		EnabledInMVP = true,
	},
	Iron = {
		Id = "Iron",
		DisplayName = "Iron",
		Tier = 2,
		Value = 3,
		Color = Color3.fromRGB(200, 120, 70),
		EnabledInMVP = true,
	},
	Titanium = {
		Id = "Titanium",
		DisplayName = "Titanium",
		Tier = 3,
		Value = 10,
		Color = Color3.fromRGB(170, 200, 230),
		EnabledInMVP = true,
	},
	Gold = {
		Id = "Gold",
		DisplayName = "Gold",
		Tier = 4,
		Value = 35,
		Color = Color3.fromRGB(255, 200, 50),
		EnabledInMVP = true,
	},
	Platinum = {
		Id = "Platinum",
		DisplayName = "Platinum",
		Tier = 5,
		Value = 100,
		Color = Color3.fromRGB(220, 230, 255),
		EnabledInMVP = false,
	},
	Diamond = {
		Id = "Diamond",
		DisplayName = "Diamond",
		Tier = 6,
		Value = 500,
		Color = Color3.fromRGB(120, 230, 255),
		EnabledInMVP = false,
	},
	Uranium = {
		Id = "Uranium",
		DisplayName = "Uranium",
		Tier = 7,
		Value = 2500,
		Color = Color3.fromRGB(120, 255, 120),
		EnabledInMVP = false,
	},
	AlienCrystal = {
		Id = "AlienCrystal",
		DisplayName = "Alien Crystal",
		Tier = 8,
		Value = 15000,
		Color = Color3.fromRGB(190, 120, 255),
		EnabledInMVP = false,
	},
}

-- Deterministic ordering for loot rolls / UI.
local TierOrder: { string } = {
	"Stone",
	"Iron",
	"Titanium",
	"Gold",
	"Platinum",
	"Diamond",
	"Uranium",
	"AlienCrystal",
}

local function getTierOrder(): { string }
	return TierOrder
end

return {
	Definitions = Resources,
	TierOrder = getTierOrder,
}
