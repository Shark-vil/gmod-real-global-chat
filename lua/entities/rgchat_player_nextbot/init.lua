AddCSLuaFile('shared.lua')
AddCSLuaFile('cl_init.lua')
include('shared.lua')
-- local util_JSONToTable = util.JSONToTable
local coroutine_wait = coroutine.wait
-- local Vector = Vector
-- local util_Decompress = util.Decompress
-- local string_Split = string.Split
-- local tonumber = tonumber
local coroutine_yield = coroutine.yield
local util_IsValidModel = util.IsValidModel
-- local game_MountGMA = game.MountGMA
local table_remove = table.remove
local table_Copy = table.Copy

-- local steamworks_DownloadUGC = steamworks.DownloadUGC
function ENT:RunBehaviour()
	self.loco:SetJumpHeight(70)
	self.loco:SetAvoidAllowed(true)
	self.loco:SetDeathDropHeight(200)
	self.loco:SetGravity(GetConVar('sv_gravity'):GetFloat())
	self.loco:SetDesiredSpeed(200)
	self.loco:SetAcceleration(800)
	self.loco:SetJumpGapsAllowed(true)

	-- local is_added_pvs = false
	-- hook.Add('SetupPlayerVisibility', self, function()
	-- 	AddOriginToPVS(self:GetPos())
	-- 	is_added_pvs = true
	-- 	hook.Remove('SetupPlayerVisibility', self)
	-- end)
	-- while not is_added_pvs do coroutine_wait(1) end

	while true and IsValid(self) do
		local actions = table_Copy(self.BotData.Actions)
		for i = #actions, 1, -1 do
			local data = actions[i]
			-- table_remove(actions, i)
			if not data or (self.BotData.LastUpdate and self.BotData.LastUpdate > data.last_update) then continue end
			self.BotData.LastUpdate = data.last_update
			self.BotData.MovePos = RealGloabalChat:PosStringToVector(data.player_pos)
			self.BotData.Ang = RealGloabalChat:PosStringToAngle(data.player_ang)
			self.BotData.Ang.y = 0
			self.BotData.Ang.x = 0
			self.BotData.EyePos = RealGloabalChat:PosStringToVector(data.player_eye_pos)
			self.BotData.EyeAng = RealGloabalChat:PosStringToAngle(data.player_ang)
			self.BotData.State = data.player_activity or ACT_HL2MP_IDLE
			self.BotData.MoveSpeed = RealGloabalChat.Enum.ActRun[self.BotData.State] and data.player_run_speed or data.player_walk_speed
			self.BotData.IsTyping = data.player_is_typing == 1

			-- if data.player_model == 'models/dih/gf/an94_pee.mdl' then
			-- 	print('1', data.player_model_wsid, '2', tostring(data.player_model_wsid))
			-- end

			if not data.player_model then
				self:SetModel('models/player/kleiner.mdl')
				self:SetNWString('pmodel', nil)
				self:SetNWString('pmwsid', nil)
			else
				if data.player_model ~= self:GetNWString('pmodel', nil) then
					self:SetNWString('pmodel', data.player_model)
				end
				local wsid_string = tostring(data.player_model_wsid)
				if wsid_string ~= self:GetNWString('pmwsid', nil) then
					self:SetNWString('pmwsid', wsid_string)
				end
				if self:GetModel() ~= data.player_model and util_IsValidModel(data.player_model) then
					self:SetModel(data.player_model)
				end
			end

			-- if data.player_model ~= self:GetNWString('pmodel', nil) then
			-- 	self:SetNWString('pmodel', data.player_model)
			-- end
			-- self:SetNWInt('pmwsid', data.player_model_wsid)

			-- if data.player_model and (not self.BotData.PlayerModelCache or data.player_model ~= self.BotData.PlayerModelCache) then
			-- 	-- local is_valid_model = util_IsValidModel(data.player_model)

			-- 	-- if is_valid_model then
			-- 	-- 	self:SetModel(data.player_model)
			-- 	-- elseif data.player_model_wsid then
			-- 	-- 	net.Start('RealGlobalChatDownloadModel')
			-- 	-- 	net.WriteInt(data.player_model_wsid, 32)
			-- 	-- 	net.WriteEntity(self)
			-- 	-- 	net.WriteString(data.player_model)
			-- 	-- 	net.Broadcast()
			-- 	-- end
			-- 	if util_IsValidModel(data.player_model) then
			-- 		self:SetModel(data.player_model)
			-- 	end
			-- 	self:SetNWString('pmodel', data.player_model)
			-- 	self:SetNWInt('pmwsid', data.player_model_wsid)	
			-- 	self.BotData.PlayerModelCache = data.player_model
			-- end

			-- if self.BotData.PlayingGesture then
			-- 	if not self:IsPlayingGesture(self.BotData.PlayingGesture) then
			-- 		self:RemoveGesture(self.BotData.PlayingGesture)
			-- 		self.BotData.PlayingGesture = nil
			-- 	else
			-- 		coroutine_wait(1)
			-- 		continue
			-- 	end
			-- elseif RealGloabalChat.Enum.ActGmodTaunt[self.BotData.State] then
			-- 		self.BotData.PlayingGesture = self.BotData.State
			-- 		self:AddGesture(self.BotData.State, false)
			-- 		coroutine_wait(1)
			-- 	continue
			-- end

			if self:OnStuck() then self:SetPos(self.BotData.MovePos) end

			if self.BotData.IsTyping  then
				self:AddGesture(ACT_GMOD_IN_CHAT, false)
				coroutine_wait(1)
				continue
			elseif not self.BotData.IsTyping and self:IsPlayingGesture(ACT_GMOD_IN_CHAT) then
				self:RemoveGesture(ACT_GMOD_IN_CHAT)
			end

			if not self.BotData.MovePos then
				if self.BotData.Ang then
					self:SetAngles(self.BotData.Ang)
				end
				self:StartActivity(ACT_HL2MP_IDLE)
				coroutine_wait(1)
				continue
			end

			local dist = self.BotData.MovePos:DistToSqr(self:GetPos())
			if dist > 1000000 or self:OnStuck() then
				self:SetPos(self.BotData.MovePos)
			elseif dist > 10000 then
				local path = Path('Follow')
				path:SetMinLookAheadDistance(300)
				path:SetGoalTolerance(20)
				path:Compute(self, self.BotData.MovePos)
				-- self:FrameAdvance()
				self.loco:SetDesiredSpeed((self.BotData.MoveSpeed or 400) + 150)
				self.loco:SetAcceleration(800)

				self:StartActivity(RealGloabalChat.Enum.ActIdle[self.BotData.State] and ACT_HL2MP_WALK or self.BotData.State)

				while IsValid(self) and not self:OnStuck() and self:IsOnGround() and path:IsValid() do
					self:LookAt(self.BotData.EyePos + self.BotData.EyeAng:Forward() * 100, 'both')
					self:SetAngles(self.BotData.Ang)
					-- self:SetAngles(RealGloabalChat:MoveTowards(FrameTime() * 120, self:GetAngles(), self.BotData.Ang))
					if path:GetAge() > 0.75 then
						-- self.loco:FaceTowards(self.BotData.EyePos * 100)
						-- self.loco:Approach(self.BotData.EyePos, 1)
						path:Compute(self, self.BotData.MovePos)
					end
					path:Update(self)
					-- path:Draw()
					coroutine_yield()
				end
			else
				self:LookAt(self.BotData.EyePos + self.BotData.EyeAng:Forward() * 100, 'both')
				self:SetAngles(self.BotData.Ang)
				self:StartActivity(self.BotData.State or ACT_HL2MP_IDLE)
				if self:OnStuck() then self:SetPos(self.BotData.MovePos) end
			end
		end

		coroutine_wait(1)
	end
