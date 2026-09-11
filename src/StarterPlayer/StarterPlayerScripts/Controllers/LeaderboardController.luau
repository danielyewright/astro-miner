--!strict
-- ASTRO MINER | Controllers/LeaderboardController.luau
-- 🏆 Global boards, pulled on demand (server caches 60s). Empty in Studio
-- without DataStore access — shows "No data yet" instead of erroring.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Shared.Constants)
local NumberFormatter = require(ReplicatedStorage.Shared.Utils.NumberFormatter)

local LeaderboardController = {}
LeaderboardController.onToast = nil :: ((string) -> ())?

local boardRemote: RemoteFunction? = nil
local boards: { any } = {}
local boardIdx = 1

local frame: Frame? = nil
local boardTitle: TextLabel? = nil
local rows: ScrollingFrame? = nil

local function currentKey(): string
	if #boards == 0 then
		return "credits"
	end
	return tostring(boards[boardIdx].key)
end

local function currentTitle(): string
	if #boards == 0 then
		return "Leaderboard"
	end
	return tostring(boards[boardIdx].title)
end

local function paint(entries: { any })
	local scroll = rows
	if not scroll then
		return
	end
	for _, child in ipairs(scroll:GetChildren()) do
		child:Destroy()
	end
	if boardTitle then
		boardTitle.Text = currentTitle()
	end
	if #entries == 0 then
		local l = Instance.new("TextLabel")
		l.Text = "No data yet — be the first!"
		l.Font = Enum.Font.Gotham
		l.TextSize = 14
		l.TextColor3 = Color3.fromRGB(180, 190, 210)
		l.BackgroundTransparency = 1
		l.Size = UDim2.new(1, 0, 0, 30)
		l.Parent = scroll
		return
	end
	local y = 0
	for i, e in ipairs(entries) do
		if i > 10 then
			break
		end
		local r = Instance.new("TextLabel")
		r.Text = `# {i}  {e.name}  —  {NumberFormatter.format(e.value)}`
		r.Font = Enum.Font.GothamBold
		r.TextSize = 14
		r.TextColor3 = if i == 1 then Color3.fromRGB(255, 210, 80) else Color3.fromRGB(255, 255, 255)
		r.BackgroundTransparency = 1
		r.Size = UDim2.new(1, 0, 0, 26)
		r.Position = UDim2.new(0, 0, 0, y)
		r.TextXAlignment = Enum.TextXAlignment.Left
		r.Parent = scroll
		y += 28
	end
	scroll.CanvasSize = UDim2.new(0, 0, 0, y)
end

local function fetch()
	task.spawn(function()
		if not boardRemote then
			return
		end
		local ok, res = pcall(function()
			return (boardRemote :: RemoteFunction):InvokeServer(currentKey())
		end)
		if ok and res and res.ok then
			boards = res.data.boards or boards
			paint(res.data.entries or {})
		end
	end)
end

function LeaderboardController.build()
	local gui = Instance.new("ScreenGui")
	gui.Name = "AstroMinerBoards"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

	boardRemote = ReplicatedStorage:WaitForChild(Constants.REMOTES.Leaderboard) :: RemoteFunction

	local btn = Instance.new("TextButton")
	btn.Name = "BoardBtn"
	btn.Text = "🏆 BOARD"
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 16
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.BackgroundColor3 = Color3.fromRGB(40, 60, 110)
	btn.Size = UDim2.new(0, 130, 0, 44)
	btn.Position = UDim2.new(1, -280, 0, 168)
	local bc = Instance.new("UICorner")
	bc.CornerRadius = UDim.new(0, 10)
	bc.Parent = btn
	btn.Parent = gui
	btn.MouseButton1Click:Connect(function()
		if frame then
			frame.Visible = not frame.Visible
			if frame.Visible then
				fetch()
			end
		end
	end)

	frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 340, 0, 360)
	frame.Position = UDim2.new(1, -352, 0.25, 0)
	frame.BackgroundColor3 = Color3.fromRGB(10, 18, 32)
	frame.BackgroundTransparency = 0.08
	frame.Visible = false
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 12)
	c.Parent = frame
	frame.Parent = gui

	boardTitle = Instance.new("TextLabel")
	boardTitle.Font = Enum.Font.GothamBold
	boardTitle.TextSize = 17
	boardTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	boardTitle.BackgroundTransparency = 1
	boardTitle.Size = UDim2.new(1, -110, 0, 28)
	boardTitle.Position = UDim2.new(0, 55, 0, 8)
	boardTitle.Text = "Leaderboard"
	boardTitle.Parent = frame

	local prev = Instance.new("TextButton")
	prev.Text = "◀"
	prev.Font = Enum.Font.GothamBold
	prev.TextSize = 18
	prev.TextColor3 = Color3.fromRGB(255, 255, 255)
	prev.BackgroundColor3 = Color3.fromRGB(40, 60, 110)
	prev.Size = UDim2.new(0, 40, 0, 30)
	prev.Position = UDim2.new(0, 8, 0, 8)
	local pc = Instance.new("UICorner")
	pc.CornerRadius = UDim.new(0, 8)
	pc.Parent = prev
	prev.Parent = frame

	local next = Instance.new("TextButton")
	next.Text = "▶"
	next.Font = Enum.Font.GothamBold
	next.TextSize = 18
	next.TextColor3 = Color3.fromRGB(255, 255, 255)
	next.BackgroundColor3 = Color3.fromRGB(40, 60, 110)
	next.Size = UDim2.new(0, 40, 0, 30)
	next.Position = UDim2.new(1, -48, 0, 8)
	local nc = Instance.new("UICorner")
	nc.CornerRadius = UDim.new(0, 8)
	nc.Parent = next
	next.Parent = frame

	prev.MouseButton1Click:Connect(function()
		if #boards > 0 then
			boardIdx = ((boardIdx - 2) % #boards) + 1
			fetch()
		end
	end)
	next.MouseButton1Click:Connect(function()
		if #boards > 0 then
			boardIdx = (boardIdx % #boards) + 1
			fetch()
		end
	end)

	rows = Instance.new("ScrollingFrame")
	rows.BackgroundTransparency = 1
	rows.Size = UDim2.new(1, -20, 1, -50)
	rows.Position = UDim2.new(0, 10, 0, 42)
	rows.CanvasSize = UDim2.new(0, 0, 0, 0)
	rows.ScrollBarThickness = 4
	rows.Parent = frame
end

return LeaderboardController
