local math_Rand = math.Rand
local vector_0_0_0 = Vector(0, 0, 0)
local angle_0_0_0 = Angle(0, 0, 0)
local util_TraceLine = util.TraceLine
local weapon_hold_types = {
	['models/weapons/w_irifle.mdl'] = 'ar2',
	['models/weapons/w_bugbait.mdl'] = 'grenade',
	['models/weapons/w_crossbow.mdl'] = 'crossbow',
	['models/weapons/w_crowbar.mdl'] = 'melee',
	['models/weapons/w_grenade.mdl'] = 'grenade',
	['models/weapons/w_Physics.mdl'] = 'physgun',
	['models/weapons/w_pistol.mdl'] = 'pistol',
	['models/weapons/w_rocket_launcher.mdl'] = 'rpg',
	['models/weapons/w_shotgun.mdl'] = 'shotgun',
	['models/weapons/w_slam.mdl'] = 'slam',
	['models/weapons/w_smg1.mdl'] = 'smg',
	['models/weapons/w_stunbaton.mdl'] = 'melee',
	['models/weapons/w_medkit.mdl'] = 'pistol',
	['models/weapons/w_toolgun.mdl'] = 'revolver',
	['models/weapons/w_pist_glock18.mdl'] = 'pistol',
	['models/weapons/w_pist_p228.mdl'] = 'pistol',
	['models/weapons/w_pist_deagle.mdl'] = 'revolver',
	['models/weapons/w_pist_usp_silencer.mdl'] = 'pistol',
	['models/weapons/w_pist_elite.mdl'] = 'duel',
	['models/weapons/w_pist_fiveseven.mdl'] = 'pistol',
	['models/weapons/w_shot_m3super90.mdl'] = 'shotgun',
	['models/weapons/w_shot_xm1014.mdl'] = 'shotgun',
	['models/weapons/w_smg_p90.mdl'] = 'smg',
	['models/weapons/w_smg_mp5.mdl'] = 'smg',
	['models/weapons/w_smg_mac10.mdl'] = 'pistol',
	['models/weapons/w_smg_ump45.mdl'] = 'smg',
	['models/weapons/w_mach_m249para.mdl'] = 'crossow',
	['models/weapons/w_rif_galil.mdl'] = 'ar2',
	['models/weapons/w_rif_ak47.mdl'] = 'ar2',
	['models/weapons/w_rif_m4a1.mdl'] = 'ar2',
	['models/weapons/w_rif_m4a1_silencer.mdl'] = 'ar2',
	['models/weapons/w_rif_sg552.mdl'] = 'ar2',
	['models/weapons/w_snip_awp.mdl'] = 'ar2',
	['models/weapons/w_snip_scout.mdl'] = 'ar2',
	['models/weapons/w_snip_g3sg1.mdl'] = 'ar2',
	['models/weapons/w_snip_sg550.mdl'] = 'ar2',
	['models/weapons/w_rif_famas.mdl'] = 'ar2',
	['models/weapons/w_rif_aug.mdl'] = 'ar2'
}

local function GetHoldType(worldmodel)
	if weapon_hold_types[worldmodel] then return weapon_hold_types[worldmodel] end

	return 'normal'
end

function ENT:GetShootPos()
	return self:GetPos() + self:GetHeadHeightVector() + self:GetForward()
end

function ENT:GetHeadHeightVector()
	local _, posModelOffsetMax = self:GetModelBounds()

	return Vector(0, 0, posModelOffsetMax.z - 16)
end

function ENT:ViewPunch()
end

function ENT:SetEyeAngles()
end

function ENT:GetActiveWeapon()
	return self.CurrentWeapon
end

function ENT:GetAimVector()
	return self:GetForward()
end

function ENT:AccountID()
	return '[U:1:165067711]'
end

function ENT:DrawWorldModel()
end

function ENT:SetViewEntity()
end

function ENT:SteamID64()
	return self.BotData.SteamId64Number
end

function ENT:GetViewModel()
	return self
end

function ENT:Alive()
	return true
end

function ENT:GetViewEntity()
	return self
end

function ENT:SetNoTarget()
end

function ENT:ViewPunchReset()
end

function ENT:GetAmmoCount()
	return 69
end

function ENT:GetViewPunchAngles()
	return angle_0_0_0
end

function ENT:GetEyeTrace()
	local tracedata = {}
	tracedata['start'] = self:GetHeadHeightVector() + self:GetPos()
	tracedata['endpos'] = tracedata['start'] + (self:GetForward() * 1024)
	tracedata['filter'] = self

	return util_TraceLine(tracedata)
end

function ENT:GetEyeTraceNoCursor()
	return self:GetEyeTrace()
end

function ENT:GetViewOffset()
	return self:GetHeadHeightVector()
end

function ENT:RemoveAmmo()
end

function ENT:IsNPC()
	return false
end

function ENT:IsPlayer()
	return true
end

function ENT:GetName()
	return self.BotData.NickName
end

function ENT:Name()
	return self.BotData.NickName
end

function ENT:Nick()
	return self.BotData.NickName
end

function ENT:DoAttackEvent()
end

function ENT:DoSecondaryAttack()
end

function ENT:DoReloadEvent()
end

function ENT:UniqueID()
	return math_Rand(0, 999)
end

function ENT:GetInfoNum(cVarName, default)
	return 0
