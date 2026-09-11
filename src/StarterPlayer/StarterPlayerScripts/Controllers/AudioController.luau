--!strict
-- ASTRO MINER | Controllers/AudioController.luau
-- Pooled 2D sounds (no 3D positioning = reliable + cheap). Silent until real
-- rbxassetids land in Config/Audio. One looping ambient slot, also silent at 0.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Audio = require(ReplicatedStorage.Shared.Config.Audio)
local Performance = require(ReplicatedStorage.Shared.Config.Performance)

local AudioController = {}

local pool: { Sound } = {}
local folder: Folder? = nil

local function ensureFolder(): Folder
	if folder then
		return folder
	end
	local f = Instance.new("Folder")
	f.Name = "AstroMinerAudio"
	f.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	folder = f
	return f
end

function AudioController.play(key: string)
	local def = Audio.getDef(key)
	if not def or def.Id == 0 then
		return -- unconfigured: silent by design
	end
	for _, s in ipairs(pool) do
		if not s.IsPlaying then
			s.SoundId = "rbxassetid://" .. tostring(def.Id)
			s.Volume = def.Volume
			s.PlaybackSpeed = def.PitchBase + (math.random() - 0.5) * 2 * def.PitchVariance
			s:Play()
			return
		end
	end
	-- Pool exhausted: steal the oldest instead of stacking (mobile budget).
	local oldest = pool[1]
	if oldest then
		oldest:Stop()
		oldest.SoundId = "rbxassetid://" .. tostring(def.Id)
		oldest.Volume = def.Volume
		oldest:Play()
	end
end

function AudioController.init()
	for _ = 1, Performance.MaxSounds do
		local s = Instance.new("Sound")
		s.Parent = ensureFolder()
		table.insert(pool, s)
	end
	-- Ambient loop (silent at ID 0; unobtrusive when configured).
	local def = Audio.getDef("Ambient")
	if def and def.Id ~= 0 then
		local amb = Instance.new("Sound")
		amb.SoundId = "rbxassetid://" .. tostring(def.Id)
		amb.Volume = def.Volume
		amb.Looped = true
		amb.Parent = ensureFolder()
		amb:Play()
	end
end

return AudioController
