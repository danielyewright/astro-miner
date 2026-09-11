--!strict
-- ASTRO MINER | Shared/Utils/Validator.luau
-- Shared sanity helpers. Server is authoritative; client must never set currency.

local function isPositiveInteger(n: unknown): boolean
	return typeof(n) == "number"
		and (n :: number) == math.floor(n :: number)
		and (n :: number) > 0
end

local function clamp(n: number, minN: number, maxN: number): number
	if n < minN then
		return minN
	end
	if n > maxN then
		return maxN
	end
	return n
end

return {
	isPositiveInteger = isPositiveInteger,
	clamp = clamp,
}
