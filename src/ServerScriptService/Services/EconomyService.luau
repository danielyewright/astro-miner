--!strict
-- ASTRO MINER | Server/Services/EconomyService.luau
-- Server-authoritative credits/ore. Client only requests SellAll; amounts are
-- computed here from Config/Resources values.

local Resources = require(game.ReplicatedStorage.Shared.Config.Resources)
local Zones = require(game.ReplicatedStorage.Shared.Config.Zones)
local PlayerDataService = require(script.Parent.PlayerDataService)
local PrestigeService = require(script.Parent.PrestigeService)
local MonetizationService = require(script.Parent.MonetizationService)

local EconomyService = {}

-- Adds credits. Only callable from server code, never directly from a Remote.
-- Pass/boost multipliers apply here so ALL income respects them.
function EconomyService.addCredits(player: Player, amount: number): number
	local data = PlayerDataService.get(player)
	assert(data, "No profile for " .. player.Name)
	amount = math.floor(amount * MonetizationService.creditsMultiplier(player))
	if amount <= 0 then
		return data.Currencies.Credits
	end
	-- Hard cap guards against overflow bugs/exploits.
	data.Currencies.Credits = math.min(data.Currencies.Credits + amount, 9e18)
	data.Statistics.LifetimeCredits += amount
	data.Statistics.RunCredits += amount
	return data.Currencies.Credits
end

function EconomyService.spendCredits(player: Player, amount: number): boolean
	local data = PlayerDataService.get(player)
	assert(data, "No profile for " .. player.Name)
	amount = math.floor(amount)
	if amount <= 0 then
		return false
	end
	if data.Currencies.Credits < amount then
		return false
	end
	data.Currencies.Credits -= amount
	return true
end

-- Converts ALL unsold ore -> credits using Resources values x zone multiplier.
-- Returns credits earned.
function EconomyService.sellAll(player: Player): number
	local data = PlayerDataService.get(player)
	assert(data, "No profile for " .. player.Name)
	local zoneDef = Zones.Definitions[data.Progression.Zone] or Zones.Definitions[1]
	local earned = 0
	for oreId, qty in pairs(data.Ore) do
		local def = Resources.Definitions[oreId]
		if def and qty > 0 then
			earned += math.floor(qty * def.Value * zoneDef.SellMultiplier)
			data.Ore[oreId] = 0
		end
	end
	if earned > 0 then
		earned = math.floor(earned * PrestigeService.sellMultiplier(player))
		EconomyService.addCredits(player, earned)
	end
	return earned
end

function EconomyService.addOre(player: Player, rewards: { [string]: number })
	local data = PlayerDataService.get(player)
	assert(data, "No profile for " .. player.Name)
	for oreId, qty in pairs(rewards) do
		if Resources.Definitions[oreId] and qty > 0 then
			data.Ore[oreId] = (data.Ore[oreId] or 0) + math.floor(qty)
			data.Statistics.ResourcesCollected += math.floor(qty)
		end
	end
end

return EconomyService
