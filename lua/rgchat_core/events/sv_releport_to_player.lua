net.Receive('RGChat_TeleportToPlayer', function(_, ply)
    local rgchat_steamid = net.ReadString()

    if not rgchat_steamid or rgchat_steamid == '' then
        RealGloabalChat:PrintForPlayerWarning(ply, 'The SteamId specified is invalid')
        return
    end

    for _, other_player in ipairs(player.GetHumans()) do
        if IsValid(other_player) and other_player:SteamID64() == rgchat_steamid then
            RealGloabalChat:PrintForPlayerWarning(ply, 'You can\'t teleport to players on the server!')
            return
        end
    end

    for _, ent in ipairs(ents.FindByClass('rgchat_player_nextbot')) do
        if IsValid(ent) and ent.BotData and ent.BotData.SteamId64 and ent.BotData.SteamId64 == rgchat_steamid then
            ply:SetPos(ent:GetPos())
            break
        end
    end
end)