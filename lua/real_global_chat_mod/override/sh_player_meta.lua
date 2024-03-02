local meta = FindMetaTable('Player')
local original_AnimSetGestureSequence = meta.AnimSetGestureSequence
local original_AddVCDSequenceToGestureSlot = meta.AddVCDSequenceToGestureSlot
local original_AnimRestartGesture = meta.AnimRestartGesture
local original_AnimResetGestureSlot = meta.AnimResetGestureSlot

function meta:AnimSetGestureSequence(slot, sequenceID)
	print('AnimSetGestureSequence', slot, sequenceID)
	return original_AnimSetGestureSequence(self, slot, sequenceID)
end

function meta:AddVCDSequenceToGestureSlot(slot, sequenceID, cycle, autokill)
	print('AddVCDSequenceToGestureSlot', slot, sequenceID, cycle, autokill)
	return original_AddVCDSequenceToGestureSlot(self, slot, sequenceID, cycle, autokill)
end

function meta:AnimRestartGesture(slot, activity, autokill)
	print('AnimRestartGesture', slot, activity, autokill)
	return original_AnimRestartGesture(self, slot, activity, autokill)
end

function meta:AnimResetGestureSlot(slot)
	print('AnimResetGestureSlot', slot)
	return original_AnimResetGestureSlot(self, slot)
end