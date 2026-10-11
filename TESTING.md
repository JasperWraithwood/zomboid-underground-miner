# UGM Spike: step-by-step test guide (game version 42.21)

This guide tests the **UGM Spike test mod**. It is a small debug tool, not the real mod. It answers four questions:

1. Does a dug underground room count as **indoors**: no rain, not lit like daytime?
2. Does it **survive save, quit and reload**, and a server restart?
3. Does it work in **multiplayer**, on a server you host on your laptop?
4. Can we go **several levels deep** without flicker?

**Total time:** about 1–1.5 hours. You can split it: Part 2 (single player) one day, Part 3 (laptop server) another day.

---

## Part 0: Safety first (5 minutes). Your RespawnHost server stays untouched

**Why your real server is safe:**
- The test mod is a **local** mod: it lives only in a folder on your PC.
- Your RespawnHost server decides which mods are used when you join it, and this mod is **not** on it.
- The mod only changes the **new test worlds** you make below. It never touches other saves.
- It uses only vanilla game graphics, so even the test worlds don't break if the mod is removed.

To be 100 % sure, follow these rules:

| ✅ Do | ❌ Never |
|---|---|
| Test only in a **NEW** single-player save and a **NEW** local server called `ugmtest` | Add the mod to an existing save |
| Remove the mod folder **before** you join RespawnHost again (Part 4) | Upload the mod to RespawnHost or add it to the server's mod list |
| Make the backup below | Use the server name of anything you already have |

**Make a backup (one time):**
1. Close Project Zomboid.
2. Press **Win + R**, type `%UserProfile%\Zomboid` and press **Enter**. A folder opens.
3. Select the folders **`Saves`** and **`Server`**, copy them (**Ctrl + C**) and paste them (**Ctrl + V**) into a new folder on your Desktop, for example `Zomboid-backup-2026-10`.

You don't need the `-debug` launch option for this test. If you already use it, that's fine for Parts 2–3, but **remove it before Part 4**.

---

## Part 1: Install the test mod (5 minutes)

1. Get the mod:
   - **Option A:** download `UGMSpike.zip`, which I sent in the chat.
   - **Option B:** on GitHub open the branch `claude/nifty-darwin-7rrf15` → **Code** → **Download ZIP**. The mod is inside at `Contents\mods\UGMSpike`.
2. Press **Win + R**, type `%UserProfile%\Zomboid\mods` and press **Enter**. If Windows says the folder doesn't exist, open `%UserProfile%\Zomboid` and create a new folder named `mods`.
3. Open the zip by double-clicking it, then **drag the `UGMSpike` folder** into the `mods` folder.
   - Don't use "Extract All" into `mods`; that often creates a double folder.
4. **Check the path.** This file must exist:
   `%UserProfile%\Zomboid\mods\UGMSpike\42\mod.info`
   - If you see `mods\UGMSpike\UGMSpike\42\...` (double folder), move the inner `UGMSpike` up one level.

---

## Part 2: Single player test (30–40 minutes)

### 2.1 Start a test game
1. Start Project Zomboid.
2. On the main menu click **Mods**. Find **Underground Miner - Test Spike**, tick it (enable) and confirm/save. Then go back to the main menu.
3. Click **Solo** → start a **new** game → choose **Sandbox**.
4. Recommended: in the sandbox settings set **Zombie Count = None**, so nothing interrupts the tests. Check that the mod is enabled for this new game if the screen shows a mod list.
5. Choose **Muldraugh** as the spawn location, create any character and start.
6. When the game has loaded, look at the **top-left corner**. You should see yellow text **`UGM Spike - live (SP)`** with lines like `isOutside`, `isInARoom` and `light`.
   - ❗ If it's missing, the mod didn't load. Quit and send me `console.txt` (Part 5).

All test actions are in the **right-click menu** on the ground: **UGM Spike (test)** → submenu.

### 2.2 Tests: write down the results in the table in Part 5

**A1: Carve a room and go down**
1. Walk **outside** onto grass or dirt, at least **4 tiles away from any wall, fence or tree**.
2. Right-click the ground → **UGM Spike (test)** → **1. Carve test room below me**. A message appears: *"Carved test room #1 at z=-1"*.
3. Right-click → **UGM Spike (test)** → **2. Teleport down one level**. You're now underground in a 5×5 room with log walls.
4. Read the overlay and take a **screenshot** with Steam's F12 key. Note:
   - `isOutside`: hoped **false**
   - `isInARoom`: hoped **true**
   - `openAir`: hoped **false**
   - `room`: hoped **ugm_spike ...**
   - `light`: the number. Is the room **dark**, or bright like daytime?

