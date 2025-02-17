local _IsValid = IsValid
local _ConVar = RealGloabalChat.ConVar

function RealGloabalChat.Api:PlayerChatIsActive(ply)
	if CLIENT then return RealGloabalChat.USER and _ConVar:GetBool('cl_rgc_status') end
	if not _IsValid(ply) then return false end
	local active = RealGloabalChat:GetFromStorage('ModActive', ply)
	if not active then return false end
	return true
end