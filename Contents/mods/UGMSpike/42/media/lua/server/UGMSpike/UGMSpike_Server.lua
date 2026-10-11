-- Underground Miner - test spike, server side (also runs in single player).
-- All world changes happen here; multiplayer clients only ask for them.

require "UGMSpike/UGMSpike_Core"

local U = UGMSpike
local S = {}
U.Server = S

-- Reply to the player who sent the command (direct call in single player).
local function reply(player, command, args)
    if isServer() then
        sendServerCommand(player, U.MODULE, command, args)
    elseif U.Client then
        U.Client.handle(command, args)
    end
end

-- Tell every multiplayer client (single player already has the change).
local function broadcast(command, args)
    if isServer() then
        sendServerCommand(U.MODULE, command, args)
    end
end

local function statsText(stats)
    return "squares created=" .. stats.squaresCreated .. ", objects added=" .. stats.objectsAdded
        .. ", objects removed=" .. stats.objectsRemoved .. ", level fixes=" .. stats.levelFixes
        .. ", skipped (chunk not loaded)=" .. stats.unloaded
end

local function roomIdText(x, y, z)
    local def = getWorld():getMetaGrid():getRoomAt(x, y, z)
    return def and def:getIDString() or "none"
end

local function playerTile(player)
    return math.floor(player:getX()), math.floor(player:getY()), math.floor(player:getZ())
end

