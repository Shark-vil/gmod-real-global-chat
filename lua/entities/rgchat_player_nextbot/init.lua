AddCSLuaFile('shared.lua')
AddCSLuaFile('cl_init.lua')
AddCSLuaFile('states.lua')
AddCSLuaFile('playermeta.lua')
AddCSLuaFile('functions.lua')
include('shared.lua')
include('states.lua')
include('playermeta.lua')
include('functions.lua')
-- local Path = Path
local IsValid = IsValid
local CurTime = CurTime
-- local tostring = tostring
-- local timer_Remove = timer.Remove
-- local timer_Create = timer.Create
-- local math_ApproachAngle = math.ApproachAngle
local coroutine_wait = coroutine.wait
-- local coroutine_yield = coroutine.yield
-- local util_IsValidModel = util.IsValidModel
local table_Copy = table.Copy
-- local cvar_dev = GetConVar('developer')

-- local ACT_HL2MP_IDLE = ACT_HL2MP_IDLE
-- local ACT_HL2MP_WALK = ACT_HL2MP_WALK
-- local type = type
function ENT:RunBehaviour()
	self.loco:SetJumpHeight(50)
	self.loco:SetStepHeight(18)
	self.loco:SetAvoidAllowed(true)
	self.loco:SetDeathDropHeight(200)
	self.loco:SetGravity(self:GetGravity())
	-- self.loco:SetDesiredSpeed(200)
	-- self.loco:SetAcceleration(600)
	-- self.loco:SetAcceleration(2000)
	self.loco:SetJumpGapsAllowed(true)

	self._navmesh_is_loaded = navmesh.IsLoaded()
	if self._navmesh_is_loaded then
		self._Path = Path('Follow')
		self._Path:SetMinLookAheadDistance(300)
		self._Path:SetGoalTolerance(20)
	end

	self:StartTimer('RGChatNextBotRotate', .1, 0, function()
		if not self.BotData.Ang then return end
		local rot = RealGloabalChat:MoveTowards(self:GetAngles(), self.BotData.Ang, 20)
		if rot ~= self.BotData.Ang then self:SetAngles(rot) end
	end)

	while true and IsValid(self) do
		local data = self:GetData()

		if not data.Actions then
			coroutine_wait(1)
			continue
		end

		local actions = table_Copy(data.Actions)

		for i = 1, #actions do
			local action = actions[i]

			self:SetAction(action)
			self:UpdateVars()
			self:ModelNetworkUpdate()

			if self:GetActiveWeaponClassName() ~= self.BotData.WeaponClass then
				self:SelectWeapon(self.BotData.WeaponClass)
			end

			if data.EyePos and data.EyeAng then
				local look_at_pos = data.EyePos + data.EyeAng:Forward() * 100

				if not data.LastUpdateLookAt or data.LastUpdateLookAt < CurTime() then
					self:LookAt(look_at_pos)
					data.LastUpdateLookAt = CurTime() + .5
				end

				-- self.loco:FaceTowards(look_at_pos)
			end

			if RealGloabalChat.Values.Enum .ActJump[data.State] then
				data.JumpReset = CurTime() + .5
			end

			data.CanSit = RealGloabalChat.Values.Enum .ActSit[data.State]

			local is_noclip_move_type = self:IsNoclipMoveType()
			if is_noclip_move_type and not self:IsNoclip() then
				self:StartNoclip()
			elseif not is_noclip_move_type and self:IsNoclip() and (not self._navmesh_is_loaded or self:IsOnGround()) then
				self:StopNoclip()
			end

			if data.CanSit then
				self:SetState('sit')
			elseif data.Gesture then
				self:SetState('gesture')
			elseif data.IsTyping then
				self:SetState('typing')
			elseif RealGloabalChat.Values.Enum .ActIdle[data.State] then
				self:SetState('idle')
			else
				self:SetState('move_to_pos')
			end

			self:Update()
			self:UpdateCurrentState()
			self:UpdateMovement()
		end

		coroutine_wait(1)
	end
end

function ENT:Use(activator)
	if not IsValid(activator) or not activator:IsPlayer() then return end
	if self.EntHasUseDelay and self.EntHasUseDelay > CurTime() then
		self.EntHasUseDelay = CurTime() + .2
		return
	end

	self.EntHasUseDelay = CurTime() + .2

	local target_id = activator:GetNWString('RGC_SYNC_TARGET', '')

	if target_id == self.BotData.SteamId64 then
		target_id = ''
	else
		target_id = self.BotData.SteamId64
	end

	RealGloabalChat:WatchToPlayer(activator, target_id)
end

function ENT:RgChatDisconnected()
	for _, ply in ipairs(player.GetAll()) do
		local target_entity_sync = ply:GetNWString('RGC_SYNC_TARGET', '')
		if target_entity_sync ~= '' and target_entity_sync == self.BotData.SteamId64 then
			RealGloabalChat:WatchToPlayer(ply, '')
		end
	end
end

function ENT:OnTakeDamage(dmginfo)
	local attacker = dmginfo:GetAttacker()
	if IsValid(attacker) and attacker:IsPlayer() then
		return
	end
	return 0
end

function ENT:BodyUpdate()
	self:BodyMoveXY(0, 0)
end

function ENT:OnKilled(dmginfo)
	if IsValid(self.CurrentWeapon) then
		self.CurrentWeapon:Remove()
	end

	SafeRemoveEntity(self)
end

-- function ENT:OnRemove()
-- 	self:RgChatDisconnected()
-- end