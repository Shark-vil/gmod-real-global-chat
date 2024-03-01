RealGloabalChat = {
	Values = {},
	Enum = {},
}

RealGloabalChat.Values.ApiUrl = 'https://rgcgmod.vincy.ru/'
RealGloabalChat.Values.Version = '1.0.11'
RealGloabalChat.Values.Addons = {}
RealGloabalChat.Values.AddonsModels = {}
RealGloabalChat.Values.AddonsDownloadedProgress = {}
RealGloabalChat.Values.AddonsModelsDownloadChecked = {}
RealGloabalChat.Values.NextBotStates = {}
RealGloabalChat.Values.ModActive = {}
RealGloabalChat.Values.Nextbots = {}

RealGloabalChat.Enum.ActIdle = {
	[ACT_HL2MP_IDLE_PISTOL] = true,
	[ACT_HL2MP_IDLE_AR2] = true,
	[ACT_HL2MP_IDLE_REVOLVER] = true,
	[ACT_HL2MP_IDLE_SHOTGUN] = true,
	[ACT_HL2MP_IDLE_CAMERA] = true,
	[ACT_HL2MP_IDLE_SMG1] = true,
	[ACT_HL2MP_IDLE_PHYSGUN] = true,
	[ACT_HL2MP_IDLE_GRENADE] = true,
	[ACT_HL2MP_IDLE_RPG] = true,
	[ACT_HL2MP_IDLE_CROSSBOW] = true,
	[ACT_HL2MP_IDLE] = true,
	[ACT_HL2MP_IDLE_MAGIC] = true,
	[ACT_HL2MP_IDLE_DUEL] = true,
}

RealGloabalChat.Enum.ActRun = {
	[ACT_HL2MP_RUN_PISTOL] = true,
	[ACT_HL2MP_RUN_AR2] = true,
	[ACT_HL2MP_RUN_REVOLVER] = true,
	[ACT_HL2MP_RUN_SHOTGUN] = true,
	[ACT_HL2MP_RUN_CAMERA] = true,
	[ACT_HL2MP_RUN_SMG1] = true,
	[ACT_HL2MP_RUN_PHYSGUN] = true,
	[ACT_HL2MP_RUN_GRENADE] = true,
	[ACT_HL2MP_RUN_RPG] = true,
	[ACT_HL2MP_RUN_CROSSBOW] = true,
	[ACT_HL2MP_RUN] = true,
	[ACT_HL2MP_RUN_MAGIC] = true,
	[ACT_HL2MP_RUN_DUEL] = true,
}


RealGloabalChat.Enum.ActWalk = {
	[ACT_HL2MP_WALK_PISTOL] = true,
	[ACT_HL2MP_WALK_AR2] = true,
	[ACT_HL2MP_WALK_REVOLVER] = true,
	[ACT_HL2MP_WALK_SHOTGUN] = true,
	[ACT_HL2MP_WALK_CAMERA] = true,
	[ACT_HL2MP_WALK_SMG1] = true,
	[ACT_HL2MP_WALK_PHYSGUN] = true,
	[ACT_HL2MP_WALK_GRENADE] = true,
	[ACT_HL2MP_WALK_RPG] = true,
	[ACT_HL2MP_WALK_CROSSBOW] = true,
	[ACT_HL2MP_WALK] = true,
	[ACT_HL2MP_WALK_MAGIC] = true,
	[ACT_HL2MP_WALK_DUEL] = true,
}

RealGloabalChat.Enum.ActJump = {
	[ACT_HL2MP_JUMP_PISTOL] = true,
	[ACT_HL2MP_JUMP_AR2] = true,
	[ACT_HL2MP_JUMP_REVOLVER] = true,
	[ACT_HL2MP_JUMP_SHOTGUN] = true,
	[ACT_HL2MP_JUMP_CAMERA] = true,
	[ACT_HL2MP_JUMP_SMG1] = true,
	[ACT_HL2MP_JUMP_PHYSGUN] = true,
	[ACT_HL2MP_JUMP_GRENADE] = true,
	[ACT_HL2MP_JUMP_RPG] = true,
	[ACT_HL2MP_JUMP_CROSSBOW] = true,
	[ACT_HL2MP_JUMP] = true,
	[ACT_HL2MP_JUMP_MAGIC] = true,
	[ACT_HL2MP_JUMP_DUEL] = true,
}