**A2: Rain**
1. Right-click → **Start rain**. Wait **2 real minutes** underground.
2. Note `wetness`: does it stay **0**? Do you see raindrops or puddles inside the room?
3. Right-click → **3. Teleport up one level**. On the surface you should get wet, which proves it's really raining. Note `wetness` and `airTemp` on the surface.
4. **Teleport down** again and note `airTemp` underground.
5. Right-click → **Stop rain override**.

**A3: Light**
Equip a flashlight or a lit lantern in the room. Look in houses if your character has none, or skip this test. Does it light the room normally?

**A4: Make the room bigger**
1. Stand in the middle of the room. Right-click → **Grow room 1 tile east (separate room)**. A small pocket opens in the east wall.
2. Walk into the pocket and check the overlay (`isInARoom`, `isOutside`).
3. Go back and choose **Grow room 1 tile east (same room)**. The pocket gets one tile longer. Walk into the new tile and check again.
4. Do the walls look closed and correct? Screenshot.

**A5: Deeper levels**
1. Stand in the z = −1 room. Right-click → **1. Carve test room below me**, then **2. Teleport down one level**. You're at z = −2 (shown in `pos` as the last number).
2. Repeat to get to **z = −3** and **z = −4**.
3. On every level, walk around for about 30 seconds and go up and down with the teleport options. Watch for **flickering, black or missing areas, missing walls, or tiles from other levels showing through**.
4. If something looks wrong: screenshot it, then right-click → **Redraw nearby chunks**. Note whether that fixes it.

**A6: Save and reload** (the most important test)
1. Press **Esc** → **Quit to main menu**. This saves the game.
2. Main menu → **Load** → choose the same save → play.
3. Go to the spot, teleport down, and visit each level. Are the walls and floors still there? Does the overlay still show `isInARoom: true` and `isOutside: false`?

**A7: Under a house** (optional)
1. Go inside any house (ground floor), stand in a room, and do A1 there.
2. Teleport back up and check the house still looks and behaves normally: roof, walls hiding when you walk in, upstairs.

**A8: Proof check** (optional, do it last)
1. Right-click → **Forget all test rooms (registry)**.
2. Esc → Quit to main menu → Load the save again.
3. Teleport down: the rooms should now show **`isOutside: true`**. That proves the indoor effect comes from our mod.

### 2.3 Collect the single-player log
1. **Close Project Zomboid completely.**
2. Press **Win + R** → `%UserProfile%\Zomboid` → **Enter**.
3. Copy **`console.txt`** to your Desktop and rename it **`console-SP.txt`**.
   - Do this **before** you start the game again, because each start overwrites it.

---

## Part 3: Test on your own laptop server (30 minutes)

This server runs only on your laptop. It doesn't touch RespawnHost.

### 3.1 Create the test server
1. Start Project Zomboid → main menu → **Host**.
2. Click **Manage Settings** (or similar) → **Create new** → name it exactly **`ugmtest`**.
3. Edit `ugmtest`:
   - In the **Mods** section/tab, **add "Underground Miner - Test Spike"**.
   - Optional: in the sandbox section set **Zombie Count = None**.
   - **Save.**
4. Back on the Host screen, select **`ugmtest`** and click **Start**. Create a character in Muldraugh and play.
5. The overlay should now say **`UGM Spike - live (CLIENT)`**. As the host you are admin, which the teleport option needs.

### 3.2 Multiplayer tests
1. **Carve and enter:** walk outside to open ground. Right-click → **1. Carve test room below me** → **2. Teleport down one level**.
   - If the teleport does nothing, wait 5 seconds and use **Teleport down (backup method)** instead. Note which one worked.
