local math_Rand = math.Rand
local vector_0_0_0 = Vector(0, 0, 0)
local angle_0_0_0 = Angle(0, 0, 0)
local util_TraceLine = util.TraceLine
-- local weapons_IsBasedOn = weapons.IsBasedOn
-- local weapons_Get = weapons.Get

-- local weapon_hold_types = {
-- 	['models/weapons/w_irifle.mdl'] = 'ar2',
-- 	['models/weapons/w_bugbait.mdl'] = 'grenade',
-- 	['models/weapons/w_crossbow.mdl'] = 'crossbow',
-- 	['models/weapons/w_crowbar.mdl'] = 'melee',
-- 	['models/weapons/w_grenade.mdl'] = 'grenade',
-- 	['models/weapons/w_Physics.mdl'] = 'physgun',
-- 	['models/weapons/w_pistol.mdl'] = 'pistol',
-- 	['models/weapons/w_rocket_launcher.mdl'] = 'rpg',
-- 	['models/weapons/w_shotgun.mdl'] = 'shotgun',
-- 	['models/weapons/w_slam.mdl'] = 'slam',
-- 	['models/weapons/w_smg1.mdl'] = 'smg',
-- 	['models/weapons/w_stunbaton.mdl'] = 'melee',
-- 	['models/weapons/w_medkit.mdl'] = 'pistol',
-- 	['models/weapons/w_toolgun.mdl'] = 'revolver',
-- 	['models/weapons/w_pist_glock18.mdl'] = 'pistol',
-- 	['models/weapons/w_pist_p228.mdl'] = 'pistol',
-- 	['models/weapons/w_pist_deagle.mdl'] = 'revolver',
-- 	['models/weapons/w_pist_usp_silencer.mdl'] = 'pistol',
-- 	['models/weapons/w_pist_elite.mdl'] = 'duel',
-- 	['models/weapons/w_pist_fiveseven.mdl'] = 'pistol',
-- 	['models/weapons/w_shot_m3super90.mdl'] = 'shotgun',
-- 	['models/weapons/w_shot_xm1014.mdl'] = 'shotgun',
-- 	['models/weapons/w_smg_p90.mdl'] = 'smg',
-- 	['models/weapons/w_smg_mp5.mdl'] = 'smg',
-- 	['models/weapons/w_smg_mac10.mdl'] = 'pistol',
-- 	['models/weapons/w_smg_ump45.mdl'] = 'smg',
-- 	['models/weapons/w_mach_m249para.mdl'] = 'crossow',
-- 	['models/weapons/w_rif_galil.mdl'] = 'ar2',
-- 	['models/weapons/w_rif_ak47.mdl'] = 'ar2',
-- 	['models/weapons/w_rif_m4a1.mdl'] = 'ar2',
-- 	['models/weapons/w_rif_m4a1_silencer.mdl'] = 'ar2',
-- 	['models/weapons/w_rif_sg552.mdl'] = 'ar2',
-- 	['models/weapons/w_snip_awp.mdl'] = 'ar2',
-- 	['models/weapons/w_snip_scout.mdl'] = 'ar2',
-- 	['models/weapons/w_snip_g3sg1.mdl'] = 'ar2',
-- 	['models/weapons/w_snip_sg550.mdl'] = 'ar2',
-- 	['models/weapons/w_rif_famas.mdl'] = 'ar2',
-- 	['models/weapons/w_rif_aug.mdl'] = 'ar2'
-- }
-- local weapons_world_models = {
-- 	['weapon_ar2'] = 'models/weapons/w_irifle.mdl',
-- 	['weapon_bugbait'] = 'models/weapons/w_bugbait.mdl',
-- 	['weapon_crossbow'] = 'models/weapons/w_crossbow.mdl',
-- 	['weapon_crowbar'] = 'models/weapons/w_crowbar.mdl',
-- 	['weapon_frag'] = 'models/weapons/w_grenade.mdl',
-- 	['weapon_physcannon'] = 'models/weapons/w_Physics.mdl',
-- 	['weapon_physgun'] = 'models/weapons/w_Physics.mdl',
-- 	['weapon_pistol'] = 'models/weapons/w_pistol.mdl',
-- 	['weapon_rpg'] = 'models/weapons/w_rocket_launcher.mdl',
-- 	['weapon_shotgun'] = 'models/weapons/w_shotgun.mdl',
-- 	['weapon_slam'] = 'models/weapons/w_slam.mdl',
-- 	['weapon_smg1'] = 'models/weapons/w_smg1.mdl',
-- 	['weapon_stunstick'] = 'models/weapons/w_stunbaton.mdl',
-- 	['weapon_medkit'] = 'models/weapons/w_medkit.mdl',
-- 	['gmod_tool'] = 'models/weapons/w_toolgun.mdl',
-- }

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
	return (IsValid(self.WeaponENT) and self._WeaponClass) and self.WeaponENT
