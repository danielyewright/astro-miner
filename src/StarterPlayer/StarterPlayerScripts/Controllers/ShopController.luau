--!strict
-- ASTRO MINER | Controllers/ShopController.luau
-- 🛒 SHOP: gamepasses + consumables + live boost timers. Purchases go through
-- Roblox prompts; the server is the only thing that grants or owns anything.
-- Entries with AssetId 0 show as SOON (IDs not yet created in Dashboard).

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Shared.Constants)
local AudioController = require(script.Parent.AudioController)

local ShopController = {}
ShopController.onToast = nil :: ((string) -> ())?

local shopRefresh: RemoteFunction? = nil

local state = {
	configured = false,
	passes = {},
	products = {},
	boosts = {},
}

local frame: Frame? = nil
local body: ScrollingFrame? = nil

local function toast(text: string)
	local cb = ShopController.onToast
	if cb then
		cb(text)
	end
end

local function refreshOwnership()
	task.spawn(function()
		if not shopRefresh then
			return
		end
		pcall(function()
			(shopRefresh :: RemoteFunction):InvokeServer()
		end)
	end)
end

function ShopController.build()
	local player = Players.LocalPlayer
	local gui = Instance.new("ScreenGui")
	gui.Name = "AstroMinerShop"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = player:WaitForChild("PlayerGui")

	shopRefresh = ReplicatedStorage:WaitForChild(Constants.REMOTES.ShopRefresh) :: RemoteFunction

	local btn = Instance.new("TextButton")
	btn.Name = "ShopBtn"
	btn.Text = "🛒 SHOP"
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 16
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.BackgroundColor3 = Color3.fromRGB(40, 60, 110)
	btn.Size = UDim2.new(0, 130, 0, 44)
	btn.Position = UDim2.new(1, -140, 0, 116)
	local bc = Instance.new("UICorner")
	bc.CornerRadius = UDim.new(0, 10)
	bc.Parent = btn
	btn.Parent = gui
	btn.MouseButton1Click:Connect(function()
		if frame then
			frame.Visible = not frame.Visible
		end
	end)

	frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 340, 0, 400)
	frame.Position = UDim2.new(1, -352, 0.2, 0)
	frame.BackgroundColor3 = Color3.fromRGB(10, 18, 32)
	frame.BackgroundTransparency = 0.08
	frame.Visible = false
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 12)
	c.Parent = frame
	frame.Parent = gui

	local title = Instance.new("TextLabel")
	title.Text = "🛒 SHOP"
	title.Font = Enum.Font.GothamBold
	title.TextSize = 18
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, -20, 0, 28)
	title.Position = UDim2.new(0, 10, 0, 8)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = frame

	body = Instance.new("ScrollingFrame")
	body.BackgroundTransparency = 1
	body.Size = UDim2.new(1, -20, 1, -50)
	body.Position = UDim2.new(0, 10, 0, 42)
	body.CanvasSize = UDim2.new(0, 0, 0, 0)
	body.ScrollBarThickness = 4
	body.Parent = frame

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(_pid, purchased)
		if purchased then
			AudioController.play("Purchase")
			refreshOwnership()
			toast("✅ Pass activated!")
		end
	end)
end

local function section(parent: Instance, y: number, text: string): number
	local l = Instance.new("TextLabel")
	l.Text = text
	l.Font = Enum.Font.GothamBold
	l.TextSize = 14
	l.TextColor3 = Color3.fromRGB(160, 200, 255)
	l.BackgroundTransparency = 1
	l.Size = UDim2.new(1, 0, 0, 22)
	l.Position = UDim2.new(0, 0, 0, y)
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Parent = parent
	return y + 24
end

