local states = {}

states['typing'] = {
	start = function(self)
		self:AddGesture(ACT_GMOD_IN_CHAT, false)
	end,
	stop = function(self)
		self:RemoveGesture(ACT_GMOD_IN_CHAT)
	end
}

states['sit'] = {
	start = function(self)
		self:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
		self:SetPos(self.BotData.MovePos)
	end,
	update = function(self)
		self:SetMovePos(self.BotData.MovePos)
	end,
	stop = function(self)
		self:SetCollisionGroup(COLLISION_GROUP_WORLD)
		self:DropToFloor()
	end
}

states['gesture'] = {
	start = function(self)
		self:AddGesture(self.BotData.Gesture, false)
		self.BotData.LastGesture = self.BotData.Gesture
	end,
	stop = function(self)
		if not self.BotData.LastGesture then return end
		self:RemoveGesture(self.BotData.LastGesture)
		self.BotData.LastGesture = nil
	end
}

states['move_to_pos'] = {
	update = function(self)
		if self:IsNoclip() then return end
		self:SetMovePos(self.BotData.MovePos)
	end,
}

states['idle'] = {
	start = function(self)
		self:SetMovePos(self.BotData.MovePos)
		self.IdleMoveTimeout = CurTime() + 3
	end,
	update = function(self)
		if not self:IsNoclip() and (not self:GetMovePos() or (self.IdleMoveTimeout and 	self.IdleMoveTimeout < CurTime())) then
			if self.BotData.MovePos and self.BotData.MovePos:DistToSqr(self:GetPos()) > 2500 then
				self:SetPos(self.BotData.MovePos)
			end
			self:SetMovePos(nil)
		end
		if not self:GetMovePos() then
			self:CustomStartActivity(self.BotData.State)
		end
	end,
}

RealGloabalChat:AddToStorage('NextBot', 'States', states)