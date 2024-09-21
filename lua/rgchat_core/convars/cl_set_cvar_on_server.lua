net.Receive('RGChat_SwitchCvarFromClient', function()
	local cvar_name = net.ReadString()
	local cvar_object = RealGloabalChat.ConVar:Get(cvar_name)
	if not cvar_object then return end
	RunConsoleCommand(cvar_name, cvar_object:GetInt() == 1 and '0' or '1')
end)

net.Receive('RGChat_SetCvarFromClient', function()
	local cvar_name = net.ReadString()
	local cvar_value = net.ReadString()
	RunConsoleCommand(cvar_name, cvar_value)
end)