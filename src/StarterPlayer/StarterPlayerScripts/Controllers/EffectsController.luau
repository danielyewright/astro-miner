--!strict
-- ASTRO MINER | Controllers/EffectsController.luau
-- Client-side visuals only: floating numbers, beams, shockwaves, debris,
-- hit flash, crit nudge, rare banner. Everything pooled + capped (Spec §30);
-- zero server load. Sounds via AudioController (silent until IDs configured).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local Constants = require(ReplicatedStorage.Shared.Constants)
local Performance = require(ReplicatedStorage.Shared.Config.Performance)
local AudioController = require(script.Parent.AudioController)

local EffectsController = {}

local gui: ScreenGui? = nil
local labelPool: { TextLabel } = {}
local labelGen = 0
local fxFolder: Folder? = nil
local shockPool: { Part } = {}
local debrisPool: { Part } = {}

local function ensureGui(): ScreenGui
	if gui then
		return gui
	end
	local g = Instance.new("ScreenGui")
	g.Name = "AstroMinerFx"
	g.ResetOnSpawn = false
	g.IgnoreGuiInset = true
	g.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	gui = g
	return g
end

local function ensureFolder(): Folder
	if fxFolder then
		return fxFolder
	end
	local f = Instance.new("Folder")
	f.Name = "AstroMinerFxParts"
	f.Parent = workspace
	fxFolder = f
	return f
end

