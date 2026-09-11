--!strict
-- ASTRO MINER | ServerMain (place in ServerScriptService as a Script)
-- Creates RemoteEvents, wires PlayerData/Economy/Mining/Upgrade, spawns MVP field.
-- MVP spawn: Lunar Outpost pad at origin; asteroids ring around (0, 5, -40).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local Constants = require(ReplicatedStorage.Shared.Constants)
local Buildings = require(ReplicatedStorage.Shared.Config.Buildings)
local Services = script.Parent.Services
local PlayerDataService = require(Services.PlayerDataService)
local EconomyService = require(Services.EconomyService)
local MiningService = require(Services.MiningService)
local UpgradeService = require(Services.UpgradeService)
local MapService = require(Services.MapService)
local MissionService = require(Services.MissionService)
local RewardService = require(Services.RewardService)
local OfflineEarningsService = require(Services.OfflineEarningsService)
local PassiveIncomeService = require(Services.PassiveIncomeService)
local DroneService = require(Services.DroneService)
local BuildingService = require(Services.BuildingService)
local PrestigeService = require(Services.PrestigeService)
local BoostService = require(Services.BoostService)
local MonetizationService = require(Services.MonetizationService)
local LeaderboardService = require(Services.LeaderboardService)
local StateService = require(Services.StateService)

local function getOrCreateRemote(name: string, className: string): Instance
	local existing = ReplicatedStorage:FindFirstChild(name)
	if existing then
		return existing
	end
	local resolvedClass: string = if className == "RF" then "RemoteFunction" else "RemoteEvent"
	local r = Instance.new(resolvedClass)
	r.Name = name
	r.Parent = ReplicatedStorage
	return r
end

local remotes = {
	[Constants.REMOTES.Mine] = getOrCreateRemote(Constants.REMOTES.Mine, "RF"),
	[Constants.REMOTES.SellAll] = getOrCreateRemote(Constants.REMOTES.SellAll, "RF"),
	[Constants.REMOTES.BuyEquipment] = getOrCreateRemote(Constants.REMOTES.BuyEquipment, "RF"),
	[Constants.REMOTES.ClaimOffline] = getOrCreateRemote(Constants.REMOTES.ClaimOffline, "RF"),
	[Constants.REMOTES.ClaimDaily] = getOrCreateRemote(Constants.REMOTES.ClaimDaily, "RF"),
	[Constants.REMOTES.ClaimMission] = getOrCreateRemote(Constants.REMOTES.ClaimMission, "RF"),
	[Constants.REMOTES.BuyDrone] = getOrCreateRemote(Constants.REMOTES.BuyDrone, "RF"),
	[Constants.REMOTES.BuyBuilding] = getOrCreateRemote(Constants.REMOTES.BuyBuilding, "RF"),
	[Constants.REMOTES.DoPrestige] = getOrCreateRemote(Constants.REMOTES.DoPrestige, "RF"),
	[Constants.REMOTES.BuyPrestigeUpgrade] = getOrCreateRemote(Constants.REMOTES.BuyPrestigeUpgrade, "RF"),
	[Constants.REMOTES.ShopRefresh] = getOrCreateRemote(Constants.REMOTES.ShopRefresh, "RF"),
	[Constants.REMOTES.Leaderboard] = getOrCreateRemote(Constants.REMOTES.Leaderboard, "RF"),
	[Constants.REMOTES.StateSync] = getOrCreateRemote(Constants.REMOTES.StateSync, "RE"),
	[Constants.REMOTES.Fx] = getOrCreateRemote(Constants.REMOTES.Fx, "RE"),
}
MiningService.bindRemotes(remotes :: any)

-- Build (or repair) the minimal Lunar Outpost map, then spawn the field.
-- MapService is idempotent, so re-syncs never leave a blank void.
local fieldFolder = MapService.build() :: Folder
MiningService.spawnField(Vector3.new(0, 7, -45), 8, 1)

-- Build visible asteroid parts (pooled rock blocks with health bars).
-- Old gray-ball parts from previous versions are wiped so you never see "planets".
for _, child in ipairs(fieldFolder:GetChildren()) do
	child:Destroy()
end
local asteroidParts: { [string]: Part } = {}
local index = 0
for id, ast in pairs(MiningService.Asteroids) do
	index += 1
	local part = Instance.new("Part")
	part.Name = id
	part.Position = ast.Position
	part.Anchored = true
	part.CanCollide = false
	part.Parent = fieldFolder
	MapService.styleAsteroid(part, index)
	MapService.setAsteroidVisual(part, true, 1)
	local detector = Instance.new("ClickDetector")
	detector.MaxActivationDistance = 32
	detector.Parent = part
	asteroidParts[id] = part
