--!strict
-- ASTRO MINER | Shared/Constants.luau

return {
	DATA_VERSION = 1,
	DATASTORE_NAME = "AstroMiner_PlayerData_v1",
	AUTOSAVE_INTERVAL = 120, -- seconds

	-- Mining tuning (MVP Zone 1)
	BASE_RARE_CHANCE = 0.02, -- 2% chance an asteroid kill upgrades one drop tier
	MAX_MINE_DISTANCE = 30, -- studs; server distance check
	MINE_RATE_LIMIT = 8, -- max Mine requests per second per player (server-enforced)

	-- Number abbreviation (Spec §4)
	ABBREVIATIONS = { "", "K", "M", "B", "T", "Qa", "Qi" },

	-- Remote names (created at runtime by ServerMain if missing)
	REMOTES = {
		Mine = "RM_Mine",
		SellAll = "RM_SellAll",
		BuyEquipment = "RM_BuyEquipment",
		StateSync = "RM_StateSync", -- server -> client full/incremental sync
		Fx = "RM_Fx", -- server -> client cosmetic event (floating numbers, explosions)
		ClaimOffline = "RM_ClaimOffline",
		ClaimDaily = "RM_ClaimDaily",
		ClaimMission = "RM_ClaimMission",
		BuyDrone = "RM_BuyDrone",
		BuyBuilding = "RM_BuyBuilding",
		DoPrestige = "RM_DoPrestige",
		BuyPrestigeUpgrade = "RM_BuyPrestigeUpgrade",
		ShopRefresh = "RM_ShopRefresh",
		Leaderboard = "RM_Leaderboard",
	},
}
