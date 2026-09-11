--!strict
-- ASTRO MINER | Shared/Config/Missions.luau
-- Daily missions (Spec §19). Kinds: "asteroid" | "rare" | "credits" | "upgrade".
-- Targets tuned for MVP session lengths (much smaller than endgame spec numbers).

export type MissionDef = {
	Id: string,
	Name: string,
	Kind: string,
	Target: number,
	Credits: number,
	Stardust: number,
}

local Templates: { MissionDef } = {
	{ Id = "mine_25", Name = "Mine 25 asteroids", Kind = "asteroid", Target = 25, Credits = 10000, Stardust = 0 },
	{ Id = "earn_10k", Name = "Earn 10,000 credits", Kind = "credits", Target = 10000, Credits = 5000, Stardust = 0 },
	{ Id = "upg_1", Name = "Buy 1 equipment upgrade", Kind = "upgrade", Target = 1, Credits = 5000, Stardust = 2 },
	{ Id = "rare_3", Name = "Find 3 rare resources", Kind = "rare", Target = 3, Credits = 25000, Stardust = 3 },
	{ Id = "drones_2", Name = "Own 2 drones", Kind = "drones", Target = 2, Credits = 20000, Stardust = 2 },
}

-- Deterministic daily rotation: 3 missions per day from templates.
local function forDate(dateStr: string): { MissionDef }
	local h = 0
	for i = 1, #dateStr do
		h = (h * 31 + string.byte(dateStr, i)) % 1000003
	end
	local out: { MissionDef } = {}
	for k = 1, 3 do
		table.insert(out, Templates[((h + k - 1) % #Templates) + 1])
	end
	return out
end

return {
	Templates = Templates,
	forDate = forDate,
}
