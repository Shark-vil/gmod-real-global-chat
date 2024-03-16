hook.Add('PlayerStartTaunt', 'RGChatPlayerStartTaunt', function(ply, act, length)
	ply.RgChatActiveGesture = act

	if length then
		timer.Create('RGChatPlayerStopTaunt.' .. ply:EntIndex(), length, 1, function()
			if not IsValid(ply) then return end
			ply.RgChatActiveGesture = nil
		end)
	end
end)