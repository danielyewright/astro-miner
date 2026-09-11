--!strict
-- ASTRO MINER | Server/Services/RewardService.luau
-- 7-day daily login cycle (Spec §18). Claimable once per calendar day
-- (20h minimum gap to be timezone-forgiving). Advances Day 1..7, wraps.

local DailyRewards = require(game.ReplicatedStorage.Shared.Config.DailyRewards)
local PlayerDataService = require(script.Parent.PlayerDataService)
local EconomyService = require(script.Parent.EconomyService)
local MonetizationService = require(script.Parent.MonetizationService)

local RewardService = {}

local CLAIM_GAP = 20 * 3600

function RewardService.canClaim(player: Player): boolean
	local data = PlayerDataService.get(player)
	if not data then
		return false
	end
	return (os.time() - (data.DailyRewards.LastClaim or 0)) >= CLAIM_GAP
end

function RewardService.currentDay(player: Player): number
	local data = PlayerDataService.get(player)
	if not data then
		return 1
	end
	return data.DailyRewards.Day or 1
end

-- Returns: ok, rewardTitle
function RewardService.claim(player: Player): (boolean, string)
	local data = PlayerDataService.get(player)
	if not data then
		return false, "no-profile"
	end
	if not RewardService.canClaim(player) then
		return false, "already-claimed"
	end
	local def = DailyRewards.getDef(data.DailyRewards.Day or 1)
	local vipMult = if MonetizationService.isVIP(player) then 2 else 1
	if def.Credits > 0 then
		EconomyService.addCredits(player, def.Credits * vipMult)
	end
	if def.Stardust > 0 then
		data.Currencies.Stardust = math.min(data.Currencies.Stardust + def.Stardust * vipMult, 9e12)
	end
	data.DailyRewards.LastClaim = os.time()
	data.Statistics.TotalDailyClaims += 1
	local claimedDay = data.DailyRewards.Day or 1
	data.DailyRewards.Day = (claimedDay % 7) + 1
	return true, def.Title
end

return RewardService