local function getLabel(): TextLabel
	for _, l in ipairs(labelPool) do
		if not l.Visible then
			return l
		end
	end
	if #labelPool < Performance.MaxFxLabels then
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromOffset(140, 32)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamBold
		label.TextSize = 20
		label.TextStrokeTransparency = 0.5
		label.Visible = false
		label.Parent = ensureGui()
		table.insert(labelPool, label)
		return label
	end
	-- Pool full: steal oldest (generation guard kills its stale animation).
	return labelPool[math.random(1, #labelPool)]
end

function EffectsController.floatingText(text: string, color: Color3, big: boolean?)
	local label = getLabel()
	labelGen += 1
	label:SetAttribute("Gen", labelGen)
	local myGen = labelGen
	label.Text = text
	label.TextColor3 = color
	label.TextSize = if big then 26 else 20
	label.TextTransparency = 0
	label.TextStrokeTransparency = 0.5
	local x = 0.5 + (math.random() - 0.5) * 0.12
	label.Position = UDim2.fromScale(x, 0.45)
	label.Visible = true
	task.spawn(function()
		for i = 1, 20 do
			if label:GetAttribute("Gen") ~= myGen then
				return -- stolen by a newer effect
			end
			label.Position += UDim2.fromOffset(0, -2)
			label.TextTransparency = i / 20
			label.TextStrokeTransparency = 0.5 + (i / 20) * 0.5
			task.wait(0.03)
		end
		if label:GetAttribute("Gen") == myGen then
			label.Visible = false
		end
	end)
end

function EffectsController.hitFlash(part: BasePart?)
	if not part then
		return
	end
	task.spawn(function()
		local original = part.Color
		part.Color = Color3.new(1, 1, 1)
		task.wait(0.06)
		if part.Parent then
			part.Color = original
		end
	end)
end

-- Mining beam: brief neon link from the miner toward the rock.
function EffectsController.beam(from: Vector3, to: Vector3)
	local dist = (to - from).Magnitude
	if dist <= 0.5 or dist > 60 then
		return
	end
	local beam = Instance.new("Part")
	beam.Shape = Enum.PartType.Block
	beam.Size = Vector3.new(0.3, 0.3, dist)
	beam.CFrame = CFrame.lookAt(from + (to - from) * 0.5, to)
	beam.Color = Color3.fromRGB(0, 220, 255)
	beam.Material = Enum.Material.Neon
	beam.Anchored = true
	beam.CanCollide = false
	beam.CanQuery = false
	beam.Transparency = 0.4
	beam.Parent = ensureFolder()
	Debris:AddItem(beam, 0.09)
end

local function getShockwave(): Part
	for _, p in ipairs(shockPool) do
		if not p.Visible then
			return p
		end
	end
	if #shockPool < Performance.MaxShockwaves then
		local p = Instance.new("Part")
		p.Shape = Enum.PartType.Ball
		p.Material = Enum.Material.Neon
		p.Color = Color3.fromRGB(255, 200, 80)
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.Parent = ensureFolder()
		table.insert(shockPool, p)
		return p
	end
	return shockPool[math.random(1, #shockPool)]
end

function EffectsController.shockwave(pos: Vector3)
	local ring = getShockwave()
	ring.Position = pos
	ring.Size = Vector3.new(2, 2, 2)
	ring.Transparency = 0.3
	ring.Visible = true
	task.spawn(function()
		for i = 1, 10 do
			ring.Size += Vector3.new(2.4, 2.4, 2.4)
			ring.Transparency = 0.3 + (i / 10) * 0.7
			task.wait(0.03)
		end
		ring.Visible = false
	end)
end

local function getDebris(): Part
	for _, p in ipairs(debrisPool) do
		if not p.Visible then
			return p
		end
	end
	if #debrisPool < Performance.MaxDebrisParts then
		local p = Instance.new("Part")
		p.Shape = Enum.PartType.Block
		p.Material = Enum.Material.Rock
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.Parent = ensureFolder()
		table.insert(debrisPool, p)
		return p
	end
	return debrisPool[math.random(1, #debrisPool)]
end

-- Rock chunks: anchored faders, never physics (mobile perf).
function EffectsController.debrisBurst(pos: Vector3, color: Color3)
	for _ = 1, 3 do
		local chunk = getDebris()
		local s = 0.8 + math.random() * 1.2
		chunk.Size = Vector3.new(s, s, s)
		chunk.Color = color
		chunk.Transparency = 0
		chunk.Position = pos + Vector3.new((math.random() - 0.5) * 6, math.random() * 3, (math.random() - 0.5) * 6)
		chunk.Orientation = Vector3.new(math.random(0, 90), math.random(0, 90), 0)
		chunk.Visible = true
		task.spawn(function()
			for i = 1, 12 do
				chunk.Transparency = i / 12
				task.wait(0.05)
			end
			chunk.Visible = false
		end)
	end
end

function EffectsController.explosion(pos: Vector3)
	local explosion = Instance.new("Explosion")
	explosion.BlastPressure = 0 -- visual only
	explosion.BlastRadius = 6
	explosion.DestroyJointRadiusPercent = 0
	explosion.Position = pos
	explosion.Parent = workspace
	Debris:AddItem(explosion, 2)
end

-- Tiny camera nudge on crits via Humanoid.CameraOffset (no CFrame fights).
function EffectsController.critNudge()
	local char = Players.LocalPlayer.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.CameraOffset = Vector3.new(0.6, 0.6, 0)
		task.delay(0.12, function()
			if hum.Parent then
				hum.CameraOffset = Vector3.new(0, 0, 0)
			end
		end)
	end
end

local function findAsteroid(id: string): BasePart?
	local field = workspace:FindFirstChild("AstroMinerField")
	local direct = field and field:FindFirstChild(id)
	if direct and direct:IsA("BasePart") then
		return direct
	end
	return nil
end

local function charPos(): Vector3?
	local char = Players.LocalPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root.Position
	end
	return nil
end

function EffectsController.init()
	local fx = ReplicatedStorage:WaitForChild(Constants.REMOTES.Fx) :: RemoteEvent
	fx.OnClientEvent:Connect(function(kind: string, payload: any)
		if kind == "mineHit" and typeof(payload) == "table" then
			local target = findAsteroid(tostring(payload.id))
			EffectsController.hitFlash(target)
			local from = charPos()
			if from and target then
				EffectsController.beam(from + Vector3.new(0, 2, 0), target.Position)
			end
			if payload.destroyed then
				AudioController.play("Destroy")
				EffectsController.floatingText("💥 ASTEROID DOWN", Color3.fromRGB(255, 200, 50), true)
				if target then
					EffectsController.explosion(target.Position)
					EffectsController.shockwave(target.Position)
					EffectsController.debrisBurst(target.Position, target.Color)
				end
				if payload.rewards then
					for oreId, qty in pairs(payload.rewards) do
						EffectsController.floatingText(`+{qty} {oreId}`, Color3.fromRGB(120, 230, 255))
					end
				end
				if payload.rare == true then
					AudioController.play("Rare")
					EffectsController.floatingText("💎 RARE DISCOVERY!", Color3.fromRGB(190, 120, 255), true)
				end
			else
				if payload.crit then
					AudioController.play("Crit")
					EffectsController.critNudge()
					EffectsController.floatingText(`CRITICAL! +{payload.damage}`, Color3.fromRGB(255, 120, 60))
				else
					AudioController.play("Hit")
					EffectsController.floatingText(`+{payload.damage}`, Color3.fromRGB(255, 255, 255))
				end
			end
		elseif kind == "asteroidRespawned" then
			-- Respawn shimmer intentionally omitted for perf.
		end
	end)
end

return EffectsController
