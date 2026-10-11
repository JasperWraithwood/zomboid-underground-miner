-- Underground Miner - test spike, client side: right-click menu, live overlay,
-- and applying server changes on multiplayer clients.

require "UGMSpike/UGMSpike_Core"

local U = UGMSpike
local C = {}
U.Client = C

C.overlay = true
C.result = nil
C.cache = nil
C.frame = 0

function C.say(text)
    U.log("MSG " .. tostring(text))
    local player = getSpecificPlayer(0)
    if player then
        U.try(nil, function() player:setHaloNote(tostring(text), 230, 230, 120, 500) end)
    end
end

function C.showResult(title, lines)
    U.log("RESULT " .. tostring(title))
    for _, line in ipairs(lines or {}) do U.log("  " .. line) end
    C.result = { title = title, lines = lines or {} }
end

-- Ask the server (or the local "server" in single player) to do something.
function C.send(_, player, command, args)
    if isClient() then
        sendClientCommand(player, U.MODULE, command, args or {})
    elseif U.Server then
        U.Server.handle(command, player, args or {})
    else
        C.say("UGM Spike: server code not loaded")
    end
end

function C.teleport(_, player, dz)
    local x, y = math.floor(player:getX()), math.floor(player:getY())
    local z = math.floor(player:getZ()) + dz
    local sq = getCell():getGridSquare(x, y, z)
    if not sq or not sq:getFloor() then
        C.say("No floor at z=" .. z .. " here. Carve a test room first and stand above it.")
        return
    end
    U.log("teleport to " .. x .. "," .. y .. "," .. z)
    if isClient() then
        -- Admin command; works on your own server where you are admin.
        SendCommandToServer("/teleportto " .. (x + 0.5) .. "," .. (y + 0.5) .. "," .. z)
    else
        player:teleportTo(x + 0.5, y + 0.5, z)
    end
end

function C.printLocalDiag(_, player)
    C.showResult("Diagnostics (" .. U.side() .. " view)", U.diagnose(player, player:getCurrentSquare()))
end

function C.redraw(_, player)
    local x, y, z = math.floor(player:getX()), math.floor(player:getY()), math.floor(player:getZ())
    U.refreshLocalRendering(x, y, z)
    C.say("Redrew nearby chunks")
end

function C.toggleOverlay()
    C.overlay = not C.overlay
end

function C.clearResult()
    C.result = nil
end

---------------------------------------------------------------------------
-- Messages from the server (multiplayer) or direct calls (single player)
---------------------------------------------------------------------------

function C.handle(command, args)
    if command == "message" then
        C.say(args.text)
    elseif command == "result" then
        C.showResult(args.title, args.lines)
    elseif command == "registry" then
        local rooms = args.rooms or {}
        U.log("received registry with " .. #rooms .. " room(s)")
        if isClient() then
            U.trackRoomChunks(rooms)
            local count = U.registerRooms(rooms, false, false)
            local player = getSpecificPlayer(0)
            if player then
                U.refreshLocalRendering(math.floor(player:getX()), math.floor(player:getY()), math.floor(player:getZ()))
            end
            U.log("registered " .. count .. " room(s) from server")
        end
    elseif command == "carved" then
        if not isClient() then return end -- single player already applied it
        local rooms = args.rooms or {}
        U.trackRoomChunks(rooms)
        local layout = args.layout
        local first = layout.cells[1]
        U.applyLayoutClient(layout, function()
            U.refreshLocalRendering(first.x, first.y, first.z)
        end)
        U.registerRooms(rooms, false, args.replace)
        U.refreshLocalRendering(first.x, first.y, first.z)
    end
end

Events.OnServerCommand.Add(function(module, command, args)
    if module ~= U.MODULE then return end
    local ok, err = pcall(C.handle, command, args or {})
    if not ok then U.log("ERROR handling " .. tostring(command) .. ": " .. tostring(err)) end
end)

Events.OnGameStart.Add(function()
    if not isClient() then return end
    -- Get the server's room list so this client's room map matches.
    U.schedule(30, function()
        local player = getSpecificPlayer(0)
        if player then sendClientCommand(player, U.MODULE, "requestRegistry", {}) end
    end)
end)

---------------------------------------------------------------------------
-- Right-click menu
---------------------------------------------------------------------------

local function addMenu(playerIndex, context, worldObjects, test)
    if test then return end
    local player = getSpecificPlayer(playerIndex)
    if not player then return end

    local root = context:addOption("UGM Spike (test)", nil, nil)
    local sub = ISContextMenu:getNew(context)
    context:addSubMenu(root, sub)

    sub:addOption("1. Carve test room below me", nil, C.send, player, "carveBelow", {})
    sub:addOption("2. Teleport down one level", nil, C.teleport, player, -1)
    sub:addOption("3. Teleport up one level", nil, C.teleport, player, 1)
    sub:addOption("Grow room 1 tile east (separate room)", nil, C.send, player, "grow", { mode = "newRoom" })
    sub:addOption("Grow room 1 tile east (same room)", nil, C.send, player, "grow", { mode = "sameRoom" })
    sub:addOption("Start rain", nil, C.send, player, "startRain", {})
    sub:addOption("Stop rain override", nil, C.send, player, "stopRain", {})
    sub:addOption("Diagnose here (this game)", nil, C.printLocalDiag, player)
    if isClient() then
        sub:addOption("Diagnose here (server view)", nil, C.send, player, "diag", {})
    end
    sub:addOption("List test rooms", nil, C.send, player, "listRooms", {})
    sub:addOption("Redraw nearby chunks", nil, C.redraw, player)
    sub:addOption(C.overlay and "Hide overlay" or "Show overlay", nil, C.toggleOverlay)
    if C.result then
        sub:addOption("Clear result panel", nil, C.clearResult)
    end
    sub:addOption("Forget all test rooms (registry)", nil, C.send, player, "forgetRooms", {})
end

Events.OnFillWorldObjectContextMenu.Add(addMenu)

---------------------------------------------------------------------------
-- Live overlay (top-left): what this game thinks about the square you stand on
---------------------------------------------------------------------------

local LINE = 18

Events.OnPostUIDraw.Add(function()
    if not C.overlay then return end
    local player = getSpecificPlayer(0)
    if not player then return end

    C.frame = C.frame + 1
    if not C.cache or C.frame % 20 == 0 then
        C.cache = U.try({ "diagnostics failed" }, U.diagnose, player, player:getCurrentSquare())
    end

    local tm = getTextManager()
    local x, y = 60, 140
    tm:DrawString(x, y, "UGM Spike - live (" .. U.side() .. ")", 1, 0.85, 0.3, 1)
    y = y + LINE
    for _, line in ipairs(C.cache) do
        tm:DrawString(x, y, line, 1, 1, 1, 1)
        y = y + LINE
    end
    if C.result then
        y = y + LINE / 2
        tm:DrawString(x, y, C.result.title, 0.5, 1, 0.5, 1)
        y = y + LINE
        for _, line in ipairs(C.result.lines) do
            tm:DrawString(x, y, line, 0.8, 1, 0.8, 1)
            y = y + LINE
        end
    end
end)
