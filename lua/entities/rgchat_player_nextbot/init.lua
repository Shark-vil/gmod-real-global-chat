AddCSLuaFile('shared.lua')
AddCSLuaFile('cl_init.lua')
AddCSLuaFile('states.lua')
AddCSLuaFile('functions.lua')
include('shared.lua')
include('states.lua')
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
local cvar_dev = GetConVar('developer')

-- local ACT_HL2MP_IDLE = ACT_HL2MP_IDLE
-- local ACT_HL2MP_WALK = ACT_HL2MP_WALK
-- local type = type
function ENT:RunBehaviour()
	self.loco:SetJumpHeight(70)
	self.loco:SetAvoidAllowed(true)
	self.loco:SetDeathDropHeight(200)
	self.loco:SetGravity(GetConVar('sv_gravity'):GetFloat())
	self.loco:SetDesiredSpeed(200)
	self.loco:SetAcceleration(800)
	self.loco:SetJumpGapsAllowed(true)

	while true and IsValid(self) do
		local data = self:GetData()

		if not data.Actions then
			coroutine_wait(1)
			continue
		end

		local actions = table_Copy(data.Actions)

		for i = 1, #actions do
			local action = actions[i]
			if not self.BotData.LastUpdate or self.BotData.LastUpdate < action.last_update then
				self.BotData.LastUpdate = action.last_update
				self:SetAction(action)
				self:UpdateVars()
				self:ModelNetworkUpdate()

				local look_at_pos = self.BotData.EyePos + self.BotData.EyeAng:Forward() * 100

				if not self.BotData.LastUpdateLookAt or self.BotData.LastUpdateLookAt < CurTime() then
					self:LookAt(look_at_pos)
					self.BotData.LastUpdateLookAt = CurTime() + .5
				end

				self.loco:FaceTowards(look_at_pos)

				if RealGloabalChat.Enum.ActJump[self.BotData.State] then
					self.JumpReset = CurTime() + 1
				end

				local is_noclip_move_type = self:IsNoclipMoveType()
				if is_noclip_move_type and not self:IsNoclip() then
					self:StartNoclip()
				elseif not is_noclip_move_type and self:IsNoclip() then
					self:StopNoclip()
				end

				if data.Gesture then
					self:SetState('gesture')
				elseif data.IsTyping then
					self:SetState('typing')
				elseif RealGloabalChat.Enum.ActIdle[self.BotData.State] then
					self:SetState('idle')
				else
					self:SetState('move_to_pos')
				end

				if cvar_dev:GetBool() then
					local ply = player.GetAll()[1]
					if IsValid(ply) then
						ply:ChatPrint('GRChatNextBot - ' .. self:GetActiveStateName())
					end
				end

				self:Update()
				self:UpdateCurrentState()
				self:UpdateMovement()
			end
		end

		coroutine_wait(1)
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