--!strict
-- ASTRO MINER | Controllers/PrestigeController.luau
-- 🌌 COSMIC RESET panel + permanent upgrade tree. Display only: threshold,
-- stardust math, and purchases are all validated server-side.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Shared.Constants)
local Prestige = require(ReplicatedStorage.Shared.Config.Prestige)
local NumberFormatter = require(ReplicatedStorage.Shared.Utils.NumberFormatter)
local AudioController = require(script.Parent.AudioController)

local PrestigeController = {}
PrestigeController.onToast = nil :: ((string) -> ())?

local doPrestige: RemoteFunction? = nil
local buyUpgrade: RemoteFunction? = nil

local state = {
	runCredits = 0,
	threshold = 1,
	preview = 0,
	canReset = false,
	count = 0,
	stardust = 0,
	branches = {},
}
local armed = false

local frame: Frame? = nil
local headerLabel: TextLabel? = nil
local progressLabel: TextLabel? = nil
local previewLabel: TextLabel? = nil
local resetBtn: TextButton? = nil
local treeRows: ScrollingFrame? = nil

local function refreshResetBtn()
	if not resetBtn then
		return
	end
	if not state.canReset then
		resetBtn.Text = "LOCKED"
		resetBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
	elseif armed then
		resetBtn.Text = "SURE? TAP AGAIN"
		resetBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
	else
		resetBtn.Text = `RESET (+{state.preview} ✦)`
		resetBtn.BackgroundColor3 = Color3.fromRGB(70, 40, 130)
	end
end

local function toast(text: string)
	local cb = PrestigeController.onToast
	if cb then
		cb(text)
	end
end

local function titleLabel(parent: Instance, text: string, y: number, size: number?): TextLabel
	local l = Instance.new("TextLabel")
	l.Text = text
	l.Font = Enum.Font.GothamBold
	l.TextSize = size or 18
	l.TextColor3 = Color3.fromRGB(255, 255, 255)
	l.BackgroundTransparency = 1
	l.Size = UDim2.new(1, -20, 0, 28)
	l.Position = UDim2.new(0, 10, 0, y)
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Parent = parent
	return l
end

function PrestigeController.build()
	local gui = Instance.new("ScreenGui")
	gui.Name = "AstroMinerPrestige"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

	doPrestige = ReplicatedStorage:WaitForChild(Constants.REMOTES.DoPrestige) :: RemoteFunction
	buyUpgrade = ReplicatedStorage:WaitForChild(Constants.REMOTES.BuyPrestigeUpgrade) :: RemoteFunction

	local btn = Instance.new("TextButton")
	btn.Name = "CosmicBtn"
	btn.Text = "🌌 COSMIC"
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 16
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.BackgroundColor3 = Color3.fromRGB(70, 40, 130)
	btn.Size = UDim2.new(0, 130, 0, 44)
	btn.Position = UDim2.new(1, -280, 0, 116)
	local bc = Instance.new("UICorner")
	bc.CornerRadius = UDim.new(0, 10)
	bc.Parent = btn
	btn.Parent = gui
	btn.MouseButton1Click:Connect(function()
		if frame then
			frame.Visible = not frame.Visible
			armed = false
			refreshResetBtn()
		end
	end)

	frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 340, 0, 430)
	frame.Position = UDim2.new(0.5, -170, 0.22, 0)
	frame.BackgroundColor3 = Color3.fromRGB(10, 18, 32)
	frame.BackgroundTransparency = 0.08
	frame.Visible = false
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 12)
	c.Parent = frame
	frame.Parent = gui

	headerLabel = titleLabel(frame, "🌌 COSMIC RESET", 8)
	progressLabel = titleLabel(frame, "", 36, 14)
	progressLabel.TextColor3 = Color3.fromRGB(140, 220, 255)
	previewLabel = titleLabel(frame, "", 60, 16)
	previewLabel.TextColor3 = Color3.fromRGB(190, 140, 255)
	resetBtn = Instance.new("TextButton")
	resetBtn.Font = Enum.Font.GothamBold
	resetBtn.TextSize = 18
	resetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	resetBtn.Size = UDim2.new(1, -20, 0, 48)
	resetBtn.Position = UDim2.new(0, 10, 0, 90)
	local rc = Instance.new("UICorner")
	rc.CornerRadius = UDim.new(0, 10)
	rc.Parent = resetBtn
	resetBtn.Parent = frame
	resetBtn.MouseButton1Click:Connect(function()
		if not state.canReset then
			toast("Earn " .. NumberFormatter.format(state.threshold) .. " run credits to reset.")
			return
		end
		if not armed then
			armed = true
			refreshResetBtn()
			return
		end
		armed = false
		task.spawn(function()
			if not doPrestige then
				return
			end
			local ok, res = pcall(function()
				return (doPrestige :: RemoteFunction):InvokeServer()
			end)
			if ok and res and res.ok then
				AudioController.play("Prestige")
				toast(`🌌 Reborn! +{res.data.earned} Stardust`)
			else
				toast("Reset rejected by server.")
			end
			refreshResetBtn()
		end)
	end)

	treeRows = Instance.new("ScrollingFrame")
	treeRows.BackgroundTransparency = 1
	treeRows.Size = UDim2.new(1, -20, 1, -150)
	treeRows.Position = UDim2.new(0, 10, 0, 144)
	treeRows.CanvasSize = UDim2.new(0, 0, 0, 0)
	treeRows.ScrollBarThickness = 4
	treeRows.Parent = frame
