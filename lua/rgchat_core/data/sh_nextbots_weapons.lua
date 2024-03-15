hook.Add('InitPostEntity', 'RGChat.ParseWeapons', function()
	local weapon_list = {}

	local weapons_world_models = {
		['weapon_ar2'] = 'models/weapons/w_irifle.mdl',
		['weapon_bugbait'] = 'models/weapons/w_bugbait.mdl',
		['weapon_crossbow'] = 'models/weapons/w_crossbow.mdl',
		['weapon_crowbar'] = 'models/weapons/w_crowbar.mdl',
		['weapon_frag'] = 'models/weapons/w_grenade.mdl',
		['weapon_physcannon'] = 'models/weapons/w_Physics.mdl',
		['weapon_physgun'] = 'models/weapons/w_Physics.mdl',
		['weapon_pistol'] = 'models/weapons/w_pistol.mdl',
		['weapon_rpg'] = 'models/weapons/w_rocket_launcher.mdl',
		['weapon_shotgun'] = 'models/weapons/w_shotgun.mdl',
		['weapon_slam'] = 'models/weapons/w_slam.mdl',
		['weapon_smg1'] = 'models/weapons/w_smg1.mdl',
		['weapon_stunstick'] = 'models/weapons/w_stunbaton.mdl',
		['weapon_medkit'] = 'models/weapons/w_medkit.mdl',
		['gmod_tool'] = 'models/weapons/w_toolgun.mdl',
	}

	for _, wep in ipairs(weapons.GetList()) do
		weapon_list[wep.ClassName] = {
			WorldModel = wep.WorldModel,
			WorldModelOffset = wep.WorldModelOffset
		}
	end

	for className, worldModel in pairs(weapons_world_models) do
		weapon_list[className] = {
			WorldModel = worldModel
		}
	end

	RealGloabalChat.AllRegistredWeapons = weapon_list
end)