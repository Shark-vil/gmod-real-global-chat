RealGloabalChat.ConVar.AllRegistered = RealGloabalChat.ConVar.AllRegistered or {}

function RealGloabalChat.ConVar:Register(name, value, flags, helpText, min, max)
	if (CLIENT and string.StartsWith(name, 'cl')) or (SERVER and string.StartsWith(name, 'sv')) then
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