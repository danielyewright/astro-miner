--!strict
-- ASTRO MINER | Shared/Config/Buildings.luau
-- Lunar Outpost tycoon track (Spec §14). Single-purchase structures that
-- visibly grow the base + add passive credits/sec and drone capacity.

export type BuildingDef = {
	Id: string,
	Name: string,
	Cost: number,
	CreditsPerSec: number,
	DroneCapacity: number,
	Description: string,
	Color: Color3,
	Size: Vector3,
}

local Buildings: { [string]: BuildingDef } = {
	StorageContainer = {
		Id = "StorageContainer",
		Name = "Storage Container",
		Cost = 100,
		CreditsPerSec = 2,
		DroneCapacity = 0,
		Description = "+2/s passive",
		Color = Color3.fromRGB(90, 140, 90),
		Size = Vector3.new(6, 4, 6),
	},
	DrillRig = {
		Id = "DrillRig",
		Name = "Basic Drill Rig",
		Cost = 500,
		CreditsPerSec = 5,
		DroneCapacity = 0,
		Description = "+5/s passive",
		Color = Color3.fromRGB(140, 110, 70),
		Size = Vector3.new(6, 8, 6),
	},
	Refinery = {
		Id = "Refinery",
		Name = "Refinery",
		Cost = 2500,
		CreditsPerSec = 15,
		DroneCapacity = 0,
		Description = "+15/s passive",
		Color = Color3.fromRGB(200, 120, 50),
		Size = Vector3.new(8, 8, 8),
	},
	DroneBay = {
		Id = "DroneBay",
		Name = "Drone Bay",
		Cost = 10000,
		CreditsPerSec = 10,
		DroneCapacity = 3,
		Description = "+3 drone slots, +10/s",
		Color = Color3.fromRGB(60, 120, 200),
		Size = Vector3.new(10, 6, 10),
	},
	AdvancedRefinery = {
		Id = "AdvancedRefinery",
		Name = "Advanced Refinery",
		Cost = 50000,
		CreditsPerSec = 100,
		DroneCapacity = 0,
		Description = "+100/s passive",
		Color = Color3.fromRGB(200, 80, 200),
		Size = Vector3.new(10, 12, 10),
	},
	CommandCenter = {
		Id = "CommandCenter",
		Name = "Command Center",
		Cost = 250000,
		CreditsPerSec = 500,
		DroneCapacity = 2,
		Description = "+2 drone slots, +500/s",
		Color = Color3.fromRGB(240, 240, 255),
		Size = Vector3.new(12, 14, 12),
	},
}

local Order: { string } = {
	"StorageContainer",
	"DrillRig",
	"Refinery",
	"DroneBay",
	"AdvancedRefinery",
	"CommandCenter",
}

local function getDef(id: string): BuildingDef?
	return Buildings[id]
end

return {
	Definitions = Buildings,
	Order = Order,
	getDef = getDef,
}
