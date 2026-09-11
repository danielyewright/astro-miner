--!strict
-- ASTRO MINER | Server/Services/PassiveIncomeService.luau
-- Credits/sec while online; also the rate basis for offline earnings.
-- DroneService (later) adds via Passive.registerProvider("drones", fn).

local Players = game:GetService("Players")

local Passive = require(game.ReplicatedStorage.Shared.Config.Passive)
local PlayerDataService = require(script.Parent.PlayerDataService)
local EconomyService = require(script.Parent.EconomyService)

local PassiveIncomeService = {}

function PassiveIncomeService.rateFor(player: Player): number
	local data = PlayerDataService.get(player)
	if not data then
		return 0
	end
	return Passive.rateFor(data.Progression.EquipmentLevel) + Passive.extraFor(player)
end

function PassiveIncomeService.start(push: (Player) -> ())
	task.spawn(function()
		while true do
			task.wait(Passive.Config.LiveTickSeconds)
			for _, player in ipairs(Players:GetPlayers()) do
				local rate = PassiveIncomeService.rateFor(player)
				if rate > 0 then
					EconomyService.addCredits(player, rate * Passive.Config.LiveTickSeconds)
					push(player)
				end
			end
		end
	end)
end

return PassiveIncomeService