function S.carveBelow(player, args)
    local px, py, pz = playerTile(player)
    local z = pz - 1
    if z < U.MIN_LEVEL then
        return reply(player, "message", { text = "Too deep: z=" .. z })
    end
    local reg = U.getRegistry()
    if U.findRoomDefAt(reg.rooms, px, py, z) then
        return reply(player, "message", { text = "There is already a test room below you (z=" .. z .. ")." })
    end

    local half = math.floor(U.ROOM_SIZE / 2)
    local x0, y0 = px - half, py - half
    local layout = U.roomLayout(x0, y0, U.ROOM_SIZE, U.ROOM_SIZE, z)
    local stats = U.applyLayoutAuthority(layout)

    local def = {
        id = reg.nextId, z = z, name = U.ROOM_NAME, kind = "main",
        cx = px, cy = py, grown = 0,
        rects = { { x = x0, y = y0, w = U.ROOM_SIZE, h = U.ROOM_SIZE } },
    }
    reg.nextId = reg.nextId + 1
    reg.rooms[#reg.rooms + 1] = def
    U.trackRoomChunks({ def })
    U.registerRooms({ def }, false, false)
    if isServer() then U.assignRoomOnLoadedSquares(def) end
    U.refreshLocalRendering(px, py, z)

    local sq = getCell():getGridSquare(px, py, z)
    U.log("carved " .. U.describeDef(def) .. " by " .. tostring(player:getUsername()) .. ": " .. statsText(stats)
        .. "; chunk levels " .. U.chunkLevelsText(sq) .. "; room id " .. roomIdText(px, py, z))

    broadcast("carved", { layout = layout, rooms = { def }, replace = false })
    reply(player, "message", { text = "Carved test room #" .. def.id .. " at z=" .. z .. ". Use 'Teleport down one level'." })
end

-- mode "newRoom": the new tile becomes its own one-tile room (separate building).
-- mode "sameRoom": the main room is re-registered with the extra tile (one room).
function S.grow(player, args)
    local mode = args.mode == "sameRoom" and "sameRoom" or "newRoom"
    local px, py, pz = playerTile(player)
    local reg = U.getRegistry()
    local def = U.findRoomDefAt(reg.rooms, px, py, pz)
    if def and def.parentId then
        def = U.findRoomDefById(reg.rooms, def.parentId)
    end
    if not def or def.kind ~= "main" then
        return reply(player, "message", { text = "Stand inside a test room first." })
    end

    local main = def.rects[1]
    local tx, ty = main.x + main.w + def.grown, def.cy
    local idBefore = roomIdText(main.x, main.y, def.z)
    local layout = U.growLayout(tx, ty, def.z)
    local stats = U.applyLayoutAuthority(layout)
    def.grown = def.grown + 1

    local changed
    if mode == "sameRoom" then
        def.rects[#def.rects + 1] = { x = tx, y = ty, w = 1, h = 1 }
        changed = def
        U.registerRooms({ def }, false, true)
    else
        changed = {
            id = reg.nextId, z = def.z, name = U.ROOM_NAME, kind = "pocket", parentId = def.id,
            rects = { { x = tx, y = ty, w = 1, h = 1 } },
        }
        reg.nextId = reg.nextId + 1
        reg.rooms[#reg.rooms + 1] = changed
        U.registerRooms({ changed }, false, false)
    end
    U.trackRoomChunks({ changed })
    if isServer() then U.assignRoomOnLoadedSquares(changed) end
    U.refreshLocalRendering(tx, ty, def.z)

    U.log("grew room#" .. def.id .. " (" .. mode .. ") to " .. tx .. "," .. ty .. "," .. def.z .. ": " .. statsText(stats)
        .. "; main room id before=" .. idBefore .. " after=" .. roomIdText(main.x, main.y, def.z)
        .. "; new tile room id=" .. roomIdText(tx, ty, def.z))

    broadcast("carved", { layout = layout, rooms = { changed }, replace = mode == "sameRoom" })
    reply(player, "message", { text = "Grew room #" .. def.id .. " east (" .. mode .. ")." })
end

function S.requestRegistry(player, args)
    local reg = U.getRegistry()
    U.log("sending " .. #reg.rooms .. " room(s) to " .. tostring(player:getUsername()))
    reply(player, "registry", { rooms = reg.rooms })
end

function S.listRooms(player, args)
    local reg = U.getRegistry()
    local lines = {}
    for _, def in ipairs(reg.rooms) do
        local r = def.rects[1]
        lines[#lines + 1] = U.describeDef(def) .. " roomMap=" .. roomIdText(r.x, r.y, def.z)
    end
    if #lines == 0 then lines[1] = "no test rooms" end
    for _, line in ipairs(lines) do U.log("ROOM " .. line) end
    reply(player, "result", { title = "Test rooms (" .. U.side() .. ")", lines = lines })
end

function S.forgetRooms(player, args)
    local reg = U.getRegistry()
    local count = #reg.rooms
    reg.rooms = {}
    U.log("registry cleared (" .. count .. " room(s)); walls and floors stay, rooms are gone after the next reload")
    reply(player, "message", { text = "Forgot " .. count .. " test room(s). Reload to see them become outdoors." })
end

function S.diag(player, args)
    local lines = U.diagnose(player, player:getCurrentSquare())
    for _, line in ipairs(lines) do U.log("DIAG " .. line) end
    reply(player, "result", { title = "Diagnostics (" .. U.side() .. " view)", lines = lines })
end

local function precipitationFloat()
    return getClimateManager():getClimateFloat(ClimateManager.FLOAT_PRECIPITATION_INTENSITY)
end

function S.startRain(player, args)
    if isServer() then
        getClimateManager():transmitServerStartRain(1.0)
    else
        local f = precipitationFloat()
        f:setEnableAdmin(true)
        f:setAdminValue(1.0)
    end
    U.log("rain forced on")
    reply(player, "message", { text = "Rain forced on (it may be snow if it is cold)." })
end

function S.stopRain(player, args)
    if isServer() then
        getClimateManager():transmitServerStopRain()
    else
        precipitationFloat():setEnableAdmin(false)
    end
    U.log("rain override off")
    reply(player, "message", { text = "Rain override off." })
end

local handlers = {
    carveBelow = S.carveBelow,
    grow = S.grow,
    requestRegistry = S.requestRegistry,
    listRooms = S.listRooms,
    forgetRooms = S.forgetRooms,
    diag = S.diag,
    startRain = S.startRain,
    stopRain = S.stopRain,
}

function S.handle(command, player, args)
    local handler = handlers[command]
    if not handler or not player then return end
    local ok, err = pcall(handler, player, args or {})
    if not ok then
        U.log("ERROR in " .. command .. ": " .. tostring(err))
        reply(player, "message", { text = "UGM Spike error in " .. command .. " - see console.txt" })
    end
end

Events.OnClientCommand.Add(function(module, command, player, args)
    if module ~= U.MODULE then return end
    S.handle(command, player, args)
end)