2. **Compare two views:** read the overlay (your game's view). Then right-click → **Diagnose here (server view)**; the server's view appears in green under the overlay. Screenshot both.
   - Right after carving, the server may still say `isInARoom: false`. That's expected in many map areas, so just note it.
3. **Rain:** right-click → **Start rain**, wait 2 minutes underground and check `wetness`. Then **Stop rain override**.
4. **Grow:** run both **Grow room** options and check the overlay in the new tiles.
5. **Deeper:** go down to **z = −2 and z = −3** as in A5 and watch for flicker.
6. **Server restart:**
   1. Esc → **Quit**.
   2. Main menu → **Host** → select `ugmtest` → **Start** again.
   3. Teleport down into the rooms and check the overlay **and** "Diagnose here (server view)". Both should now say `isInARoom: true`.

### 3.3 Friend test (optional, only if it's easy)
If a friend can join your laptop server (Steam invite, or the same home network):
1. Your friend puts the **same `UGMSpike` folder** into their own `%UserProfile%\Zomboid\mods`.
2. Your friend joins `ugmtest` and stands **next to you** **before** you carve a new room.
3. You carve the room. Then teleport your friend down by typing in chat: `/teleportto "FriendName" x,y,-1`.
   - Take `x,y` from the `pos` line in your overlay.
   - If that format doesn't work, try it without the quotes.
4. Your friend checks: are the walls and floor visible? Is `isInARoom: true`? Your friend sends you their `console.txt`.

### 3.4 Collect the server logs
1. **Close Project Zomboid completely.**
2. In `%UserProfile%\Zomboid`, copy:
   - `console.txt` → rename to **`console-HOST.txt`**
   - `coop-console.txt` (or `server-console.txt`, whichever exists) → keep its name
   - from your friend, if any: their `console.txt` → rename to **`console-FRIEND.txt`**

---

## Part 4: Before you play on RespawnHost again ❗

1. Start Project Zomboid → **Mods** → **untick "Underground Miner - Test Spike"** → save. Then **close the game**.
2. Press **Win + R** → `%UserProfile%\Zomboid\mods` → **Enter**. **Move the `UGMSpike` folder to your Desktop**, out of `mods`. Now the game can't load it at all.
3. If you added `-debug` to the launch options, remove it: Steam → right-click Project Zomboid → Properties → Launch options → clear it.
4. Start the game → **Join** → your RespawnHost server, as usual.

To test again later, move the folder back into `mods`.

---

## Part 5: What to send me

**1. Log files**
- `console-SP.txt`
- `console-HOST.txt`
- `coop-console.txt` (or `server-console.txt`)
- `console-FRIEND.txt`, if a friend tested

**2. Screenshots**
- The overlay in each test.
- Every visual glitch.
- Steam screenshots are in Steam → View → Screenshots.

**3. This table**, filled in. Short answers are fine.

| Test | Question | Your result |
|---|---|---|
| 2.1 | Overlay visible after loading? | |
| A1 | Underground: `isOutside` false and `isInARoom` true? | |
| A1 | Dark underground? `light` value? | |
| A2 | Rain underground: `wetness` stays 0? No raindrops inside? | |
| A2 | `airTemp` on the surface vs underground | |
| A3 | Flashlight/lantern lights the room normally? | |
| A4 | "Separate room" tile counts as indoors? Walls OK? | |
| A4 | "Same room" tile counts as indoors? Walls OK? | |
| A5 | z = −2: flicker or glitches? | |
| A5 | z = −3 and −4: flicker or glitches? | |
| A5 | Did "Redraw nearby chunks" fix glitches? | |
| A6 | After reload: walls and floors still there? | |
| A6 | After reload: still indoors? | |
| A7 | House above still normal? | |
| A8 | After "forget" + reload: rooms became outdoors? | |
| 3.2 | Which teleport worked: normal or backup? | |
| 3.2 | Server view vs your view right after carving | |
| 3.2 | Rain underground on the server: stays dry? | |
| 3.2 | z = −2 / −3 on the server: glitches? | |
| 3.2 | After server restart: walls OK, indoors in both views? | |
| 3.3 | Friend sees the new room immediately? Indoors for them? | |
| — | Any error message, red box or crash? (screenshot) | |

---

## If something goes wrong

- **The game crashes or won't load the save:**
  1. Close it.
  2. Move `UGMSpike` out of `mods`.
  3. Send me `console.txt`.
  - Your real saves are safe; this only affects the test save.
- **"UGM Spike error in ..." message:** carry on if you can. The details are in `console.txt`.
- **No "UGM Spike (test)" in the right-click menu:** right-click on a floor or ground tile in the world, not on the UI. If it's still missing, the mod isn't enabled for that save.
- **You get stuck underground:** use **3. Teleport up one level**, or **Teleport up (backup method)** on the server.

---

## For developers: offline check

`tests/spike_sim.lua` runs the mod's own logic against stubbed game objects. It covers single player, server and client, a late-joining client, and reload. It catches typos and logic bugs, but only the real game can show engine behaviour.

```
lua5.1 tests/spike_sim.lua
```
