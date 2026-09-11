--!strict
-- ASTRO MINER | Controllers/MiningController.luau
-- Binds ClickDetectors + a large mobile MINE button to server Mine calls.
-- No economy logic here: only requests actions, renders server responses.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Shared.Constants)
local Performance = require(ReplicatedStorage.Shared.Config.Performance)

local MiningController = {}
MiningController.SelectedAsteroid = "AST_1" :: string?

local lastRequest = 0

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local function getRemote(name: string): RemoteFunction
	return ReplicatedStorage:WaitForChild(name) :: RemoteFunction
end

function MiningController.init(onResult: (any) -> ())
	local mineRemote = getRemote(Constants.REMOTES.Mine)

	local function requestMine(id: string?)
		if not id then
			return
		end
		-- Client spam guard: server still enforces cooldown + rate limit.
		local now = os.clock()
		if now - lastRequest < Performance.ClientMineGuard then
			return
		end
		lastRequest = now
		task.spawn(function()
			local ok, response = pcall(function()
				return mineRemote:InvokeServer(id)
			end)
			if ok and response then
				onResult(response)
			end
		end)
	end

	-- Desktop: clicking any asteroid part mines it.
	mouse.Button1Down:Connect(function()
		local target = mouse.Target
		if target and string.sub(target.Name, 1, 4) == "AST_" then
			MiningController.SelectedAsteroid = target.Name
			requestMine(target.Name)
		end
	end)

	-- Touch/gamepad + mobile big button support: touch on part also routes here
	-- via ClickDetector MouseClick (fires for touch taps too).
	local function bindField()
		local field = workspace:WaitForChild("AstroMinerField", 10)
		if not field then
			return
		end
		for _, part in ipairs(field:GetChildren()) do
			if part:IsA("BasePart") then
				local det = part:FindFirstChildOfClass("ClickDetector")
				if det then
					det.MouseClick:Connect(function()
						MiningController.SelectedAsteroid = part.Name
						requestMine(part.Name)
					end)
				end
			end
		end
	end
	task.spawn(bindField)

	-- Exposed for the mobile MINE button in UIController.
	function MiningController.mineSelected()
		requestMine(MiningController.SelectedAsteroid)
	end
end

return MiningController
