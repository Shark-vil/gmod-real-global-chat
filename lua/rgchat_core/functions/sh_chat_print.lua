local _SendToClient
local _util_TableToJSON = util.TableToJSON
local _util_JSONToTable = util.JSONToTable
local _unpack = unpack

if SERVER then
	function _SendToClient(ply, json_data_messages, message_type)
		if not IsValid(ply) or not ply:IsPlayer() then return end
		net.Start('RGChat_PrintToChat')
		net.WriteInt(message_type, 3)
		net.WriteString(json_data_messages)
		net.Send(ply)
	end
else
	net.Receive('RGChat_PrintToChat', function()
		local message_type = net.ReadInt(3)
		local json_data_messages = net.ReadString()
		local messages_args = _util_JSONToTable(json_data_messages)
		if message_type == 0 then
			RealGloabalChat:Print(_unpack(messages_args))
		elseif message_type == 1 then
			RealGloabalChat:PrintWarning(_unpack(messages_args))
		elseif message_type == 3 then
			RealGloabalChat:PrintError(_unpack(messages_args))
		end
	end)
end

function RealGloabalChat:Print(...)
	if SERVER then return end
	chat.AddText(RealGloabalChat.Color.Log, '[RGChat] ', ...)
end

function RealGloabalChat:PrintWarning(...)
	if SERVER then return end
	chat.AddText(RealGloabalChat.Color.Warning, '[RGChat Warning] ', ...)
end

function RealGloabalChat:PrintError(...)
	if SERVER then return end
	chat.AddText(RealGloabalChat.Color.Error, '[RGChat Error] ', ...)
end

function RealGloabalChat:PrintForPlayer(ply, ...)
	if CLIENT then
		RealGloabalChat:Print(...)
		return
	end
	_SendToClient(ply, _util_TableToJSON({ ... }), 0)
end

function RealGloabalChat:PrintForPlayerWarning(ply, ...)
	if CLIENT then
		RealGloabalChat:PrintWarning(...)
		return
	end
	_SendToClient(ply, _util_TableToJSON({ ... }), 1)
end

function RealGloabalChat:PrintForPlayerError(ply, ...)
	if CLIENT then
		RealGloabalChat:PrintError(...)
		return
	end
	_SendToClient(ply, _util_TableToJSON({ ... }), 2)
end