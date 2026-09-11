--!strict
-- ASTRO MINER | Server/Services/BuildingService.luau
-- Tycoon track (Spec §14): single-purchase structures. Effects are passive
-- credits/sec + drone capacity, registered via Passive.registerProvider.
-- Visuals appear on base pads through MapService (cosmetic only).

local Drones = require(game.ReplicatedStorage.Shared.Config.Drones)
local Buildings = require(game.ReplicatedStorage.Shared.Config.Buildings)
local Passive = require(game.ReplicatedStorage.Shared.Config.Passive)
local PlayerDataService = require(script.Parent.PlayerDataService)
local EconomyService = require(script.Parent.EconomyService)
local MapService = require(script.Parent.MapService)

local BuildingService = {}

function BuildingService.isOwned(player: Player, id: string): boolean
	local data = PlayerDataService.get(player)
	if not data then
		return false
	end
	return (data.Buildings[id] or 0) > 0
end

function BuildingService.passiveRate(player: Player): number
	local data = PlayerDataService.get(player)
	if not data then
		return 0
	end
	local total = 0
	for id, count in pairs(data.Buildings) do
		local def = Buildings.getDef(id)
		if def and count > 0 then
			total += def.CreditsPerSec
		end
	end
	return total
end

function BuildingService.capacityBonus(player: Player): number
	local data = PlayerDataService.get(player)
	if not data then
		return 0
	end
	local total = Drones.BaseCapacity
	for id, count in pairs(data.Buildings) do
		local def = Buildings.getDef(id)
		if def and count > 0 then
			total += def.DroneCapacity
		end
	end
	return total
end

-- Returns: ok, message
function BuildingService.buy(player: Player, id: unknown): (boolean, string)
	if typeof(id) ~= "string" then
		return false, "bad-request"
	end
	local def = Buildings.getDef(id)
	if not def then
		return false, "unknown-building"
	end
	local data = PlayerDataService.get(player)
	if not data then
		return false, "no-profile"
	end
	if (data.Buildings[id] or 0) > 0 then
		return false, "already-owned"
	end
	if data.Currencies.Credits < def.Cost then
		return false, "insufficient-funds"
	end
	if not EconomyService.spendCredits(player, def.Cost) then
		return false, "insufficient-funds"
	end
	data.Buildings[id] = 1
	MapService.setBuildingVisual(id, true)
	return true, def.Name
end

-- Restores pad visuals for a returning player's owned buildings.
function BuildingService.restoreVisuals(player: Player)
	local data = PlayerDataService.get(player)
	if not data then
		return
	end
	for id, count in pairs(data.Buildings) do
		if count > 0 then
			MapService.setBuildingVisual(id, true)
		end
	end
end

Passive.registerProvider("buildings", function(player: Player): number
	return BuildingService.passiveRate(player)
end)

return BuildingService
