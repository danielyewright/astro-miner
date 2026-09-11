--!strict
-- ASTRO MINER | Server/Services/DroneService.luau
-- Automation (Spec §8-9): drones deposit zone-weighted ore every tick.
-- Visuals: up to MaxVisual neon orbiters around the owner's character
-- (personal, cheap, always visible). Field-orbiting is a future art pass.

local Players = game:GetService("Players")

local Drones = require(game.ReplicatedStorage.Shared.Config.Drones)
local Resources = require(game.ReplicatedStorage.Shared.Config.Resources)
local Zones = require(game.ReplicatedStorage.Shared.Config.Zones)
local Passive = require(game.ReplicatedStorage.Shared.Config.Passive)
local PlayerDataService = require(script.Parent.PlayerDataService)
local EconomyService = require(script.Parent.EconomyService)
local MissionService = require(script.Parent.MissionService)
local PrestigeService = require(script.Parent.PrestigeService)
local MonetizationService = require(script.Parent.MonetizationService)
local BuildingService = require(script.Parent.BuildingService)

local DroneService = {}

local TICK_SECONDS = 10
local ZONE_WEIGHTS = { 50, 30, 15, 5 }
local visuals: { [number]: { Part } } = {} -- userId -> orbiter parts

function DroneService.totalOwned(player: Player): number
	local data = PlayerDataService.get(player)
	if not data then
		return 0
	end
	local total = 0
	for _, count in pairs(data.Drones) do
		total += count
	end
	return total
end

function DroneService.capacity(player: Player): number
	return BuildingService.capacityBonus(player) + MonetizationService.capacityBonus(player)
end

function DroneService.orePerSec(player: Player): number
	local data = PlayerDataService.get(player)
	if not data then
		return 0
	end
	local total = 0
	for id, count in pairs(data.Drones) do
		local def = Drones.getDef(id)
		if def and count > 0 then
			total += def.OrePerSec * count
		end
	end
	return math.floor(total * PrestigeService.droneMultiplier(player) * MonetizationService.droneMultiplier(player))
end

