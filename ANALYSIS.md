# Underground Miner: feasibility analysis and plan

Researched on 2026-10-11, against Project Zomboid **42.21**. Here is how each part was checked:

- **Steam Workshop pages, PZwiki and the TIS forums** could not be opened from the research sandbox. Facts from them come from search-engine snippets and are marked *(unverified)*.
- **Game internals** come from reading vanilla Lua (Umbrella typings for 42.21) and public decompiles of the 42.21 Java code.
- **Competing mods** were checked by reading their source code where it is public.

---

## 1. Bottom line

- **The engine can do it.** Build 42 has real underground levels (z −32 to +31), and Lua can create underground squares at runtime.
- **Basic digging already exists.** *Excavation* has about 189k subscribers and works today. It is limited, though: dug areas count as outdoors, it digs only one level deep, its multiplayer behaviour is weak, and it is not open-licensed.
- **There is room for a much better mod**, but only if it solves the hard problems the others have not:
  1. Dug space that counts as **real indoors**: no rain, cave temperature, dark until you light it.
  2. **Several levels without visual bugs.**
  3. **Correct multiplayer sync.**
  4. **Surviving save and reload**, and a **safe way to uninstall**.

  If those four work, more gameplay (supports, cave-ins, hidden hatches, a root cellar, mining) can go on top. If they don't, more features alone will not beat the existing mod.
- **The first step is a small technical test (a "spike"), not the full mod.** It proves or disproves #1 to #4 in the real game. That decides go or no-go cheaply.

---

## 2. Facts about the game (B42)

| Topic | Fact | Confidence |
|---|---|---|
| Version | 42.20 became stable with multiplayer on 2026-07-29. **42.21 is the current stable**, released around 2026-09-28. | high (dates from snippets) |
| Release pace | A minor version ships every 3–6 weeks. **Each one has broken some mods**: 42.13 rewrote timed actions for multiplayer, 42.15 moved translations to JSON and changed mod IDs, 42.20 forced library API changes, and 42.21 changed some timed-action function signatures. | high |
| Vertical range | z −32 to +31. Each 8×8 chunk has its own min and max level, which **grow automatically** when a square is created. | high (code) |
| Underground | Squares below z=0 **do not exist** until something creates them; the game calls this "the void". There is no rock fill. | high (code) |
| Vanilla basements | Prefab `.pzby` files are stamped **only when a chunk is generated for the first time**. Lua cannot stamp one at runtime, so a mod cannot reuse this for player digging. | high (code) |
| Vanilla digging | **None for players.** But 42.21 contains unfinished stubs: `client/Mining/DiggingUtil.lua`, an `ISDigStairsAction` whose `perform` does nothing, and `ISWorldObjectContextMenu.onExcavateStairs`, which is never added to the menu. **TIS may ship its own digging later.** | high (code) |
| Floors at z ≤ 0 | The vanilla sledgehammer can't remove ground or basement floors (`ISDestroyCursor` allows only z > 0). Vanilla wooden stairs can't be built down into the ground. The mod must do both itself. | high (code) |

---

## 3. Competition (state on 2026-10-11)

