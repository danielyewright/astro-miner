--!strict
-- ASTRO MINER | Shared/Config/Prestige.luau
-- COSMIC RESET (Spec §16-17). Threshold in run-credits; stardust scales with
-- sqrt so early resets are reachable and deep runs pay off without exploding.

export type PrestigeTier = {
	Bonus: number, -- additive: damage/drone/sell/offline mult, or rare pp
	Cost: number, -- stardust
}

export type PrestigeBranch = {
	Id: string,
	Name: string,
	Description: string,
	Tiers: { PrestigeTier },
}

local Threshold = 1000000 -- run credits needed for first reset

local function stardustFor(runCredits: number): number
	if runCredits < Threshold then
		return 0
	end
	return math.floor(25 * math.sqrt(runCredits / Threshold))
end

local Branches: { PrestigeBranch } = {
	{
		Id = "Mining",
		Name = "Mining",
		Description = "+manual damage",
		Tiers = {
			{ Bonus = 0.10, Cost = 10 },
			{ Bonus = 0.25, Cost = 30 },
			{ Bonus = 0.50, Cost = 75 },
		},
	},
	{
		Id = "Automation",
		Name = "Automation",
		Description = "+drone output",
		Tiers = {
			{ Bonus = 0.10, Cost = 10 },
			{ Bonus = 0.25, Cost = 30 },
			{ Bonus = 0.50, Cost = 75 },
		},
	},
	{
		Id = "Fortune",
		Name = "Fortune",
		Description = "+rare chance",
		Tiers = {
			{ Bonus = 0.01, Cost = 10 },
			{ Bonus = 0.02, Cost = 30 },
			{ Bonus = 0.03, Cost = 75 },
		},
	},
	{
		Id = "Logistics",
		Name = "Logistics",
		Description = "+sell value",
		Tiers = {
			{ Bonus = 0.10, Cost = 10 },
			{ Bonus = 0.25, Cost = 30 },
			{ Bonus = 0.50, Cost = 75 },
		},
	},
	{
		Id = "Offline",
		Name = "Offline",
		Description = "+offline earnings",
		Tiers = {
			{ Bonus = 0.10, Cost = 10 },
			{ Bonus = 0.25, Cost = 30 },
			{ Bonus = 0.50, Cost = 75 },
		},
	},
}

local function getBranch(id: string): PrestigeBranch?
	for _, b in ipairs(Branches) do
		if b.Id == id then
			return b
		end
	end
	return nil
end

return {
	Threshold = Threshold,
	stardustFor = stardustFor,
	Branches = Branches,
	getBranch = getBranch,
}
