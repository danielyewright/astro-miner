--!strict
-- ASTRO MINER | Server/Services/MapService.luau
-- Builds a minimal playable Lunar Outpost at runtime if the Studio map is
-- empty (which happens when Rojo syncs an empty Workspace).
-- Idempotent: safe to call on every server start.

local Lighting = game:GetService("Lighting")

local MapService = {}

local ROCK_COLORS = {
	Color3.fromRGB(120, 116, 122),
	Color3.fromRGB(139, 109, 78),
	Color3.fromRGB(150, 160, 180),
	Color3.fromRGB(176, 141, 79),
}

function MapService.getRockColor(index: number): Color3
	return ROCK_COLORS[((index - 1) % #ROCK_COLORS) + 1]
end

function MapService.build(): Folder
	-- 1. Space lighting (no external assets, works everywhere).
	Lighting.ClockTime = 0
	Lighting.Brightness = 2
	Lighting.Ambient = Color3.fromRGB(60, 60, 80)
	Lighting.OutdoorAmbient = Color3.fromRGB(20, 20, 40)
	pcall(function()
		Lighting.Atmosphere.Density = 0.3
		Lighting.Atmosphere.Color = Color3.fromRGB(150, 170, 255)
	end)

	-- 2. Ground platform so the player never falls into the void.
	local ground = workspace:FindFirstChild("AstroMinerGround")
	if not ground then
		local g = Instance.new("Part")
		g.Name = "AstroMinerGround"
		g.Size = Vector3.new(200, 2, 200)
		g.Position = Vector3.new(0, 0, -30)
		g.Anchored = true
		g.Color = Color3.fromRGB(35, 38, 50)
		g.Material = Enum.Material.Slate
		g.TopSurface = Enum.SurfaceType.Smooth
		g.Parent = workspace
	end

	-- 3. Spawn pad (uses SpawnLocation so respawns work, not just first spawn).
	local spawn = workspace:FindFirstChild("AstroMinerSpawn")
	if not spawn then
		local s = Instance.new("SpawnLocation")
		s.Name = "AstroMinerSpawn"
		s.Size = Vector3.new(10, 1, 10)
		s.Position = Vector3.new(0, 2, -18)
		s.Anchored = true
		s.Color = Color3.fromRGB(0, 170, 200)
		s.Material = Enum.Material.Neon
		s.TopSurface = Enum.SurfaceType.Smooth
		s.AllowTeamChangeOnTouch = false
		s.Neutral = true
		s.Enabled = true
		s.Parent = workspace
	end

	-- 4. Refinery visual (orientation landmark; selling is via SELL button in MVP).
	local refinery = workspace:FindFirstChild("AstroMinerRefinery")
	if not refinery then
		local r = Instance.new("Part")
		r.Name = "AstroMinerRefinery"
		r.Size = Vector3.new(10, 8, 10)
		r.Position = Vector3.new(14, 5, -18)
		r.Anchored = true
		r.Color = Color3.fromRGB(255, 150, 40)
		r.Material = Enum.Material.Metal
		r.Parent = workspace
		local gui = Instance.new("BillboardGui")
		gui.Size = UDim2.fromOffset(120, 30)
		gui.StudsOffset = Vector3.new(0, 5, 0)
		gui.AlwaysOnTop = true
		gui.Parent = r
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamBold
		label.TextSize = 16
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		label.Text = "⛽ REFINERY (SELL)"
		label.Parent = gui
	end

	-- 5. Player base plots (tycoon row west of spawn; structures appear on purchase).
	MapService.buildBase()

	-- 6. Field folder for asteroids.
	local field = workspace:FindFirstChild("AstroMinerField")
	if not field then
		field = Instance.new("Folder")
		field.Name = "AstroMinerField"
		field.Parent = workspace
	end
	return field :: Folder
end

-- 6 tycoon pads in a 3x2 grid. Idempotent: existing pads are left alone.
-- Positions read from Buildings Order so labels match the shop.
function MapService.buildBase()
	local Buildings = require(game.ReplicatedStorage.Shared.Config.Buildings)
	local base = workspace:FindFirstChild("AstroMinerBase")
	if not base then
		base = Instance.new("Folder")
		base.Name = "AstroMinerBase"
		base.Parent = workspace
	end
	local folder = base :: Folder
	for i, id in ipairs(Buildings.Order) do
		local padName = "Pad_" .. id
		if not folder:FindFirstChild(padName) then
			local def = Buildings.getDef(id)
			assert(def, "missing building def " .. id)
			local col = (i - 1) % 3
			local row = math.floor((i - 1) / 3)
			local pad = Instance.new("Part")
			pad.Name = padName
			pad.Size = Vector3.new(13, 1, 13)
			pad.Position = Vector3.new(-34 + col * 15, 1.5, 2 + row * 15)
			pad.Anchored = true
			pad.Color = Color3.fromRGB(50, 55, 75)
			pad.Material = Enum.Material.Concrete
			pad.TopSurface = Enum.SurfaceType.Smooth
			pad.Parent = folder
			local gui = Instance.new("BillboardGui")
			gui.Size = UDim2.fromOffset(160, 30)
			gui.StudsOffset = Vector3.new(0, 4, 0)
			gui.AlwaysOnTop = true
			gui.Parent = pad
			local label = Instance.new("TextLabel")
			label.Name = "PadLabel"
			label.Size = UDim2.new(1, 0, 1, 0)
			label.BackgroundTransparency = 1
			label.Font = Enum.Font.GothamBold
			label.TextSize = 14
			label.TextColor3 = Color3.fromRGB(180, 190, 210)
			label.Text = def.Name:upper()
			label.Parent = gui
		end
	end
end

-- Shows/hides the structure on a base pad. Cosmetic only.
function MapService.setBuildingVisual(id: string, owned: boolean)
	local base = workspace:FindFirstChild("AstroMinerBase")
	local pad = base and base:FindFirstChild("Pad_" .. id)
	if not pad or not pad:IsA("BasePart") then
		return
	end
	local Buildings = require(game.ReplicatedStorage.Shared.Config.Buildings)
	local existing = pad:FindFirstChild("Structure")
	if owned and not existing then
		local def = Buildings.getDef(id)
		assert(def, "missing building def " .. id)
		local s = Instance.new("Part")
		s.Name = "Structure"
		s.Size = def.Size
		s.Position = pad.Position + Vector3.new(0, 0.5 + def.Size.Y / 2, 0)
		s.Anchored = true
		s.CanCollide = false
		s.Color = def.Color
		s.Material = Enum.Material.Metal
		s.TopSurface = Enum.SurfaceType.Smooth
		s.Parent = pad
	elseif not owned and existing then
		existing:Destroy()
	end
	local label = pad:FindFirstChild("PadLabel", true)
	if label and label:IsA("TextLabel") then
		label.TextColor3 = if owned then Color3.fromRGB(140, 255, 170) else Color3.fromRGB(180, 190, 210)
	end
end

-- Styles one asteroid part as a rock (not a smooth planet) + health bar.
function MapService.styleAsteroid(part: Part, index: number)
	part.Shape = Enum.PartType.Block
	part.Size = Vector3.new(7, 7, 7)
	part.Color = MapService.getRockColor(index)
	part.Material = Enum.Material.Rock
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	-- Slight random tilt so blocks read as asteroids, not cubes.
	part.Orientation = Vector3.new(index * 17 % 45, index * 31 % 90, 0)

	-- Health bar (server-owned so exploiters can't fake it; cosmetic only).
	local old = part:FindFirstChild("HealthGui")
	if old then
		old:Destroy()
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "HealthGui"
	gui.Size = UDim2.fromOffset(100, 14)
	gui.StudsOffset = Vector3.new(0, 5, 0)
	gui.AlwaysOnTop = true
	gui.Parent = part
	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	bg.BorderSizePixel = 0
	bg.Parent = gui
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.new(1, 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
	fill.BorderSizePixel = 0
	fill.Parent = bg
end

function MapService.setAsteroidVisual(part: Part, alive: boolean, healthFrac: number)
	part.Transparency = if alive then 0 else 1
	part.CanCollide = false
	part.CanQuery = alive
	local det = part:FindFirstChildOfClass("ClickDetector")
	if det then
		det.MaxActivationDistance = if alive then 32 else 0
	end
	local gui = part:FindFirstChild("HealthGui")
	local fill = gui and gui:FindFirstChild("Fill", true)
	if fill and fill:IsA("Frame") then
		fill.Size = UDim2.new(math.clamp(healthFrac, 0, 1), 0, 1, 0)
		fill.BackgroundColor3 = if healthFrac > 0.5
			then Color3.fromRGB(0, 200, 100)
			elseif healthFrac > 0.25 then Color3.fromRGB(255, 170, 0)
			else Color3.fromRGB(255, 60, 60)
	end
	local bb = part:FindFirstChild("HealthGui")
	if bb and bb:IsA("BillboardGui") then
		bb.Enabled = alive
	end
end

return MapService
