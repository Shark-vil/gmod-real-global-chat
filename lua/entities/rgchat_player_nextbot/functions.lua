local util_IsValidModel = util.IsValidModel
local coroutine_yield = coroutine.yield
-- local timer_Exists = timer.Exists
-- local type = type
-- local Angle = Angle
-- local Vector = Vector
local tostring = tostring
local timer_Remove = timer.Remove
local timer_Create = timer.Create
local math_ApproachAngle = math.ApproachAngle
local Path = Path
local CurTime = CurTime
local IsValid = IsValid
local angle_m20_0_0 = Angle(-20, 0, 0)
local vector_0_0_5 = Vector(0, 0, 5)

function ENT:ModelNetworkUpdate()
	local data = self:GetData()

	if not data.Model then
		self:SetModel('models/player/kleiner.mdl')
		self:SetNWString('pmodel', nil)
		self:SetNWString('pmwsid', nil)
	else
		if data.Model ~= self:GetNWString('pmodel', nil) then
			self:SetNWString('pmodel', data.Model)
		end

		local wsid_string = tostring(data.ModelWsid)

		if wsid_string ~= self:GetNWString('pmwsid', nil) then
			self:SetNWString('pmwsid', wsid_string)
		end

		if self:GetModel() ~= data.Model and util_IsValidModel(data.Model) then
			self:SetModel(data.Model)
		end
	end
end

function ENT:UpdateCurrentState()
	local state_func = self:GetActiveState()

	if state_func and state_func.update then
		state_func.update(self)
	end
end

function ENT:UpdateMovement()
	if self:IsNoclip() then return end
	local move_pos = self:GetMovePos()
	if not move_pos then return end
	local activity_id = self.BotData.State
	local activity = RealGloabalChat.Enum.ActIdle[activity_id] and ACT_HL2MP_WALK or activity_id
	local speed = self.BotData.MoveSpeed or 400
	local timeout = CurTime() + 10
	local path = Path('Follow')
	path:SetMinLookAheadDistance(300)
	path:SetGoalTolerance(20)
	path:MoveCursorToClosestPosition(move_pos, 2)
	path:Compute(self, move_pos)
	self.loco:SetDesiredSpeed(speed)
	self.loco:SetAcceleration(800)
	self:CustomStartActivity(activity)

	if not path:IsValid() then
		self:SetPos(move_pos)
	else
		while IsValid(self) and not self:IsNoclip() and not self:OnStuck() and self:IsOnGround() and path:IsValid() do
			if timeout < CurTime() then
				self:SetPos(move_pos)
			end

			if path:GetAge() > 0.75 then
				path:Compute(self, move_pos)
			end

			path:Update(self)
			-- path:Draw()
			self:Update()
			self:UpdateCurrentState()
			coroutine_yield()
		end
		if move_pos:DistToSqr(self:GetPos()) > 2500 then
			self:SetPos(move_pos)
		end
	end
end

function ENT:IsNoclipMoveType()
	local mt = self.BotData.MoveType
	if mt and (mt == 4 or mt == 5 or mt == 8 or mt == 10) then
		return true
	end
	return false
end

function ENT:StartNoclip()
	if self.BotData.IsNoclip then return end
	local timer_name = 'rgchatnextbotnoclip.' .. tostring(self:EntIndex())
	if timer.Exists(timer_name) then return end
	self.BotData.IsNoclip = true
	self:SetMovePos(nil)
	self:AddGesture(ACT_GMOD_NOCLIP_LAYER, false)
	local vector_0_0_0 = Vector(0, 0, 0)
	timer.Create(timer_name, 0, 0, function()
		if not IsValid(self) then
			timer.Remove(timer_name)
			return
		end
		if not self.BotData.MovePos then return end
		self:SetMovePos(nil)
		local speed = self.BotData.MoveSpeed and (self.BotData.MoveSpeed / 10) or 20
		local new_pos = RealGloabalChat:MoveTowards(self:GetPos(), self.BotData.MovePos, speed)
		self:SetPos(new_pos)
		self.loco:SetGravity(0)
		self.loco:SetVelocity(vector_0_0_0)
	end)
end

function ENT:StopNoclip()
	if not self.BotData.IsNoclip then return end
	local timer_name = 'rgchatnextbotnoclip.' .. tostring(self:EntIndex())
	timer.Remove(timer_name)
	self:RemoveGesture(ACT_GMOD_NOCLIP_LAYER)
	self.loco:SetGravity(GetConVar('sv_gravity'):GetFloat())
	self.BotData.IsNoclip = false
end

function ENT:IsNoclip()
	return self.BotData.IsNoclip or false
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
				Pos = self:GetPos() + self:OBBCenter() + vector_0_0_5,
				Ang = self:GetForward():Angle() + angle_m20_0_0
			}
		else
			return self:GetAttachment(lookup)
		end
	end
end

function ENT:StopLooking()
	local ent_index = tostring(self:EntIndex())
	timer_Remove('rgchat.lookat' .. ent_index)
	self:ResetPose()
end

function ENT:ResetPose()
	self.BotData.IsResettingPose = true
	local ent_index = tostring(self:EntIndex())
	timer_Create('rgchat.resetpose' .. ent_index, 0, 0, function()
		if not IsValid(self) then
			timer_Remove('rgchat.resetpose' .. ent_index)

			return
		end

		local headposeyaw = self:GetPoseParameter('head_yaw')
		local headposepitch = self:GetPoseParameter('head_pitch')
		local aimposeyaw = self:GetPoseParameter('aim_yaw')
		local aimposepitch = self:GetPoseParameter('aim_pitch')
		local approachy = math_ApproachAngle(self:GetPoseParameter('head_yaw') or 0, 0, 3)
		local approachp = math_ApproachAngle(self:GetPoseParameter('head_pitch') or 0, 0, 3)
		local aimapproachy = math_ApproachAngle(self:GetPoseParameter('aim_yaw') or 0, 0, 3)
		local aimapproachp = math_ApproachAngle(self:GetPoseParameter('aim_pitch') or 0, 0, 3)
		self:SetPoseParameter('head_yaw', approachy)
		self:SetPoseParameter('head_pitch', approachp)
		self:SetPoseParameter('aim_yaw', aimapproachy)
		self:SetPoseParameter('aim_pitch', aimapproachp)

		if headposeyaw == 0 and headposepitch == 0 and aimposeyaw == 0 and aimposepitch == 0 then
			timer.Remove('rgchat.resetpose' .. ent_index)
			self.BotData.IsResettingPose = false
		end
	end)
end

function ENT:LookAt(look_pos)
	local ent_index = tostring(self:EntIndex())
	timer_Create('rgchat.lookat' .. ent_index, 0, 0, function()
		if not IsValid(self) then
			timer_Remove('rgchat.lookat' .. ent_index)

			return
		end

		local aimangle = (look_pos - self:GetAttachmentPoint('eyes').Pos):Angle()
		local lookAng = self:WorldToLocalAngles(aimangle)
		local poseP = (self:GetPoseParameter('head_pitch') + self:GetPoseParameter('aim_pitch')) / 2
		local poseY = (self:GetPoseParameter('head_yaw') + self:GetPoseParameter('aim_yaw')) / 2
		local approachp = Lerp(4 * FrameTime(), poseP, lookAng.p)
		local approachy = Lerp(4 * FrameTime(), poseY, lookAng.y)

		self:SetPoseParameter('head_yaw', approachy)
		self:SetPoseParameter('head_pitch', approachp)
		self:SetPoseParameter('aim_yaw', approachy)
		self:SetPoseParameter('aim_pitch', approachp)
	end)
end