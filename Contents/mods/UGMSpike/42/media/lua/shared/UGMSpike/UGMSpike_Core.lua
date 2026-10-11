-- Underground Miner - test spike, shared core.
--
-- Questions this spike answers in the real game (42.21):
--   1. Does a room registered at runtime through the vanilla BuildingRoomsEditor make
--      dug squares count as indoors (no rain, no skylight, indoor temperature)?
--   2. Does it survive save/reload when we re-register it from global ModData before
--      chunks load (OnLoadedMapZones)?
--   3. Do other multiplayer clients see newly created underground squares?
--   4. Does keeping each chunk's lowest level even stop the multi-level flicker?
--      (Render code draws underground levels in pairs: -2/-1, -4/-3, ...)
--
-- Every line this mod prints starts with "[UGMSpike]" so it is easy to find in console.txt.

UGMSpike = UGMSpike or {}
local U = UGMSpike

U.MODULE = "UGMSpike"
U.VERSION = "0.1.1"
U.ROOM_NAME = "ugm_spike"
U.ROOM_SIZE = 5
U.MIN_LEVEL = -32
U.CLIENT_OBJECT_CHECK_DELAY = 60 -- ticks to wait for object packets before filling gaps locally

-- Vanilla sprites only. Log walls stand in for dirt walls in this test.
U.SPRITES = {
    floor = "blends_natural_01_64",
    wallW = "walls_logs_96",
    wallN = "walls_logs_97",
    wallNW = "walls_logs_98",
    wallSE = "walls_logs_99",
}

-- FBORenderChunk dirty flags: LIGHTING(32) + OBJECT_ADD(64) + CREATE(512) + REDRAW(1024)
U.RENDER_DIRTY_FLAGS = 32 + 64 + 512 + 1024

---------------------------------------------------------------------------
-- Logging and small helpers
---------------------------------------------------------------------------

function U.side()
    if isServer() then return "SERVER" end
    if isClient() then return "CLIENT" end
    return "SP"
end

-- True where world changes are authoritative: single player or the server.
function U.isAuthority()
    return not isClient()
end

function U.log(msg)
    print("[UGMSpike] [" .. U.side() .. "] " .. tostring(msg))
end

-- Calls fn and returns its result, or the fallback if it throws (API missing or changed).
function U.try(fallback, fn, ...)
    local ok, result = pcall(fn, ...)
    if ok then return result end
    return fallback
end

local function isOdd(n)
    return n - 2 * math.floor(n / 2) ~= 0
end

---------------------------------------------------------------------------
-- Tick scheduler (runs on client, server and single player)
---------------------------------------------------------------------------

U.tasks = U.tasks or {}

