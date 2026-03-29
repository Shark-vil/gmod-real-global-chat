AddCSLuaFile('shared.lua')
AddCSLuaFile('cl_init.lua')
AddCSLuaFile('functions.lua')
include('shared.lua')
include('functions.lua')
local IsValid = IsValid
local CurTime = CurTime
local coroutine_wait = coroutine.wait
local coroutine_yield = coroutine.yield
local table_Copy = table.Copy
local table_remove = table.remove

function ENT:RunBehaviour()
	self.loco:SetJumpHeight(50)
	self.loco:SetStepHeight(18)
	self.loco:SetAvoidAllowed(true)
	self.loco:SetDeathDropHeight(200)
	self.loco:SetGravity(self:GetGravity())
	self.loco:SetJumpGapsAllowed(true)
	self._navmesh_is_loaded = navmesh.IsLoaded()
	if self._navmesh_is_loaded then
		self._Path = Path('Follow')
		self._Path:SetMinLookAheadDistance(300)
		self._Path:SetGoalTolerance(25)
	end

	while true and IsValid(self) do
		local data = self:GetData()
		if not data.Actions or #data.Actions == 0 then
			coroutine_wait(1)
			continue
		end

		self.ActiveActions = table_Copy(data.Actions)

		--[[
		local is_cancel
		repeat
			local action = self:GetNextAction()
			if not action then break end
			self:UpdateAction(action)
			self:UpdateMovement()
			self:RotateToAng()
			is_cancel = #self.ActiveActions == 0
			if not is_cancel then coroutine_yield() end
		until is_cancel
		--]]

		local action = self:GetNextAction()
		if action then
			self:UpdateAction(action)
			self:UpdateMovement()
		end
		self:RotateToAng()
		coroutine_yield()
	end
end

function ENT:RotateToAng()
	local data = self:GetData()
	if not data or not data.Ang then return end
	local rot = RealGloabalChat:MoveTowards(self:GetAngles(), data.Ang, FrameTime() * 1000)
	if rot ~= data.Ang then self:SetAngles(rot) end
end

function ENT:GetMoveSpeed()
	local data = self:GetData()
	return data and data.MoveSpeed or 400
end

function ENT:GetNextAction()
	if not self.ActiveActions or #self.ActiveActions == 0 then return end
	return table_remove(self.ActiveActions, 1)
end

function ENT:UpdateAction(action)
	local data = self:GetData()
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
	end

	if RealGloabalChat.Enum.ActJump[data.State] then
		data.JumpReset = CurTime() + .5
	end

	data.CanSit = RealGloabalChat.Enum.ActSit[data.State]

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
	elseif RealGloabalChat.Enum.ActIdle[data.State] then
		self:SetState('idle')
	else
		self:SetState('move_to_pos')
	end

	local activity_id = data.State
	local activity = RealGloabalChat.Enum.ActIdle[activity_id] and ACT_HL2MP_WALK or activity_id
	self:CustomStartActivity(activity)

	self:Update()
	self:UpdateCurrentState()
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
		if target_entity_sync ~= '' and target_entity_sync == self.BotData.SteamId64 then RealGloabalChat:WatchToPlayer(ply, '') end
	end
end

function ENT:OnTakeDamage(dmginfo)
	local attacker = dmginfo:GetAttacker()
	if IsValid(attacker) and attacker:IsPlayer() then return end
	return 0
end

function ENT:BodyUpdate()
	self:BodyMoveXY(0, 0)
end

function ENT:OnKilled(dmginfo)
	if IsValid(self.CurrentWeapon) then self.CurrentWeapon:Remove() end
	SafeRemoveEntity(self)
end
-- function ENT:OnRemove()
-- 	self:RgChatDisconnected()
-- end