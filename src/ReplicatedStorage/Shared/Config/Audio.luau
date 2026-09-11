--!strict
-- ASTRO MINER | Shared/Config/Audio.luau
-- Phase 11 (Spec §28). IDs are 0 until real audio is sourced; AudioController
-- treats 0 as silent so the game plays fine with zero audio configured.
-- When adding sounds: short (<2s) hits, distinct rare/prestige stingers,
-- ambient loop kept quiet. Avoid constant background noise.

export type SoundDef = {
	Id: number, -- rbxassetid, 0 = silent placeholder
	Volume: number, -- 0..1
	PitchBase: number,
	PitchVariance: number, -- +/- random for hit variety
}

local Sounds: { [string]: SoundDef } = {
	Hit = { Id = 0, Volume = 0.5, PitchBase = 1, PitchVariance = 0.15 },
	Crit = { Id = 0, Volume = 0.7, PitchBase = 1.3, PitchVariance = 0.1 },
	Destroy = { Id = 0, Volume = 0.8, PitchBase = 0.9, PitchVariance = 0.1 },
	Rare = { Id = 0, Volume = 0.8, PitchBase = 1.2, PitchVariance = 0.05 },
	Purchase = { Id = 0, Volume = 0.6, PitchBase = 1.1, PitchVariance = 0.05 },
	Achievement = { Id = 0, Volume = 0.7, PitchBase = 1, PitchVariance = 0.05 },
	Prestige = { Id = 0, Volume = 0.9, PitchBase = 0.8, PitchVariance = 0 },
	Daily = { Id = 0, Volume = 0.6, PitchBase = 1.2, PitchVariance = 0.05 },
	Ambient = { Id = 0, Volume = 0.25, PitchBase = 1, PitchVariance = 0 },
}

local function getDef(key: string): SoundDef?
	return Sounds[key]
end

return {
	Sounds = Sounds,
	getDef = getDef,
}
