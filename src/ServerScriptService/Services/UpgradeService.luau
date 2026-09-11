--!strict
-- ASTRO MINER | Server/Services/UpgradeService.luau (Milestone 2 stub -> functional)
-- Equipment purchases only. Server validates cost + level sequence.

local Equipment = require(game.ReplicatedStorage.Shared.Config.Equipment)
local PlayerDataService = require(script.Parent.PlayerDataService)
local EconomyService = require(script.Parent.EconomyService)
local MissionService = require(script.Parent.MissionService)

local UpgradeService = {}

function UpgradeService.buyNextEquipment(player: Player): (boolean, string)
	local data = PlayerDataService.get(player)
	if not data then
		return false, "no-profile"
	end
	local nextLevel = data.Progression.EquipmentLevel + 1
	if nextLevel > Equipment.MaxLevel then
		return false, "max-level"
	end
	local def = Equipment.getDef(nextLevel)
	assert(def, "missing equipment def")
	if data.Currencies.Credits < def.Cost then
		return false, "insufficient-funds"
	end
	local spent = EconomyService.spendCredits(player, def.Cost)
	if not spent then
		return false, "insufficient-funds"
	end
	data.Progression.EquipmentLevel = nextLevel
	MissionService.onEvent(player, "upgrade", 1)
	return true, def.Name
end

return UpgradeService
