function RealGloabalChat:IsDeveloperMode()
	return RealGloabalChat.ConVar:GetBool('developer')
end

function RealGloabalChat:IsHttpDebug()
	return RealGloabalChat.ConVar:GetBool('sv_rgc_http_debug')
end

function RealGloabalChat:Log(message)
	MsgC(Color(225, 225, 225), '[RGChat Log]', message, '\n')
end

function RealGloabalChat:LogWarning(message)
	MsgC(Color(241, 189, 91), '[RGChat Warning]', message, '\n')
end

function RealGloabalChat:LogError(message)
	MsgC(Color(255, 125, 123), '[RGChat Error]', message, '\n')
end