end

function ENT:BodyUpdate()
	self:BodyMoveXY(0, 0)
end

function ENT:GetAttachmentPoint(pointtype)
	if pointtype == 'hand' then
		local lookup = self:LookupAttachment('anim_attachment_RH')

		if lookup == 0 then
			local bone = self:LookupBone('ValveBiped.Bip01_R_Hand')

			if not bone then
				return {
					Pos = self:GetPos() + self:OBBCenter(),
					Ang = self:GetForward():Angle()
				}
			else
				return self:GetBonePosAngs(bone)
			end
		else
			return self:GetAttachment(lookup)
		end
	elseif pointtype == 'eyes' then
		local lookup = self:LookupAttachment('eyes')

		if lookup == 0 then
			return {
				Pos = self:GetPos() + self:OBBCenter() + Vector(0, 0, 5),
				Ang = self:GetForward():Angle() + Angle(-20, 0, 0)
			}
		else
			return self:GetAttachment(lookup)
		end
	end
end

function ENT:LookAt(ent_pos, posetype, time)
	local ent_index = tostring(self:EntIndex())

	timer.Remove('rgchat.setpose' .. ent_index)
	timer.Remove('rgchat.looktimeput' .. ent_index)

	if time then
		timer.Create('rgchat.looktimeput' .. ent_index, time, 1, function()
			if not IsValid(self) then return end
			self:StopLooking()
			self:PrepareResetPose()
		end)
	end

	if type(ent_pos) == 'Vector' then
		timer.Create('rgchat.lookat' .. ent_index, 0, 0, function()
			if not IsValid(self) then
				timer.Remove('rgchat.lookat' .. ent_index)
				return
			end

			aimangle = (ent_pos - self:GetAttachmentPoint('eyes').Pos):Angle()
			local loca = self:WorldToLocalAngles(aimangle)
			local approachy = math.ApproachAngle(self:GetPoseParameter('head_yaw') or 0, loca[2], 4)
			local approachp = math.ApproachAngle(self:GetPoseParameter('head_pitch') or 0, loca[1], 4)
			local approachaimy = math.ApproachAngle(self:GetPoseParameter('aim_yaw') or 0, loca[2], 4)
			local approachaimp = math.ApproachAngle(self:GetPoseParameter('aim_pitch') or 0, loca[1], 4)

			if posetype == 'both' then
				self:SetPoseParameter('head_yaw', approachy)
				self:SetPoseParameter('head_pitch', approachp)
				self:SetPoseParameter('aim_yaw', approachaimy)
				self:SetPoseParameter('aim_pitch', approachaimp)
			end

			if posetype == 'head' then
				self:SetPoseParameter('head_yaw', approachy)
				self:SetPoseParameter('head_pitch', approachp)
			end

			if posetype == 'body' then
				self:SetPoseParameter('aim_yaw', approachaimy)
				self:SetPoseParameter('aim_pitch', approachaimp)
			end
		end)
	end
end