end

-- Cheap visual sync (8 parts): skipped entirely while no mining happened.
-- Gameplay truth stays in MiningService; this is cosmetic only.
task.spawn(function()
	local lastRevision = -1
	while true do
		task.wait(0.15)
		if MiningService.Revision == lastRevision then
			continue
		end
		lastRevision = MiningService.Revision
		for id, ast in pairs(MiningService.Asteroids) do
			local part = asteroidParts[id]
			if part and part.Parent then
				local frac = if ast.MaxHealth > 0 then ast.Health / ast.MaxHealth else 0
				MapService.setAsteroidVisual(part, ast.Alive, frac)
				if ast.Alive and part.Transparency ~= 0 then
					part.Position = ast.Position
				end
			end
		end
	end
end)

-- Remote handlers (all validated server-side inside services).
local mineRemote = remotes[Constants.REMOTES.Mine] :: RemoteFunction
mineRemote.OnServerInvoke = function(player: Player, asteroidId: unknown)
	local ok, payload = MiningService.mine(player, asteroidId)
	return { ok = ok, data = payload }
end

local sellRemoteFn = remotes[Constants.REMOTES.SellAll] :: RemoteFunction
sellRemoteFn.OnServerInvoke = function(player: Player)
	local earned = EconomyService.sellAll(player)
	if earned > 0 then
		MissionService.onEvent(player, "credits", earned)
	end
	StateService.push(player)
	return { ok = true, data = { earned = earned } }
end

local buyRemoteFn = remotes[Constants.REMOTES.BuyEquipment] :: RemoteFunction
buyRemoteFn.OnServerInvoke = function(player: Player)
	local ok, msg = UpgradeService.buyNextEquipment(player)
	StateService.push(player)
	return { ok = ok, data = { message = msg } }
end

local claimOfflineFn = remotes[Constants.REMOTES.ClaimOffline] :: RemoteFunction
claimOfflineFn.OnServerInvoke = function(player: Player)
	local owed = OfflineEarningsService.claim(player)
	StateService.push(player)
	return { ok = true, data = { claimed = owed } }
end

local claimDailyFn = remotes[Constants.REMOTES.ClaimDaily] :: RemoteFunction
claimDailyFn.OnServerInvoke = function(player: Player)
	local ok, msg = RewardService.claim(player)
	StateService.push(player)
	return { ok = ok, data = { message = msg } }
end

local claimMissionFn = remotes[Constants.REMOTES.ClaimMission] :: RemoteFunction
claimMissionFn.OnServerInvoke = function(player: Player, defId: unknown)
	local ok, msg = MissionService.claim(player, defId)
	StateService.push(player)
	return { ok = ok, data = { message = msg } }
end

local buyDroneFn = remotes[Constants.REMOTES.BuyDrone] :: RemoteFunction
buyDroneFn.OnServerInvoke = function(player: Player, droneId: unknown)
	local ok, msg = DroneService.buy(player, droneId)
	StateService.push(player)
	return { ok = ok, data = { message = msg } }
end

local buyBuildingFn = remotes[Constants.REMOTES.BuyBuilding] :: RemoteFunction
buyBuildingFn.OnServerInvoke = function(player: Player, buildingId: unknown)
	local ok, msg = BuildingService.buy(player, buildingId)
	StateService.push(player)
	return { ok = ok, data = { message = msg } }
end

local doPrestigeFn = remotes[Constants.REMOTES.DoPrestige] :: RemoteFunction
doPrestigeFn.OnServerInvoke = function(player: Player)
	local earned = PrestigeService.reset(player)
	if earned > 0 then
		OfflineEarningsService.clear(player)
		MissionService.ensure(player)
		for _, id in ipairs(Buildings.Order) do
			MapService.setBuildingVisual(id, false)
		end
		DroneService.refreshVisuals(player)
	end
	StateService.push(player)
	return { ok = earned > 0, data = { earned = earned } }
end

local buyPrestigeFn = remotes[Constants.REMOTES.BuyPrestigeUpgrade] :: RemoteFunction
buyPrestigeFn.OnServerInvoke = function(player: Player, branchId: unknown, tierIdx: unknown)
	local ok, msg = PrestigeService.buyUpgrade(player, branchId, tierIdx)
	StateService.push(player)
	return { ok = ok, data = { message = msg } }
