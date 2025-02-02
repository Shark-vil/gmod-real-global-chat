if not util.IsBinaryModuleInstalled('gwsockets') then return end
require('gwsockets')

local _util_TableToJSON = util.TableToJSON
local _isstring = isstring
local _istable = istable
local _isfunction = isfunction
local _xpcall = xpcall
local _ipairs = ipairs
local _ErrorNoHalt = ErrorNoHalt
local _assert = assert
local _uuid_template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
local _math_random = math.random
local _string_gsub = string.gsub
local _string_format = string.format
local _timer_Simple = timer.Simple
local _util_JSONToTable = util.JSONToTable
local _wsDomain = 'ws://localhost:5014'

local private = {}
private.socket = nil
private.events = {}
private.isReady = false
private.isRunning = false

-- https://gist.github.com/jrus/3197011
function private:UUID()
    return _string_gsub(_uuid_template, '[xy]', function (c)
        local v = (c == 'x') and _math_random(0, 0xf) or _math_random(8, 0xb)
        return _string_format('%x', v)
    end)
end

function private:SendMsg(data)
    private.socket:write(_util_TableToJSON(data))
end

function private:CallEvents(dataResponse)
    for eventName, func in _ipairs(private.events) do
        if dataResponse.name == eventName then
            local errMessage
            _xpcall(func, function(err)
                errMessage = err
            end, _util_JSONToTable(dataResponse.data) or dataResponse.data)
            if errMessage then
                _ErrorNoHalt('Event name: ' .. eventName .. '\nEvent error:\n' .. errMessage)
            end
            break
        end
    end
end

local public = {}

function public:AddEvent(eventName, func)
    _assert(_isstring(eventName), 'Must be a string')
    _assert(_isfunction(func), 'Must be a function')
    private.events[eventName] = func
end

-- Send
function public:MsgTo(steamIds, eventName, data)
    if _isstring(steamIds) then
        steamIds = { steamIds }
    end
    _assert(_istable(steamIds), 'Must be a table')
    _assert(_istable(data), 'Must be a table')
    _assert(_isstring(eventName), 'Must be a string')
    private:SendMsg({
        type = 'msgto',
        name = eventName,
        receivers = steamIds,
        data = data
    })
end

-- SendOmit
function public:MsgToExcept(excepSteamIds, eventName, data)
    if _isstring(excepSteamIds) then
        excepSteamIds = { excepSteamIds }
    end
    _assert(_istable(excepSteamIds), 'Must be a table')
    _assert(_istable(data), 'Must be a table')
    _assert(_isstring(eventName), 'Must be a string')
    private:SendMsg({
        type = 'msgtoexcept',
        name = eventName,
        receivers = excepSteamIds,
        data = data
    })
end

-- Broadcast
function public:MsgToAll(eventName, data)
    _assert(_istable(data), 'Must be a table')
    _assert(_isstring(eventName), 'Must be a string')
    private:SendMsg({
        type = 'msgtoall',
        name = eventName,
        data = data
    })
end

function public:IsReady()
    return private.isReady
end

function public:Close()
    private.isRunning = false
    private.socket:close()
end

function public:CloseFromServer()
    private.isRunning = false
    private:SendMsg({
        type = 'close',
        name = '0',
        receivers = nil
    })
end

function public:Connect(ply)
    if CLIENT then ply = LocalPlayer() end
    local readyCode = private:UUID()
    local steamid64 = ply:SteamID64()
    local socket = GWSockets.createWebSocket(_wsDomain .. '/ws?clientId=' .. steamid64)
    private.socket = socket
    private.isReady = false
    private.isRunning = true

    function socket:onMessage(data)
        print('[RGChat] WebSocket onMessage: ' .. tostring(data))
        if not private.isReady and data then
            local jsonData = _util_JSONToTable(data)
            if jsonData and jsonData.name == readyCode then
                private.isReady = true
                print('[RGChat] WebSocket is ready!')
            end
        elseif private.isReady then
            private:CallEvents(data)
        end
    end

    function socket:onError(err)
        print('[RGChat] WebSocket Error: ', err)
        socket:close()
        if private.isRunning then
            _timer_Simple(1, function() public:Connect(ply) end)
        end
    end

    function socket:onConnected()
        print('[RGChat] WebSocket is connected')
        private:SendMsg({
            type = 'echo',
            name = readyCode,
        })
    end

    function socket:onDisconnected()
        private.isReady = false
        print('[RGChat] WebSocket disconnected')
    end

    socket:open()
end

RealGloabalChat.WebSocket = public

concommand.Add('sv_rgc_test_websocket', function(ply)
    local ConVar = RealGloabalChat.ConVar
    if not ConVar:GetBool('sv_rgc_devmode') then return end

    RealGloabalChat.WebSocket:Connect(ply)
    RealGloabalChat.WebSocket:AddEvent('movement', function(data)
        print(data)
    end)
    timer.Create('wstest', .1, 0, function()
        if not RealGloabalChat.WebSocket:IsReady() then return end
        RealGloabalChat.WebSocket:MsgToAll('movement', {
            pos = ply:GetPos()
        })
    end)
end)