local function row(parent: Instance, y: number, title: string, sub: string, btnText: string, enabled: boolean, onTap: (() -> ())?): number
	local r = Instance.new("Frame")
	r.BackgroundColor3 = Color3.fromRGB(22, 32, 55)
	r.Size = UDim2.new(1, -8, 0, 64)
	r.Position = UDim2.new(0, 0, 0, y)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = r
	r.Parent = parent
	local name = Instance.new("TextLabel")
	name.Text = title
	name.Font = Enum.Font.GothamBold
	name.TextSize = 14
	name.TextColor3 = Color3.fromRGB(255, 255, 255)
	name.BackgroundTransparency = 1
	name.Size = UDim2.new(0.62, 0, 0, 22)
	name.Position = UDim2.new(0, 6, 0, 4)
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.Parent = r
	local info = Instance.new("TextLabel")
	info.Text = sub
	info.Font = Enum.Font.Gotham
	info.TextSize = 12
	info.TextColor3 = Color3.fromRGB(140, 220, 255)
	info.BackgroundTransparency = 1
	info.Size = UDim2.new(0.62, 0, 0, 18)
	info.Position = UDim2.new(0, 6, 0, 26)
	info.TextXAlignment = Enum.TextXAlignment.Left
	info.Parent = r
	local btn = Instance.new("TextButton")
	btn.Text = btnText
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 14
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.BackgroundColor3 = if enabled then Color3.fromRGB(0, 150, 120) else Color3.fromRGB(60, 60, 70)
	btn.Size = UDim2.new(0.34, -6, 0, 30)
	btn.Position = UDim2.new(0.66, 0, 0, 17)
	btn.Active = enabled
	btn.AutoButtonColor = enabled
	local cr = Instance.new("UICorner")
	cr.CornerRadius = UDim.new(0, 6)
	cr.Parent = btn
	btn.Parent = r
	if enabled and onTap then
		btn.MouseButton1Click:Connect(function()
			onTap()
		end)
	end
	return y + 70
end

local function fmtTime(sec: number): string
	local m = math.floor(sec / 60)
	local s = math.floor(sec % 60)
	return string.format("%d:%02d", m, s)
end

local function refresh()
	local scroll = body
	if not scroll then
		return
	end
	for _, child in ipairs(scroll:GetChildren()) do
		child:Destroy()
	end
	local player = Players.LocalPlayer
	local y = 0
	if not state.configured then
		y = section(scroll, y, "Shop IDs not configured yet — playtesting build.")
	end
	y = section(scroll, y, "— GAMEPASSES —")
	for _, p in ipairs(state.passes) do
		local owned = p.owned == true
		local ready = p.assetId ~= 0
		local label = if owned then "OWNED ✓" elseif not ready then "SOON" else "BUY"
		local desc = tostring(p.description)
		local assetId = p.assetId
		y = row(scroll, y, tostring(p.name), desc, label, owned == false and ready, function()
			task.spawn(function()
				local ok, err = pcall(function()
					MarketplaceService:PromptGamePassPurchase(player, assetId)
				end)
				if not ok then
					toast("Store unavailable: " .. tostring(err))
				end
			end)
		end)
	end
	y = section(scroll, y, "— CONSUMABLES —")
	for _, p in ipairs(state.products) do
		local ready = p.assetId ~= 0
		local assetId = p.assetId
		y = row(scroll, y, tostring(p.name), "One-time grant", if ready then "BUY" else "SOON", ready, function()
			task.spawn(function()
				local ok, err = pcall(function()
					MarketplaceService:PromptProductPurchase(player, assetId)
				end)
				if not ok then
					toast("Store unavailable: " .. tostring(err))
				end
			end)
		end)
	end
	y = section(scroll, y, "— ACTIVE BOOSTS —")
	if #state.boosts == 0 then
		y = section(scroll, y, "None. Boosts come from consumables + events.")
	else
		for _, b in ipairs(state.boosts) do
			y = row(scroll, y, tostring(b.name), fmtTime(b.remaining) .. " left", "⏱", false, nil)
		end
	end
	scroll.CanvasSize = UDim2.new(0, 0, 0, y)
end

function ShopController.update(patch: any)
	if typeof(patch) ~= "table" or typeof(patch.shop) ~= "table" then
		return
	end
	state.configured = patch.shop.configured == true
	state.passes = patch.shop.passes or {}
	state.products = patch.shop.products or {}
	state.boosts = patch.shop.boosts or {}
	refresh()
end

return ShopController
