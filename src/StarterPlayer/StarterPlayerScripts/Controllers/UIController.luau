--!strict
-- ASTRO MINER | Controllers/UIController.luau
-- Minimal MVP HUD: credits, ore, equipment, SELL + UPGRADE + big MINE button,
-- and a single NEXT OBJECTIVE line (Spec §43). Responsive + touch-first.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Shared.Constants)
local Equipment = require(ReplicatedStorage.Shared.Config.Equipment)
local NumberFormatter = require(ReplicatedStorage.Shared.Utils.NumberFormatter)

local UIController = {}

local state = {
	credits = 0,
	stardust = 0,
	achCount = 0,
	achTotal = 0,
	ore = {},
	equipment = 1,
}

local labels: { [string]: TextLabel } = {}
local objectiveLabel: TextLabel? = nil
local mineButton: TextButton? = nil

local function theme(frame: Frame)
	frame.BackgroundColor3 = Color3.fromRGB(10, 18, 32)
	frame.BackgroundTransparency = 0.15
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = frame
end

local function makeLabel(parent: Instance, name: string, text: string, size: number): TextLabel
	local l = Instance.new("TextLabel")
	l.Name = name
	l.Text = text
	l.Font = Enum.Font.GothamBold
	l.TextSize = size
	l.TextColor3 = Color3.fromRGB(255, 255, 255)
	l.BackgroundTransparency = 1
	l.Size = UDim2.new(1, -16, 0, 28)
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Parent = parent
	labels[name] = l
	return l
end

function UIController.build(mineSelected: () -> (), onSell: () -> (), onUpgrade: () -> ())
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local gui = Instance.new("ScreenGui")
	gui.Name = "AstroMinerHUD"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = playerGui

	-- Top-left: currencies
	local topLeft = Instance.new("Frame")
	topLeft.Size = UDim2.new(0, 240, 0, 140)
	topLeft.Position = UDim2.new(0, 12, 0, 12)
	topLeft.Parent = gui
	theme(topLeft)
	makeLabel(topLeft, "Credits", "Credits: 0", 20).Position = UDim2.new(0, 8, 0, 6)
	makeLabel(topLeft, "Stardust", "✦ Stardust: 0", 15).Position = UDim2.new(0, 8, 0, 34)
	labels.Stardust.TextColor3 = Color3.fromRGB(190, 140, 255)
	makeLabel(topLeft, "Ore", "Ore: —", 15).Position = UDim2.new(0, 8, 0, 58)
	makeLabel(topLeft, "Equip", "Drill Lv.1", 15).Position = UDim2.new(0, 8, 0, 86)
	makeLabel(topLeft, "Achieve", "🏆 0/0", 14).Position = UDim2.new(0, 8, 0, 110)
	labels.Achieve.TextColor3 = Color3.fromRGB(255, 210, 120)
	labels.Ore.TextColor3 = Color3.fromRGB(140, 220, 255)

	-- Top-center: zone
	local zone = Instance.new("TextLabel")
	zone.Text = "🌙 LUNAR OUTPOST"
	zone.Font = Enum.Font.GothamBold
	zone.TextSize = 18
	zone.TextColor3 = Color3.fromRGB(255, 255, 255)
	zone.BackgroundTransparency = 1
	zone.Size = UDim2.new(0, 300, 0, 30)
	zone.Position = UDim2.new(0.5, -150, 0, 12)
	zone.Parent = gui

	-- Objective line
	local obj = Instance.new("TextLabel")
	obj.Name = "Objective"
	obj.Font = Enum.Font.Gotham
	obj.TextSize = 15
	obj.TextColor3 = Color3.fromRGB(160, 255, 180)
	obj.BackgroundTransparency = 1
	obj.Size = UDim2.new(0, 400, 0, 24)
	obj.Position = UDim2.new(0.5, -200, 0, 42)
	obj.Text = "NEXT: Mine an asteroid"
	obj.Parent = gui
	objectiveLabel = obj

	-- Bottom bar: SELL / UPGRADE / MINE (big touch target, min 64px)
	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(1, -24, 0, 84)
	bar.Position = UDim2.new(0, 12, 1, -96)
	bar.BackgroundTransparency = 1
	bar.Parent = gui

	local function makeButton(name: string, text: string, xScale: number, width: number, color: Color3): TextButton
		local b = Instance.new("TextButton")
		b.Name = name
		b.Text = text
		b.Font = Enum.Font.GothamBold
		b.TextSize = 20
		b.TextColor3 = Color3.fromRGB(255, 255, 255)
		b.BackgroundColor3 = color
		b.Size = UDim2.new(0, width, 0, 64)
		b.Position = UDim2.new(xScale, 0, 0, 10)
		b.AutoButtonColor = true
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 12)
		c.Parent = b
		b.Parent = bar
		return b
	end

	local sell = makeButton("Sell", "SELL", 0, 140, Color3.fromRGB(30, 140, 80))
	local upg = makeButton("Upgrade", "UPGRADE", 0, 170, Color3.fromRGB(60, 90, 180))
	upg.Position = UDim2.new(0, 150, 0, 10)
	local mine = makeButton("Mine", "⛏ MINE", 1, 200, Color3.fromRGB(0, 170, 200))
	mine.AnchorPoint = Vector2.new(1, 0)
	mine.Position = UDim2.new(1, 0, 0, 10)
	mineButton = mine

	sell.MouseButton1Click:Connect(function()
		onSell()
	end)
	upg.MouseButton1Click:Connect(function()
		onUpgrade()
	end)
	mine.MouseButton1Click:Connect(function()
		mineSelected()
	end)