end

function ENT:GetActiveWeaponClassName()
	return self._WeaponClass
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
	return NULL
end

function ENT:SetActiveWeapon(weapon)
	if weapon ~= NULL and weapon ~= nil then
		self:SelectWeapon(weapon.ClassName)
	else
		self:StripWeapon()
	end
end

-- function ENT:GetAttachmentPoint(pointtype)
-- 	if pointtype == 'hand' then
-- 		local lookup = self:LookupAttachment('anim_attachment_RH')
-- 		if lookup == 0 then
-- 			local bone = self:LookupBone('ValveBiped.Bip01_R_Hand')
-- 			if not bone then
-- 				return {
-- 					Pos = self:GetPos() + self:OBBCenter(),
-- 					Ang = self:GetForward():Angle()
-- 				}
-- 			else
-- 				return self:GetBonePosAngs(bone)
-- 			end
-- 		else
-- 			return self:GetAttachment(lookup)
-- 		end
-- 	elseif pointtype == 'eyes' then
-- 		local lookup = self:LookupAttachment('eyes')
-- 		if lookup == 0 then
-- 			return {
-- 				Pos = self:GetPos() + self:OBBCenter() + Vector(0, 0, 5),
-- 				Ang = self:GetForward():Angle() + Angle(-20, 0, 0)
-- 			}
-- 		else
-- 			return self:GetAttachment(lookup)
-- 		end
-- 	end
-- end
function ENT:SelectWeapon(className)
	self:DeEquipWeapon()
	if self._WeaponClass == className then return end
	if not RealGloabalChat.AllRegistredWeapons[className] then return end
	local weapon_data = RealGloabalChat.AllRegistredWeapons[className]

	if weapon_data.WorldModel and weapon_data.WorldModel ~= '' then
		local fake_weapon = self:GetWeaponENT()
		fake_weapon:SetModel(weapon_data.WorldModel)
		fake_weapon:SetLocalPos(Vector(0, 0, 0))
		fake_weapon:SetLocalAngles(Angle(0, 0, 0))

		if istable(weapon_data.WorldModelOffset) then
			if isvector(weapon_data.WorldModelOffset.Pos) then
				fake_weapon:SetLocalPos(weapon_data.WorldModelOffset.Pos)
			end

			if isangle(weapon_data.WorldModelOffset.Ang) then
				fake_weapon:SetLocalAngles(weapon_data.WorldModelOffset.Ang)
			end
		end

		if className == 'weapon_physgun' then
			fake_weapon:SetSkin(1)

			for k, v in ipairs(fake_weapon:GetMaterials()) do
				if string.EndsWith(v, 'w_physics_sheet') then
					fake_weapon:SetSubMaterial(k, 'models/weapons/zetaphysgun/w_physics_sheet2')
				end
			end
		else
			fake_weapon:SetSkin(0)

			for k, v in ipairs(fake_weapon:GetMaterials()) do
				fake_weapon:SetSubMaterial(k, 'nil')
			end
		end

		fake_weapon:SetNoDraw(false)
	end

	self._WeaponClass = className
end

function ENT:EquipWeapon(weapon_num)
	self:DeEquipWeapon()
	if not weapon_num then return end
	local index = 0

	for weaponClass, _ in pairs(RealGloabalChat.AllRegistredWeapons) do
		index = index + 1

		if index == weapon_num then
			self:SelectWeapon(weaponClass)
			break
		end
	end
end

function ENT:TimeConnected()
	return 0
end

function ENT:DeEquipWeapon()
	if self._WeaponClass then
		self._WeaponClass = nil
	end

	if not IsValid(self.WeaponENT) then return end
	self.WeaponENT:SetNoDraw(true)
end

-- function ENT:CollectAllWeapons()
-- 	local weapon_list = {}

-- 	for _, wep in ipairs(weapons.GetList()) do
-- 		weapon_list[wep.ClassName] = {
-- 			WorldModel = wep.WorldModel,
-- 			WorldModelOffset = wep.WorldModelOffset
-- 		}
-- 	end

-- 	for className, worldModel in pairs(weapons_world_models) do
-- 		weapon_list[className] = {
-- 			WorldModel = worldModel
-- 		}
-- 	end

-- 	RealGloabalChat.AllRegistredWeapons = weapon_list
-- end

function ENT:Say(texttosay)
end

function ENT:OnKilled(dmginfo)
	-- hook.Call('OnNPCKilled', GAMEMODE, self, dmginfo:GetAttacker(), dmginfo:GetInflictor())

	if self.CurrentWeapon ~= nil then
		self.CurrentWeapon:Remove()
	end

	self:BecomeRagdoll(dmginfo)
end