end

function ENT:ConCommand()
end

function ENT:SetRunSpeed(speed)
	self:SetWalkSpeed(speed)
end

function ENT:SetWalkSpeed(speed)
	self.loco:SetDesiredSpeed(speed)
end

function ENT:SendHint(name, delay)
end

function ENT:SendLua(script)
end

function ENT:Send()
end

function ENT:AddDeaths(count)
end

function ENT:AddFrozenPhysicsObject(ent, physobj)
end

function ENT:AddPlayerOption(name, timeout, vote_callback, draw_callback)
end

function ENT:AllowFlashlight(canFlashlight)
end

function ENT:Armor()
	return 100
end

function ENT:Ban(minutes, kick)
end

function ENT:Crouching()
	return false
end

function ENT:GetInfo(cVarName)
	return ''
end

function ENT:KeyDown(key)
	return true
end

function ENT:KeyPressed(key)
	return true
end

function ENT:ChatPrint(message)
end

function ENT:Say(text, teamOnly)
end

function ENT:PrintMessage(type, message)
end

function ENT:AddVCDSequenceToGestureSlot()
end

function ENT:WorldModelOffsets()
	return vector_0_0_0
end

function ENT:StripWeapon()
	self:DeEquipWeapon()
end

function ENT:GetEnemy()
	return self.BadNearEnt
end

function ENT:SetActiveWeapon(weapon)
	if weapon ~= NULL and weapon ~= nil then
		self:SelectWeapon(weapon.ClassName)
	else
		self:StripWeapon()
	end
end

function ENT:SelectWeapon(className)
	self.EquipWeapons = true

	if self.CurrentWeapon ~= nil then
		self:DeEquipWeapon()
	end

	if not weapons.Get(className) then return end
	local handpoint = self:LookupAttachment('anim_attachment_RH')
	local handattach = self:LookupAttachment('hand')
	self.CurrentWeapon = ents.Create(className)
	self.CurrentWeapon:SetOwner(self)
	self.CurrentWeapon:DeleteOnRemove(self.CurrentWeapon)
	self.CurrentWeapon:AddEffects(EF_BONEMERGE)
	self.CurrentWeapon:SetMoveType(MOVETYPE_NONE)
	local matrix = self:GetBoneMatrix(handattach)
	local pos = matrix:GetTranslation()
	local ang = matrix:GetAngles()
	self.CurrentWeapon:SetPos(pos)
	self.CurrentWeapon:SetAngles(ang)
	self.CurrentWeapon:SetParent(self, handpoint)
	self.CurrentWeapon:SetModel('models/props_junk/PopCan01a.mdl')

	if self.CurrentWeapon.HoldType ~= nil then
		self.CurWeaponHT = self.CurrentWeapon.HoldType
	else
		self.CurWeaponHT = GetHoldType(self.CurrentWeapon.WorldModel)
	end
end

function ENT:TimeConnected()
	return 0
end

function ENT:DeEquipWeapon()
	if self.CurrentWeapon ~= nil and IsValid(self.CurrentWeapon) then
		self.CurrentWeapon:Remove()
		self.CurrentWeapon = nil
		self.CurWeaponHT = 'normal'
	end
end

function ENT:CollectAllWeapons()
	local WepCarryOver = {}

	for k, Wep in ipairs(weapons.GetList()) do
		if Wep.AdminOnly then
			if self.AdminWeapons then
				table.insert(WepCarryOver, Wep)
			end
		else
			table.insert(WepCarryOver, Wep)
		end
	end

	self.AllSwepWeapons = WepCarryOver
end

function ENT:EquipWeapon(weaponnum)
	if self.CurrentWeapon ~= nil then
		self:DeEquipWeapon()
	end

	if not self.AllSwepWeapons[weaponnum] then return end
	local handpoint = self:LookupAttachment('anim_attachment_RH')
	local handattach = self:LookupAttachment('hand')
	self.CurrentWeapon = ents.Create(self.AllSwepWeapons[weaponnum].ClassName)
	self.CurrentWeapon:SetOwner(self)
	self.CurrentWeapon:DeleteOnRemove(self.CurrentWeapon)
	self.CurrentWeapon:AddEffects(EF_BONEMERGE)
	self.CurrentWeapon:SetMoveType(MOVETYPE_NONE)
	local matrix = self:GetBoneMatrix(handattach)
	local pos = matrix:GetTranslation()
	local ang = matrix:GetAngles()
	self.CurrentWeapon:SetPos(pos)
	self.CurrentWeapon:SetAngles(ang)
	self.CurrentWeapon:SetParent(self, handpoint)
	self.CurrentWeapon:SetModel('models/props_junk/PopCan01a.mdl')

	if self.CurrentWeapon.HoldType ~= nil then
		self.CurWeaponHT = self.CurrentWeapon.HoldType
	else
		self.CurWeaponHT = GetHoldType(self.CurrentWeapon.WorldModel)
	end
end

function ENT:Say(texttosay)
end

function ENT:OnKilled(dmginfo)
	hook.Call('OnNPCKilled', GAMEMODE, self, dmginfo:GetAttacker(), dmginfo:GetInflictor())

	if self.CurrentWeapon ~= nil then
		self.CurrentWeapon:Remove()
	end

	self:BecomeRagdoll(dmginfo)
end