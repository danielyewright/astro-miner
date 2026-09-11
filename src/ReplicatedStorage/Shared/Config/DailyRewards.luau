--!strict
-- ASTRO MINER | Shared/Config/DailyRewards.luau
-- 7-day cycle (Spec §18). MVP grants Credits/Stardust only; drone/boost
-- rewards resolve to credit equivalents until those systems exist (see Note).

export type DailyRewardDef = {
	Day: number,
	Title: string,
	Credits: number,
	Stardust: number,
	Note: string?, -- future hook, e.g. "GoldenDrone when capsules exist"
}

local DailyRewards: { [number]: DailyRewardDef } = {
	[1] = { Day = 1, Title = "$5,000 Credits", Credits = 5000, Stardust = 0 },
	[2] = { Day = 2, Title = "Mining Boost Cache", Credits = 15000, Stardust = 0, Note = "Becomes 15-min 2x boost" },
	[3] = { Day = 3, Title = "Drone Parts", Credits = 30000, Stardust = 0, Note = "Becomes drone upgrade" },
	[4] = { Day = 4, Title = "$100,000 Credits", Credits = 100000, Stardust = 0 },
	[5] = { Day = 5, Title = "Rare Find", Credits = 150000, Stardust = 2, Note = "Becomes rare drone capsule" },
	[6] = { Day = 6, Title = "Stardust Cache", Credits = 0, Stardust = 10 },
	[7] = { Day = 7, Title = "Golden Haul", Credits = 500000, Stardust = 25, Note = "Becomes Golden Drone" },
}

local function getDef(day: number): DailyRewardDef
	return DailyRewards[((day - 1) % 7) + 1]
end

return {
	Definitions = DailyRewards,
	getDef = getDef,
}