end

local shopRefreshFn = remotes[Constants.REMOTES.ShopRefresh] :: RemoteFunction
shopRefreshFn.OnServerInvoke = function(player: Player)
	MonetizationService.refresh(player)
	StateService.push(player)
	return { ok = true, data = {} }
end

local leaderboardFn = remotes[Constants.REMOTES.Leaderboard] :: RemoteFunction
leaderboardFn.OnServerInvoke = function(_player: Player, boardKey: unknown)
	if typeof(boardKey) ~= "string" then
		return { ok = false, data = {} }
	end
	return { ok = true, data = { boards = LeaderboardService.defs(), entries = LeaderboardService.top(boardKey) } }
end

-- Developer product receipts: grant here (Economy/Boost), never trust client.
MarketplaceService.ProcessReceipt = function(receipt)
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local action = MonetizationService.actionForProduct(receipt.ProductId)
	if not action then
		return Enum.ProductPurchaseDecision.Processed -- unknown: ack, don't clog queue
	end
	if action.credits > 0 then
		EconomyService.addCredits(player, action.credits)
	end
	if action.stardust > 0 then
		local data = PlayerDataService.get(player)
		if data then
			data.Currencies.Stardust = math.min(data.Currencies.Stardust + action.stardust, 9e12)
		end
	end
	if action.boostId then
		BoostService.grant(player, action.boostId, action.boostMinutes)
	end
	StateService.push(player)
	return Enum.ProductPurchaseDecision.Processed
end

-- Lifecycle: load on join, save on leave + autosave.
local function onJoin(player: Player)
	PlayerDataService.load(player)
	MissionService.ensure(player)
	-- Offline earnings computed AFTER load (uses LastLogout from previous session).
	OfflineEarningsService.computeOnJoin(player)
	BuildingService.restoreVisuals(player)
	DroneService.onJoin(player)
	MonetizationService.refresh(player)
	-- Spawn on the cyan pad (SpawnLocation handles respawns; this covers first spawn).
	player.CharacterAdded:Connect(function(char)
		task.defer(function()
			local root = char:WaitForChild("HumanoidRootPart", 5)
			local spawn = workspace:FindFirstChild("AstroMinerSpawn")
			local dest = if spawn and spawn:IsA("BasePart")
				then spawn.Position + Vector3.new(0, 4, 0)
				else Vector3.new(0, 6, -18)
			if root and root:IsA("BasePart") then
				root.CFrame = CFrame.new(dest)
			end
		end)
	end)
	player:LoadCharacter()
	StateService.push(player)
end

Players.PlayerAdded:Connect(onJoin)
-- Play Solo race: PlayerAdded may have fired before this script ran.
for _, existing in ipairs(Players:GetPlayers()) do
	task.spawn(onJoin, existing)
end
Players.PlayerRemoving:Connect(function(player)
	LeaderboardService.submit(player, true)
	PlayerDataService.save(player)
	PlayerDataService.remove(player)
	OfflineEarningsService.clear(player)
	MonetizationService.clear(player)
	LeaderboardService.clear(player)
	DroneService.onLeave(player)
end)
game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		PlayerDataService.save(player)
	end
end)

PlayerDataService.startAutosave()
task.spawn(function()
	while true do
		task.wait(120)
		LeaderboardService.submitAll()
	end
end)
PassiveIncomeService.start(StateService.push)
DroneService.startOrbit()
task.spawn(function()
	DroneService.tickAll(StateService.push)
end)
-- Auto-Mine gamepass: server performs the owner's manual swing on cooldown.
task.spawn(function()
	while true do
		task.wait(1)
		for _, player in ipairs(Players:GetPlayers()) do
			if MonetizationService.hasAutoMine(player) then
				local char = player.Character
				local root = char and char:FindFirstChild("HumanoidRootPart")
				if root and root:IsA("BasePart") then
					local best, bestDist = nil, Constants.MAX_MINE_DISTANCE + 20
					for id, ast in pairs(MiningService.Asteroids) do
						if ast.Alive then
							local d = (root.Position - ast.Position).Magnitude
							if d < bestDist then
								best, bestDist = id, d
							end
						end
					end
					if best then
						pcall(function()
							MiningService.mine(player, best)
						end)
					end
				end
			end
		end
	end
end)
print("[AstroMiner] ServerMain ready. MVP field spawned.")
