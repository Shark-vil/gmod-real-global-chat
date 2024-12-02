RealGloabalChat.ConVar.AllRegistered = RealGloabalChat.ConVar.AllRegistered or {}

function RealGloabalChat.ConVar:Register(name, value, flags, helpText, min, max)
	local is_client = CLIENT and string.StartsWith(name, 'cl')
	local is_rpc = CLIENT and string.StartsWith(name, 'sv') and isnumber(flags) and bit.band(flags, FCVAR_REPLICATED) == FCVAR_REPLICATED
	local is_server = SERVER and string.StartsWith(name, 'sv')

	if is_client or is_rpc or is_server then
		CreateConVar(name, value, flags, helpText, min, max)
		RealGloabalChat.ConVar.AllRegistered[name] = GetConVar(name)
	end
end

function RealGloabalChat.ConVar:Get(name)
	if RealGloabalChat.ConVar.AllRegistered[name] then
		return RealGloabalChat.ConVar.AllRegistered[name]
	end
	local convar = GetConVar(name)
	if not convar then return end
	RealGloabalChat.ConVar.AllRegistered[name] = convar
	return convar
end

function RealGloabalChat.ConVar:GetInt(name)
	local cvar_object = RealGloabalChat.ConVar:Get(name)
	if not cvar_object then return end
	return cvar_object:GetInt()
end

function RealGloabalChat.ConVar:GetBool(name)
	local cvar_object = RealGloabalChat.ConVar:Get(name)
	if not cvar_object then return end
	return cvar_object:GetBool()
end

function RealGloabalChat.ConVar:GetFloat(name)
	local cvar_object = RealGloabalChat.ConVar:Get(name)
	if not cvar_object then return end
	return cvar_object:GetFloat()
end

function RealGloabalChat.ConVar:GetString(name)
	local cvar_object = RealGloabalChat.ConVar:Get(name)
	if not cvar_object then return end
	return cvar_object:GetString()
end