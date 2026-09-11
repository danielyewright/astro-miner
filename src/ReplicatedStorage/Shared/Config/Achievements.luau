--!strict
-- ASTRO MINER | Shared/Config/Achievements.luau
-- Retention (Spec §39). Auto-granted server-side on unlock; rewards are
-- normal income (mission "earn" credit included). Zone-locked entries arrive
-- with Zone 2 (marked Future).

export type AchievementDef = {
	Id: string,
	Name: string,
	Description: string,
	Credits: number,
	Stardust: number,
}

-- Checks receive the full PlayerData table. Keep them pure + cheap:
-- they run on every state push.
local Checks: { [string]: (data: any) -> boolean } = {
	FirstStrike = function(d) return d.Statistics.AsteroidsMined >= 1 end,
	OreHauler = function(d) return d.Statistics.ResourcesCollected >= 100 end,
	Earner = function(d) return d.Statistics.LifetimeCredits >= 50000 end,
	Millionaire = function(d) return d.Statistics.LifetimeCredits >= 1000000 end,
	SharpTool = function(d) return d.Progression.EquipmentLevel >= 3 end,
	QuantumTouch = function(d) return d.Progression.EquipmentLevel >= 5 end,
	DroneOwner = function(d)
		local n = 0
		for _, c in pairs(d.Drones) do n += c end
		return n >= 1
	end,
	Industrialist = function(d)
		local n = 0
		for _, c in pairs(d.Drones) do n += c end
		return n >= 5
	end,
	Landowner = function(d)
		local n = 0
		for _, c in pairs(d.Buildings) do n += c end
		return n >= 2
	end,
	Tycoon = function(d)
		local n = 0
		for _, c in pairs(d.Buildings) do n += c end
		return n >= 6
	end,
	Lucky7 = function(d) return d.Statistics.RareFound >= 7 end,
	Reborn = function(d) return d.Progression.PrestigeCount >= 1 end,
	Loyal = function(d) return (d.Statistics.TotalDailyClaims or 0) >= 3 end,
}

local Definitions: { AchievementDef } = {
	{ Id = "FirstStrike", Name = "First Strike", Description = "Mine your first asteroid.", Credits = 1000, Stardust = 0 },
	{ Id = "OreHauler", Name = "Ore Hauler", Description = "Collect 100 resources.", Credits = 2000, Stardust = 0 },
	{ Id = "Earner", Name = "Earner", Description = "Earn 50K lifetime credits.", Credits = 5000, Stardust = 0 },
	{ Id = "Millionaire", Name = "Millionaire", Description = "Earn 1M lifetime credits.", Credits = 25000, Stardust = 5 },
	{ Id = "SharpTool", Name = "Sharp Tool", Description = "Reach equipment level 3.", Credits = 10000, Stardust = 0 },
	{ Id = "QuantumTouch", Name = "Quantum Touch", Description = "Reach equipment level 5.", Credits = 100000, Stardust = 0 },
	{ Id = "DroneOwner", Name = "Drone Owner", Description = "Deploy your first drone.", Credits = 5000, Stardust = 0 },
	{ Id = "Industrialist", Name = "Industrialist", Description = "Own 5 drones.", Credits = 25000, Stardust = 0 },
	{ Id = "Landowner", Name = "Landowner", Description = "Own 2 buildings.", Credits = 10000, Stardust = 0 },
	{ Id = "Tycoon", Name = "Tycoon", Description = "Own all 6 base buildings.", Credits = 150000, Stardust = 10 },
	{ Id = "Lucky7", Name = "Lucky Seven", Description = "Find 7 rare resources.", Credits = 30000, Stardust = 0 },
	{ Id = "Reborn", Name = "Reborn", Description = "Perform a Cosmic Reset.", Credits = 0, Stardust = 25 },
	{ Id = "Loyal", Name = "Loyal Miner", Description = "Claim 3 daily rewards.", Credits = 20000, Stardust = 5 },
}

local function check(id: string, data: any): boolean
	local fn = Checks[id]
	if not fn then
		return false
	end
	local ok, result = pcall(fn, data)
	return ok and result == true
end

local function getDef(id: string): AchievementDef?
	for _, d in ipairs(Definitions) do
		if d.Id == id then
			return d
		end
	end
	return nil
end

return {
	Definitions = Definitions,
	check = check,
	getDef = getDef,
}
