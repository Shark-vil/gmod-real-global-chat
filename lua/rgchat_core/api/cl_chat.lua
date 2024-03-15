function RealGloabalChat.Api:GetChatRoom()
	local chatRoomName = 'world'

	if RealGloabalChat.ConVar:GetBool('cl_rgc_country_mode') then
		chatRoomName = 'country.' .. string.lower(system.GetCountry())
	end

	return chatRoomName
end