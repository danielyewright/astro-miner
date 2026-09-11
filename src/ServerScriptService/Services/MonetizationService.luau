--!strict
-- ASTRO MINER | Server/Services/MonetizationService.luau
-- Gamepass ownership (cached) + aggregated benefit multipliers.
-- Dependency-light on purpose: PlayerData + Boosts + Config only, so
-- Economy/Mining/Drones can all require this with zero require cycles.
-- Product fulfillment actions are pure data; ServerMain applies them.

local MarketplaceService = game:GetService("MarketplaceService")

local Monetization = require(game.ReplicatedStorage.Shared.Config.Monetization)
local PlayerDataService = require(script.Parent.PlayerDataService)
local BoostService = require(script.Parent.BoostService)

local MonetizationService = {}
local cache: { [number]: { [string]: boolean } } = {}

function MonetizationService.configured(): boolean
	for _, p in ipairs(Monetization.Passes) do
		if p.AssetId ~= 0 then
			return true
		end
	end
	for _, p in ipairs(Monetization.Products) do
		if p.AssetId ~= 0 then
			return true
		end
	end
	return false
end

-- Re-checks ownership with Roblox; safe no-op for unconfigured passes.
function MonetizationService.refresh(player: Player): { [string]: boolean }
	local owned: { [string]: boolean } = cache[player.UserId] or {}
	for _, pass in ipairs(Monetization.Passes) do
		if pass.AssetId ~= 0 then
			local ok, result = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, pass.AssetId)
			end)
			if ok then
				owned[pass.Key] = result
			end
		else
			owned[pass.Key] = false
		end
	end
	cache[player.UserId] = owned
	return owned
end

function MonetizationService.has(player: Player, key: string): boolean
	local owned = cache[player.UserId]
	if owned == nil then
		owned = MonetizationService.refresh(player)
	end
	return owned[key] == true
end

function MonetizationService.clear(player: Player)
	cache[player.UserId] = nil
end

function MonetizationService.creditsMultiplier(player: Player): number
	local m = if MonetizationService.has(player, "TwoXCredits") then 2 else 1
	if BoostService.active(player, "Credits2x") then
		m *= 2
	end
	return m
end

function MonetizationService.damageMultiplier(player: Player): number
	local m = if MonetizationService.has(player, "FasterMining") then 1.25 else 1
	if BoostService.active(player, "Mining2x") then
		m *= 2
	end
	return m
end

function MonetizationService.droneMultiplier(player: Player): number
	return if BoostService.active(player, "Drones2x") then 2 else 1
end

function MonetizationService.rareBonus(player: Player): number
	return if BoostService.active(player, "Luck") then 0.08 else 0
end

function MonetizationService.offlineMultiplier(player: Player): number
	return if BoostService.active(player, "Offline2x") then 2 else 1
end

function MonetizationService.capacityBonus(player: Player): number
	return if MonetizationService.has(player, "DroneSlots") then 2 else 0
end

function MonetizationService.offlineCap(player: Player): number
	return if MonetizationService.has(player, "PremiumOffline") then 24 * 3600 else 8 * 3600
end

function MonetizationService.isVIP(player: Player): boolean
	return MonetizationService.has(player, "VIP")
end

function MonetizationService.hasAutoMine(player: Player): boolean
	return MonetizationService.has(player, "AutoMine")
end

-- Pure lookup: what does this product grant? ServerMain applies + pushes.
function MonetizationService.actionForProduct(assetId: number): any
	local def = Monetization.productByAsset(assetId)
	if not def then
		return nil
	end
	return {
		credits = def.Credits,
		stardust = def.Stardust,
		boostId = def.BoostId,
		boostMinutes = def.BoostMinutes or 0,
		title = def.Name,
	}
end

return MonetizationService
