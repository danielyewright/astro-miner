--!strict
-- ASTRO MINER | Shared/Config/Monetization.luau
-- Phase 10 hooks (Spec §22-23) + temporary boosts (§21).
-- IDs are 0 until real assets exist in Creator Dashboard; the shop disables
-- unconfigured entries instead of prompting. NEVER gate core progression.

export type PassDef = {
	Key: string,
	Name: string,
	Description: string,
	AssetId: number, -- gamepass ID, 0 = unconfigured
}

export type ProductDef = {
	Key: string,
	Name: string,
	AssetId: number, -- developer product ID, 0 = unconfigured
	Credits: number,
	Stardust: number,
	BoostId: string?,
	BoostMinutes: number?,
}

export type BoostDef = {
	Id: string,
	Name: string,
	Description: string,
}

local Passes: { PassDef } = {
	{ Key = "TwoXCredits", Name = "2× Credits", Description = "Permanent double credits.", AssetId = 0 },
	{ Key = "VIP", Name = "VIP", Description = "2× daily rewards + tag.", AssetId = 0 },
	{ Key = "AutoMine", Name = "Auto-Mine", Description = "Server mines for you.", AssetId = 0 },
	{ Key = "DroneSlots", Name = "+2 Drone Slots", Description = "Permanent capacity.", AssetId = 0 },
	{ Key = "PremiumOffline", Name = "Premium Offline", Description = "24h offline cap.", AssetId = 0 },
	{ Key = "FasterMining", Name = "Faster Mining", Description = "+25% mining damage.", AssetId = 0 },
}

local Products: { ProductDef } = {
	{ Key = "Credits100K", Name = "100K Credits", AssetId = 0, Credits = 100000, Stardust = 0 },
	{ Key = "Credits1M", Name = "1M Credits", AssetId = 0, Credits = 1000000, Stardust = 0 },
	{ Key = "Credits10M", Name = "10M Credits", AssetId = 0, Credits = 10000000, Stardust = 0 },
	{ Key = "Boost15", Name = "15-min 2× Boost", AssetId = 0, Credits = 0, Stardust = 0, BoostId = "Credits2x", BoostMinutes = 15 },
	{ Key = "Boost30", Name = "30-min 2× Boost", AssetId = 0, Credits = 0, Stardust = 0, BoostId = "Credits2x", BoostMinutes = 30 },
	{ Key = "Stardust25", Name = "25 Stardust", AssetId = 0, Credits = 0, Stardust = 25 },
}

local Boosts: { BoostDef } = {
	{ Id = "Credits2x", Name = "2× Credits", Description = "Double all credit income." },
	{ Id = "Mining2x", Name = "2× Mining", Description = "Double manual damage." },
	{ Id = "Drones2x", Name = "2× Drones", Description = "Double drone output." },
	{ Id = "Luck", Name = "Lucky Scan", Description = "+8% rare chance." },
	{ Id = "Offline2x", Name = "2× Offline", Description = "Double offline earnings." },
}

local function passByKey(key: string): PassDef?
	for _, p in ipairs(Passes) do
		if p.Key == key then
			return p
		end
	end
	return nil
end

local function productByAsset(assetId: number): ProductDef?
	for _, p in ipairs(Products) do
		if p.AssetId ~= 0 and p.AssetId == assetId then
			return p
		end
	end
	return nil
end

return {
	Passes = Passes,
	Products = Products,
	Boosts = Boosts,
	passByKey = passByKey,
	productByAsset = productByAsset,
}
