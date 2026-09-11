--!strict
-- ASTRO MINER | Server/Services/PrestigeService.luau
-- COSMIC RESET (Spec §16): trade run progress for Stardust + permanent
-- multipliers. Wipes credits/ore/equipment/buildings/drones; keeps Stardust,
-- lifetime stats, dailies. Upgrades stored in the `Upgrades` map as
-- "<Branch>_<TierIndex>" (sequential purchase enforced).

local Prestige = require(game.ReplicatedStorage.Shared.Config.Prestige)
local PlayerDataService = require(script.Parent.PlayerDataService)

local PrestigeService = {}

local function key(branchId: string, tierIdx: number): string
	return branchId .. "_" .. tostring(tierIdx)
end

local function branchBonus(data: any, branchId: string): number
	local branch = Prestige.getBranch(branchId)
	if not branch then
		return 0
	end
	local total = 0
	for i, _ in ipairs(branch.Tiers) do
		if data.Upgrades[key(branchId, i)] then
			total += branch.Tiers[i].Bonus
		end
	end
	return total
end

function PrestigeService.damageMultiplier(player: Player): number
	local data = PlayerDataService.get(player)
	return if data then 1 + branchBonus(data, "Mining") else 1
end

function PrestigeService.droneMultiplier(player: Player): number
	local data = PlayerDataService.get(player)
	return if data then 1 + branchBonus(data, "Automation") else 1
end

function PrestigeService.rareBonus(player: Player): number
	local data = PlayerDataService.get(player)
	return if data then branchBonus(data, "Fortune") else 0
end

function PrestigeService.sellMultiplier(player: Player): number
	local data = PlayerDataService.get(player)
	return if data then 1 + branchBonus(data, "Logistics") else 1
end

function PrestigeService.offlineMultiplier(player: Player): number
	local data = PlayerDataService.get(player)
	return if data then 1 + branchBonus(data, "Offline") else 1
end

function PrestigeService.preview(player: Player): number
	local data = PlayerDataService.get(player)
	if not data then
		return 0
	end
	return Prestige.stardustFor(data.Statistics.RunCredits)
end

function PrestigeService.canReset(player: Player): boolean
	local data = PlayerDataService.get(player)
	if not data then
		return false
	end
	return data.Statistics.RunCredits >= Prestige.Threshold
end

-- Full empire wipe except permanent progression. Returns stardust earned (0 = rejected).
function PrestigeService.reset(player: Player): number
	local data = PlayerDataService.get(player)
	if not data then
		return 0
	end
	local earned = Prestige.stardustFor(data.Statistics.RunCredits)
	if earned <= 0 then
		return 0
	end
	data.Currencies.Stardust = math.min(data.Currencies.Stardust + earned, 9e12)
	data.Currencies.Credits = 0
	for k, _ in pairs(data.Ore) do
		data.Ore[k] = 0
	end
	data.Progression.Zone = 1
	data.Progression.EquipmentLevel = 1
	data.Progression.PrestigeCount += 1
	table.clear(data.Buildings)
	table.clear(data.Drones)
	data.Statistics.RunCredits = 0
	data.Missions.Date = "" -- forces fresh missions via ensure()
	return earned
end

-- Returns: ok, message. Tiers must be bought in order.
function PrestigeService.buyUpgrade(player: Player, branchId: unknown, tierIdx: unknown): (boolean, string)
	if typeof(branchId) ~= "string" or typeof(tierIdx) ~= "number" then
		return false, "bad-request"
	end
	local branch = Prestige.getBranch(branchId)
	if not branch then
		return false, "unknown-branch"
	end
	local idx = math.floor(tierIdx)
	if idx < 1 or idx > #branch.Tiers then
		return false, "unknown-tier"
	end
	local data = PlayerDataService.get(player)
	if not data then
		return false, "no-profile"
	end
	if data.Upgrades[key(branchId, idx)] then
		return false, "already-owned"
	end
	if idx > 1 and not data.Upgrades[key(branchId, idx - 1)] then
		return false, "locked"
	end
	local cost = branch.Tiers[idx].Cost
	if data.Currencies.Stardust < cost then
		return false, "insufficient-stardust"
	end
	data.Currencies.Stardust -= cost
	data.Upgrades[key(branchId, idx)] = true
	return true, branch.Name .. " +" .. tostring(math.floor(branch.Tiers[idx].Bonus * 100)) .. "%"
end

-- Client view: threshold progress, preview, owned tiers per branch.
function PrestigeService.view(player: Player): any
	local data = PlayerDataService.get(player)
	if not data then
		return nil
	end
	local branches: { any } = {}
	for _, b in ipairs(Prestige.Branches) do
		local owned = 0
		for i, _ in ipairs(b.Tiers) do
			if data.Upgrades[key(b.Id, i)] then
				owned = i
			else
				break
			end
		end
		table.insert(branches, {
			id = b.Id,
			name = b.Name,
			description = b.Description,
			owned = owned,
			tiers = #b.Tiers,
		})
	end
	return {
		runCredits = data.Statistics.RunCredits,
		threshold = Prestige.Threshold,
		preview = Prestige.stardustFor(data.Statistics.RunCredits),
		canReset = data.Statistics.RunCredits >= Prestige.Threshold,
		count = data.Progression.PrestigeCount,
		stardust = data.Currencies.Stardust,
		branches = branches,
	}
end

return PrestigeService
