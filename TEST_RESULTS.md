# UGM Spike: test results

## Single player: game 42.21.0, Windows 11. Tested by the project owner, 2026-10-11/12

| Test | Result | Notes |
|---|---|---|
| A1: underground room counts as indoors | ✅ Pass | `isOutside=false`, `isInARoom=true`, `openAir=false`, chunk levels `-2..0`; room ID > 2^53, as expected in cell Y ≥ 32 |
| A1: darkness | ✅ Pass | `light=0.00`: pitch dark without a light, like vanilla basements |
| A2: rain | ✅ Pass | No rain inside, no drops or puddles. The player gets wet on the surface and dries underground. |
| A2: temperature | ⚠️ By design | 22 °C underground. Vanilla gives every interior 22 °C while grid power is on. Follow-up: frost-free cellar + root cellar, see ANALYSIS §5.9 |
| A3: light | ✅ Pass | A powered table lamp lights the room (`light=0.66`). Walls, floor and player render correctly. |
| A4: growing the room | ✅ Pass | Both separate-room and same-room growth work |
| A5: levels −2 to −4 | ✅ Pass | No flicker reported (keeping each chunk's lowest level even) |
| A6: save and reload, v0.1.1 | ❌ Crash | `NullPointerException` in `WorldRegionToMetaGrid.assignBuildingToRegions`: IsoRegions treated our user-defined buildings as its own |
| A6: save and reload, v0.1.2 | ✅ Pass | After the fix (buildings marked as map buildings), the save loads and rooms, walls and indoor status all hold. Log: 5 rooms re-registered with `map building=true`, and no exceptions in two reloads. |
| Level fix after reload | ✅ Pass | Log: `chunk min level -1 was odd, extended to -2` on load. A z=−3 room extends the chunk to −4 (`chunk levels -4..0`). |
| Same-room growth: room IDs | ⚠️ Noted | Log: main room ID `...152 → ...153` after growth (replace re-adds it at the end of the cell's room list), so the pocket room's ID shifted too. SP/clients reassign squares at once, but server squares would hold stale IDs until reload. Design decision: see ANALYSIS §5.3. |
| A7: under a house | — | Not tested yet |
| A8: forget + reload | — | Not tested yet |

Log notes (2026-10-12): `invalid room/building metaID ... in cell 42,36` = our rooms, expected and harmless. The `cell 25,33` and `Basements ... duplicate RoomDef.metaID ... 10707,9484,0` errors are vanilla and appear without the mod's rooms.

## Hosted server (Part B)

Not tested yet.
