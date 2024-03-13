local color_rgchat_tag = Color(207, 237, 73)
local color_message = Color(255, 255, 255)
local lang = RealGloabalChat.Values.Language
local IsValid = IsValid
local last_players_count

timer.Create('RealGlobalChat.UpdateOnline', 30, 0, function()
	if not RealGloabalChat:ModIsActive() then return end
	local ply = LocalPlayer()
	if not IsValid(ply) then return end
	RealGloabalChat:UpdateOnline()
end)

timer.Create('RealGlobalChat.CheckOnline', 300, 0, function()
	if not RealGloabalChat:ModIsActive() then return end
	local ply = LocalPlayer()
	if not IsValid(ply) then return end

	RealGloabalChat:GetOnlineCount(function(count)
		if not last_players_count or last_players_count ~= count then
			last_players_count = count
			chat.AddText(color_rgchat_tag, lang['rgchat_info'] .. ' ', color_message, ': ' .. string.Replace(lang['chat_online'], '%count%', count))
		end
	end)
end)