-- Weighted average ore value for the player's zone: converts drone ore/sec
-- into a credits/sec equivalent for offline earnings.
function DroneService.offlineRate(player: Player): number
	local data = PlayerDataService.get(player)
	if not data then
		return 0
	end
	local zoneDef = Zones.Definitions[data.Progression.Zone] or Zones.Definitions[1]
	local wTotal, vTotal = 0, 0
	for i, oreId in ipairs(zoneDef.Resources) do
		local def = Resources.Definitions[oreId]
		local w = ZONE_WEIGHTS[math.min(i, #ZONE_WEIGHTS)]
		if def then
			wTotal += w
			vTotal += w * def.Value
		end
	end
	if wTotal <= 0 then
		return 0
	end
	return DroneService.orePerSec(player) * (vTotal / wTotal)
end

-- Returns: ok, message
function DroneService.buy(player: Player, id: unknown): (boolean, string)
	if typeof(id) ~= "string" then
		return false, "bad-request"
	end
	local def = Drones.getDef(id)
	if not def then
		return false, "unknown-drone"
	end
	local data = PlayerDataService.get(player)
	if not data then
		return false, "no-profile"
	end
	if DroneService.totalOwned(player) >= DroneService.capacity(player) then
		return false, "no-capacity"
	end
	if data.Currencies.Credits < def.Cost then
		return false, "insufficient-funds"
	end
	if not EconomyService.spendCredits(player, def.Cost) then
		return false, "insufficient-funds"
	end
	data.Drones[id] = (data.Drones[id] or 0) + 1
	MissionService.onEvent(player, "drones", 1)
	DroneService.refreshVisuals(player)
	return true, def.Name
end

-- Deterministic split of tick output across zone tiers by weight.
function DroneService.tickPlayer(player: Player)
	local perSec = DroneService.orePerSec(player)
	if perSec <= 0 then
		return
	end
	local data = PlayerDataService.get(player)
	if not data then
		return
	end
	local zoneDef = Zones.Definitions[data.Progression.Zone] or Zones.Definitions[1]
	local totalUnits = math.floor(perSec * TICK_SECONDS)
	if totalUnits <= 0 then
		return
	end
	local wTotal = 0
	for i = 1, math.min(#zoneDef.Resources, #ZONE_WEIGHTS) do
		wTotal += ZONE_WEIGHTS[i]
	end
	local rewards: { [string]: number } = {}
	for i, oreId in ipairs(zoneDef.Resources) do
		if i > #ZONE_WEIGHTS then
			break
		end
		local qty = math.floor(totalUnits * ZONE_WEIGHTS[i] / wTotal)
		if qty > 0 then
			rewards[oreId] = qty
		end
	end
	if next(rewards) ~= nil then
		EconomyService.addOre(player, rewards)
	end
end

function DroneService.tickAll(push: (Player) -> ())
	while true do
		task.wait(TICK_SECONDS)
		for _, player in ipairs(Players:GetPlayers()) do
			if DroneService.orePerSec(player) > 0 then
				DroneService.tickPlayer(player)
				push(player)
			end
		end
	end
end

local function droneFolder(userId: number): Folder
	local found = workspace:FindFirstChild("AstroMinerDrones")
	local root: Folder
	if found and found:IsA("Folder") then
		root = found
	else
		root = Instance.new("Folder")
		root.Name = "AstroMinerDrones"
		root.Parent = workspace
	end
	local name = "D_" .. tostring(userId)
	local subFound = root:FindFirstChild(name)
	local sub: Folder
	if subFound and subFound:IsA("Folder") then
		sub = subFound
	else
		sub = Instance.new("Folder")
		sub.Name = name
		sub.Parent = root
	end
	return sub
end

local function richestColor(player: Player): Color3
	local data = PlayerDataService.get(player)
	local best = Drones.Definitions.RustyBot.Color
	local bestCost = 0
	if data then
		for id, count in pairs(data.Drones) do
			local def = Drones.getDef(id)
			if def and count > 0 and def.Cost > bestCost then
				bestCost = def.Cost
				best = def.Color
			end
		end
	end
	return best
end

function DroneService.refreshVisuals(player: Player)
	local folder = droneFolder(player.UserId)
	for _, child in ipairs(folder:GetChildren()) do
		child:Destroy()
	end
	visuals[player.UserId] = {}
	local n = math.min(DroneService.totalOwned(player), Drones.MaxVisual)
	local color = richestColor(player)
	for i = 1, n do
		local p = Instance.new("Part")
		p.Name = "Drone" .. tostring(i)
		p.Shape = Enum.PartType.Ball
		p.Size = Vector3.new(1.5, 1.5, 1.5)
		p.Color = color
		p.Material = Enum.Material.Neon
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.Parent = folder
		table.insert(visuals[player.UserId], p)
	end
end

local function charPos(player: Player): Vector3?
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root.Position
	end
	return nil
end

function DroneService.startOrbit()
	task.spawn(function()
		local t = 0
		while true do
			task.wait(0.2)
			t += 0.2
			for _, player in ipairs(Players:GetPlayers()) do
				local parts = visuals[player.UserId]
				local center = charPos(player)
				if parts and center then
					for i, part in ipairs(parts) do
						if part.Parent then
							local a = t * 1.2 + (i / #parts) * math.pi * 2
							part.Position = center + Vector3.new(math.cos(a) * 6, 3 + math.sin(t * 2 + i) * 0.8, math.sin(a) * 6)
						end
					end
				end
			end
		end
	end)
end

function DroneService.onJoin(player: Player)
	DroneService.refreshVisuals(player)
	-- Returning owners get credit toward "own N drones" missions.
	local total = DroneService.totalOwned(player)
	if total > 0 then
		MissionService.onEvent(player, "drones", total)
	end
end

function DroneService.onLeave(player: Player)
	visuals[player.UserId] = nil
	local root = workspace:FindFirstChild("AstroMinerDrones")
	local sub = root and root:FindFirstChild("D_" .. tostring(player.UserId))
	if sub then
		sub:Destroy()
	end
end

Passive.registerProvider("drones", function(player: Player): number
	return DroneService.offlineRate(player)
end)

Players.PlayerRemoving:Connect(function(player)
	visuals[player.UserId] = nil
end)

return DroneService
