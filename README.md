# ⛏ ASTRO MINER

A Roblox incremental / tycoon / idle-empire simulator. Start with a basic drill
on a rock; end up running an interplanetary mining corporation.

**Mine → Sell → Upgrade → Automate → Expand → Prestige → Repeat**

## Features (Lunar Outpost MVP)

- Manual asteroid mining with crits, rare drops, beams, shockwaves, debris
- Credits / Stardust economy with abbreviated numbers (1K → Qa)
- 5 equipment tiers, 6 drone tiers with visible orbiters, 6 tycoon buildings
  that physically grow your base
- Passive income, offline earnings (8h cap), 7-day daily rewards, daily missions
- Cosmic Reset prestige + 5-branch permanent upgrade tree
- 13 auto-granted achievements, 5 global leaderboards
- Shop hooks (gamepasses / dev products) + temporary boosts
- Fully server-authoritative economy with rate limits and validation

## Quickstart

```bash
rojo serve        # sync via the Studio Rojo plugin, then press Play
# or without the plugin:
rojo build -o AstroMiner.rbxlx   # Studio → File → Open, then Play
```

The map (ground, spawn, refinery, base pads, asteroid field) is built at
runtime — an empty Workspace on open is normal.

## Project layout

- `default.project.json` — Rojo tree (no `Workspace` mapping by design)
- `src/ReplicatedStorage/Shared/Config/` — all game tuning lives here
- `src/ServerScriptService/` — `ServerMain` + `Services/` (authority)
- `src/StarterPlayer/StarterPlayerScripts/` — `ClientMain` + `Controllers/`
- `HANDOFF.md` — active-dev notes: conventions, status, what's next

## Conventions

- Services compute; controllers render. The client never sets currency.
- New content = new Config rows + small service hooks.
- Shop audio/asset IDs are `0` (SOON) until real Creator Dashboard assets exist.

## Roadmap

Balance pass → **Zone 2: Asteroid Belt** → Mars → Jupiter → Deep Space →
Alien Worlds.
