local string_lower = string.lower
-- local IsValid = IsValid
local CurTime = CurTime
-- local FrameTime = FrameTime

ENT.Base = 'base_nextbot'
ENT.Spawnable = false
ENT.BotData = {}
ENT.States = {}
ENT.EntityWatchers = {}
ENT.OpinionOnEnts = {}
ENT.VJ_AddEntityToSNPCAttackList = true
ENT.dt = ''

function ENT:Initialize()
	self:SetModel('models/player/kleiner.mdl')
	self:AddFlags(FL_OBJECT + FL_NPC + FL_FAKECLIENT)
	self:PhysicsInitShadow()
	self:SetCollisionGroup(COLLISION_GROUP_WORLD)
	self:PhysWake()
	self:SetHealth(100)
	if SERVER then
		self:SetLagCompensated(true)
		self:SetSolidMask(MASK_PLAYERSOLID)
	end
end

function ENT:Update()
	local data = self:GetData()
	if self:OnStuck() then self:SetPos(data.MovePos) end
	if data.Color then self:SetColor(data.Color) end
	if RealGloabalChat.Enum.ActJump[data.State] and data.JumpReset and data.JumpReset < CurTime() then
		self:CustomStartActivity(RealGloabalChat.Enum.ActJumpToRun[data.State])
	end
end

function ENT:SetData(data)
	self:UpdateData(data)
	self:SetNWString('UserName', '[RGChat] ' .. data.username)
	self:SetName(self.BotData.NickName)
end

function ENT:GetData()
	return self.BotData
end

function ENT:UpdateData(data)
	self.BotData.NickName = data.username
	self.BotData.SteamId64 = data.steamid64
	self.BotData.SteamId64Number = tonumber(data.steamid64)
	self.BotData.ModelWsid = data.model_wsid
	self.BotData.Model = data.model
	self.BotData.Actions = data.actions
end

function ENT:UpdateVars()
	local data = self:GetActiveAction()
	if not data then return end
	self.BotData.LastUpdate = data.last_update
	self.BotData.MovePos = RealGloabalChat:PosStringToVector(data.pos)
	self.BotData.Ang = RealGloabalChat:PosStringToAngle(data.ang)
	self.BotData.Ang.z = 0
	self.BotData.Ang.x = 0
	self.BotData.EyePos = RealGloabalChat:PosStringToVector(data.eye_pos)
	self.BotData.EyeAng = RealGloabalChat:PosStringToAngle(data.eye_ang)
	self.BotData.State = data.activity or ACT_HL2MP_IDLE
	self.BotData.MoveSpeed = RealGloabalChat.Enum.ActRun[self.BotData.State] and data.run_speed or data.walk_speed
	self.BotData.IsTyping = data.is_typing == 1
	self.BotData.Sequence = data.sequence
	self.BotData.Gesture = data.gesture
	-- self.BotData.WeaponActivity = data.weapon_activity
	self.BotData.WeaponClass = data.weapon_class
	self.BotData.MoveType = data.move_type
	self.BotData.Alive = data.alive == 1
	self.BotData.Attacker = data.attacker
	self.BotData.Inflictor = data.inflictor
	self.BotData.Velocity = RealGloabalChat:PosStringToVector(data.velocity)
	self.BotData.Color = RealGloabalChat:ColorStringToColor(data.color)
	self.BotData.Skin = data.skin
	self.BotData.Bodygroups = data.bodygroups
end

-- function ENT:UpdateActions(actions)
-- 	self.BotData.Actions = actions
-- end

function ENT:CustomStartActivity(activity)
	local current_activity = self:GetActivity()
	if current_activity == activity or not activity then return end
	self:StartActivity(activity)
end

function ENT:SetMovePos(pos)
	self.BotData.TargetMovePos = pos
end

function ENT:GetMovePos()
	return self.BotData.TargetMovePos
end

function ENT:IsActiveMovePos()
	return self.BotData.TargetMovePos ~= nil
end

function ENT:SetAction(action)
	self.BotData.ActiveAction = action
end

function ENT:GetActiveAction()
	return self.BotData.ActiveAction
end

function ENT:SetState(state_name)
	state_name = string_lower(state_name)
	local old_state = self.BotData.CurrentState
	if old_state and old_state.name == state_name then return end
	local bot_states = RealGloabalChat:GetFromStorage('NextBot', 'States', state_name)
	local state = bot_states[state_name]
	if state and old_state and old_state.func and old_state.func.stop then
		old_state.func.stop(self)
	end
	self.BotData.CurrentState = { name = state_name, func = state }
	local current_state = self.BotData.CurrentState
	if current_state and current_state.func and current_state.func.start then
		current_state.func.start(self)
	end
end

function ENT:GetActiveState()
	if not self.BotData.CurrentState then return end
	return self.BotData.CurrentState.func
end

function ENT:GetActiveStateName()
	if not self.BotData.CurrentState then return end
	return self.BotData.CurrentState.name
end