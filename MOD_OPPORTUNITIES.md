# Which mod would help the community most? (Project Zomboid, October 2026)

Researched on 2026-10-11. The game is on 42.21 stable, and B42 multiplayer has been stable since 42.20 (July 2026).

> **How reliable this is.** Steam, Reddit, the TIS forums and PZwiki could not be opened from the research environment, and Reddit was not searchable at all. Everything below comes from search-engine snippets of Workshop pages, Workshop mirror sites, gaming press and GitHub. Subscriber counts are cached snapshots and often disagree with each other. Treat the numbers as rough and the rankings as informed judgement, not measurement.

---

## 1. Short answer

Players want three kinds of mod most, and each has a different catch:

1. **Companions and NPCs.** This is the biggest demand. A companion dogs mod reached about 190–400k subscribers within months. But the space is crowded with alpha mods, and **vanilla NPCs arrive in Build 43**. Avoid it.
2. **Underground: digging, basements, sewers, mining.** Demand is proven (Excavation about 189k), but **4 or more competitors appeared in the last 2 weeks**, and vanilla has unfinished digging code. It is still winnable on quality: real indoors, several levels deep, solid multiplayer. That is what our test mod checks.
3. **Server and multiplayer tooling, defenses, late-game goals.** Steady demand, **weak supply**, low vanilla risk, and no 3D art needed. These fit a one-person Lua team best.

**My recommendation:**
- **Keep underground as the main project**, but only if the test mod passes (see `TESTING.md`). We now understand the engine problems better than the existing mods appear to.
- **If the test fails**, or as a second, smaller project, build **zombie defenses and traps** or a **multiplayer admin and anti-grief toolkit**. You run a server with friends, which is a ready-made test group for the toolkit.

---

## 2. Ranked opportunities for us (1 developer + AI, Lua, little 3D art)

Score from 1 (bad) to 5 (good). "Fit" is how well it suits our skills and setup.

| # | Idea | Demand | Competition (5 = little) | Difficulty for us (5 = easy) | Art needed (5 = none) | Vanilla risk (5 = safe) | Fit | Notes |
|---|---|---|---|---|---|---|---|---|
| 1 | **Underground done right**: real indoors, several levels, multiplayer-safe, supports and cave-ins | 5 | 2 | 2 | 3 | 2 | **4** | Proven demand. Win on quality, not features. Test mod decides go/no-go. |
| 2 | **Zombie defenses and traps**: spike pits, blade traps, barricade damage, alarms | 4 | 5 | 3 | 3 | 4 | **4** | Weak coverage in B42 and steady requests. Can reuse vanilla sprites at first. |
| 3 | **Multiplayer admin and anti-grief toolkit**: action/loot log viewer, rollback helpers, a staff panel that works on 42.21, a "which mods failed to load" check | 4 | 4 | 4 | 5 | 3 | **5** | Multiplayer went stable in July and admin tools are fragmented. Pure Lua UI. You can test it on your own server. |
| 4 | **Late-game goals and events**: meta events, roaming hordes, base upkeep, objectives | 3 | 3 | 4 | 5 | 4 | **4** | "Nothing to do once the base is built" complaints. Expanded Helicopter Events is close to a B42 version, so avoid copying it. |
| 5 | **PvP factions, territory and raids** (successor to SSR) | 3 (PvP servers) | 5 | 3 | 4 | 5 | 3 | Smaller audience, but nothing like it exists. Vanilla factions are only planned for B45. |
| 6 | **One maintained, multiplayer-safe solar/electricity mod** | 3 | 2 | 3 | 3 | 4 | 3 | Immersive Solar Arrays was a B41 hit; it now has 3+ forks, and Electricity Zones exists. |
| 7 | **Small QoL: repeat or queue a craft N times**, finer item moving | 3 | 4 (unverified gap) | 5 | 5 | 3 | 3 | Quick win. Gap not confirmed. |
| 8 | **Night and darkness visibility** (Darkvision-style port) | 4 | 4 | 2 | 5 | 4 | 2 | Long complaint threads, but another modder says B42 lighting blocked a similar effect. Technical risk. |

**Avoid for now:**
- **Companion NPC engines:** crowded alpha field, and vanilla NPCs come in B43.
- **Weapon packs:** official Brita B42 versions are on the way.
- **Vehicles and vehicle armor:** heavy 3D art. SVU3 and a new "Vehicle Armor Crafting" mod already cover armor.
- **Maps:** TIS hasn't released the B42 map tools yet.
- **General UI overhauls:** the Neat UI family dominates.
- **Livestock and mod-options frameworks:** vanilla covers both now.

---

## 3. Evidence summary

### What players ask for (demand)