| Mod | Build | How it works | Main weaknesses |
|---|---|---|---|
| **Excavation – Basement Expansion** (albion), [Workshop 3392001801](https://steamcommunity.com/sharedfiles/filedetails/?id=3392001801), [GitHub](https://github.com/demiurgeQuantified/Excavation) | B42, v0.2.12 (2026-07-29) | Digs tile by tile with a shovel (dirt) or pickaxe (stone), needs sacks for the dirt, digs stairs down. Real negative-z squares, created server-side. Requires Starlit Library. | **Not indoors** (rain, cold, boredom). Only z −1 by default, because deeper levels flicker badly. Some floors can't be dug. Cutaway bugs. No explicit multiplayer square sync. Its planned features (supports, ores, building walls on dirt) are unbuilt since Dec 2024. **No license file**, so its code can't be copied. |
| **Basement Building** (APAROSA), [3806513504](https://steamcommunity.com/sharedfiles/filedetails/?id=3806513504) | B42.21, ~2026-10-08 | Defines its own room over the dug area, so it **counts as indoors**. Powered light switch, several levels, connected basements merge. | Closed source. Very new. Removing it from a running MP server stops players rejoining. Walls built inside don't split the room. *(unverified)* |
| **HydeCo. Knox Underground!**, [3811471690](https://steamcommunity.com/sharedfiles/filedetails/?id=3811471690) | B42.21, 2026-10-03 | Sewers, caves reached through dry wells, a mining mode, rock layers down to z −30 with ore seams. | WIP. Incompatible with several other underground mods. *(unverified)* |
| **Plysken Underground Revolution**, [3776279483](https://steamcommunity.com/sharedfiles/filedetails/?id=3776279483) | B42, SP only | Shaft, ladder and hatch. Borrows the room of a nearby vanilla cellar so the dug area counts as indoors. | Without a cellar nearby, rain still gets in. No multiplayer. |
| Basement Builder, [3721980333](https://steamcommunity.com/sharedfiles/filedetails/?id=3721980333) | B42 | Kit, a 3-tile preview, automatic walls | Reportedly poorly reviewed |
| Basements (B41), [2849247394](https://steamcommunity.com/sharedfiles/filedetails/?id=2849247394) | B41, deprecated | A hatch teleports you to prefab basements on a hidden far-away map cell | Teleport bugs. Obsolete in B42. |

**What this means:** demand is clearly there. Three new underground mods appeared between September and October 2026, and Excavation has about 189k subscribers. But nobody has shipped all of these together: indoors, several levels, solid multiplayer, open source. The most technically skilled author in this space, albion, who also maintains Starlit, the B42 decompiler and the JavaDocs, still calls indoors "a hard limitation". APAROSA's mod suggests that has changed. **Treat "indoors works" as unproven until we test it ourselves.**

---

## 4. What "much better" would mean

**Core quality**, which none of the existing mods fully covers:

1. **Truly indoor underground rooms.** No rain, cave temperature instead of outdoor wind chill, dark until lit, no zombie respawns inside.
2. **Several levels deep without flicker.** The cause is known in part, see §5.4.
3. **Multiplayer-correct.** Every player sees new tunnels immediately, not only after leaving and coming back.
4. **Persistent.** Rooms, walls and floors are all there after save and reload and after a server restart.
5. **Safe to remove.** An admin or player "prepare for uninstall" command converts the mod's custom tiles to vanilla ones first, so removing the mod doesn't leave holes into the void.
6. **Works with vanilla basements.** Expand an existing cellar, and the new space joins that cellar's room.
7. **Open source** with a small public API, so other mods (ladders, mining, maps) can build on it.

**Gameplay on top**, after the core works:

- **Soil logistics:** dirt has to go somewhere, in sacks or carts, dumped as piles or used for farming and sandbags.
- **Supports and cave-ins:** wooden or metal beams within N tiles, otherwise a risk of collapse. Excavation's top planned feature, never built.
- **Hidden hatch entrance** that zombies don't notice, and a lockable trapdoor.
- **Root cellar:** a stable cool temperature that slows food spoilage.
- **Underground light and power:** lanterns, wiring from a generator or the grid, ventilation for generators and fires.
- **Water:** digging near rivers or below a depth floods tiles, and pumps are needed. Optional.
- **Mining:** stone, then rare ore deposits as an optional sandbox setting. Knox Underground is already going this way, so it is lower priority.

---

## 5. Technical design: how each part works in B42

### 5.1 Creating underground space

- **Create squares** with `getCell():createNewGridSquare(x, y, z, true)`. It returns `nil` if the chunk isn't loaded, so check for that.
  - Don't use `getOrCreateGridSquare`. On an unloaded chunk it creates an orphan square that isn't attached to anything.
- **Chunk levels** extend automatically.
  - Never shrink them with `setMinMaxLevel`, because that deletes the squares on the dropped levels.
  - After creating a new level, call `getCell():getChunkMap(i):calculateZExtentsForChunkMap()`, as vanilla does.
- **All world changes happen on the server,** inside the timed action's `complete()`:
  - The timed action file goes in `media/lua/shared/`. Since 42.13, `complete()` runs on the server in MP and locally in SP.
  - Add objects with `square:transmitAddObjectToSquare(obj, -1)`.
  - Remove them with `square:transmitRemoveItemFromSquare(obj)`.
- **Use the renamed API.** `:Is(flag)` became `:has(flag)` in B42.

### 5.2 Persistence

- **Every dug square needs a floor object**, such as dirt `blends_natural_01_64`. The engine does not save empty squares below z=0, so they vanish on reload.
- **Room membership is not saved.** It is recalculated from the map's room data on load.
  - Our own "dug area" registry has to live in global ModData.
  - Rooms must be re-applied on every world load, see §5.3.

### 5.3 Indoors (the hardest problem, and the reason for the spike)

**How the engine decides indoors:** a square counts as outdoors when `roomID == -1` and it has no roof.

- **Roof:** the roof flag is set only from rain-blocking tiles at z ≥ 1.
  - The z = 0 ground does **not** roof z = −1.
  - Lua cannot set the roof flag.
- **Open air:** if a square is outdoors and so is every square above it, it counts as "open air". It then gets **skylight**, so a tunnel under open ground is lit like daytime.
- **Rain, wind chill and temperature** all follow these same flags.
- **Vanilla's room detection for player builds** (IsoRegions) does not work below z = 0.

**Update after reading the 42.21 game code.** The test mod uses approach 1 below, through the game's own `BuildingRoomsEditor`. What the code shows:

- **Registering rooms.** `BuildingRoomsEditor` is reachable from Lua. `createBuilding()` → `createRoom(z)` → `addRectangle()` → `applyChanges()` adds a user-defined building to the room map.
  - Its rooms are created with `explored = true` and `doneSpawn = true`. So they should not spawn zombies or loot.
  - On the player's machine, `applyChanges(false)` also updates loaded squares, lighting, cutaways and pathfinding.
- **Saving and reloading.** The game never writes these rooms to disk itself. Rooms are not saved per square either: on chunk load each square gets its room from the room map.
  - So the mod stores its rooms in ModData and registers them again in `OnLoadedMapZones`. That event fires after the room map loads and before any chunk loads.
- **Never pass a room ID through Lua.** Room IDs are 64-bit, and Lua numbers are doubles. For map cells with Y index ≥ 32 (most of Knox County) the ID silently loses precision. Calling `square:setRoomID()` from Lua is therefore unsafe; the test mod lets Java assign rooms instead.
- **Server timing.** A dedicated or hosted server has no player chunk maps, so its already-loaded squares only pick up a new room when the chunk reloads. Vanilla's own player-built rooms behave the same way.
  - Where the ID is small enough to be exact, the test mod sets it on the server immediately.
- **Mark the buildings as normal map buildings. Found in testing (game test, 2026-10-12).** The editor creates "user-defined" buildings, but those belong to the player-built building system (IsoRegions). After reload it rebuilds every user-defined building in the cell from its own data. On ours it threw a `NullPointerException` in `WorldRegionToMetaGrid.assignBuildingToRegions` every frame, which sent the player back to the menu.
  - Fix: right after registering, call `setUserDefined(false)` on our buildings.
  - Surface player builds are unaffected, because that system only compares basements with basements (`BuildingDef.isBasement`).
  - Side effect: the game now also saves our rooms in `map_meta.bin`. On load it logs a harmless "invalid room/building metaID" for each of them, because they are re-registered only later.
- **Growing a room.** Re-registering a building at the same position and level *replaces* it, because the building and room "meta IDs" include x, y and z. That gives a way to grow one room tile by tile.
  - Side effect: room IDs of rooms added later in the same 256×256 cell shift. The test checks how much that matters.

**So the dug area needs a real room.** Candidate approaches, in the order to try:

1. **Create `RoomDef`/`BuildingDef` (or `IsoRoom`) objects from Lua and register them in the map's room data.**
   - Candidate calls: `IsoMetaCell.addRoom`, `RoomDef.new`, `BuildingDef.new(true)` for a user-defined building, `RoomDef:refreshSquares`, and `IsoGridSquare:setRoom`.
   - Re-create them from ModData on every load, on the server and on every client.
   - APAROSA's mod appears to do something like this.
2. **The `BuildingRoomsEditor` API** (`createBuilding`, `createRoom`, `addRectangle`, `applyChanges`).
   - It is exposed to Lua, but in 42.21 its save function is never called and it has no network packet. Probably debug-only.
3. **Join an existing cellar's room** (Plysken's trick).
   - This works only next to a vanilla basement. Use it as a bonus for expanding cellars.

**The spike must check:**
- Does the room stop rain?
- Does it stop wind chill?
- Does it remove skylight, so the area is dark?
- Do placed lights work inside it?
- Does it survive save and reload?
- Does it work on the MP server and on a second client?
- Does it stop zombie spawns?
- Is it stable when the room grows tile by tile?

### 5.4 Lighting and several levels

- Excavation's flicker on "even" depths matches a known engine quirk. Its helper library (Starlit) keeps each chunk's lowest level from becoming **odd**, because "if it does, when the next lowest level is created its lighting will be severely bugged."
- The plan is to always grow levels in pairs, and to test z −1 to −4 in the spike. If flicker stays, limit the depth by default (like Excavation) and keep investigating.
- **Confirmed in the code:** the renderer draws underground levels in pairs: −2/−1, −4/−3 and so on (`FBORenderLevels.calculateMinLevel`). So a chunk whose lowest level is odd has a half-empty pair.
  - The test mod keeps every chunk's lowest level even. It creates an empty helper square one level down, and redoes this after reload, because empty squares aren't saved.
- **A likely cause of the existing flicker bugs:** Starlit's parity check (`IsoObjectUtils.addSquare`) appears to have its comparison reversed (`minLevel < z - 1`).
  - If so, it never extends the chunk downward. Worse, it can *raise* the lowest level, which deletes deeper squares.
  - That may explain Excavation's flicker and its "walls disappeared" reports when the depth limit is turned off.
  - This is from reading the code only; not confirmed in game.
- While the player is underground, the renderer draws only that level and the levels below it. That is useful, because nothing above clutters the view.

### 5.5 Getting down

- **Our own "dig stairs" action** removes the z = 0 floor server-side and places stair tiles at z = −1, the same layout as vanilla basements, which have their stairs at z = −1 with the top at z = 0.
- **Hatch with a ladder or shaft**, for a hidden entrance. Vanilla rope-climbing flags (`climbSheet*`) can make a ladder climbable; this is the technique the "Ladders!?" mod uses, and that mod is AGPL.

### 5.6 Multiplayer

- **The problem:** the server can create a square and send objects, but **clients drop objects for squares they don't have.** Players who already have the area loaded don't see the new tunnel until it reloads, and this is probably behind the "walls missing" reports.
- **The fix**, which vanilla building also does by creating the square on both sides:
  1. The server creates the squares and objects.
  2. It sends `sendServerCommand` to nearby clients.
  3. The clients call `createNewGridSquare` for those coordinates.
  4. The object packets then land.
- **Room registration** (§5.3) needs the same server-to-client broadcast, plus a full resync when a player joins.

### 5.7 Tiles and art

- **Vanilla has no dirt or rock wall tiles.** Excavation ships its own `walls_underground_dirt` set.
- **B42 custom tiles are more than a PNG:** they need a `.tiles` definition, a texture pack, depth maps and tile geometry. That means **TileZed / WorldEd**, which are Windows tools.
- **Plan:** prototype with vanilla stand-ins (stone and bunker walls, `blends_natural_01_64` floor), and add proper art later.
- **Custom tiles are also what makes uninstalling dangerous**, see §4 item 5.

### 5.8 Mod structure

```
Contents/mods/UndergroundMiner/
  common/                    # shared assets (tiles, textures, translations JSON)
  42.21/                     # versioned code folder; the game picks the highest ≤ running version
    mod.info                 # id, name, versionMin=42.21.0, require=...
    media/lua/shared/        # timed actions, shared logic
    media/lua/server/        # world changes, room registry
    media/lua/client/        # context menu, cursors, UI, client-side square sync
    media/sandbox-options.txt
workshop.txt, preview.png
```

---

## 6. Risks

| Risk | Impact | Mitigation |
|---|---|---|
| Indoor rooms impossible or unstable from Lua | Removes the main reason this mod would be better | Spike first; go/no-go before building features |
| TIS ships vanilla digging (the stubs are already in the game) | The mod becomes partly obsolete, or conflicts with it | Keep the core small. Watch patch notes. Pivot to "gameplay on top of vanilla digging" if it lands. |
| API churn every 3–6 weeks | Regular breakage | Versioned folders, a test checklist per release, a small surface area |
| Multiplayer edge cases (joins, chunk streaming, server restart) | Desync and lost tunnels, which players hate most | Server-authoritative design, explicit resync, a two-client test setup |
| Custom tiles leaving holes when the mod is removed | Broken saves, bad reviews | Uninstall command, and vanilla tiles where possible |
| I can't run the game in this environment | Slow test loop | Clear test scripts and debug logging. You run the tests and send me `console.txt`. |
| Conflicts with other underground mods | Bug reports | A small public API. Coexist with vanilla basements and Excavation, or detect them. |

---

## 7. Roadmap

**Phase 0: technical spike** (go/no-go). **Built:** `Contents/mods/UGMSpike`. The test steps are in `TESTING.md`.
A debug-only test mod with right-click commands:
1. Carve a 5×5 room at z −1 under the player, with walls and a floor.
2. Register it as a room (approach §5.3-1, then -2).
3. Print `isOutside`, `isInARoom`, `getOpenAir` and the temperature at the player.
4. Grow the room by one tile, and add z −2 to z −4.

You run the test script: SP, then save and reload, then a hosted MP game with a second client. **Decision point:** if indoors plus persistence plus MP sync work, go on. If not, choose between a smaller "gameplay add-on" scope and stopping.

**Phase 1: MVP** (single player)
- Dig dirt with a shovel, needing sacks.
- Dig stairs down, and remove natural floors.
- Automatic walls and floor.
- Indoor rooms.
- Depth down to −2.
- Sandbox options.
- English translations.

**Phase 2: multiplayer hardening**
- Client square sync, room sync on join, server-restart tests, admin uninstall command.

**Phase 3: gameplay depth**
- Supports and cave-ins, hidden hatch, root cellar temperature, light and power, then optional mining and water.

**Phase 4: art and polish**
- Custom dirt and rock wall tiles, sounds, Workshop page, translations.

**Ongoing:** retest on every minor game release.

---

## 8. How we would work, and what I need from you

**Dev loop:**
1. I write and push the code on this branch.
2. You copy `Contents/mods/UndergroundMiner` into `~/Zomboid/mods/`, or on Windows `C:\Users\<you>\Zomboid\mods\`.
3. You start the game with the `-debug` launch option and follow the test script.
4. You send me `~/Zomboid/console.txt` and, if needed, screenshots.

**Decisions and inputs I need:**
1. **Go or no-go on Phase 0.** Recommended: yes. It is cheap and tells us whether "much better" is achievable.
2. **Target:** B42 only, 42.21 and newer (recommended). Single player first, or multiplayer from day one?
3. **Testing setup:**
   - Do you own PZ, and on which OS?
   - Can you run `-debug` and send logs?
   - For MP tests, can you host a local server and connect a second client (a second PC or Steam account, or the `-nosteam` method)?
4. **Mod name and ID**, and the author name for the Workshop.
5. **License:** recommended MIT or another open license; it is also a selling point against closed competitors.
6. **Art:** OK with vanilla placeholder tiles at first? Later, who makes the dirt and rock tiles (you, a contributor, or me producing textures that you pack with TileZed on Windows)?
7. **Your top 3 gameplay features** from §4.
8. **Optional:** run [ZomboidDecompiler](https://github.com/demiurgeQuantified/ZomboidDecompiler) on your own install, so we read the exact Java code of your game version.

---

## 9. Sources

- Excavation source: https://github.com/demiurgeQuantified/Excavation (read: `DiggingAPI.lua`, `server/Excavation/Mining.lua`, `workshop.txt`, `mod.info`)
- Starlit Library source: https://github.com/demiurgeQuantified/StarlitLibrary (`IsoObjectUtils.addSquare`)
- Umbrella typings and vanilla Lua 42.21: https://github.com/asledgehammer/Umbrella
- Vanilla Lua 42.20.2: https://github.com/Project-Zomboid-Community-Modding/ProjectZomboid-Vanilla-Lua
- Decompiled 42.21 Java (third party): https://github.com/rbm4/apocalipsebr-zomboid-patches
- ZomboidDecompiler: https://github.com/demiurgeQuantified/ZomboidDecompiler
- Ladders mod (AGPL-3.0): https://github.com/quarantin/zomboid-ladders
- B42 stable plans: https://projectzomboid.com/blog/news/2026/07/build-42-stable-plans/
- 42.21 stable: https://projectzomboid.com/blog/news/2026/09/42-21-stable-released/
- Basements dev blog: https://projectzomboid.com/blog/news/2023/10/cellar-door-doid/
- Workshop pages listed in §3 (content from search snippets, unverified)
