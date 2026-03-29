local util_IsValidModel = util.IsValidModel
local coroutine_yield = coroutine.yield
local timer_Exists = timer.Exists
-- local type = type
-- local Angle = Angle
-- local Vector = Vector
local tostring = tostring
local timer_Remove = timer.Remove
local timer_Create = timer.Create
local ismatrix = ismatrix
local math_ApproachAngle = math.ApproachAngle
-- local Path = Path
local CurTime = CurTime
local IsValid = IsValid
local angle_m20_0_0 = Angle(-20, 0, 0)
local vector_0_0_5 = Vector(0, 0, 5)
local cvar_gravity = GetConVar('sv_gravity')
local vector_0_0_0 = Vector(0, 0, 0)
-- local vector_0_0_1 = Vector(0, 0, 1)
-- local util_TraceLine = util.TraceLine

function ENT:ModelNetworkUpdate()
	local data = self:GetData()

	if not data.Model then
		data.Model = 'models/player/kleiner.mdl'
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
	end

	local is_valid_model = util_IsValidModel(data.Model)

	if self:GetModel() ~= data.Model and is_valid_model then
		self:SetModel(data.Model)
	end

	if not data.OldModel or data.OldModel ~= data.Model then
		data.OldModel = data.Model
		data.OldBodygroups = nil
		data.OldSkin = nil
	end

	if is_valid_model then
		if data.Bodygroups and (not data.OldBodygroups or data.OldBodygroups ~= data.Bodygroups) then
			self:SetBodyGroups(data.Bodygroups)
			data.OldBodygroups = data.Bodygroups
		end

		if data.Skin and (not data.OldSkin or data.OldSkin ~= data.Skin) then
			self:SetSkin(data.Skin)
			data.OldSkin = data.Skin
		end
	end
end

function ENT:GetWeaponENT()
	if IsValid(self.WeaponENT) then return self.WeaponENT end
	local lookup = self:LookupAttachment('anim_attachment_RH')
	local attachment = self:GetAttachmentPoint('hand')
	self.WeaponENT = ents.Create('base_anim')
	self.WeaponENT:SetOwner(self)
	self.WeaponENT:AddEffects(EF_BONEMERGE)
	self.WeaponENT:SetMoveType(MOVETYPE_NONE)
	self.WeaponENT:SetPos(attachment.Pos)
	self.WeaponENT:SetAngles(attachment.Ang)
	self.WeaponENT:SetParent(self, lookup)
	-- self.WeaponENT:SetModel('models/hunter/plates/plate.mdl')
	-- self.WeaponENT:SetMaterial('null')
	self.WeaponENT:SetNoDraw(true)
	self:DeleteOnRemove(self.WeaponENT)

	return self.WeaponENT
end

function ENT:UpdateCurrentState()
	local state_func = self:GetActiveState()

	if state_func and state_func.update then
		state_func.update(self)
	end
end

