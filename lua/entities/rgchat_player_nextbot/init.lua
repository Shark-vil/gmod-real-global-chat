AddCSLuaFile('shared.lua')
AddCSLuaFile('cl_init.lua')
include('shared.lua')

local Path = Path
local IsValid = IsValid
local tostring = tostring
local timer_Remove = timer.Remove
local timer_Create = timer.Create
local math_ApproachAngle = math.ApproachAngle
local coroutine_wait = coroutine.wait
local coroutine_yield = coroutine.yield
local util_IsValidModel = util.IsValidModel
local table_Copy = table.Copy
local ACT_HL2MP_IDLE = ACT_HL2MP_IDLE
local ACT_HL2MP_WALK = ACT_HL2MP_WALK
local type = type

function ENT:RunBehaviour()
	self.loco:SetJumpHeight(70)
	self.loco:SetAvoidAllowed(true)
	self.loco:SetDeathDropHeight(200)
	self.loco:SetGravity(GetConVar('sv_gravity'):GetFloat())
	self.loco:SetDesiredSpeed(200)
	self.loco:SetAcceleration(800)
	self.loco:SetJumpGapsAllowed(true)

	while true and IsValid(self) do
		local actions = table_Copy(self.BotData.Actions)

		for i = #actions, 1, -1 do
			local data = actions[i]
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

			if self:OnStuck() then
				self:SetPos(self.BotData.MovePos)
			end

			if self.BotData.IsTyping then
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
				self.loco:SetDesiredSpeed((self.BotData.MoveSpeed or 400) + 150)
				self.loco:SetAcceleration(800)
				self:StartActivity(RealGloabalChat.Enum.ActIdle[self.BotData.State] and ACT_HL2MP_WALK or self.BotData.State)

				while IsValid(self) and not self:OnStuck() and self:IsOnGround() and path:IsValid() do
					self:LookAt(self.BotData.EyePos + self.BotData.EyeAng:Forward() * 100, 'both')
					self:SetAngles(self.BotData.Ang)

					if path:GetAge() > 0.75 then
						path:Compute(self, self.BotData.MovePos)
					end

					path:Update(self)
					coroutine_yield()
				end
			else
				self:LookAt(self.BotData.EyePos + self.BotData.EyeAng:Forward() * 100, 'both')
				self:SetAngles(self.BotData.Ang)
				self:StartActivity(self.BotData.State or ACT_HL2MP_IDLE)

				if self:OnStuck() then
					self:SetPos(self.BotData.MovePos)
				end
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
	timer_Remove('rgchat.setpose' .. ent_index)
	timer_Remove('rgchat.looktimeput' .. ent_index)

	if time then
		timer_Create('rgchat.looktimeput' .. ent_index, time, 1, function()
			if not IsValid(self) then return end
			self:StopLooking()
			self:PrepareResetPose()
		end)
	end

	if type(ent_pos) == 'Vector' then
		timer_Create('rgchat.lookat' .. ent_index, 0, 0, function()
			if not IsValid(self) then
				timer_Remove('rgchat.lookat' .. ent_index)

				return
			end

			aimangle = (ent_pos - self:GetAttachmentPoint('eyes').Pos):Angle()
			local loca = self:WorldToLocalAngles(aimangle)
			local approachy = math_ApproachAngle(self:GetPoseParameter('head_yaw') or 0, loca[2], 4)
			local approachp = math_ApproachAngle(self:GetPoseParameter('head_pitch') or 0, loca[1], 4)
			local approachaimy = math_ApproachAngle(self:GetPoseParameter('aim_yaw') or 0, loca[2], 4)
			local approachaimp = math_ApproachAngle(self:GetPoseParameter('aim_pitch') or 0, loca[1], 4)

			if posetype == 'both' then
				self:SetPoseParameter('head_yaw', approachy)
				self:SetPoseParameter('head_pitch', approachp)
				self:SetPoseParameter('aim_yaw', approachaimy)
				self:SetPoseParameter('aim_pitch', approachaimp)
			elseif posetype == 'head' then
				self:SetPoseParameter('head_yaw', approachy)
				self:SetPoseParameter('head_pitch', approachp)
			elseif posetype == 'body' then
				self:SetPoseParameter('aim_yaw', approachaimy)
				self:SetPoseParameter('aim_pitch', approachaimp)
			end
		end)
	end
end