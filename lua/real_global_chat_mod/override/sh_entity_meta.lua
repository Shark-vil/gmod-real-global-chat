local meta = FindMetaTable('Entity')
local original_AddGesture = meta.AddGesture
local original_RemoveGesture = meta.RemoveGesture
local original_RemoveAllGestures = meta.RemoveAllGestures

function meta:AddGesture(activity, autokill)
	self.RgChatActiveGesture = activity
	if autokill then
		timer.Create('RgChatGestureAutoKill' .. self:EntIndex(), 1, function()
			if not IsValid(self) then return end
			self.RgChatActiveGesture = nil
		end)
	end
	return original_AddGesture(self, activity, autokill)
end

function meta:RemoveAllGestures()
	if self.RgChatActiveGesture and self.RgChatActiveGesture == activity then
		self.RgChatActiveGesture = nil
		timer.Remove('RgChatGestureAutoKill' .. self:EntIndex())
	end
	return original_RemoveGesture(self, activity)
end

function meta:RemoveAllGestures()
	if self.RgChatActiveGesture then
		self.RgChatActiveGesture = nil
		timer.Remove('RgChatGestureAutoKill' .. self:EntIndex())
	end
	return original_RemoveAllGestures(self)
end
