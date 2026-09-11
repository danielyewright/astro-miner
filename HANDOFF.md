# ASTRO MINER — Session Handoff

Roblox incremental/tycoon (Lunar Outpost MVP). Config-driven, server-authoritative.

## Run it (macOS or Windows — identical)

```bash
rojo serve            # serve on :34872, sync via Studio Rojo plugin, then Play
# or one-way, no plugin:
rojo build -o AstroMiner.rbxlx   # Studio → File → Open, then Play
```

Map (ground, spawn, refinery, base pads, asteroids) is built at runtime by
`MapService` — an empty Workspace on open is normal.

## Layout

- `default.project.json` — Rojo tree. NOTE: no `Workspace` mapping (it used to
  wipe the baseplate on sync) and no `Remotes` mapping (empty folder broke
  `rojo serve`; remotes are created at runtime by ServerMain).
- `src/ReplicatedStorage/Shared/Config/` — all tuning: Resources, Equipment,
  Zones, Passive, DailyRewards, Missions, Drones, Buildings, Prestige,
  Monetization, Achievements, Audio (IDs 0 = silent), Performance.
- `src/ServerScriptService/` — `ServerMain.server.luau` (Script) + `Services/`
  (ModuleScripts): PlayerData, Economy, Mining, Upgrade, Map, PassiveIncome,
  OfflineEarnings, Reward (daily), Mission, State (sync payload), Drone,
  Building, Prestige, Boost, Monetization, Achievement, Leaderboard.
- `src/StarterPlayer/StarterPlayerScripts/` — `ClientMain.client.luau`
  (LocalScript) + `Controllers/` (ModuleScripts): Mining, Effects, UI,
  Reward, Empire, Prestige, Shop, Leaderboard, Audio.

## Rules the codebase follows

- Server computes everything (credits, ore, costs, stardust, rolls). Client
  only invokes remotes (`RM_*`, see `Shared/Constants`) and renders.
- New content = new Config rows + small service hooks, never hardcoded logic.
- Studio's Luau parser bites to avoid:
  - Never start a statement with `(cast)` and never assign to `(x :: T).prop`
    — use a typed local first.
  - Never `Table.Field: Type = value` — use `Table.Field = value :: Type`.

## Done so far

Mining → sell → equipment (5 tiers) → passive income → offline earnings (8h
cap) → dailies → missions → drones (6 tiers, orbiters) → tycoon base (6 pads)
→ Cosmic Reset + 5-branch upgrade tree → shop (IDs 0/SOON) + boosts →
achievements (13) → leaderboards (5 boards) → audio hooks (silent) + FX
(beams, shockwaves, debris) + perf pass (spam guard, revision-gated sync).

## Next (agreed: Zone 2 LAST)

1. Playtest/balance pass on the Zone 1 economy (time-to-upgrade targets).
2. Zone 2 — Asteroid Belt ($100K gate; stub already in `Config/Zones`).
   Then 3–6 per spec §12 (only Zone 3 has a stub; 4–6 need config + fields).

## Test shortcuts

- Boosts with shop unconfigured (server command bar):
  `require(game.ServerScriptService.Services.BoostService).grant(game.Players:GetPlayers()[1], "Credits2x", 15)`
- Prestige: temporarily lower `Threshold` in `Config/Prestige` (restore after).
- Leaderboards need a published place with DataStore API on; Studio serves empty.
