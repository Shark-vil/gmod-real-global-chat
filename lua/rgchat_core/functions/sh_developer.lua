local _unpack = unpack
local _MsgC = MsgC

function RealGloabalChat:IsDeveloperMode()
	-- return RealGloabalChat.ConVar:GetBool('developer')
	return RealGloabalChat.ConVar:GetBool('sv_rgc_devmode')
end

function RealGloabalChat:IsHttpDebug()
	return RealGloabalChat.ConVar:GetBool('sv_rgc_http_debug')
end

function RealGloabalChat:Log(...)
	local args = { ... }
	args[#args + 1] = '\n'
	_MsgC(RealGloabalChat.Color.Log, '[RGChat Log] ', _unpack(args))
end

function RealGloabalChat:LogWarning(...)
	local args = { ... }
	args[#args + 1] = '\n'
	_MsgC(RealGloabalChat.Color.Warning, '[RGChat Warning] ', _unpack(args))
end

function RealGloabalChat:LogError(...)
	local args = { ... }
	args[#args + 1] = '\n'
	_MsgC(RealGloabalChat.Color.Error, '[RGChat Error] ', _unpack(args))
end