| Theme | Strength | Evidence (snippet-level) |
|---|---|---|
| Companions/NPCs | High, crowded | Companion Dogs about 193–400k subscribers ([Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=3740052292)); "Any friendly NPC mods for Build 42 yet?" ([Steam thread](https://steamcommunity.com/app/108600/discussions/0/592885445492226701/)); Project A-Life covered by [PCGamesN](https://www.pcgamesn.com/project-zomboid/mod-a-life-npcs-factions) |
| Underground | High, filling fast | Excavation about 189k ([Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=3392001801)); Sewers Under Every Town about 9.7k in 5 days ([top-mods](https://top-mods.com/mods/project-zomboid/gameplay/16454-sewers-under-every-town-build-42.html)); HydeCo Knox Underground with ore layers to z −30 ([top-mods](https://top-mods.com/mods/project-zomboid/gameplay/16541-hydeco-knox-underground-42-21-0.html)) |
| Mounts | High, filled | Horse Mod about 409k ([Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=3661336777)) |
| Darkness | Medium-high | "In an unlit basement you literally cannot see" ([Steam thread](https://steamcommunity.com/app/108600/discussions/0/691996029262765027/)); Darkvision author invites a port ([Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=2916589393)) |
| Grind/tedium | Medium-high | Slow Nimble and aiming leveling ([TIS forum](https://theindiestone.com/forums/topic/100783-b42-feedback-from-a-longtime-vet/)) |
| Crafting UI clutter | Medium, mostly filled | [Steam thread](https://steamcommunity.com/app/108600/discussions/0/84032037661524113/); Neat Crafting and others exist |
| Late-game emptiness | Medium | "No point… once you get your base built" ([Steam thread](https://steamcommunity.com/app/108600/discussions/0/595135824845103681/)) |
| Abandoned B41 favourites | Medium | Vanilla Firearms Expansion on hold; Immersive Solar Arrays forks; Inventory Tetris forks; Brita and Raven Creek unofficial ports only |
| Single-player-only hits need multiplayer | Medium | Horse riding, Project Remnants, True Sewers, SOTO in multiplayer |

### What exists and what is missing (supply)

- **Strong or crowded:** UI and QoL (Neat/Clean UI, Inventory Tetris, Proximity Inventory), vehicles (KI5, Autotsar), traits, hostile NPCs (the Bandits ecosystem, about 1M subscribers).
- **Fragmented:** companion NPCs (all alpha), solar and electricity, water pipes, economy and shops.
- **Weak:**
  - zombie defenses and traps (no spike-pit or blade-trap mod found)
  - PvP factions and raids
  - multiplayer admin tooling (one admin panel is stuck on 42.18, and a 42.20.2 bug broke vanilla admin cheats)
  - large crafting overhauls (Hydrocraft scale)
  - firearms (official Brita pending)
  - maps (waiting for tools)
- **Big B41 mods with no good B42 version:** Hydrocraft, Arsenal(26) GunFighter, official Brita, Superb Survivors, Eris Minimap, SSR faction capture, and official versions of Raven Creek, Immersive Solar Arrays and True Music.

### What vanilla covers or will cover (don't build these)

- **Already vanilla in 42.x:**
  - mod options API
  - sitting
  - picking items up off the ground
  - animals and livestock
  - the hunting and trapping overhaul
  - about 400 procedural + 75 hand-made basements
  - generator range options
  - rain-collector plumbing
  - admin roles and permissions
  - read-book checkmarks
- **Rest of 2026:** a "B42 Support Update" with optimization, more modding support and multiplayer fixes ([TIS blog](https://projectzomboid.com/blog/news/2026/07/next-steps-2/)).
- **Build 43:** first stage of NPCs. Undated; don't expect it in 2026. Factions come in B45.
- **Digging:**
  - **No TIS announcement of player digging.**
  - A 2024 dev comment says players won't be able to tunnel out of underground structures in 42 (snippet only).
  - The 42.21 game files contain **unfinished digging code** (`DiggingUtil.lua`, `ISDigStairsAction`). This is the main long-term risk for any digging mod.

---

## 4. What this means for the underground project

- **Demand:** confirmed, and the biggest mod in the niche is weak exactly where we're aiming.
- **Competition:**
  - Excavation (about 189k, WIP).
  - Basement Building (closed source; claims indoors).
  - HydeCo Knox Underground (mining layers and ores).
  - Plysken (single player only).
  - Several sewer mods.
- **Our edge, if the test passes:**
  - dug rooms that count as indoors and survive reloads, through the vanilla room system
  - a likely fix for the multi-level flicker: underground levels render in pairs, so a chunk's lowest level must stay even
  - correct multiplayer sync
  - open source
  - working **with** Excavation and the sewer mods instead of against them
- **Positioning:** "the underground that actually feels like a basement": indoors, dark, cool, safe from rain, multiplayer-solid, several levels. Then add supports and cave-ins, which Excavation planned but never built.

If the test shows that indoors or multiplayer can't be made reliable, switch to idea #2 (defenses and traps) or #3 (multiplayer admin toolkit) from the table above.
