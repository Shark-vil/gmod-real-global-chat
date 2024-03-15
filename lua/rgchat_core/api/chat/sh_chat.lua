function RealGloabalChat.Api:PlayerChatIsActive(ply)
	if CLIENT then return RealGloabalChat.ConVar:GetBool('cl_rgc_status') end
	if not IsValid(ply) then return false end
	local active = RealGloabalChat:GetFromStorage('ModActive', ply)
	if not active then return false end
	return true
end