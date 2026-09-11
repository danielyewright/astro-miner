--!strict
-- ASTRO MINER | Controllers/RewardController.luau
-- Offline WELCOME BACK popup + Daily rewards + Missions panels.
-- Display only: all grants are computed and validated server-side.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Shared.Constants)
local NumberFormatter = require(ReplicatedStorage.Shared.Utils.NumberFormatter)
local AudioController = require(script.Parent.AudioController)

local RewardController = {}
RewardController.onToast = nil :: ((string) -> ())?

local claimOffline: RemoteFunction? = nil
local claimDaily: RemoteFunction? = nil
local claimMission: RemoteFunction? = nil

local state = {
	offlinePending = 0,
	dailyDay = 1,
	dailyCanClaim = false,
	dailyTitle = "",
	missions = {},
}
local dismissedOffline = false

local offlineFrame: Frame? = nil
local offlineAmount: TextLabel? = nil
local dailyFrame: Frame? = nil
local dailyTitle: TextLabel? = nil
local dailyClaimBtn: TextButton? = nil
local missionFrame: Frame? = nil
local missionRows: Frame? = nil

local function toast(text: string)
	local cb = RewardController.onToast
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

local function actionButton(parent: Instance, text: string, y: number): TextButton
	local b = Instance.new("TextButton")
	b.Text = text
	b.Font = Enum.Font.GothamBold
	b.TextSize = 18
	b.TextColor3 = Color3.fromRGB(255, 255, 255)
	b.BackgroundColor3 = Color3.fromRGB(30, 140, 80)
	b.Size = UDim2.new(1, -20, 0, 48)
	b.Position = UDim2.new(0, 10, 0, y)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 10)
	c.Parent = b
	b.Parent = parent
	return b
end

local function smallButton(parent: Instance, name: string, text: string, x: number): TextButton
	local b = Instance.new("TextButton")
	b.Name = name
	b.Text = text
	b.Font = Enum.Font.GothamBold
	b.TextSize = 16
	b.TextColor3 = Color3.fromRGB(255, 255, 255)
	b.BackgroundColor3 = Color3.fromRGB(40, 60, 110)
	b.Size = UDim2.new(0, 130, 0, 44)
	b.Position = UDim2.new(1, x, 0, 12)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 10)
	c.Parent = b
	b.Parent = parent
	return b
end

function RewardController.build()
	local gui = Instance.new("ScreenGui")
	gui.Name = "AstroMinerRewards"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

	claimOffline = ReplicatedStorage:WaitForChild(Constants.REMOTES.ClaimOffline) :: RemoteFunction
	claimDaily = ReplicatedStorage:WaitForChild(Constants.REMOTES.ClaimDaily) :: RemoteFunction
	claimMission = ReplicatedStorage:WaitForChild(Constants.REMOTES.ClaimMission) :: RemoteFunction

	-- Top-right shortcut buttons (HUD top-right is free).
	local dailyBtn = smallButton(gui, "DailyBtn", "🎁 DAILY", -280)
	local missionBtn = smallButton(gui, "MissionBtn", "🎯 MISSIONS", -140)
	dailyBtn.MouseButton1Click:Connect(function()
		if dailyFrame then
			dailyFrame.Visible = not dailyFrame.Visible
		end
	end)
	missionBtn.MouseButton1Click:Connect(function()
		if missionFrame then
			missionFrame.Visible = not missionFrame.Visible
		end
	end)

	-- Offline popup (center).
	offlineFrame = panel(gui, UDim2.new(0, 320, 0, 190), UDim2.new(0.5, -160, 0.35, 0))
	titleLabel(offlineFrame, "WELCOME BACK! ⛏", 8)
	offlineAmount = titleLabel(offlineFrame, "+0 Credits", 40)
	offlineAmount.TextColor3 = Color3.fromRGB(140, 255, 170)
	local sub = titleLabel(offlineFrame, "Your empire kept mining.", 68)
	sub.TextSize = 14
	sub.TextColor3 = Color3.fromRGB(180, 190, 210)
	local collect = actionButton(offlineFrame, "COLLECT", 110)
	collect.MouseButton1Click:Connect(function()
		task.spawn(function()
			if not claimOffline then
				return
			end
			local ok, res = pcall(function()
				return (claimOffline :: RemoteFunction):InvokeServer()
			end)
			if ok and res and res.ok then
				dismissedOffline = true
				AudioController.play("Purchase")
				if offlineFrame then
					offlineFrame.Visible = false
				end
				toast(`✅ Collected {NumberFormatter.format(res.data.claimed)} Credits`)
			end
		end)
	end)

	-- Daily panel (center).
	dailyFrame = panel(gui, UDim2.new(0, 320, 0, 200), UDim2.new(0.5, -160, 0.3, 0))
	dailyTitle = titleLabel(dailyFrame, "Day 1", 8)
	local dailySub = titleLabel(dailyFrame, "Come back daily for bigger hauls.", 36)
	dailySub.TextSize = 14
	dailySub.TextColor3 = Color3.fromRGB(180, 190, 210)
	dailyClaimBtn = actionButton(dailyFrame, "CLAIM", 110)
	dailyClaimBtn.MouseButton1Click:Connect(function()
		task.spawn(function()
			if not claimDaily then
				return
			end
			local ok, res = pcall(function()
				return (claimDaily :: RemoteFunction):InvokeServer()
			end)
			if ok and res then
				if res.ok then
					AudioController.play("Daily")
					toast("✅ Daily claimed: " .. tostring(res.data.message))
				else
					toast("Daily already claimed — see you tomorrow!")
				end
			end
		end)
	end)

	-- Missions panel (right side).
	missionFrame = panel(gui, UDim2.new(0, 320, 0, 300), UDim2.new(1, -332, 0.2, 0))
	titleLabel(missionFrame, "🎯 DAILY MISSIONS", 8)
	missionRows = Instance.new("Frame")
	missionRows.BackgroundTransparency = 1
	missionRows.Size = UDim2.new(1, -20, 1, -50)
	missionRows.Position = UDim2.new(0, 10, 0, 42)
	missionRows.Parent = missionFrame
