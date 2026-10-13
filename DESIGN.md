# Gameplay design: digging, stairs, supports

Status: **agreed (2026-10-13)**. The project owner decided the open questions (see §6). Numbers are starting values, and most of them are sandbox options.

This builds on what the test mod proved in the real game (42.21): dug rooms count as indoors, stay dry, are dark until lit, keep working after save/reload, and go down to z −4 without flicker.

---

## 1. Digging, tile by tile

**How it plays.**
1. Right-click the wall of a dug area (or a cellar wall) → **Dig**.
2. A cursor shows which tile will be dug.
3. The character walks there and digs with a timed action (shovel animation).
4. The tile opens up. Its walls and floor are placed automatically.

| | Dirt (z −1, −2) | Stone (z −3 and deeper) |
|---|---|---|
| Tool | Shovel / spade (vanilla item tag `DigGrave`) | Pickaxe (vanilla tag `PickAxe`) |
| Time per tile (normal speed) | **~60 s** real time (agreed) | **~3 min** (agreed) |
| Material out | 2 sacks of dirt (needs empty sacks) | 2–4 stones (vanilla stone item) |
| Cost to the character | Endurance, arm and back strain (B42 muscle strain) | More of both |

**Rules.**
- You can't dig when exhausted ("too tired").
- You can't dig next to water, under roads or asphalt without breaking them first, or deeper than the sandbox limit (default −4, tested).
- **Soil must go somewhere (agreed: mandatory).** Each tile needs empty sacks, which become sacks of dirt (vanilla items, so the dirt is useful for farming and sandbag walls). No "soil disappears" mode.
- **Supports are mandatory** (§3): you can't dig a tile that would be too far from a support.
- Strength and Fitness speed digging up. Digging gives a little Strength XP.

**Where you can start.**
- From the **surface**, only by digging stairs or a shaft (§2).
- From a **vanilla basement** wall, to expand an existing cellar. The new area joins that basement.

---

## 2. Getting down

### 2a. Stairs (main entrance; agreed: two steps)

1. On natural ground (grass, dirt, gravel, sand), right-click → **Dig stairs down**.
2. A cursor shows a **1 × 3 tile** stairwell, and you pick the direction (N/E/S/W). Vanilla's own unfinished digging code uses the same 1 × 3 footprint, so we stay compatible if TIS finishes it.
3. **Step 1, dig the stairwell** (shovel, sacks, ~4 min: 3 tiles + landing at ~60 s each):
   - The 3 ground tiles at z 0 are removed, leaving an open hole.
   - 3 tiles plus a 1-tile landing are carved at z −1.
   - A **support is required** at the landing (the stair entrance counts as dug space).
4. **Step 2, build the stairs** (hammer, planks, nails, Carpentry 2, same as vanilla wooden stairs):
   - The mod places real vanilla stairs (`square:AddStairs`, vanilla wooden stair sprites).
   - Walking up and down, pathfinding and zombies use the game's normal stair logic.
5. Deeper levels use the same action from a dug level.

**The opening at z 0.**
- It is open sky, so rain falls into the stairwell like a real outdoor cellar entrance.
- Players can cover it: build vanilla walls and a roof over it (a small shed), or add a cellar door (§2c).
- *Open question:* also offer a quick "cellar hatch roof" build?

### 2b. Ladder shaft (later, Phase 3)

- A 1-tile vertical shaft with a ladder. It is small and hidden, but slow to climb, and you can't carry heavy things.
- It uses the game's built-in rope-climbing mechanic, by giving a ladder sprite climbable properties. This is a vanilla engine feature; the AGPL "Ladders" mod's code is not used.

### 2c. Hatch / cellar door (later, Phase 3)

- A closable cover over the stairwell or shaft.
- When closed it looks like ground: zombies don't notice it and rain stays out.
- It can be lockable.

---

## 3. Supports (mandatory)

**The rule:** every dug tile must be covered by a support.
- **In dirt (z −1, −2):** coverage is **2 tiles** around the support, an area of **5 × 5**.
  - A 5 × 5 room needs one support in the middle.
  - A long tunnel needs a support every 5 tiles.
- **In stone (z −3 and deeper):** rock holds itself better, so every support covers **more**: 3 tiles more around it (agreed).
- All radii are sandbox options.

**Enforcement:**
- The dig cursor turns red and says "Too dangerous: build a support first" when the target tile isn't covered.
- The player can't skip supports. That's the "mandatory" part, and it's predictable rather than random.