function ENT:UpdateMovement()
	if self:IsNoclip() then return end
	local data, move_pos, speed, state_name
	local devmode = RealGloabalChat:IsDeveloperMode()

	local function load_current_data()
		local new_move_pos = self:GetMovePos()
		if new_move_pos then move_pos = new_move_pos end
		data = self:GetData()
		speed = self:GetMoveSpeed()
		state_name = self:GetActiveStateName()
	end

	local function run_final_path_pos()
		if not move_pos or self:GetPos():DistToSqr(move_pos) <= 225 then
			return
		end
		self:StartTimer('RgChatNextFinalPathMove', 0, 0, function(stop_timer)
			-- local new_pos
			-- local is_near = self:GetPos():DistToSqr(move_pos) <= 225
			-- if move_pos and not is_near then
			-- 	new_pos = RealGloabalChat:MoveTowards(self:GetPos(), move_pos, FrameTime() * 100)
			-- 	self:SetPos(new_pos)
			-- end
			-- if not move_pos or not new_pos or is_near or self:GetPos() == move_pos then
			-- 	self:StopTimer('RgChatNextFinalPathMove')
			-- end

			local new_pos
			if move_pos then
				new_pos = RealGloabalChat:MoveTowards(self:GetPos(), move_pos, FrameTime() * 100)
				self:SetPos(new_pos)
			end
			if not move_pos or not new_pos or self:GetPos() == move_pos then
				self:StopTimer('RgChatNextFinalPathMove')
			end
		end)
	end

	load_current_data()

	if not move_pos or self:GetPos():DistToSqr(move_pos) <= 625 then
		-- run_final_path_pos()
		return
	end

	self:StopTimer('RgChatNextFinalPathMove')

	if data.CanSit then
		self.loco:SetGravity(0)

		self:StartTimer('RgChatNextBotMove', 0, 0, function(stop_timer)
			if not data.CanSit or state_name ~= self:GetActiveStateName() or self:IsNoclip() then
				stop_timer()
			else
				local pos = RealGloabalChat:MoveTowards(self:GetPos(), move_pos, FrameTime() * 1000)

				if pos then
					self:SetPos(pos)
					self.loco:SetVelocity(vector_0_0_0)
				end
			end
		end)
	else
		local is_valid_path = self._navmesh_is_loaded
		local path = self._Path

		if is_valid_path then
			path:MoveCursorToClosestPosition(move_pos, 2)
			path:Compute(self, move_pos)
			is_valid_path = path:IsValid()
		end

		self.loco:SetGravity(self:GetGravity())

		if not is_valid_path then
			if not data.LastTargetPos or data.LastTargetPos ~= move_pos then
				data.LastTargetPos = move_pos

				local acceleration = self:GetAcceleration(move_pos)
				if self:GetDefaultAcceleration() == acceleration then
					acceleration = 0
				else
					acceleration = acceleration / 2
				end

				self:StartTimer('RgChatNextBotMove', 0, 0, function(stop_timer)
					if state_name ~= self:GetActiveStateName() or move_pos:DistToSqr(self:GetPos()) <= 2500 or self:IsNoclip() then
						stop_timer()
					else
						local pos = RealGloabalChat:MoveTowards(self:GetPos(), move_pos, FrameTime() * (speed + acceleration))

						if pos then
							self:SetPos(pos)
							self.loco:SetVelocity(data.Velocity or vector_0_0_0)
						end
					end
				end)
			end
		else
			self:StopTimer('RgChatNextBotMove')

			if not self:IsOnGround() or not self.loco:IsOnGround() then
				self:DropToFloor()
			end

			while IsValid(self) and path:IsValid() and not self:IsNoclip() and not self:OnStuck() and self:IsOnGround() and self.loco:IsOnGround() do
				local actions_size = #self.ActiveActions
				if actions_size == 0 then break end
				if  path:GetAge() > 5 then
					if move_pos then self:SetPos(move_pos) end
					break
				elseif self:GetPos():DistToSqr(move_pos) <= 2500 then
					local action = self:GetNextAction()
					if not action then break end
					self:UpdateAction(action)
					load_current_data()
					path:ResetAge()
					path:Compute(self, move_pos)
				end
				self.loco:SetDesiredSpeed(speed)
				local accel_speed = self:GetAcceleration(move_pos)
				self.loco:SetAcceleration(accel_speed)
				self.loco:SetDeceleration(accel_speed)
				path:Update(self)
				self:RotateToAng()
				if devmode then path:Draw() end
				coroutine_yield()
			end

			run_final_path_pos()
		end
	end
end

function ENT:GetAcceleration(move_pos)
	if move_pos then
		local dist = self:GetPos():DistToSqr(move_pos)
		if dist >= 250000 then
			return 500
		elseif dist >= 40000 then
			return 400
		end
	end
	return self:GetDefaultAcceleration()
end

function ENT:GetDefaultAcceleration()
	return 300
end

function ENT:IsNoclipMoveType()
	local mt = self.BotData.MoveType
	if mt and (mt == 4 or mt == 5 or mt == 8 or mt == 10) and not RealGloabalChat.Enum.ActSit[self.BotData.State] then return true end

	return false
end

function ENT:StartTimer(timer_name, delay, repetitions, func)
	timer_name = timer_name .. '.' .. tostring(self:EntIndex())

	local function stop_timer()
		timer_Remove(timer_name)
	end

	timer_Create(timer_name, delay, repetitions, function()
		if not IsValid(self) or self:Health() <= 0 then
			timer_Remove(timer_name)

			return
		end

		func(stop_timer)
	end)
end

function ENT:ExistsTimer(timer_name)
	timer_name = timer_name .. '.' .. tostring(self:EntIndex())
	return timer_Exists(timer_name)
end

function ENT:StopTimer(timer_name)
	timer_name = timer_name .. '.' .. tostring(self:EntIndex())
	if not timer_Exists(timer_name) then return end
	timer_Remove(timer_name)
end

