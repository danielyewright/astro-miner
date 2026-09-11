--!strict
-- ASTRO MINER | Server/Services/StateService.luau
-- Single place that builds the StateSync payload (credits, ore, equipment,
-- dailies, missions, offline pending). All push call sites use this.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Shared.Constants)
local DailyRewards = require(ReplicatedStorage.Shared.Config.DailyRewards)
local Drones = require(ReplicatedStorage.Shared.Config.Drones)
local Buildings = require(ReplicatedStorage.Shared.Config.Buildings)
local Monetization = require(ReplicatedStorage.Shared.Config.Monetization)
local PlayerDataService = require(script.Parent.PlayerDataService)
local OfflineEarningsService = require(script.Parent.OfflineEarningsService)
local RewardService = require(script.Parent.RewardService)
local MissionService = require(script.Parent.MissionService)
local DroneService = require(script.Parent.DroneService)
local BuildingService = require(script.Parent.BuildingService)
local PrestigeService = require(script.Parent.PrestigeService)
local MonetizationService = require(script.Parent.MonetizationService)
local BoostService = require(script.Parent.BoostService)
local AchievementService = require(script.Parent.AchievementService)
local Achievements = require(ReplicatedStorage.Shared.Config.Achievements)

local StateService = {}

function StateService.build(player: Player): any
	local data = PlayerDataService.get(player)
	if not data then
		return nil
	end
	local day = RewardService.currentDay(player)
	local droneList: { any } = {}
	for _, id in ipairs(Drones.Order) do
		local def = Drones.getDef(id)
		if def then
			table.insert(droneList, {
				id = def.Id,
				name = def.Name,
				rarity = def.Rarity,
				cost = def.Cost,
				orePerSec = def.OrePerSec,
				owned = (data.Drones[id] or 0),
			})
		end
	end
	local buildingList: { any } = {}
	for _, id in ipairs(Buildings.Order) do
		local def = Buildings.getDef(id)
		if def then
			table.insert(buildingList, {
				id = def.Id,
				name = def.Name,
				cost = def.Cost,
				owned = (data.Buildings[id] or 0) > 0,
				description = def.Description,
			})
		end
	end
	return {
		credits = data.Currencies.Credits,
		stardust = data.Currencies.Stardust,
		ore = table.clone(data.Ore),
		equipment = data.Progression.EquipmentLevel,
		stats = table.clone(data.Statistics),
		daily = {
			day = day,
			canClaim = RewardService.canClaim(player),
			title = DailyRewards.getDef(day).Title,
		},
		missions = MissionService.view(player),
		offlinePending = OfflineEarningsService.peek(player),
		drones = {
			owned = table.clone(data.Drones),
			capacity = DroneService.capacity(player),
			totalPerSec = DroneService.orePerSec(player),
			catalog = droneList,
		},
		buildings = buildingList,
		prestige = PrestigeService.view(player),
		shop = StateService.shopView(player),
		achievements = {
			count = AchievementService.ownedCount(player),
			total = #Achievements.Definitions,
			newly = {},
		},
	}
end

function StateService.push(player: Player)
	local sync = ReplicatedStorage:FindFirstChild(Constants.REMOTES.StateSync)
	if sync and sync:IsA("RemoteEvent") then
		-- Achievements grant first so the payload reflects rewards + missions.
		local newly = AchievementService.checkAndGrant(player)
		local payload = StateService.build(player)
		if payload then
			payload.achievements.newly = newly
			sync:FireClient(player, payload)
		end
	end
end

-- Shop shelf: pass ownership, configured IDs, and live boost timers.
function StateService.shopView(player: Player): any
	local passes: { any } = {}
	for _, p in ipairs(Monetization.Passes) do
		table.insert(passes, {
			key = p.Key,
			name = p.Name,
			description = p.Description,
			assetId = p.AssetId,
			owned = MonetizationService.has(player, p.Key),
		})
	end
	local products: { any } = {}
	for _, p in ipairs(Monetization.Products) do
		table.insert(products, {
			key = p.Key,
			name = p.Name,
			assetId = p.AssetId,
		})
	end
	local boosts: { any } = {}
	for _, b in ipairs(Monetization.Boosts) do
		local left = BoostService.remaining(player, b.Id)
		if left > 0 then
			table.insert(boosts, { id = b.Id, name = b.Name, remaining = left })
		end
	end
	return {
		configured = MonetizationService.configured(),
		passes = passes,
		products = products,
		boosts = boosts,
	}
end

return StateService
