local _sendToClient

if SERVER then
	function _sendToClient(ply, message, message_type)
		if not IsValid(ply) or not ply:IsPlayer() then return end
		net.Start('RGChat_PrintToChat')
		net.WriteInt(message_type, 3)
		net.WriteString(message)
		net.Send(ply)
	end
else
	net.Receive('RGChat_PrintToChat', function()
		local message_type = net.ReadInt(3)
		local message = net.ReadString()
		if message_type == 0 then
			RealGloabalChat:Print(message)
		elseif message_type == 1 then
			RealGloabalChat:PrintWarning(message)
		elseif message_type == 3 then
			RealGloabalChat:PrintError(message)
		end
	end)
end

function RealGloabalChat:Print(message, ply)
	if SERVER then
		_sendToClient(ply, message, 0)
		return
	end
	chat.AddText(RealGloabalChat.Color.Log, '[RGChat]', message)
end

function RealGloabalChat:PrintWarning(message)
	if SERVER then
		_sendToClient(ply, message, 1)
		return
	end
	chat.AddText(RealGloabalChat.Color.Warning, '[RGChat Warning]', message)
end

function RealGloabalChat:PrintError(message)
	if SERVER then
		_sendToClient(ply, message, 2)
		return
	end
	chat.AddText(RealGloabalChat.Color.Error, '[RGChat Error]', message)
end