function ENT:StartNoclip()
	if self.BotData.IsNoclip then return end
	self.BotData.IsNoclip = true
	self:SetMovePos(nil)
	self:AddGesture(ACT_GMOD_NOCLIP_LAYER, false)
	self:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)

	self:StartTimer('RgChatNextBotNoclip', 0, 0, function(stop_timer)
		if not self.BotData.IsNoclip then
			stop_timer()

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
	self:StopTimer('RgChatNextBotNoclip')
	self:SetCollisionGroup(COLLISION_GROUP_WORLD)
	self:RemoveGesture(ACT_GMOD_NOCLIP_LAYER)
	self.loco:SetGravity(self:GetGravity())
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

function ENT:GetBonePosAngs(index)
	local pos, angle = self:GetBonePosition(index)

	if pos and pos == self:GetPos() then
		local matrix = self:GetBoneMatrix(index)

		if ismatrix(matrix) and matrix ~= nil then
			pos = matrix:GetTranslation()
		else
			return {
				Pos = self:GetPos() + self:OBBCenter(),
				Ang = self:GetForward():Angle()
			}
		end
	elseif not pos then
		pos = self:GetPos() + self:OBBCenter()
	end

	return {
		Pos = pos,
		Ang = angle
	}
end

function ENT:StopLooking()
	self:StopTimer('RGChatNextBotLookAt')
	self:ResetPose()
end

function ENT:ResetPose()
	self.BotData.IsResettingPose = true

	self:StartTimer('RgChatResetBodyPosRotate', 0, 0, function(stop_timer)
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
			stop_timer()
			self.BotData.IsResettingPose = false
		end
	end)
end

function ENT:LookAt(look_pos)
	self:StartTimer('RGChatNextBotLookAt', 0, 0, function(stop_timer)
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

function ENT:GetGravity()
	return cvar_gravity:GetFloat()
end

function ENT:StripWeapon()
	self:DeEquipWeapon()
end

function ENT:SetActiveWeapon(weapon)
	if weapon ~= NULL and weapon ~= nil then
		self:SelectWeapon(weapon.ClassName)
	else
		self:StripWeapon()
	end
end

function ENT:SelectWeapon(className)
	self:DeEquipWeapon()
	if self._WeaponClass == className then return end
	if not RealGloabalChat.AllRegistredWeapons[className] then return end
	local weapon_data = RealGloabalChat.AllRegistredWeapons[className]

	if weapon_data.WorldModel and weapon_data.WorldModel ~= '' then
		local fake_weapon = self:GetWeaponENT()
		fake_weapon:SetModel(weapon_data.WorldModel)
		fake_weapon:SetLocalPos(Vector(0, 0, 0))
		fake_weapon:SetLocalAngles(Angle(0, 0, 0))

		if istable(weapon_data.WorldModelOffset) then
			if isvector(weapon_data.WorldModelOffset.Pos) then
				fake_weapon:SetLocalPos(weapon_data.WorldModelOffset.Pos)
			end

			if isangle(weapon_data.WorldModelOffset.Ang) then
				fake_weapon:SetLocalAngles(weapon_data.WorldModelOffset.Ang)
			end
		end

		if className == 'weapon_physgun' then
			fake_weapon:SetSkin(1)

			for k, v in ipairs(fake_weapon:GetMaterials()) do
				if string.EndsWith(v, 'w_physics_sheet') then
					fake_weapon:SetSubMaterial(k, 'models/weapons/zetaphysgun/w_physics_sheet2')
				end
			end
		else
			fake_weapon:SetSkin(0)

			for k, v in ipairs(fake_weapon:GetMaterials()) do
				fake_weapon:SetSubMaterial(k, 'nil')
			end
		end

		fake_weapon:SetNoDraw(false)
	end

	self._WeaponClass = className
end

function ENT:EquipWeapon(weapon_num)
	self:DeEquipWeapon()
	if not weapon_num then return end
	local index = 0

	for weaponClass, _ in pairs(RealGloabalChat.AllRegistredWeapons) do
		index = index + 1

		if index == weapon_num then
			self:SelectWeapon(weaponClass)
			break
		end
	end
end

function ENT:DeEquipWeapon()
	if self._WeaponClass then
		self._WeaponClass = nil
	end

	if not IsValid(self.WeaponENT) then return end
	self.WeaponENT:SetNoDraw(true)
end

function ENT:GetActiveWeaponClassName()
	return self._WeaponClass
end