end

local function totalOre(): number
	local t = 0
	for _, v in pairs(state.ore) do
		if typeof(v) == "number" then
			t += v
		end
	end
	return t
end

function UIController.update(patch: any)
	if typeof(patch) ~= "table" then
		return
	end
	if patch.credits ~= nil then
		state.credits = patch.credits
	end
	if patch.stardust ~= nil then
		state.stardust = patch.stardust
	end
	if patch.ore ~= nil then
		state.ore = patch.ore
	end
	if patch.equipment ~= nil then
		state.equipment = patch.equipment
	end
	if typeof(patch.achievements) == "table" then
		state.achCount = patch.achievements.count or state.achCount
		state.achTotal = patch.achievements.total or state.achTotal
	end
	if labels.Achieve then
		labels.Achieve.Text = `🏆 {state.achCount}/{state.achTotal}`
	end
	if labels.Credits then
		labels.Credits.Text = "Credits: " .. NumberFormatter.format(state.credits)
	end
	if labels.Stardust then
		labels.Stardust.Text = "✦ Stardust: " .. NumberFormatter.format(state.stardust)
	end
	if labels.Ore then
		labels.Ore.Text = `Ore: {totalOre()} (tap SELL)`
	end
	if labels.Equip then
		local def = Equipment.getDef(state.equipment) or Equipment.Definitions[1]
		labels.Equip.Text = `⚒ {def.Name} Lv.{state.equipment}`
	end
	-- Objective state machine (Spec §43): mine -> sell -> upgrade.
	if objectiveLabel then
		if totalOre() == 0 and state.credits < 100 then
			objectiveLabel.Text = "NEXT: Mine an asteroid ⛏"
		elseif totalOre() > 0 then
			objectiveLabel.Text = "NEXT: Press SELL to convert ore → Credits"
		elseif state.equipment == 1 and state.credits >= 100 then
			objectiveLabel.Text = "NEXT: Buy Industrial Drill (UPGRADE)"
		else
			objectiveLabel.Text = "NEXT: Keep mining — drone unlocks soon"
		end
	end
end

function UIController.toast(text: string)
	-- Reuse objective line briefly for purchase feedback.
	if objectiveLabel then
		local prev = objectiveLabel.Text
		objectiveLabel.Text = text
		task.delay(2, function()
			if objectiveLabel and objectiveLabel.Text == text then
				objectiveLabel.Text = prev
			end
		end)
	end
end

return UIController
