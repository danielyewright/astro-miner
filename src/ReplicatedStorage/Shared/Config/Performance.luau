--!strict
-- ASTRO MINER | Shared/Config/Performance.luau
-- Phase 12 budgets (Spec §30). Mobile-first: pooled + capped FX, no physics
-- debris, server loops consolidated where cheap to do so.

return {
	MaxFxLabels = 24, -- floating-text pool cap (oldest reused)
	MaxSounds = 8, -- concurrent 2D sound pool
	MaxDebrisParts = 12, -- fading rock-chunk pool
	MaxShockwaves = 4, -- expanding ring pool
	ClientMineGuard = 0.25, -- min seconds between client mine requests
	VisualSyncTick = 0.15, -- asteroid health-bar refresh (skipped when clean)
	DroneOrbitTick = 0.2,
}
