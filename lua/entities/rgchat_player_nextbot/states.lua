local states = RealGloabalChat.Values.NextBotStates

states['typing'] = {
	start = function(self)
		self:AddGesture(ACT_GMOD_IN_CHAT, false)
	end,
	stop = function(self)
		self:RemoveGesture(ACT_GMOD_IN_CHAT)
	end
}

states['move_to_pos'] = {
	update = function(self)
		if self:IsNoclip() then return end
		self:SetMovePos(self.BotData.MovePos)
		local dist =  self.BotData.MovePos:DistToSqr(self:GetPos())
		if dist > 1000000 or self:OnStuck() then
			self:SetPos(self.BotData.MovePos)
		end
	end,
}

states['idle'] = {
	start = function(self)
		self:SetMovePos(self.BotData.MovePos)
		self.IdleMoveTimeout = CurTime() + 1
	end,
	update = function(self)
		if not self:IsNoclip() and (not self:GetMovePos() or (self.IdleMoveTimeout and 	self.IdleMoveTimeout < CurTime())) then
			if self.BotData.MovePos and self.BotData.MovePos:DistToSqr(self:GetPos()) > 2500 then
				self:SetPos(self.BotData.MovePos)
			end
			self:SetMovePos(nil)
		end
		self:CustomStartActivity(self.BotData.State)
	end,
}