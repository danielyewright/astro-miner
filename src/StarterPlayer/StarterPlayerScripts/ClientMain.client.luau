--!strict
-- ASTRO MINER | ClientMain (place in StarterPlayerScripts as a LocalScript)
-- Wires Mining + Effects + UI. Includes welcome prompt (Spec §47, no cutscene).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Shared.Constants)
local Controllers = script.Parent.Controllers
local MiningController = require(Controllers.MiningController)
local EffectsController = require(Controllers.EffectsController)
local UIController = require(Controllers.UIController)
local RewardController = require(Controllers.RewardController)
local EmpireController = require(Controllers.EmpireController)
local PrestigeController = require(Controllers.PrestigeController)
local ShopController = require(Controllers.ShopController)
local LeaderboardController = require(Controllers.LeaderboardController)
local AudioController = require(Controllers.AudioController)

local player = Players.LocalPlayer

local function getRemote(name: string): RemoteEvent | RemoteFunction
	return ReplicatedStorage:WaitForChild(name) :: any
end

EffectsController.init()
AudioController.init()

local sellRemote = getRemote(Constants.REMOTES.SellAll) :: RemoteFunction
local buyRemote = getRemote(Constants.REMOTES.BuyEquipment) :: RemoteFunction
local sync = getRemote(Constants.REMOTES.StateSync) :: RemoteEvent

MiningController.init(function(_response)
	-- Server pushes Fx + StateSync separately; nothing required here.
end)

UIController.build(
	function()
		MiningController.mineSelected()
	end,
	function()
		task.spawn(function()
			local ok, res = pcall(function()
				return (sellRemote :: RemoteFunction):InvokeServer()
			end)
			if ok and res and res.ok then
				UIController.toast(`✅ Sold ore: +{res.data.earned} Credits`)
			end
		end)
	end,
	function()
		task.spawn(function()
			local ok, res = pcall(function()
				return (buyRemote :: RemoteFunction):InvokeServer()
			end)
			if ok and res then
				if res.ok then
					AudioController.play("Purchase")
					UIController.toast("✅ UPGRADE COMPLETE: " .. tostring(res.data.message))
				else
					UIController.toast("Need more Credits: " .. tostring(res.data.message))
				end
			end
		end)
	end
);

local syncEvent = sync :: RemoteEvent
RewardController.onToast = UIController.toast
EmpireController.onToast = UIController.toast
PrestigeController.onToast = UIController.toast
ShopController.onToast = UIController.toast
LeaderboardController.onToast = UIController.toast
RewardController.build()
EmpireController.build()
PrestigeController.build()
ShopController.build()
LeaderboardController.build()
syncEvent.OnClientEvent:Connect(function(patch)
	UIController.update(patch)
	RewardController.update(patch)
	EmpireController.update(patch)
	PrestigeController.update(patch)
	ShopController.update(patch)
	if typeof(patch) == "table"
		and typeof(patch.achievements) == "table"
		and typeof(patch.achievements.newly) == "table"
	then
		for _, title in ipairs(patch.achievements.newly) do
			AudioController.play("Achievement")
			UIController.toast("🏆 Achievement: " .. tostring(title))
		end
	end
end)

-- First-launch presentation: quick fade-in text, no blocking cutscene.
task.spawn(function()
	UIController.toast("WELCOME, MINER. Build the largest mining empire in the galaxy.")
end)
