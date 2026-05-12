# 🏭 Factorio Docker Server

A ready-to-run Factorio dedicated server using Docker Compose, with boilerplate
config and a curated set of quality-of-life mods.

---

## 📁 Project Structure

```
factorio-server/
├── docker-compose.yml          # Main compose file
├── .env.example                # Environment variable template → copy to .env
├── download-mods.sh            # Helper script to pull mods from the portal
└── data/                       # All persistent server data (auto-created on first run)
    ├── config/
    │   ├── server-settings.json   # Server name, password, autosave, etc.
    │   ├── map-gen-settings.json  # World generation (ore, water, enemies)
    │   └── map-settings.json      # Runtime behaviour (evolution, pollution)
    ├── mods/
    │   └── mod-list.json          # Which mods are enabled / disabled
    └── saves/                     # World saves (auto-generated)
```

---

## 🚀 Quick Start

### 1. Prerequisites

- [Docker](https://docs.docker.com/get-docker/) + [Docker Compose](https://docs.docker.com/compose/) installed
- Ports **34197/UDP** (game) open on your firewall / router

### 2. Clone / copy the project

```bash
# If you have the files already, just cd into the directory:
cd factorio-server
```

### 3. Create your .env file

```bash
cp .env.example .env
# Then edit .env with your favourite editor and set at minimum RCON_PASSWORD.
# FACTORIO_USERNAME / FACTORIO_TOKEN are only needed for the public server list
# and for downloading mods with download-mods.sh.
```

### 4. (Optional) Download mods

> Requires `curl` and `jq`, and your `FACTORIO_USERNAME` + `FACTORIO_TOKEN` in `.env`.  
> Get your token at <https://www.factorio.com/profile>.

```bash
chmod +x download-mods.sh
./download-mods.sh
```

### 5. Start the server

```bash
docker compose up -d
```

The first boot generates a new world using your `map-gen-settings.json`.
Watch the logs to confirm it's ready:

```bash
docker compose logs -f factorio
# Look for: "Hosting game at IP ADDR:(34197)"
```

### 6. Connect in-game

Open Factorio → **Multiplayer → Connect to address** → enter your server's
IP / hostname. The game port is `34197`.

---

## ⚙️ Configuration

### Server settings (`data/config/server-settings.json`)

| Key | Default | Purpose |
|-----|---------|---------|
| `name` | My Factorio Server | Name shown in server browser |
| `max_players` | 16 | 0 = unlimited |
| `visibility.public` | false | Set `true` + add token to appear in public list |
| `visibility.lan` | true | Visible on local network |
| `autosave_interval` | 10 | Minutes between auto-saves |
| `autosave_slots` | 5 | Number of rotating save slots |
| `allow_commands` | admins-only | `true`, `false`, or `admins-only` |
| `auto_pause` | true | Pause when no players are online |

### Map generation (`data/config/map-gen-settings.json`)

Edit **before** first launch (changing it after won't affect an existing world).

- Ore sizes are set to **big** and richness to **very-high** by default — great for multiplayer.
- Set `"peaceful_mode": true` to disable biters entirely.
- Change `"seed"` to a specific number for reproducible worlds.

### Enemy difficulty (`data/config/map-settings.json`)

Key knobs:

| Path | Default | Effect |
|------|---------|--------|
| `enemy_evolution.time_factor` | 0.000004 | Raise to speed up biter evolution |
| `enemy_evolution.destroy_factor` | 0.002 | Evolution boost per nest destroyed |
| `enemy_expansion.enabled` | true | Whether biters spread |
| `pollution.enabled` | true | Disable to stop pollution-triggered attacks |

---

## 🧩 Mods

Configured for **vanilla 2.0 base game** (no Space Age / Quality / Elevated Rails).
The DLCs are disabled both via env vars in `docker-compose.yml` (`DLC_SPACE_AGE=false`, etc.)
and explicitly turned off in `data/mods/mod-list.json`.

### Enabled QoL mods (no DLC required)

| Mod (portal slug) | What it does |
|-----|-------------|
| **flib** (`flib`) | Shared Factorio mod library — dependency for many QoL mods. Required by Factory Planner, Rate Calculator, Bottleneck Lite, etc. |
| **Ammo Alerts** (`AmmoAlerts`) | On-screen warnings when turret ammo is low. |
| **Auto Deconstruct** (`AutoDeconstruct`) | Automatically marks depleted miners for deconstruction. |
| **Auto Research (fixed + re-published)** (`AutoResearch_Continued`) | Auto-queues research and prioritises cheapest / most useful tech. |
| **Bottleneck Lite** (`BottleneckLite`) | Coloured status lights on machines (idle / starved / full) — lighter rewrite of classic Bottleneck. |
| **Bullet Trails** (`BulletTrails`) | Visible tracer trails on bullets — easier to debug turret coverage. |
| **Disco Science** (`DiscoScience`) | Labs flash colours of the science pack they're currently consuming. Pure eye candy. |
| **Even Distribution** (`even-distribution`) | Shift-click splits a stack evenly across the machines under the cursor. |
| **Factory Planner** (`factoryplanner`) | In-game production planner — calculate ratios for any product. |
| **Lighted Electric Poles +** (`LightedElectricPoles+`) | Adds a lamp to every electric pole — free, automatic lighting. |
| **More Descriptions** (`more-descriptions`) | Adds tooltips with useful extra info on vanilla items / buildings. |
| **Queue To Front (limited)** (`QueueToFrontLimited`) | ALT+Q toggles between back / front crafting queue. Admin map setting can cap queue length to protect against server lag. |
| **Rate Calculator** (`RateCalculator`) | Select an area, see total throughput / consumption rates. |
| **Resource Map Label Marker** (`ResourceLabels`) | Auto-adds map labels to discovered ore patches. |
| **Text Plates** (`textplates`) | Buildable letter/number plates to label belts, depots, train stops, etc. |
| **Timelapse Base Edition** (`TLBE`) | Takes interval screenshots of your base for timelapse videos. ⚠ Authored for the desktop client — likely a no-op (or load error) on headless servers. |
| **VehicleSnap** (`VehicleSnap`) | Smooths car / tank steering so vehicles snap to 4 / 8 / 16 directions. |

> **Portal slug** is the URL slug used on `mods.factorio.com`. If you ever
> rename a line in `mod-list.json`, use the slug (case-sensitive), not the
> human-friendly display name.

### Disabled (force-off)

`elevated-rails`, `quality`, `space-age` — the three DLCs that ship inside the
`factoriotools/factorio:stable` image. Setting `DLC_*=false` in
`docker-compose.yml` *and* `enabled: false` in `mod-list.json` keeps them off.

### Installing the mods

Two options.

**Option A — Download from the portal (recommended)**

Requires `FACTORIO_USERNAME` + `FACTORIO_TOKEN` in `.env`.

```bash
./download-mods.sh
docker compose restart factorio
```

The script reads `mod-list.json`, fetches the latest 2.0-compatible release of
each enabled mod, and drops the `.zip` files into `data/mods/`. Mods whose slug
doesn't match the portal print `⚠ Not found on mod portal, skipping` and are
ignored — the server still boots.

**Option B — Copy from your local Factorio install**

If you already have these mods enabled in your desktop Factorio, the `.zip`
files are already on your Mac. Copy them straight in:

```bash
cp ~/Library/Application\ Support/factorio/mods/*.zip ./data/mods/
docker compose restart factorio
```

This avoids re-downloading and guarantees you get the exact same versions you
play with locally (no slug-name guessing).

---

## 🔧 Useful Commands

```bash
# Start server
docker compose up -d

# Stop server
docker compose down

# View live logs
docker compose logs -f factorio

# Attach to RCON console
docker compose exec factorio rcon-client

# Restart only the game server
docker compose restart factorio

# Update to latest stable image
docker compose pull && docker compose up -d

# Start with RCON web UI (http://localhost:4326)
docker compose --profile rcon up -d
```

---

## 🌐 Public Server Listing

1. Register at <https://www.factorio.com/> and get your token from your profile.
2. Add to `.env`:
   ```
   FACTORIO_USERNAME=your_username
   FACTORIO_TOKEN=your_token
   ```
3. Set `"visibility": { "public": true }` in `server-settings.json`.
4. Restart: `docker compose restart factorio`

---

## 📦 Volumes & Backups

All data lives in `./data/`. Back it up with:

```bash
tar -czf factorio-backup-$(date +%Y%m%d).tar.gz ./data/saves ./data/mods
```

Or set up a cron job:

```cron
0 3 * * * cd /path/to/factorio-server && tar -czf /backups/factorio-$(date +\%Y\%m\%d).tar.gz ./data/saves
```

---

## 🐛 Troubleshooting

| Problem | Fix |
|---------|-----|
| Server not visible on LAN | Check `visibility.lan: true` in server-settings.json |
| Port not reachable | Open UDP 34197 in firewall / forward in router |
| Mods desyncing clients | Ensure all players have **identical** mod versions |
| "Map not found" on start | Delete `./data/saves` and let it regenerate |
| High RAM usage | Lower `mem_limit` in compose or reduce `max_players` |

---

## 📄 References

- [Official Docker image](https://github.com/factoriotools/factorio-docker)
- [Factorio Mod Portal](https://mods.factorio.com/)
- [Server settings docs](https://wiki.factorio.com/Multiplayer#Setting_up_a_Linux_Factorio_server)