RealGloabalChat.Enum.ActJumpToRun = {
	[ACT_HL2MP_JUMP_PISTOL] = ACT_HL2MP_RUN_PISTOL,
	[ACT_HL2MP_JUMP_AR2] = ACT_HL2MP_RUN_AR2,
	[ACT_HL2MP_JUMP_REVOLVER] = ACT_HL2MP_RUN_REVOLVER,
	[ACT_HL2MP_JUMP_SHOTGUN] = ACT_HL2MP_RUN_SHOTGUN,
	[ACT_HL2MP_JUMP_CAMERA] = ACT_HL2MP_RUN_CAMERA,
	[ACT_HL2MP_JUMP_SMG1] = ACT_HL2MP_RUN_SMG1,
	[ACT_HL2MP_JUMP_PHYSGUN] = ACT_HL2MP_RUN_PHYSGUN,
	[ACT_HL2MP_JUMP_GRENADE] = ACT_HL2MP_RUN_GRENADE,
	[ACT_HL2MP_JUMP_RPG] = ACT_HL2MP_RUN_RPG,
	[ACT_HL2MP_JUMP_CROSSBOW] = ACT_HL2MP_RUN_CROSSBOW,
	[ACT_HL2MP_JUMP] = ACT_HL2MP_RUN,
	[ACT_HL2MP_JUMP_MAGIC] = ACT_HL2MP_RUN_MAGIC,
	[ACT_HL2MP_JUMP_DUEL] = ACT_HL2MP_RUN_DUEL,
}

RealGloabalChat.Enum.ActGmodTaunt = {
	[ACT_GMOD_TAUNT_SALUTE] = true,
	[ACT_GMOD_TAUNT_PERSISTENCE] = true,
	[ACT_GMOD_TAUNT_MUSCLE] = true,
	[ACT_GMOD_TAUNT_LAUGH] = true,
	[ACT_GMOD_TAUNT_CHEER] = true,
	[ACT_GMOD_TAUNT_DANCE] = true,
	[ACT_GMOD_TAUNT_ROBOT] = true,
}

if not file.Exists('rgchat_data', 'DATA') then
	file.CreateDir('rgchat_data')
end

if not file.Exists('rgchat_data/verified.txt', 'DATA') then
	file.Write('rgchat_data/verified.txt', '')
end

local mod_name = 'real_global_chat_mod'

if SERVER then
	AddCSLuaFile(mod_name .. '/sh_lang.lua')
	AddCSLuaFile(mod_name .. '/sh_cvars.lua')
	AddCSLuaFile(mod_name .. '/services/sh_service.lua')
	AddCSLuaFile(mod_name .. '/controllers/chat/cl_chat_controller.lua')
	AddCSLuaFile(mod_name .. '/controllers/cl_nextbot_controller.lua')
	AddCSLuaFile(mod_name .. '/net/cl_net_receives.lua')
	AddCSLuaFile(mod_name .. '/sh_cache_workshop_models.lua')
	AddCSLuaFile(mod_name .. '/cl_menu.lua')
	include(mod_name .. '/sh_lang.lua')
	include(mod_name .. '/sh_cvars.lua')
	include(mod_name .. '/net/sv_net_register.lua')
	include(mod_name .. '/services/sh_service.lua')
	include(mod_name .. '/controllers/chat/sv_chat_controller.lua')
	include(mod_name .. '/controllers/sv_nextbot_controller.lua')
	include(mod_name .. '/controllers/sv_game_info_controller.lua')
	include(mod_name .. '/sh_cache_workshop_models.lua')
else
	include(mod_name .. '/sh_lang.lua')
	include(mod_name .. '/sh_cvars.lua')
	include(mod_name .. '/services/sh_service.lua')
	include(mod_name .. '/controllers/chat/cl_chat_controller.lua')
	include(mod_name .. '/controllers/cl_nextbot_controller.lua')
	include(mod_name .. '/net/cl_net_receives.lua')
	include(mod_name .. '/sh_cache_workshop_models.lua')
	include(mod_name .. '/cl_menu.lua')
end