| Support | Materials | Skill | Covers in dirt | Covers in stone |
|---|---|---|---|---|
| Wooden mine prop (post + beam) | 2 planks or 1 log, 4 nails, hammer | Carpentry 1 | 2 tiles (5 × 5) | 3 tiles (7 × 7) |
| Stone/brick pillar | stones or bricks, mortar | Masonry 2 | 3 tiles (7 × 7) | 4 tiles (9 × 9) |
| Metal support | metal pipes or sheets, welding torch + mask | Metalworking 2 | 3 tiles (7 × 7) | 4 tiles (9 × 9) |

- **Wooden props are allowed at every depth (agreed).** Stone and metal supports are an upgrade that covers a larger area. They are also sturdier (more health) and don't rot.
- Undug ground around a tunnel doesn't count. Only built supports do.
- Supports are objects with health, so they can be damaged or dismantled.

**Cave-ins** (agreed: **ON by default**, can be switched off in sandbox options):
- If a support is removed or destroyed, the tiles it covered become **unsupported**.
- **Warning first:** creaking sounds and dust for some in-game hours, enough time to fix it.
- If nobody fixes it, each unsupported tile has a chance per in-game hour to **collapse**:
  - It fills back in: it becomes solid ground with walls again.
  - Items on it are buried and lost.
  - A player standing there is hurt depending on the material (agreed 2026-10-13):

    | Collapse in | Result for a player standing on the tile |
    |---|---|
    | **Dirt** (z −1, −2) | **Heavy injuries:** fractures (legs and arms), deep scratches and lacerations, heavy bruising. The player is pushed to the nearest open tile. |
    | **Stone** (z −3 and deeper) | **Instant death** |

  - Zombies standing on a collapsing tile die in both materials.
  - Because stone collapses kill, the **warning must be fair and impossible to miss**:
    - creaking sounds, falling dust and a message ("The ceiling is creaking!") to everyone nearby;
    - at least **6 in-game hours** of warning before the first collapse (sandbox);
    - the warning repeats when a player enters the area.
  - **Multiplayer:** a tile can only collapse while its area is loaded. A player who logs out in a warned area is safe until someone is there again; the warning then restarts.
  - Sandbox options: injury level for dirt (light / heavy / deadly) and for stone (heavy / deadly), and a master switch for cave-ins.
  - Technical (to verify in 42.21): injuries via the vanilla body-part API (fracture time, scratches, lacerations), synced with `syncBodyPart` as other B42 mods do; death on the server through the vanilla kill path, so it counts as a normal death.
- Collapses never spread past the unsupported area, and never happen while the area isn't loaded.

**Implementation notes.**
- Supports are listed in the mod's ModData registry (positions and type), so coverage checks are cheap.
- All checks run on the server (or single player). The client only shows the cursor color.
- Cave-in checks run once per in-game hour, only over unsupported tiles, and only in loaded chunks.
- Sprites are placeholders at first (vanilla wooden post/pillar sprites). Proper mine-prop tiles come in the art phase.

---

## 4. Cellar comfort (approved 2026-10-12)

- **Root cellar:** food in containers in a dug room spoils more slowly (~50 %, sandbox).
- **Frost-free cellar:** in winter after the power shutoff the cellar stays at ≥ ~10 °C.
- Technical details: ANALYSIS.md §5.9.

---

## 5. Multiplayer rules

- Every world change (digging, stairs, supports, cave-ins) happens on the server inside the timed action's `complete()`, as vanilla B42 does.
- New underground squares are created on clients too (the sync tested by the test mod).
- New dug tiles become small rooms right away. Rooms are merged on the next load, so room IDs never shift while the server runs (TEST_RESULTS.md).
- **Safehouse protection:** non-members can't dig in, or under, another group's safehouse.
  - *Open question:* also block digging under any player-built building that isn't yours?

---

## 6. Decisions (project owner, 2026-10-13)

| Question | Decision |
|---|---|
| Sacks of dirt | **Mandatory** |
| Stairs | **Two steps:** dig the stairwell, then build the stairs with planks |
| Wooden supports | **Allowed at every depth.** In stone every support covers a larger area |
| Cave-ins | **ON by default**, sandbox switch to turn off. **Dirt: heavy injuries (fractures, scratches). Stone: instant death.** Fair warning of at least 6 in-game hours first |
| Dig speed | **~60 s per dirt tile, ~3 min per stone tile** at normal speed (changed 2026-10-13; sandbox multiplier) |

**Still open:**
- A quick "cellar hatch roof" build over the stairwell (§2a)?
- Block digging under any player-built building that isn't yours (§5)?
