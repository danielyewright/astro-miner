--!strict
-- ASTRO MINER | Shared/Utils/NumberFormatter.luau
-- Abbreviated numbers: 1K, 1.5K, 1M, 1.25B, 4.2T (Spec §4).

local Constants = require(script.Parent.Parent.Constants)

local Suffixes = Constants.ABBREVIATIONS

local function format(n: number): string
	if n ~= n or math.abs(n) == math.huge then
		return "0"
	end
	local negative = n < 0
	local value = math.abs(math.floor(n))
	if value < 1000 then
		return (if negative then "-" else "") .. tostring(value)
	end
	local tier = math.floor(math.log(value, 1000))
	if tier >= #Suffixes then
		tier = #Suffixes - 1
	end
	local scaled = value / (1000 ^ tier)
	local text: string
	if scaled >= 100 then
		text = string.format("%d", scaled)
	elseif scaled >= 10 then
		text = string.format("%.1f", scaled)
	else
		text = string.format("%.2f", scaled)
	end
	-- Trim trailing zeros: "1.50" -> "1.5", "2.00" -> "2"
	text = string.gsub(text, "%.?0+$", "")
	return (if negative then "-" else "") .. text .. Suffixes[tier + 1]
end

return {
	format = format,
}
