# Testing the UGM Spike test mod

This is **not the real mod**. It is a small debug tool that answers four questions in your real game (42.21) before we build anything big:

1. Can a dug-out underground room count as **real indoors**: no rain, not lit like daylight, indoor temperature?
2. Does that **survive save, quit and reload**, and a **server restart**?
3. Do **other players** on a server see a new underground room straight away?
4. Can we go **several levels deep without flicker** or visual glitches?

It creates 5×5 rooms with log walls and a dirt floor. The log walls are only stand-ins for real dirt walls. You move between levels by teleporting; the real mod will have stairs. A text overlay in the top-left corner shows what the game thinks about the tile you're standing on.

> ⚠️ Use a **new throwaway save** only. Don't add this mod to your real save or your friends' server world.

---

## 1. Install

1. Copy the folder `Contents/mods/UGMSpike` from this repository into your Zomboid mods folder:
   - Windows: `C:\Users\<you>\Zomboid\mods\UGMSpike`
   - Linux/Mac: `~/Zomboid/mods/UGMSpike`

   Check the result: the file `...\Zomboid\mods\UGMSpike\42\mod.info` must exist.
2. In Steam, right-click Project Zomboid → Properties → Launch options, and add `-debug`. This shows Lua errors.
3. Start the game. On the main menu open **Mods**, enable **Underground Miner - Test Spike** and save.
4. Start a **new** Sandbox game. Optional but recommended: set Zombie count to *None* so nothing interrupts the tests.

When the game loads, the top-left corner shows yellow text **"UGM Spike - live (SP)"** with lines such as `isOutside`, `isInARoom` and `light`. If you don't see it, the mod didn't load: send me `console.txt`.

Every action is in the right-click menu under **UGM Spike (test)**.

---

## 2. Test A: single player

Write down what you see for each step. A results table to fill in is at the end of this file.

**A1: Carve and go down**
1. Stand on open grass **outside**, not inside a building.
2. Right-click → UGM Spike → **1. Carve test room below me**.
3. Right-click → UGM Spike → **2. Teleport down one level**.
4. Read the overlay. The hoped-for values are `isOutside: false`, `isInARoom: true`, `openAir: false` and `room: ugm_spike ...`.
5. Is the room **dark** or bright like daytime? Note the `light` value.

**A2: Rain**
1. Right-click → **Start rain**, then wait about 2 real minutes.
2. Underground: does `wetness` stay at 0? Do you see raindrops or puddles inside the room?
3. Use **3. Teleport up one level** and check that you *do* get wet on the surface, so we know the rain is real.
4. Compare `airTemp` on the surface and underground.
5. Right-click → **Stop rain override**.

**A3: Light**
Use a flashlight or a lit lantern in the room. Does it light the room normally?

**A4: Expanding the room**
1. Stand inside the room and choose **Grow room 1 tile east (separate room)**. A one-tile pocket opens on the east side of the centre row.
2. Walk into the pocket and check the overlay.
3. Choose **Grow room 1 tile east (same room)**, walk into that tile and check again.
4. Do the walls look right? Does the room still count as indoors?

**A5: Several levels**
1. While in the z = −1 room, choose **Carve test room below me**, then **Teleport down**. You're now at z = −2.
2. Repeat to get to z = −3 and z = −4.
3. On each level, walk around and go up and down. Watch for **flickering, black areas, missing walls, or tiles from other levels showing through**.
4. If you see glitches, try **Redraw nearby chunks** and note whether that fixes them.
5. Take screenshots of any glitch.

**A6: Save and reload** (the most important test)
1. Press Esc → Quit to main menu, then load the same save.
2. Teleport down to each room. Are the walls and floors still there?
3. Does the overlay still show `isInARoom: true` and `isOutside: false`?

**A7 (optional): Under a house**
1. Go inside a house on the ground floor and repeat A1 there.
2. Afterwards, check that the house itself still behaves normally upstairs: roof, walls hiding, lights.

**A8 (optional): Proof check**
1. Right-click → **Forget all test rooms (registry)**, save, quit and reload.
2. The rooms should now show as **outdoors**. That proves our own re-registration is what makes them indoors, and also shows whether the game saves them by itself.

**After Test A:** copy `C:\Users\<you>\Zomboid\console.txt` somewhere safe. The game overwrites it on every launch; older copies are in `Zomboid\Logs`.

---

## 3. Test B: your own server on your laptop

1. Main menu → **Host**. In the server settings, enable the **Underground Miner - Test Spike** mod, then start. As the host you're admin, which the teleport option needs.
2. Repeat **A1, A2, A4 and A5**. "Start rain" now changes the server's weather.
3. In each room, also use **Diagnose here (server view)**. It shows what the **server** thinks about your tile. Compare it with the overlay, which is your game's view.
   - In multiplayer the server may only see the room after the area reloads, so a mismatch right after carving is expected. Note it.
4. **Restart test:** quit, Host again with the same save, and check the rooms in both views.
5. **Friend test** (very valuable if possible):
   1. Your friend puts the **same** `UGMSpike` folder into their `Zomboid\mods` and joins your server.
   2. Your friend stands **next to you** (within ~20 tiles) **before** you carve a room.
   3. You carve a room, then teleport your friend into it by typing in chat: `/teleportto FriendName x,y,-1`, using the `pos` numbers from your overlay.
   4. Your friend checks: are the walls and floor visible? Is `isInARoom: true`? Can they walk around normally?
   5. Your friend sends their `console.txt`. The line `client sync: ... objects missing and added locally=N` tells me whether the server's changes reached them.

After Test B, collect the logs:
- Your `console.txt`.
- The server log: `coop-console.txt` or `server-console.txt` in the `Zomboid` folder, whichever exists.
- Your friend's `console.txt`, if they joined.

---

## 4. What to send me

1. **Log files:** `console.txt` from SP, plus the server and friend logs from Test B. All my lines start with `[UGMSpike]`, and the vanilla lines around them matter too. Send whole files.
2. **Screenshots:** of the overlay in the rooms, and of every visual glitch.
3. **The table below**, filled in.

| Test | Question | Your result |
|---|---|---|
| A1 | Underground: `isOutside` false and `isInARoom` true? | |
| A1 | Dark underground (no daylight)? `light` value? | |
| A2 | Rain underground: wetness stays 0? No raindrops inside? | |
| A2 | `airTemp` surface vs underground | |
| A3 | Flashlight/lantern lights the room normally? | |
| A4 | Separate-room tile counts as indoors? Walls OK? | |
| A4 | Same-room tile counts as indoors? Walls OK? | |
| A5 | z = −2: any flicker or glitches? | |
| A5 | z = −3 and z = −4: any flicker or glitches? | |
| A5 | Did "Redraw nearby chunks" fix the glitches? | |
| A6 | After reload: walls and floors still there? | |
| A6 | After reload: still indoors? | |
| A7 | House above still normal? | |
| A8 | After "forget" + reload: rooms became outdoors? | |
| B | Server view vs your view right after carving | |
| B | After server restart: walls OK, indoors OK (both views)? | |
| B | Friend sees the new room immediately? Indoors for them? | |
| — | Any red error box or crash? (screenshot + log) | |

---

## 5. Offline check (for developers)

`tests/spike_sim.lua` runs the mod's own logic against stubbed game objects. It covers single player, server and client, a late-joining client, and reload. It catches typos and logic bugs, but only the real game can show engine behaviour.

```
lua5.1 tests/spike_sim.lua
```