function U.schedule(ticks, fn)
    U.tasks[#U.tasks + 1] = { ticks = ticks, fn = fn }
end

local function runTasks()
    if #U.tasks == 0 then return end
    for i = #U.tasks, 1, -1 do
        local task = U.tasks[i]
        task.ticks = task.ticks - 1
        if task.ticks <= 0 then
            table.remove(U.tasks, i)
            local ok, err = pcall(task.fn)
            if not ok then U.log("task error: " .. tostring(err)) end
        end
    end
end

---------------------------------------------------------------------------
-- Registry of carved rooms (global ModData; authoritative copy on server / SP)
---------------------------------------------------------------------------

function U.getRegistry()
    local reg = ModData.getOrCreate(U.MODULE)
    if not reg.version then
        reg.version = 1
        reg.nextId = 1
        reg.rooms = {}
    end
    reg.rooms = reg.rooms or {}
    return reg
end

local function rectContains(r, x, y)
    return x >= r.x and y >= r.y and x < r.x + r.w and y < r.y + r.h
end

function U.findRoomDefAt(rooms, x, y, z)
    for _, def in ipairs(rooms) do
        if def.z == z then
            for _, r in ipairs(def.rects) do
                if rectContains(r, x, y) then return def end
            end
        end
    end
    return nil
end

function U.findRoomDefById(rooms, id)
    for _, def in ipairs(rooms) do
        if def.id == id then return def end
    end
    return nil
end

function U.describeDef(def)
    local parts = {}
    for _, r in ipairs(def.rects) do
        parts[#parts + 1] = r.x .. "," .. r.y .. " " .. r.w .. "x" .. r.h
    end
    return "room#" .. tostring(def.id) .. " (" .. tostring(def.kind) .. ") z=" .. def.z .. " rects=[" .. table.concat(parts, "; ") .. "]"
end

---------------------------------------------------------------------------
-- Room registration through the vanilla BuildingRoomsEditor
---------------------------------------------------------------------------

local function existingRoomName(def)
    local r = def.rects[1]
    local roomDef = getWorld():getMetaGrid():getRoomAt(r.x, r.y, def.z)
    return roomDef and roomDef:getName() or nil
end

-- Registers rooms in the world's room map.
--   loading: true when called before chunks load (no square refresh needed).
--   replace: re-register even if a room already exists there. A building with the
--            same position/level is replaced by the editor (it logs a "duplicate
--            BuildingDef.metaID" error line, which is expected in that case).
-- Returns the number of rooms registered.
function U.registerRooms(defs, loading, replace)
    if not defs or #defs == 0 then return 0 end

    local todo = {}
    for _, def in ipairs(defs) do
        if replace or existingRoomName(def) ~= def.name then
            todo[#todo + 1] = def
        end
    end
    if #todo == 0 then return 0 end

    -- Reset clears any half-finished edit (for example from the debug Rooms editor)
    -- so applyChanges only touches our buildings.
    BuildingRoomsEditor.Reset()
    local editor = BuildingRoomsEditor.getInstance()
    for _, def in ipairs(todo) do
        local building = editor:createBuilding()
        local room = building:createRoom(def.z)
        room:setName(def.name)
        for _, r in ipairs(def.rects) do
            room:addRectangle(r.x, r.y, r.w, r.h)
        end
    end
    if not editor:isValid() then
        U.log("room editor rejected rooms: " .. tostring(editor:getInvalidString()))
        BuildingRoomsEditor.Reset()
        return 0
    end

    -- A dedicated/hosted server has no player chunk maps to refresh, so it always uses
    -- the "loading" path; its loaded squares pick the room up on chunk reload.
    local bLoading = loading or isServer()
    editor:applyChanges(bLoading)
    BuildingRoomsEditor.Reset()

    for _, def in ipairs(todo) do
        local name = existingRoomName(def)
        U.log("registered " .. U.describeDef(def) .. " -> room map now says '" .. tostring(name) .. "' (loading=" .. tostring(bLoading) .. ")")
    end
    return #todo
end

-- Server only: Lua numbers are doubles, so a 64-bit room ID only survives the trip
-- through Lua when it is below 2^53 (map cells with Y index < 32). Where it does, set
-- the room on already-loaded server squares right away; elsewhere they get it on reload.
function U.assignRoomOnLoadedSquares(def)
    local metaGrid = getWorld():getMetaGrid()
    local cell = getCell()
    local exact, imprecise, missing = 0, 0, 0
    for _, r in ipairs(def.rects) do
        for x = r.x, r.x + r.w - 1 do
            for y = r.y, r.y + r.h - 1 do
                local sq = cell:getGridSquare(x, y, def.z)
                local roomDef = metaGrid:getRoomAt(x, y, def.z)
                if not sq or not roomDef then
                    missing = missing + 1
                else
                    local id = roomDef:getID()
                    local asText = U.try(nil, string.format, "%.0f", id)
                    if asText ~= nil and asText == roomDef:getIDString() then
                        sq:setRoomID(id)
                        sq:RecalcProperties()
                        exact = exact + 1
                    else
                        imprecise = imprecise + 1
                    end
                end
            end
        end
    end
    U.log("server room assign for room#" .. tostring(def.id) .. ": set=" .. exact .. " idTooLargeForLua=" .. imprecise .. " missing=" .. missing)
end

---------------------------------------------------------------------------
-- Squares, levels and objects
---------------------------------------------------------------------------

-- Returns square, created. Nil if the chunk is not loaded here.
function U.getOrCreateSquare(x, y, z)
    local cell = getCell()
    local sq = cell:getGridSquare(x, y, z)
    if sq then return sq, false end
    sq = cell:createNewGridSquare(x, y, z, true)
    return sq, sq ~= nil
end

-- Underground levels render in pairs (-2/-1, -4/-3 ...). If a chunk's lowest level is
-- odd, extend it one level down so the pair is complete before anything renders there.
function U.ensureEvenMinLevel(sq)
    local chunk = sq and sq:getChunk()
    if not chunk then return false end
    local minLevel = chunk:getMinLevel()
    if minLevel < 0 and isOdd(minLevel) and minLevel - 1 >= U.MIN_LEVEL then
        local below = getCell():createNewGridSquare(sq:getX(), sq:getY(), minLevel - 1, true)
        U.log("chunk min level " .. minLevel .. " was odd, extended to " .. chunk:getMinLevel() .. " (helper square " .. tostring(below ~= nil) .. ")")
        return true
    end
    return false
end

function U.chunkLevelsText(sq)
    local chunk = sq and sq:getChunk()
    if not chunk then return "no chunk" end
    return chunk:getMinLevel() .. ".." .. chunk:getMaxLevel()
end

-- Client / single player: recompute the visible level range and redraw nearby chunks.
function U.refreshLocalRendering(x, y, z)
    if isServer() then return end
    local cell = getCell()
    for i = 0, getNumActivePlayers() - 1 do
        local chunkMap = cell:getChunkMap(i)
        if chunkMap then U.try(nil, function() chunkMap:calculateZExtentsForChunkMap() end) end
    end
    for dx = -8, 8, 8 do
        for dy = -8, 8, 8 do
            local chunk = cell:getChunkForGridSquare(x + dx, y + dy, z)
            if chunk then U.try(nil, function() chunk:invalidateRenderChunkLevels(U.RENDER_DIRTY_FLAGS) end) end
        end
    end
end

function U.findObjectBySprite(sq, spriteName)
    local objects = sq:getObjects()
    for i = 0, objects:size() - 1 do
        local obj = objects:get(i)
        local sprite = obj and obj:getSprite()
        if sprite and sprite:getName() == spriteName then return obj end
    end
    return nil
end

-- Adds a sprite object unless the square already has it.
--   transmit: true on server / single player (sends to clients), false for a local-only fill-in.
function U.addSpriteObject(sq, spriteName, transmit)
    if U.findObjectBySprite(sq, spriteName) then return false end
    local obj = IsoObject.getNew(sq, spriteName, nil, false)
    local index = spriteName == U.SPRITES.floor and 0 or -1
    if transmit then
        sq:transmitAddObjectToSquare(obj, index)
    else
        sq:AddTileObject(obj, index)
    end
    return true
end

function U.removeSpriteObject(sq, spriteName, transmit)
    local obj = U.findObjectBySprite(sq, spriteName)
    if not obj then return false end
    if transmit then
        sq:transmitRemoveItemFromSquare(obj)
    else
        sq:RemoveTileObject(obj)
    end
    return true
end

---------------------------------------------------------------------------
-- Layouts: which sprites go on which square. Shared so clients can fill gaps.
---------------------------------------------------------------------------

local function newLayout()
    local layout = { cells = {}, removes = {} }
    layout.index = {}
    return layout
end

local function layoutCell(layout, x, y, z)
    local key = x .. "," .. y .. "," .. z
    local c = layout.index[key]
    if not c then
        c = { x = x, y = y, z = z, sprites = {} }
        layout.index[key] = c
        layout.cells[#layout.cells + 1] = c
    end
    return c
end

local function addSprite(layout, x, y, z, sprite)
    local c = layoutCell(layout, x, y, z)
    c.sprites[#c.sprites + 1] = sprite
end

-- A closed w x h room with its top-left corner at (x0, y0) on level z.
-- North/west walls sit on the room's own edge squares; south/east walls sit on the
-- squares just outside the room (that is how wall sprites work in PZ).
function U.roomLayout(x0, y0, w, h, z)
    local S = U.SPRITES
    local layout = newLayout()
    for x = x0, x0 + w - 1 do
        for y = y0, y0 + h - 1 do
            addSprite(layout, x, y, z, S.floor)
        end
    end
    for x = x0, x0 + w - 1 do
        addSprite(layout, x, y0, z, x == x0 and S.wallNW or S.wallN)
        addSprite(layout, x, y0 + h, z, S.wallN)
    end
    for y = y0, y0 + h - 1 do
        if y ~= y0 then addSprite(layout, x0, y, z, S.wallW) end
        addSprite(layout, x0 + w, y, z, S.wallW)
    end
    addSprite(layout, x0 + w, y0 + h, z, S.wallSE)
    layout.index = nil
    return layout
end

-- Opens the wall east of (tx - 1, ty) and adds a one-tile pocket at (tx, ty).
function U.growLayout(tx, ty, z)
    local S = U.SPRITES
    local layout = newLayout()
    layout.removes[1] = { x = tx, y = ty, z = z, sprite = S.wallW }
    addSprite(layout, tx, ty, z, S.floor)
    addSprite(layout, tx, ty, z, S.wallN)
    addSprite(layout, tx, ty + 1, z, S.wallN)
    addSprite(layout, tx + 1, ty, z, S.wallW)
    addSprite(layout, tx + 1, ty + 1, z, S.wallSE)
    layout.index = nil
    return layout
end

-- Server / single player: create squares and objects, sending them to clients.
-- Returns counts for the log.
function U.applyLayoutAuthority(layout)
    local stats = { squaresCreated = 0, objectsAdded = 0, objectsRemoved = 0, unloaded = 0, levelFixes = 0 }
    for _, rm in ipairs(layout.removes) do
        local sq = getCell():getGridSquare(rm.x, rm.y, rm.z)
        if sq and U.removeSpriteObject(sq, rm.sprite, true) then
            stats.objectsRemoved = stats.objectsRemoved + 1
        end
    end
    for _, c in ipairs(layout.cells) do
        local sq, created = U.getOrCreateSquare(c.x, c.y, c.z)
        if not sq then
            stats.unloaded = stats.unloaded + 1
        else
            if created then stats.squaresCreated = stats.squaresCreated + 1 end
            if U.ensureEvenMinLevel(sq) then stats.levelFixes = stats.levelFixes + 1 end
            for _, sprite in ipairs(c.sprites) do
                if U.addSpriteObject(sq, sprite, true) then
                    stats.objectsAdded = stats.objectsAdded + 1
                end
            end
        end
    end
    return stats
end

-- Multiplayer client: make sure the squares exist so object packets have somewhere to
-- land, then (after a delay) add anything that still did not arrive.
function U.applyLayoutClient(layout, onDone)
    local created, unloaded = 0, 0
    for _, c in ipairs(layout.cells or {}) do
        local sq, isNew = U.getOrCreateSquare(c.x, c.y, c.z)
        if not sq then
            unloaded = unloaded + 1
        else
            if isNew then created = created + 1 end
            U.ensureEvenMinLevel(sq)
        end
    end
    U.schedule(U.CLIENT_OBJECT_CHECK_DELAY, function()
        local added, removed = 0, 0
        for _, rm in ipairs(layout.removes or {}) do
            local sq = getCell():getGridSquare(rm.x, rm.y, rm.z)
            if sq and U.removeSpriteObject(sq, rm.sprite, false) then removed = removed + 1 end
        end
        for _, c in ipairs(layout.cells or {}) do
            local sq = getCell():getGridSquare(c.x, c.y, c.z)
            if sq then
                for _, sprite in ipairs(c.sprites or {}) do
                    if U.addSpriteObject(sq, sprite, false) then added = added + 1 end
                end
            end
        end
        U.log("client sync: squares created here=" .. created .. " (chunk not loaded=" .. unloaded .. "), objects missing and added locally=" .. added .. ", stale objects removed locally=" .. removed)
        if onDone then onDone() end
    end)
    return created
end

---------------------------------------------------------------------------
-- Diagnostics
---------------------------------------------------------------------------

-- Returns a list of "key: value" lines describing the square and the player.
function U.diagnose(player, sq)
    local lines = {}
    local function add(key, value) lines[#lines + 1] = key .. ": " .. tostring(value) end

    local x, y, z = math.floor(player:getX()), math.floor(player:getY()), math.floor(player:getZ())
    add("side", U.side())
    add("pos", x .. "," .. y .. "," .. z)
    if not sq then
        add("square", "none")
        return lines
    end
    add("hasFloor", sq:getFloor() ~= nil)
    add("isOutside", U.try("?", function() return sq:isOutside() end))
    add("isInARoom", U.try("?", function() return sq:isInARoom() end))
    add("openAir", U.try("?", function() return sq:getOpenAir() end))
    add("roofFull", U.try("?", function() return sq:haveRoofFull() end))
    add("room", U.try("?", function()
        local room = sq:getRoom()
        if not room then return "none" end
        local def = room:getRoomDef()
        return (def and def:getName() or "?") .. " id=" .. sq:getRoomIDString()
    end))
    add("roomMap", U.try("?", function()
        local def = getWorld():getMetaGrid():getRoomAt(x, y, z)
        if not def then return "none" end
        return def:getName() .. " userDefined=" .. tostring(def:isUserDefined())
    end))
    add("chunkLevels", U.chunkLevelsText(sq))
    if not isServer() then
        add("light", U.try("?", function() return string.format("%.2f", sq:getLightLevel(player:getPlayerNum())) end))
    end
    add("airTemp", U.try("?", function() return string.format("%.1f", getClimateManager():getAirTemperatureForSquare(sq)) end))
    add("bodyTemp", U.try("?", function() return string.format("%.2f", player:getStats():get(CharacterStat.TEMPERATURE)) end))
    add("wetness", U.try("?", function() return string.format("%.1f", player:getStats():get(CharacterStat.WETNESS)) end))
    add("raining", U.try("?", function() return getClimateManager():isRaining() end))
    add("rainIntensity", U.try("?", function() return string.format("%.2f", getClimateManager():getPrecipitationIntensity()) end))
    return lines
end

---------------------------------------------------------------------------
-- Startup and reload handling
---------------------------------------------------------------------------

-- Server / single player: re-register saved rooms before any chunk loads, so loaded
-- squares get their room from the room map like vanilla rooms do.
local function onLoadedMapZones()
    if isClient() then return end
    local reg = U.getRegistry()
    U.log("world loading: " .. #reg.rooms .. " saved room(s) in registry")
    for _, def in ipairs(reg.rooms) do
        local before = existingRoomName(def)
        U.log("  before re-register, room map at " .. U.describeDef(def) .. " says '" .. tostring(before) .. "'")
    end
    U.trackRoomChunks(reg.rooms)
    U.registerRooms(reg.rooms, true, false)
end

-- After a reload, chunks come back with only the levels that had saved squares, so an
-- odd lowest level can return. Queue chunks that hold our rooms and fix them on the
-- next ticks (vanilla basements are left alone).
U.levelCheckQueue = U.levelCheckQueue or {}
U.levelCheckKeys = U.levelCheckKeys or {}
U.roomChunks = U.roomChunks or {}

local function chunkKey(x, y)
    return math.floor(x / 8) .. "," .. math.floor(y / 8)
end

-- Remember which chunks our rooms (plus their outer wall row) touch.
function U.trackRoomChunks(defs)
    for _, def in ipairs(defs or {}) do
        for _, r in ipairs(def.rects) do
            for x = r.x, r.x + r.w do
                for y = r.y, r.y + r.h do
                    U.roomChunks[chunkKey(x, y)] = true
                end
            end
        end
    end
end

local function onLoadGridsquare(sq)
    if sq:getZ() >= 0 then return end
    local key = chunkKey(sq:getX(), sq:getY())
    if not U.roomChunks[key] or U.levelCheckKeys[key] then return end
    U.levelCheckKeys[key] = true
    U.levelCheckQueue[#U.levelCheckQueue + 1] = { x = sq:getX(), y = sq:getY(), z = sq:getZ() }
end

local function processLevelChecks()
    if #U.levelCheckQueue == 0 then return end
    local queue = U.levelCheckQueue
    U.levelCheckQueue = {}
    U.levelCheckKeys = {}
    for _, item in ipairs(queue) do
        local sq = getCell():getGridSquare(item.x, item.y, item.z)
        if sq and U.ensureEvenMinLevel(sq) then
            U.refreshLocalRendering(item.x, item.y, item.z)
        end
    end
end

Events.OnLoadedMapZones.Add(onLoadedMapZones)
Events.LoadGridsquare.Add(onLoadGridsquare)
Events.OnTick.Add(function()
    runTasks()
    processLevelChecks()
end)

U.log("loaded v" .. U.VERSION)
