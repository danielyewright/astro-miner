--!strict
-- ASTRO MINER | Controllers/EmpireController.luau
-- 🚁 DRONES + 🏠 BASE shop panels. Display only: prices, capacity, and
-- ownership come from the server; all purchases validated server-side.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Shared.Constants)
local NumberFormatter = require(ReplicatedStorage.Shared.Utils.NumberFormatter)
local AudioController = require(script.Parent.AudioController)

local EmpireController = {}
EmpireController.onToast = nil :: ((string) -> ())?

local buyDrone: RemoteFunction? = nil
local buyBuilding: RemoteFunction? = nil

local state = {
	droneCatalog = {},
	droneOwnedTotal = 0,
	droneCapacity = 2,
	dronePerSec = 0,
	buildings = {},
}

local droneFrame: Frame? = nil
local droneTitle: TextLabel? = nil
local droneRows: ScrollingFrame? = nil
local baseFrame: Frame? = nil
local baseRows: ScrollingFrame? = nil

local function toast(text: string)
	local cb = EmpireController.onToast
	if cb then
		cb(text)
	end
end

local function panel(parent: Instance, size: UDim2, pos: UDim2): Frame
	local f = Instance.new("Frame")
	f.Size = size
	f.Position = pos
	f.BackgroundColor3 = Color3.fromRGB(10, 18, 32)
	f.BackgroundTransparency = 0.08
	f.Visible = false
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 12)
	c.Parent = f
	f.Parent = parent
	return f
end

local function titleLabel(parent: Instance, text: string, y: number): TextLabel
	local l = Instance.new("TextLabel")
	l.Text = text
	l.Font = Enum.Font.GothamBold
	l.TextSize = 18
	l.TextColor3 = Color3.fromRGB(255, 255, 255)
	l.BackgroundTransparency = 1
	l.Size = UDim2.new(1, -20, 0, 28)
	l.Position = UDim2.new(0, 10, 0, y)
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Parent = parent
	return l
end

local function topButton(parent: Instance, name: string, text: string, x: number, y: number): TextButton
	local b = Instance.new("TextButton")
	b.Name = name
	b.Text = text
	b.Font = Enum.Font.GothamBold
	b.TextSize = 16
	b.TextColor3 = Color3.fromRGB(255, 255, 255)
	b.BackgroundColor3 = Color3.fromRGB(40, 60, 110)
	b.Size = UDim2.new(0, 130, 0, 44)
	b.Position = UDim2.new(1, x, 0, y)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 10)
	c.Parent = b
	b.Parent = parent
	return b
end

local function scrollArea(parent: Frame): ScrollingFrame
	local s = Instance.new("ScrollingFrame")
	s.BackgroundTransparency = 1
	s.Size = UDim2.new(1, -20, 1, -50)
	s.Position = UDim2.new(0, 10, 0, 42)
	s.CanvasSize = UDim2.new(0, 0, 0, 0)
	s.ScrollBarThickness = 4
	s.Parent = parent
	return s
end

function EmpireController.build()
	local gui = Instance.new("ScreenGui")
	gui.Name = "AstroMinerEmpire"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

	buyDrone = ReplicatedStorage:WaitForChild(Constants.REMOTES.BuyDrone) :: RemoteFunction
	buyBuilding = ReplicatedStorage:WaitForChild(Constants.REMOTES.BuyBuilding) :: RemoteFunction

	local droneBtn = topButton(gui, "DroneBtn", "🚁 DRONES", -280, 64)
	local baseBtn = topButton(gui, "BaseBtn", "🏠 BASE", -140, 64)
	droneBtn.MouseButton1Click:Connect(function()
		if droneFrame then
			droneFrame.Visible = not droneFrame.Visible
		end
	end)
	baseBtn.MouseButton1Click:Connect(function()
		if baseFrame then
			baseFrame.Visible = not baseFrame.Visible
		end
	end)

	droneFrame = panel(gui, UDim2.new(0, 340, 0, 380), UDim2.new(1, -352, 0.2, 0))
	droneTitle = titleLabel(droneFrame, "🚁 DRONES", 8)
	droneRows = scrollArea(droneFrame)

	baseFrame = panel(gui, UDim2.new(0, 340, 0, 380), UDim2.new(1, -352, 0.2, 0))
	titleLabel(baseFrame, "🏠 LUNAR BASE", 8)
	baseRows = scrollArea(baseFrame)
end

local function row(parent: Instance, y: number, h: number): Frame
	local r = Instance.new("Frame")
	r.BackgroundColor3 = Color3.fromRGB(22, 32, 55)
	r.Size = UDim2.new(1, -8, 0, h)
	r.Position = UDim2.new(0, 0, 0, y)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = r
	r.Parent = parent
	return r
end

