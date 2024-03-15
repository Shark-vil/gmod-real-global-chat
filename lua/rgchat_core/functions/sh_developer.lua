function RealGloabalChat:IsDeveloperMode()
	return RealGloabalChat.ConVar:GetBool('developer')
end

function RealGloabalChat:IsHttpDebug()
	return RealGloabalChat.ConVar:GetBool('sv_rgc_http_debug')
end

function RealGloabalChat:Log(message)
	MsgC(RealGloabalChat.Color.Log, '[RGChat Log]', message, '\n')
end

function RealGloabalChat:LogWarning(message)
	MsgC(RealGloabalChat.Color.Warning, '[RGChat Warning]', message, '\n')
end

function RealGloabalChat:LogError(message)
	MsgC(RealGloabalChat.Color.Error, '[RGChat Error]', message, '\n')
end