end

local function refreshTree()
	local rows = treeRows
	if not rows then
		return
	end
	for _, child in ipairs(rows:GetChildren()) do
		child:Destroy()
	end
	local y = 0
	for _, b in ipairs(state.branches) do
		local branch = Prestige.getBranch(tostring(b.id))
		local r = Instance.new("Frame")
		r.BackgroundColor3 = Color3.fromRGB(22, 32, 55)
		r.Size = UDim2.new(1, -8, 0, 76)
		r.Position = UDim2.new(0, 0, 0, y)
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 8)
		c.Parent = r
		r.Parent = rows

		local owned = if typeof(b.owned) == "number" then b.owned else 0
		local name = Instance.new("TextLabel")
		name.Text = `{b.name} · {owned}/3`
		name.Font = Enum.Font.GothamBold
		name.TextSize = 14
		name.TextColor3 = Color3.fromRGB(255, 255, 255)
		name.BackgroundTransparency = 1
		name.Size = UDim2.new(1, -12, 0, 22)
		name.Position = UDim2.new(0, 6, 0, 4)
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.Parent = r

		local nextText = "MAXED ✓"
		if branch and owned < #branch.Tiers then
			local t = branch.Tiers[owned + 1]
			nextText = `Next: +{math.floor(t.Bonus * 100)}% — {t.Cost} ✦`
		end
		local info = Instance.new("TextLabel")
		info.Text = `{b.description} — {nextText}`
		info.Font = Enum.Font.Gotham
		info.TextSize = 12
		info.TextColor3 = Color3.fromRGB(140, 220, 255)
		info.BackgroundTransparency = 1
		info.Size = UDim2.new(0.60, 0, 0, 20)
		info.Position = UDim2.new(0, 6, 0, 26)
		info.TextXAlignment = Enum.TextXAlignment.Left
		info.Parent = r

		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0.36, -6, 0, 26)
		btn.Position = UDim2.new(0.64, 0, 0, 46)
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 14
		local cr = Instance.new("UICorner")
		cr.CornerRadius = UDim.new(0, 6)
		cr.Parent = btn
		btn.Parent = r
		local branchId = tostring(b.id)
		local nextIdx = owned + 1
		if not branch or owned >= #branch.Tiers then
			btn.Text = "MAX"
			btn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
			btn.TextColor3 = Color3.fromRGB(180, 180, 180)
			btn.Active = false
		else
			local cost = branch.Tiers[nextIdx].Cost
			btn.Text = `BUY {cost} ✦`
			btn.BackgroundColor3 = if state.stardust >= cost
				then Color3.fromRGB(70, 40, 130)
				else Color3.fromRGB(50, 50, 65)
			btn.TextColor3 = Color3.fromRGB(255, 255, 255)
			btn.MouseButton1Click:Connect(function()
				task.spawn(function()
					if not buyUpgrade then
						return
					end
					local ok, res = pcall(function()
						return (buyUpgrade :: RemoteFunction):InvokeServer(branchId, nextIdx)
					end)
					if ok and res then
						if res.ok then
							AudioController.play("Purchase")
							toast("✅ " .. tostring(res.data.message))
						else
							toast("Upgrade: " .. tostring(res.data.message))
						end
					end
				end)
			end)
		end
		y += 82
	end
	rows.CanvasSize = UDim2.new(0, 0, 0, y)
end

function PrestigeController.update(patch: any)
	if typeof(patch) ~= "table" or typeof(patch.prestige) ~= "table" then
		return
	end
	local p = patch.prestige
	state.runCredits = p.runCredits or 0
	state.threshold = p.threshold or 1
	state.preview = p.preview or 0
	state.canReset = p.canReset == true
	state.count = p.count or 0
	state.stardust = p.stardust or 0
	state.branches = p.branches or {}
	if headerLabel then
		headerLabel.Text = if state.count > 0
			then `🌌 COSMIC RESET (×{state.count})`
			else "🌌 COSMIC RESET"
	end
	if progressLabel then
		progressLabel.Text = `Run: {NumberFormatter.format(state.runCredits)} / {NumberFormatter.format(state.threshold)}`
	end
	if previewLabel then
		previewLabel.Text = `Reward on reset: +{state.preview} ✦ Stardust`
	end
	refreshResetBtn()
	refreshTree()
end

return PrestigeController
