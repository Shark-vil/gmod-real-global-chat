function RealGloabalChat.Api:GetChatRoom()
	-- local chatRoomName = 'world'

	-- if RealGloabalChat.ConVar:GetBool('cl_rgc_country_mode') then
	-- 	chatRoomName = 'country.' .. string.lower(system.GetCountry())
	-- end

	-- return chatRoomName

	return 'developer'
end

function RealGloabalChat.Api:GetLanguage()
	local target_translate =  RealGloabalChat.ConVar:GetString('cl_rgc_target_translate')
	if isstring(target_translate) then
		target_translate = string.Trim(target_translate)
		if target_translate == 'nil' then target_translate = nil end
	end
	if not target_translate or target_translate == '' then
		target_translate = system.GetCountry()
		if not target_translate or target_translate == '' then
			target_translate = RealGloabalChat.ConVar:GetString('cl_language')
		end
	end
	return target_translate
end