local function refreshDrones()
	local rows = droneRows
	if not rows then
		return
	end
	for _, child in ipairs(rows:GetChildren()) do
		child:Destroy()
	end
	if droneTitle then
		droneTitle.Text = `🚁 DRONES ({state.droneOwnedTotal}/{state.droneCapacity} • {state.dronePerSec}/s)`
	end
	local y = 0
	for _, d in ipairs(state.droneCatalog) do
		local r = row(rows, y, 76)
		local name = Instance.new("TextLabel")
		name.Text = `{d.name} [{d.rarity}]`
		name.Font = Enum.Font.GothamBold
		name.TextSize = 14
		name.TextColor3 = Color3.fromRGB(255, 255, 255)
		name.BackgroundTransparency = 1
		name.Size = UDim2.new(1, -12, 0, 22)
		name.Position = UDim2.new(0, 6, 0, 4)
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.Parent = r
		local info = Instance.new("TextLabel")
		info.Text = `{d.orePerSec} ore/s • owned {d.owned}`
		info.Font = Enum.Font.Gotham
		info.TextSize = 13
		info.TextColor3 = Color3.fromRGB(140, 220, 255)
		info.BackgroundTransparency = 1
		info.Size = UDim2.new(0.55, 0, 0, 22)
		info.Position = UDim2.new(0, 6, 0, 26)
		info.TextXAlignment = Enum.TextXAlignment.Left
		info.Parent = r
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0.42, -6, 0, 26)
		btn.Position = UDim2.new(0.58, 0, 0, 44)
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 14
		local cr = Instance.new("UICorner")
		cr.CornerRadius = UDim.new(0, 6)
		cr.Parent = btn
		btn.Parent = r
		local droneId = tostring(d.id)
		if state.droneOwnedTotal >= state.droneCapacity then
			btn.Text = "FULL"
			btn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
			btn.TextColor3 = Color3.fromRGB(180, 180, 180)
			btn.Active = false
		else
			btn.Text = `BUY ${NumberFormatter.format(d.cost)}`
			btn.BackgroundColor3 = Color3.fromRGB(0, 150, 180)
			btn.TextColor3 = Color3.fromRGB(255, 255, 255)
			btn.MouseButton1Click:Connect(function()
				task.spawn(function()
					if not buyDrone then
						return
					end
					local ok, res = pcall(function()
						return (buyDrone :: RemoteFunction):InvokeServer(droneId)
					end)
					if ok and res then
						if res.ok then
							AudioController.play("Purchase")
							toast("✅ Drone deployed: " .. tostring(res.data.message))
						else
							toast("Drone: " .. tostring(res.data.message))
						end
					end
				end)
			end)
		end
		y += 82
	end
	rows.CanvasSize = UDim2.new(0, 0, 0, y)
end

local function refreshBuildings()
	local rows = baseRows
	if not rows then
		return
	end
	for _, child in ipairs(rows:GetChildren()) do
		child:Destroy()
	end
	local y = 0
	for _, b in ipairs(state.buildings) do
		local r = row(rows, y, 76)
		local name = Instance.new("TextLabel")
		name.Text = tostring(b.name)
		name.Font = Enum.Font.GothamBold
		name.TextSize = 14
		name.TextColor3 = Color3.fromRGB(255, 255, 255)
		name.BackgroundTransparency = 1
		name.Size = UDim2.new(1, -12, 0, 22)
		name.Position = UDim2.new(0, 6, 0, 4)
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.Parent = r
		local info = Instance.new("TextLabel")
		info.Text = tostring(b.description)
		info.Font = Enum.Font.Gotham
		info.TextSize = 13
		info.TextColor3 = Color3.fromRGB(140, 220, 255)
		info.BackgroundTransparency = 1
		info.Size = UDim2.new(0.55, 0, 0, 22)
		info.Position = UDim2.new(0, 6, 0, 26)
		info.TextXAlignment = Enum.TextXAlignment.Left
		info.Parent = r
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0.42, -6, 0, 26)
		btn.Position = UDim2.new(0.58, 0, 0, 44)
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 14
		local cr = Instance.new("UICorner")
		cr.CornerRadius = UDim.new(0, 6)
		cr.Parent = btn
		btn.Parent = r
		local buildingId = tostring(b.id)
		if b.owned then
			btn.Text = "OWNED ✓"
			btn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
			btn.TextColor3 = Color3.fromRGB(180, 180, 180)
			btn.Active = false
		else
			btn.Text = `BUY ${NumberFormatter.format(b.cost)}`
			btn.BackgroundColor3 = Color3.fromRGB(60, 90, 180)
			btn.TextColor3 = Color3.fromRGB(255, 255, 255)
			btn.MouseButton1Click:Connect(function()
				task.spawn(function()
					if not buyBuilding then
						return
					end
					local ok, res = pcall(function()
						return (buyBuilding :: RemoteFunction):InvokeServer(buildingId)
					end)
					if ok and res then
						if res.ok then
							AudioController.play("Purchase")
							toast("✅ Built: " .. tostring(res.data.message))
						else
							toast("Base: " .. tostring(res.data.message))
						end
					end
				end)
			end)
		end
		y += 82
	end
	rows.CanvasSize = UDim2.new(0, 0, 0, y)
end

function EmpireController.update(patch: any)
	if typeof(patch) ~= "table" then
		return
	end
	if typeof(patch.drones) == "table" then
		state.droneCatalog = patch.drones.catalog or {}
		state.droneCapacity = patch.drones.capacity or state.droneCapacity
		state.dronePerSec = patch.drones.totalPerSec or 0
		local total = 0
		if typeof(patch.drones.owned) == "table" then
			for _, v in pairs(patch.drones.owned) do
				if typeof(v) == "number" then
					total += v
				end
			end
		end
		state.droneOwnedTotal = total
		refreshDrones()
	end
	if typeof(patch.buildings) == "table" then
		state.buildings = patch.buildings
		refreshBuildings()
	end
end

return EmpireController
