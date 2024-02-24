ENT.Base = 'base_nextbot'
ENT.Spawnable = false
ENT.BotData = {}

function ENT:Initialize()
	self:SetModel('models/player/kleiner.mdl')
	self:AddFlags(FL_OBJECT + FL_NPC + FL_FAKECLIENT)
	self:PhysicsInitShadow()
	self:SetCollisionGroup(COLLISION_GROUP_WORLD)
	self:PhysWake()
end