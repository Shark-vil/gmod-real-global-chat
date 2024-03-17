local _IsValid = IsValid
local _ipairs = ipairs
local _pairs = pairs

function RealGloabalChat.Api:GetPlayerAction(ply)
	local ply_alive = ply:Alive()
	local ply_attacker = _IsValid(ply.RGChatAttacker) and ply.RGChatAttacker:GetName() or nil
	local ply_inflictor = _IsValid(ply.RGChatInflictor) and ply.RGChatInflictor:GetName() or nil
	local ply_sequence = ply_alive and ply:GetSequence() or nil
	local ply_velocity = ply_alive and ply:GetVelocity() or nil
	local ply_pos = ply_alive and ply:GetPos() or nil
	local ply_ang = ply_alive and ply:GetAngles() or nil
	local ply_eye_pos = ply_alive and ply:EyePos() or nil
	local ply_eye_ang = ply_alive and ply:EyeAngles() or nil
	local ply_weapon = ply_alive and ply:GetActiveWeapon() or nil
	local ply_color = ply_alive and ply:GetColor() or nil
	local ply_move_type = ply_alive and ply:GetMoveType() or nil
	local ply_activity, ply_gesture
	local ply_skin = ply.rgchat_outfitter_skin or ply:GetSkin()
	local ply_bodygroups = ply.rgchat_outfitter_bodygroups or ''

	if ply_bodygroups == '' then
		for _, v in _ipairs(ply:GetBodyGroups()) do
			local bodygroup = ply:GetBodygroup(v.id)
			ply_bodygroups = ply_bodygroups .. bodygroup
		end
	end

	if ply_pos and ply:InVehicle() then
		ply_pos = ply:GetVehicle():GetPos()
	end

	if _IsValid(ply) and ply_alive then
		if ply.RgChatActiveGesture then
			ply_gesture = ply.RgChatActiveGesture
		else
			for gesture_id, _ in _pairs(RealGloabalChat.Enum.ActGmodTaunt) do
				if ply:IsPlayingGesture(gesture_id) then
					ply_gesture = gesture_id
					break
				end
			end
		end

		ply_activity = ply:GetSequenceActivity(ply_sequence)
	end

	local action_data = {
		pos = ply_pos and (ply_pos.x .. ',' .. ply_pos.y .. ',' .. ply_pos.z) or nil,
		ang = ply_ang and (ply_ang.x .. ',' .. ply_ang.y .. ',' .. ply_ang.z) or nil,
		eye_pos = ply_eye_pos and (ply_eye_pos.x .. ',' .. ply_eye_pos.y .. ',' .. ply_eye_pos.z) or nil,
		eye_ang = ply_eye_ang and (ply_eye_ang.x .. ',' .. ply_eye_ang.y .. ',' .. ply_eye_ang.z) or nil,
		is_typing = ply:IsTyping() and 1 or 0,
		walk_speed = ply:GetWalkSpeed(),
		run_speed = ply:GetRunSpeed(),
		activity = ply_activity and ply_activity or nil,
		sequence = ply_sequence and ply_sequence or nil,
		gesture = ply_gesture and ply_gesture or nil,
		weapon_class = _IsValid(ply_weapon) and ply_weapon:GetClass() or nil,
		move_type = ply_move_type and ply_move_type or nil,
		alive = ply_alive and 1 or 0,
		attacker = ply_attacker and ply_attacker or nil,
		inflictor = ply_inflictor and ply_inflictor or nil,
		velocity = ply_velocity and (ply_velocity.x .. ',' .. ply_velocity.y .. ',' .. ply_velocity.z) or nil,
		color = ply_color and (ply_color.r .. ',' .. ply_color.g .. ',' .. ply_color.b .. ',' .. ply_color.a) or nil,
		skin = ply_skin,
		bodygroups = ply_bodygroups ~= '' and ply_bodygroups or nil,
	}

	if ply_attacker then
		ply.RGChatAttacker = nil
	end

	if ply_inflictor then
		ply.RGChatInflictor = nil
	end

	return action_data
end