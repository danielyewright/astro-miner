--!strict
-- ASTRO MINER | Server/Services/AchievementService.luau
-- Checks run inside StateService.push (cheap numeric compares) and auto-grant.
-- Claimed flags live in `data.Upgrades["ACH_<id>"]` — no schema change.

local Achievements = require(game.ReplicatedStorage.Shared.Config.Achievements)
local PlayerDataService = require(script.Parent.PlayerDataService)
local EconomyService = require(script.Parent.EconomyService)
local MissionService = require(script.Parent.MissionService)

local AchievementService = {}

local function flag(id: string): string
	return "ACH_" .. id
end

function AchievementService.ownedCount(player: Player): number
	local data = PlayerDataService.get(player)
	if not data then
		return 0
	end
	local n = 0
	for _, def in ipairs(Achievements.Definitions) do
		if data.Upgrades[flag(def.Id)] then
			n += 1
		end
	end
	return n
end

-- Grants every newly unlocked achievement. Returns granted titles.
function AchievementService.checkAndGrant(player: Player): { string }
	local data = PlayerDataService.get(player)
	if not data then
		return {}
	end
	local newly: { string } = {}
	for _, def in ipairs(Achievements.Definitions) do
		if not data.Upgrades[flag(def.Id)] and Achievements.check(def.Id, data) then
			data.Upgrades[flag(def.Id)] = true
			if def.Credits > 0 then
				EconomyService.addCredits(player, def.Credits)
				MissionService.onEvent(player, "credits", def.Credits)
			end
			if def.Stardust > 0 then
				data.Currencies.Stardust = math.min(data.Currencies.Stardust + def.Stardust, 9e12)
			end
			table.insert(newly, def.Name)
		end
	end
	return newly
end

return AchievementService