end

local function refreshMissions()
	if not missionRows then
		return
	end
	for _, child in ipairs(missionRows:GetChildren()) do
		child:Destroy()
	end
	local y = 0
	for _, m in ipairs(state.missions) do
		local row = Instance.new("Frame")
		row.BackgroundColor3 = Color3.fromRGB(22, 32, 55)
		row.Size = UDim2.new(1, 0, 0, 72)
		row.Position = UDim2.new(0, 0, 0, y)
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 8)
		c.Parent = row
		row.Parent = missionRows

		local name = Instance.new("TextLabel")
		name.Text = tostring(m.name)
		name.Font = Enum.Font.GothamBold
		name.TextSize = 14
		name.TextColor3 = Color3.fromRGB(255, 255, 255)
		name.BackgroundTransparency = 1
		name.Size = UDim2.new(1, -12, 0, 22)
		name.Position = UDim2.new(0, 6, 0, 4)
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.Parent = row

		local prog = Instance.new("TextLabel")
		prog.Text = `{m.progress}/{m.target}`
		prog.Font = Enum.Font.Gotham
		prog.TextSize = 13
		prog.TextColor3 = Color3.fromRGB(140, 220, 255)
		prog.BackgroundTransparency = 1
		prog.Size = UDim2.new(1, -12, 0, 18)
		prog.Position = UDim2.new(0, 6, 0, 26)
		prog.TextXAlignment = Enum.TextXAlignment.Left
		prog.Parent = row

		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, -12, 0, 24)
		btn.Position = UDim2.new(0, 6, 0, 44)
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 14
		local cr = Instance.new("UICorner")
		cr.CornerRadius = UDim.new(0, 6)
		cr.Parent = btn
		btn.Parent = row
		local defId = tostring(m.defId)
		if m.claimed then
			btn.Text = "CLAIMED ✓"
			btn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
			btn.TextColor3 = Color3.fromRGB(180, 180, 180)
			btn.Active = false
		elseif m.completed then
			btn.Text = "CLAIM REWARD"
			btn.BackgroundColor3 = Color3.fromRGB(30, 140, 80)
			btn.TextColor3 = Color3.fromRGB(255, 255, 255)
			btn.MouseButton1Click:Connect(function()
				task.spawn(function()
					if not claimMission then
						return
					end
					local ok, res = pcall(function()
						return (claimMission :: RemoteFunction):InvokeServer(defId)
					end)
					if ok and res then
						if res.ok then
							AudioController.play("Purchase")
							toast("✅ Mission complete: " .. tostring(res.data.message))
						else
							toast("Mission: " .. tostring(res.data.message))
						end
					end
				end)
			end)
		else
			btn.Text = "IN PROGRESS…"
			btn.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
			btn.TextColor3 = Color3.fromRGB(200, 200, 200)
			btn.Active = false
		end
		y += 78
	end
end

function RewardController.update(patch: any)
	if typeof(patch) ~= "table" then
		return
	end
	if patch.offlinePending ~= nil and typeof(patch.offlinePending) == "number" then
		state.offlinePending = patch.offlinePending
	end
	if typeof(patch.daily) == "table" then
		state.dailyDay = patch.daily.day or state.dailyDay
		state.dailyCanClaim = patch.daily.canClaim == true
		state.dailyTitle = tostring(patch.daily.title or "")
	end
	if typeof(patch.missions) == "table" then
		-- Detect newly completed missions for a toast.
		local before: { [string]: boolean } = {}
		for _, m in ipairs(state.missions) do
			before[tostring(m.defId)] = m.completed == true
		end
		state.missions = patch.missions
		for _, m in ipairs(state.missions) do
			local id = tostring(m.defId)
			if m.completed and not m.claimed and before[id] == false then
				toast("🎯 Mission complete: " .. tostring(m.name))
			end
		end
		refreshMissions()
	end
	if offlineFrame and offlineAmount then
		if state.offlinePending > 0 and not dismissedOffline then
			offlineAmount.Text = `+{NumberFormatter.format(state.offlinePending)} Credits`
			offlineFrame.Visible = true
		else
			offlineFrame.Visible = false
			if state.offlinePending <= 0 then
				dismissedOffline = false -- reset for next session's popup
			end
		end
	end
	if dailyTitle and dailyClaimBtn then
		dailyTitle.Text = `Day {state.dailyDay}: {state.dailyTitle}`
		dailyClaimBtn.Text = if state.dailyCanClaim then "CLAIM" else "CLAIMED ✓"
		dailyClaimBtn.BackgroundColor3 = if state.dailyCanClaim
			then Color3.fromRGB(30, 140, 80)
			else Color3.fromRGB(60, 60, 70)
	end
end

return RewardController
