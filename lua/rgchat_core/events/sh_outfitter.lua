if SERVER then
	timer.Create('RGChat.CheckOutfitter', 1, 0, function()
		local ply = LocalPlayer()

		if not ply.outfitter_mdl and ply.rgchat_outfitter then
			net.Start('RGChat_OutfitterChangeModel')
			net.WriteString('')
			net.WriteUInt64(0)
			net.SendToServer()
			ply.rgchat_outfitter = false

			return
		end

		if not ply.outfitter_mdl then return end
		local ply_bodygroups = ''

		for _, v in ipairs(ply:GetBodyGroups()) do
			local bodygroup = ply:GetBodygroup(v.id)

			if ply.outfitter_bodygroups and ply.outfitter_bodygroups[v.name] then
				bodygroup = ply.outfitter_bodygroups[v.name]
			end

			ply_bodygroups = ply_bodygroups .. bodygroup
		end

		if (ply.outfitter_skin or 1) ~= ply.rgchat_outfitter_skin or ply_bodygroups ~= ply.rgchat_outfitter_bodygroups then
			ply.rgchat_outfitter_skin = ply.outfitter_skin or 1
			ply.rgchat_outfitter_bodygroups = ply_bodygroups
			net.Start('RGChat_OutfitterChangeModel')
			net.WriteString(ply.outfitter_mdl)
			net.WriteUInt64(ply.outfitter_download_info)
			net.WriteInt(ply.rgchat_outfitter_skin, 16)
			net.WriteString(ply.rgchat_outfitter_bodygroups)
			net.SendToServer()
		end
	end)

	hook.Add('OutfitApply', 'RGChat.UpdateCache', function(ply, model_name, download_info)
		if model_name and download_info and model_name ~= '' and download_info ~= '' then
			RealGloabalChat:AddToStorage('AddonsModels', model_path, download_info)
			ply.rgchat_outfitter = true
			local ply_bodygroups = ''

			for _, v in ipairs(ply:GetBodyGroups()) do
				local bodygroup = ply:GetBodygroup(v.id)

				if ply.outfitter_bodygroups and ply.outfitter_bodygroups[v.name] then
					bodygroup = ply.outfitter_bodygroups[v.name]
				end

				ply_bodygroups = ply_bodygroups .. bodygroup
			end

			ply.rgchat_outfitter_skin = ply.outfitter_skin or 1
			ply.rgchat_outfitter_bodygroups = ply_bodygroups
			net.Start('RGChat_OutfitterChangeModel')
			net.WriteString(model_name)
			net.WriteUInt64(download_info)
			net.WriteInt(ply.rgchat_outfitter_skin, 16)
			net.WriteString(ply.rgchat_outfitter_bodygroups)
			net.SendToServer()
		else
			ply.rgchat_outfitter = false
			net.Start('RGChat_OutfitterChangeModel')
			net.WriteString('')
			net.WriteUInt64(0)
			net.WriteInt(0, 16)
			net.WriteString('')
			net.SendToServer()
		end
	end)
else
	net.Receive('RGChat_OutfitterChangeModel', function(_, ply)
		local model_name = net.ReadString()
		local download_info = net.ReadUInt64()
		local outfitter_skin = net.ReadInt(16)
		local outfitter_bodygroups = net.ReadString()

		if model_name == '' and download_info == 0 then
			ply.rgchat_outfitter_mdl = nil
			ply.rgchat_outfitter_skin = nil
			ply.rgchat_outfitter_bodygroups = nil

			return
		end

		RealGloabalChat:AddToStorage('AddonsModels', model_path, download_info)
		ply.rgchat_outfitter_skin = outfitter_skin

		if outfitter_bodygroups and outfitter_bodygroups ~= '' then
			ply.rgchat_outfitter_bodygroups = outfitter_bodygroups
		else
			ply.rgchat_outfitter_bodygroups = nil
		end

		ply.rgchat_outfitter_mdl = model_name
	end)
end