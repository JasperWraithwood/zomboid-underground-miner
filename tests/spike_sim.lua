-- Offline smoke test for the UGMSpike test mod (plain Lua 5.1, no game needed).
-- Stubs just enough of the Project Zomboid API to run the mod's code paths:
-- single player carve/grow/reload, and a multiplayer server + client exchange.
-- It checks the mod's own logic, not engine behaviour (that needs the real game).
--
-- Run from the repo root:  lua5.1 tests/spike_sim.lua

local MOD = "Contents/mods/UGMSpike/42/media/lua/"
local failures = 0

local function check(cond, msg)
    if cond then
        print("  ok   " .. msg)
    else
        failures = failures + 1
        print("  FAIL " .. msg)
    end
end

---------------------------------------------------------------------------
-- Minimal world stubs
---------------------------------------------------------------------------

local function javaList(t)
    return {
        size = function() return #t end,
        get = function(_, i) return t[i + 1] end,
    }
end

local function newWorld()
    local W = { squares = {}, chunks = {}, rooms = {}, modData = {}, sent = {} }

    local function key(x, y, z) return x .. "," .. y .. "," .. z end

    function W.chunkFor(x, y)
        local k = math.floor(x / 8) .. "," .. math.floor(y / 8)
        local c = W.chunks[k]
        if not c then
            c = { minLevel = 0, maxLevel = 0 }
            function c:getMinLevel() return self.minLevel end
            function c:getMaxLevel() return self.maxLevel end
            function c:setMinMaxLevel(a, b) self.minLevel, self.maxLevel = a, b end
            function c:invalidateRenderChunkLevels() end
            W.chunks[k] = c
        end
        return c
    end

    local function newSquare(x, y, z)
        local sq = { x = x, y = y, z = z, objects = {}, roomId = -1 }
        local chunk = W.chunkFor(x, y)
        if z < chunk.minLevel then chunk.minLevel = z end
        if z > chunk.maxLevel then chunk.maxLevel = z end
        function sq:getX() return self.x end
        function sq:getY() return self.y end
        function sq:getZ() return self.z end
        function sq:getChunk() return chunk end
        function sq:getObjects() return javaList(self.objects) end
        function sq:getFloor()
            for _, o in ipairs(self.objects) do
                if o.sprite == "blends_natural_01_64" then return o end
            end
            return nil
        end
        function sq:AddTileObject(obj, index)
            if index and index >= 0 and index <= #self.objects then
                table.insert(self.objects, index + 1, obj)
            else
                self.objects[#self.objects + 1] = obj
            end
        end
        function sq:transmitAddObjectToSquare(obj, index)
            self:AddTileObject(obj, index)
            W.transmitted = (W.transmitted or 0) + 1
        end
        function sq:RemoveTileObject(obj)
            for i, o in ipairs(self.objects) do
                if o == obj then table.remove(self.objects, i) return end
            end
        end
        function sq:transmitRemoveItemFromSquare(obj) self:RemoveTileObject(obj) end
        function sq:setRoomID(id) self.roomId = id end
        function sq:RecalcProperties() end
        function sq:isOutside() return self.roomId == -1 end
        function sq:isInARoom() return self.roomId ~= -1 end
        function sq:getOpenAir() return self.roomId == -1 end
        function sq:haveRoofFull() return false end
        function sq:getRoom() return nil end
        function sq:getRoomIDString() return tostring(self.roomId) end
        function sq:getLightLevel() return 0.1 end
        return sq
    end

    W.cell = {
        getGridSquare = function(_, x, y, z) return W.squares[key(x, y, z)] end,
        createNewGridSquare = function(_, x, y, z)
            if W.unloaded then return nil end
            local k = key(x, y, z)
            W.squares[k] = W.squares[k] or newSquare(x, y, z)
            return W.squares[k]
        end,
        getChunkForGridSquare = function(_, x, y) return W.chunkFor(x, y) end,
        getChunkMap = function() return { calculateZExtentsForChunkMap = function() end } end,
    }

    -- Room map: stores registered rooms; getRoomAt mimics IsoMetaGrid.getRoomAt.
    local function roomDefStub(room)
        return {
            getName = function() return room.name end,
            getID = function() return room.id end,
            getIDString = function() return string.format("%.0f", room.id) end,
            isUserDefined = function() return false end,
            getBuilding = function() return room.building end,
        }
    end
    W.metaGrid = {
        getRoomAt = function(_, x, y, z)
            for i = #W.rooms, 1, -1 do
                local room = W.rooms[i]
                if room.level == z then
                    for _, r in ipairs(room.rects) do
                        if x >= r.x and y >= r.y and x < r.x + r.w and y < r.y + r.h then
                            return roomDefStub(room)
                        end
                    end
                end
            end
            return nil
        end,
    }

    local pending = {}
    W.editor = {
        createBuilding = function()
            -- Like BREBuilding: the editor makes "user-defined" buildings.
            local building = { rooms = {}, userDefined = true }
            function building:isUserDefined() return self.userDefined end
            function building:setUserDefined(b) self.userDefined = b end
            function building:createRoom(level)
                local room = { level = level, rects = {}, name = "", building = self }
                function room:setName(n) self.name = n end
                function room:addRectangle(x, y, w, h) self.rects[#self.rects + 1] = { x = x, y = y, w = w, h = h } end
                self.rooms[#self.rooms + 1] = room
                return room
            end
            pending[#pending + 1] = building
            return building
        end,
        isValid = function() return true end,
        getInvalidString = function() return nil end,
        applyChanges = function(_, bLoading)
            for _, b in ipairs(pending) do
                for _, room in ipairs(b.rooms) do
                    -- same level + same first rect = same metaID: the editor replaces it
                    for i = #W.rooms, 1, -1 do
                        local old = W.rooms[i]
                        if old.level == room.level and old.rects[1].x == room.rects[1].x and old.rects[1].y == room.rects[1].y then
                            table.remove(W.rooms, i)
                        end
                    end
                    room.id = 1000 + #W.rooms
                    W.rooms[#W.rooms + 1] = room
                    if not bLoading then
                        for _, r in ipairs(room.rects) do
                            for x = r.x, r.x + r.w - 1 do
                                for y = r.y, r.y + r.h - 1 do
                                    local sq = W.squares[key(x, y, room.level)]
                                    if sq then sq.roomId = room.id end
                                end
                            end
                        end
                    end
                end
            end
            pending = {}
        end,
    }
    W.resetEditor = function() pending = {} end

    -- Simulates a reload: rooms only exist again if the mod re-registers them,
    -- and squares get their room from the room map when "loaded".
    function W.reloadRoomsAndSquares()
        W.rooms = {}
        for _, sq in pairs(W.squares) do sq.roomId = -1 end
    end
    -- Mimics IsoRegions.clientProcessBuildings: it throws on any user-defined
    -- building it did not create itself (the crash seen in 42.21 after reload).
    function W.userDefinedBuildings()
        local count = 0
        for _, room in ipairs(W.rooms) do
            if room.building and room.building.userDefined then count = count + 1 end
        end
        return count
    end
    function W.assignRoomsFromMap()
        for _, sq in pairs(W.squares) do
            local def = W.metaGrid:getRoomAt(sq.x, sq.y, sq.z)
            sq.roomId = def and def:getID() or -1
        end
    end
    return W
end

-- Each simulated game (SP, server, client) has its own globals; activate() switches.
local GLOBAL_NAMES = {
    "Events", "isClient", "isServer", "getCell", "getWorld", "getNumActivePlayers", "getClimateManager",
    "ClimateManager", "CharacterStat", "ModData", "IsoObject", "BuildingRoomsEditor", "sendServerCommand",
    "sendClientCommand", "SendCommandToServer", "getSpecificPlayer", "getTextManager", "ISContextMenu",
    "require", "UGMSpike",
}

local function activate(W)
    for _, name in ipairs(GLOBAL_NAMES) do _G[name] = W.globals[name] end
end

local function saveGlobals(W)
    W.globals = {}
    for _, name in ipairs(GLOBAL_NAMES) do W.globals[name] = _G[name] end
end

local function installGlobals(W, side)
    local handlers = {}
    Events = setmetatable({}, {
        __index = function(t, name)
            local e = { Add = function(fn) handlers[name] = handlers[name] or {}; table.insert(handlers[name], fn) end }
            rawset(t, name, e)
            return e
        end,
    })
    W.fire = function(name, ...)
        for _, fn in ipairs(handlers[name] or {}) do fn(...) end
    end
    isClient = function() return side == "client" end
    isServer = function() return side == "server" end
    getCell = function() return W.cell end
    getWorld = function() return { getMetaGrid = function() return W.metaGrid end } end
    getNumActivePlayers = function() return 1 end
    getClimateManager = function()
        return {
            getAirTemperatureForSquare = function() return 12.5 end,
            isRaining = function() return false end,
            getPrecipitationIntensity = function() return 0 end,
            getClimateFloat = function() return { setEnableAdmin = function() end, setAdminValue = function() end } end,
            transmitServerStartRain = function() end,
            transmitServerStopRain = function() end,
        }
    end
    ClimateManager = { FLOAT_PRECIPITATION_INTENSITY = 3 }
    CharacterStat = { TEMPERATURE = "t", WETNESS = "w" }
    ModData = { getOrCreate = function(tag) W.modData[tag] = W.modData[tag] or {}; return W.modData[tag] end }
    IsoObject = { getNew = function(sq, spriteName) return { sprite = spriteName, getSprite = function() return { getName = function() return spriteName end } end } end }
    BuildingRoomsEditor = { getInstance = function() return W.editor end, Reset = function() W.resetEditor() end }
    sendServerCommand = function(a, b, c, d)
        if type(a) == "string" then W.sent[#W.sent + 1] = { module = a, command = b, args = c, all = true }
        else W.sent[#W.sent + 1] = { module = b, command = c, args = d } end
    end
    sendClientCommand = function(player, module, command, args) W.sentToServer = { module = module, command = command, args = args } end
    SendCommandToServer = function(cmd) W.adminCommand = cmd end
    getSpecificPlayer = function() return W.player end
    getTextManager = function() return { DrawString = function() end } end
    ISContextMenu = { getNew = function() return W.menu end }
    require = function() end
    UGMSpike = nil
end

local function newPlayer(W, x, y, z)
    local p = { x = x, y = y, z = z }
    function p:getX() return self.x end
    function p:getY() return self.y end
    function p:getZ() return self.z end
    function p:getUsername() return "tester" end
    function p:getPlayerNum() return 0 end
    function p:getCurrentSquare() return W.cell:getGridSquare(math.floor(self.x), math.floor(self.y), math.floor(self.z)) end
    function p:getStats() return { get = function() return 1 end } end
    function p:setHaloNote() end
    function p:teleportTo(nx, ny, nz) self.x, self.y, self.z = nx, ny, nz end
    return p
end

local function loadMod(W, files)
    for _, f in ipairs(files) do dofile(MOD .. f) end
    saveGlobals(W)
end

local CORE = "shared/UGMSpike/UGMSpike_Core.lua"
local SERVER = "server/UGMSpike/UGMSpike_Server.lua"
local CLIENT = "client/UGMSpike/UGMSpike_Client.lua"

local function tick(W, n)
    for _ = 1, n do W.fire("OnTick") end
end

---------------------------------------------------------------------------
-- Single player
---------------------------------------------------------------------------
print("Single player")
do
    local W = newWorld()
    installGlobals(W, "sp")
    loadMod(W, { CORE, CLIENT, SERVER })
    local U = UGMSpike
    W.player = newPlayer(W, 10003.5, 10003.5, 0)
    W.cell:createNewGridSquare(10003, 10003, 0) -- ground the player stands on
    W.fire("OnLoadedMapZones")

    U.Client.send(nil, W.player, "carveBelow", {})
    local reg = U.getRegistry()
    check(#reg.rooms == 1, "carve adds one room to the registry")
    local centre = W.cell:getGridSquare(10003, 10003, -1)
    check(centre ~= nil and centre:getFloor() ~= nil, "room centre square exists with a floor")
    check(centre and centre:isInARoom(), "room centre is assigned to the registered room")
    check(W.chunkFor(10003, 10003):getMinLevel() == -2, "chunk lowest level kept even (-2)")
    check(W.userDefinedBuildings() == 0, "carved room is a map building, not user-defined (no IsoRegions crash)")
    check(W.cell:getGridSquare(10006, 10006, -1) ~= nil, "outer SE wall post square exists")

    U.Client.send(nil, W.player, "carveBelow", {})
    check(#reg.rooms == 1, "second carve at the same spot is refused")

    U.Client.teleport(nil, W.player, -1)
    check(W.player.z == -1, "teleport down moves the player to z=-1")

    U.Client.send(nil, W.player, "grow", { mode = "newRoom" })
    local pocket = W.cell:getGridSquare(10006, 10003, -1)
    check(#reg.rooms == 2 and reg.rooms[2].kind == "pocket", "grow (separate room) adds a pocket room")
    check(pocket and pocket:getFloor() ~= nil and pocket:isInARoom(), "pocket tile has a floor and a room")
    check(pocket and U.findObjectBySprite(pocket, U.SPRITES.wallW) == nil, "wall between room and pocket removed")

    U.Client.send(nil, W.player, "grow", { mode = "sameRoom" })
    check(#reg.rooms[1].rects == 2, "grow (same room) adds a rectangle to the main room")
    local tile2 = W.cell:getGridSquare(10007, 10003, -1)
    check(tile2 and tile2:isInARoom(), "second grown tile is in a room")

    U.Client.teleport(nil, W.player, -1)
    check(W.player.z == -1, "teleport down is refused where there is no floor")
    U.Client.send(nil, W.player, "carveBelow", {})
    check(#reg.rooms == 3 and reg.rooms[3].z == -2, "carving again from z=-1 makes a room at z=-2")
    check(W.chunkFor(10003, 10003):getMinLevel() == -2, "z=-2 room completes the -2/-1 pair (lowest level stays -2)")
    U.Client.teleport(nil, W.player, -1)
    U.Client.send(nil, W.player, "carveBelow", {})
    check(#reg.rooms == 4 and reg.rooms[4].z == -3, "carving from z=-2 makes a room at z=-3")
    check(W.chunkFor(10003, 10003):getMinLevel() == -4, "z=-3 room extends the chunk to -4 (keeps the -4/-3 pair)")

    -- Reload: rooms are gone from the room map until the mod re-registers them.
    W.reloadRoomsAndSquares()
    W.fire("OnLoadedMapZones")
    W.assignRoomsFromMap()
    check(W.cell:getGridSquare(10003, 10003, -1):isInARoom(), "after reload the main room is back")
    check(W.cell:getGridSquare(10007, 10003, -1):isInARoom(), "after reload the same-room tile is back")
    check(W.cell:getGridSquare(10003, 10003, -2):isInARoom(), "after reload the z=-2 room is back")
    check(W.cell:getGridSquare(10003, 10003, -3):isInARoom(), "after reload the z=-3 room is back")
    check(W.userDefinedBuildings() == 0, "after reload no user-defined buildings (no IsoRegions crash)")

    U.Client.send(nil, W.player, "listRooms", {})
    check(U.Client.result ~= nil and #U.Client.result.lines == 4, "list rooms shows 4 rooms")
    U.Client.send(nil, W.player, "startRain", {})
    U.Client.printLocalDiag(nil, W.player)
    check(U.Client.result and #U.Client.result.lines > 5, "local diagnostics produce lines")
end

---------------------------------------------------------------------------
-- Multiplayer: server world and client world are separate
---------------------------------------------------------------------------
print("Multiplayer")
do
    local SW = newWorld()
    installGlobals(SW, "server")
    loadMod(SW, { CORE, SERVER })
    local SU = UGMSpike
    SW.player = newPlayer(SW, 20003.5, 20003.5, 0)
    SW.fire("OnLoadedMapZones")
    SW.fire("OnClientCommand", "UGMSpike", "carveBelow", SW.player, {})
    local carved
    for _, m in ipairs(SW.sent) do if m.command == "carved" then carved = m end end
    check(carved ~= nil and carved.all, "server broadcasts 'carved' to all clients")
    check(#SU.getRegistry().rooms == 1, "server registry has the room")

    -- Client world that never received the object packets (squares did not exist).
    local CW = newWorld()
    installGlobals(CW, "client")
    loadMod(CW, { CORE, CLIENT })
    local CU = UGMSpike
    CW.player = newPlayer(CW, 20003.5, 20003.5, 0)
    CU.Client.handle("carved", carved.args)
    local sq = CW.cell:getGridSquare(20003, 20003, -1)
    check(sq ~= nil, "client creates the missing square")
    check(sq and sq:isInARoom(), "client registers the room")
    check(CW.userDefinedBuildings() == 0, "client room is a map building (no IsoRegions crash)")
    tick(CW, CU.CLIENT_OBJECT_CHECK_DELAY + 1)
    check(sq and sq:getFloor() ~= nil, "client fills in the floor that never arrived")
    check(CW.chunkFor(20003, 20003):getMinLevel() == -2, "client keeps chunk lowest level even")

    -- Late joiner asks for the registry.
    activate(SW)
    SW.sent = {}
    SW.fire("OnClientCommand", "UGMSpike", "requestRegistry", SW.player, {})
    local regMsg = SW.sent[1]
    check(regMsg and regMsg.command == "registry" and #regMsg.args.rooms == 1, "server answers registry request")
    local LW = newWorld()
    installGlobals(LW, "client")
    loadMod(LW, { CORE, CLIENT })
    LW.player = newPlayer(LW, 20003.5, 20003.5, 0)
    UGMSpike.Client.handle("registry", regMsg.args)
    check(#LW.rooms == 1, "late joiner registers the room in its room map")

    UGMSpike.Client.teleport(nil, LW.player, -1)
    check(LW.adminCommand == nil, "client teleport refused when it has no square there yet")
end

print(failures == 0 and "ALL PASSED" or (failures .. " FAILURE(S)"))
os.exit(failures == 0 and 0 or 1)
