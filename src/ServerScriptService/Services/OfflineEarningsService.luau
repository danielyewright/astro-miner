--!strict
-- ASTRO MINER | Server/Services/OfflineEarningsService.luau
-- Spec §15: on join, owed = rate * min(elapsed, 8h). Held as session-only
-- pending until the client shows WELCOME BACK + Collect.

local Passive = require(game.ReplicatedStorage.Shared.Config.Passive)
local PlayerDataService = require(script.Parent.PlayerDataService)
local EconomyService = require(script.Parent.EconomyService)
local PrestigeService = require(script.Parent.PrestigeService)
local MonetizationService = require(script.Parent.MonetizationService)

local OfflineEarningsService = {}
local pending: { [number]: number } = {} -- userId -> owed credits (unclaimed)

function OfflineEarningsService.computeOnJoin(player: Player): number
	local data = PlayerDataService.get(player)
	if not data then
		return 0
	end
	local last = data.LastLogout or 0
	if last <= 0 then
		return 0 -- first session ever: nothing to award
	end
	local elapsed = os.time() - last
	if elapsed < Passive.Config.MinAwaySeconds then
		return 0
	end
	local capped = math.min(elapsed, MonetizationService.offlineCap(player))
	local rate = Passive.rateFor(data.Progression.EquipmentLevel) + Passive.extraFor(player)
	local owed = math.floor(rate * capped * PrestigeService.offlineMultiplier(player) * MonetizationService.offlineMultiplier(player))
	if owed <= 0 then
		return 0
	end
	pending[player.UserId] = owed
	return owed
end

function OfflineEarningsService.peek(player: Player): number
	return pending[player.UserId] or 0
end

-- Single-claim: second call returns 0. Server adds credits, never trusts client.
function OfflineEarningsService.claim(player: Player): number
	local owed = pending[player.UserId] or 0
	if owed <= 0 then
		return 0
	end
	pending[player.UserId] = nil
	EconomyService.addCredits(player, owed)
	return owed
end

function OfflineEarningsService.clear(player: Player)
	pending[player.UserId] = nil
end

return OfflineEarningsService
