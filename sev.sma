/*
Severian's AMXX Mod by LetiLetiLepestok
ver. 1.35  [07.01.2012]


Description:

This is a clone of original Severian's server mod with some improvements.

* Shotgun reloads much faster than normal.
* Shotgun shoots much faster than normal.
* Shotgun damage increased from normal.
* Crossbow reloads much faster than normal.
* Crossbow shoots faster than normal.
* Crowbar, when right-clicked, fires off "Hello!" to nearby players.
* Snarks, when right-clicked, teleport the player to a random spawn point. This can only be done once every 2 minutes, or once per death (whichever comes quicker!).
* Snarks also look different and use the 'chumtoad' model.
* Snarks, when dying, explode and cause area effect damage for 5 points.
* Hand Grenades, when right-clicked, launch and detonate on impact. You can only do this once every 5 seconds.
* Tripmines, when right-clicked, will place a 'lightning' mine which will blow up with 150% of the damage of a regular mine.
* Players have 1 second of spawn protection before they may be shot. They can however, fire immediately upon spawning.
* Flashlight is much brighter than normal.
* Map information, remaining time, and fraglimit displayed when you are dead.
* Identification of players when you aim your crosshair at them, built in.


Cvars:
sev_flashlight_style	1 		Flashlight style 									0 - classic, 1 - severian's
sev_snark_style			1 		Snarks style 										0 - classic, 1 - severian's
sev_status_style		1 		Status of a player then aim. 						0 - classic, 1 - severians, 2 - disabled
sev_hornet_style		1 		Colored hornets 									0 - disable, 1 - enable
sev_tripmine_style		1 		Tripmines style 									0 - classic, 1 - severian's
sev_death_info			1 		HUD message ater death 								0 - disable, 1 - enable
sev_sp_time				0.5		Spawn protection time in seconds. 					0 - disable spawn protection
sev_shotgun_gibs		1		Make gibs if damage for shotgun exeeds 180 pts. 	0 - disable spawn protection
sev_remove_map_eqip		1		Remove in map spawn equipment						0 - leave ,  1 - remove
sev_shotgun_gibs		1		Make gibs on getting high shot damage				0 - disable, 1 - enable

Feedback and suggestions:
ICQ 3884085
e-mail:afalink@dolphins.ru


Credits:
Thanks to Arkshine for shotgun code
Thanks to Nadya and Stan for testing

*/

#include <amxmodx>
#include <amxmisc>
#include <xs>
#include <fakemeta>
#include <engine>
#include <hamsandwich>

#define PLUGIN "Severian's Mod AMXX"
#define VERSION "1.35"
#define AUTHOR "LetiLetiLepestok"
#define MAX_GAUSS_AMMO 254

new g_pcvar_enable_plugin;
#define PLUGIN_ENABLED (get_pcvar_num(g_pcvar_enable_plugin) == 1)

#define GAME_DESCRIPTION "Severian's Mod+"

const Float:g_DamagePerShot			= 25.0
const Float:g_DamageCrowbar			= 50.0
const Float:g_SnarkThrowInterval	= 0.1
const g_GibsDmg						= 180
const g_HornetTrailTime 			= 10

const m_pPlayer						= 28
const m_fInSpecialReload			= 34
const m_flNextPrimaryAttack			= 35
const m_flNextSecondaryAttack		= 36
const m_flTimeWeaponIdle			= 37
const m_iClip						= 40
const m_pBeam 						= 176
const m_flNextAttack				= 148
const LINUX_OFFSET_WEAPONS			= 4
const LINUX_OFFSET_AMMO				= 5
const OFFSET_AMMO_HEGRENADE			= 319
const iHandGrenadeAmmoIndex 		= 10

const m_rgAmmo					= 310;
const iUraniumAmmoIndex				= 5;

new g_CrowbarSounds[2][64] = {"scientist/hello.wav", "scientist/hello2.wav"}

new g_OldClip[33]
new g_OldSpecialReload[33]
new g_LastTripmineAttack[33]
new g_grenade_alt_counter[33]
new g_SpawnsId[64]
new g_BlockSound
new g_MaxPlayers
new g_GrenadeAllocString
new g_HudSyncObj

new g_pcvar_fraglimit
new g_pcvar_timelimit
new g_pcvar_flashlight_style
new g_pcvar_snark_style
new g_pcvar_hornet_style
new g_pcvar_status_style
new g_pcvar_tripmine_style
new g_pcvar_spawnprotect_time
new g_pcvar_remove_map_equip
new g_pcvar_death_info
new g_pcvar_shotgun_gibs
new g_pcvar_shotgun_blod

// Конфігураційні перемикачі
new g_enable_shotgun, g_enable_crossbow, g_enable_crowbar;
new g_enable_snark, g_enable_grenade, g_enable_tripmine;
new g_enable_gauss_ammo;

public plugin_cfg() {
	new configfile[64];
	get_configsdir(configfile, charsmax(configfile));
	format(configfile, charsmax(configfile), "%s/sev.ini", configfile);
	
	if (!file_exists(configfile)) {
		log_amx("sev.ini not found! All features enabled by default.");
		g_enable_shotgun = g_enable_crossbow = g_enable_crowbar = 1;
		g_enable_snark = g_enable_grenade = g_enable_tripmine = 1;
		g_enable_gauss_ammo = 1;
		return;
	}
	
	g_enable_shotgun = read_config_setting(configfile, "shotgun", 1);
	g_enable_crossbow = read_config_setting(configfile, "crossbow", 1);
	g_enable_crowbar = read_config_setting(configfile, "crowbar", 1);
	g_enable_snark = read_config_setting(configfile, "snark", 1);
	g_enable_grenade = read_config_setting(configfile, "grenade", 1);
	g_enable_tripmine = read_config_setting(configfile, "tripmine", 1);
	g_enable_gauss_ammo = read_config_setting(configfile, "gauss_ammo", 1);
}

read_config_setting(const file[], const key[], defvalue) {
	new line[128], tempKey[32], tempValue[4];
	new txtlen;
	for (new i = 0; read_file(file, i, line, charsmax(line), txtlen); i++) {
		trim(line);
		if (line[0] == ';' || line[0] == '#' || !line[0])
			continue;
		
		parse(line, tempKey, charsmax(tempKey), tempValue, charsmax(tempValue));
		if (equali(tempKey, key)) {
			return str_to_num(tempValue);
		}
	}
	return defvalue;
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	g_pcvar_enable_plugin = register_cvar("sev_mod", "1"); // Глобальний перемикач
	
	RegisterHam(Ham_Weapon_PrimaryAttack	, "weapon_shotgun", "Shotgun_PrimaryAttack_Pre" , 0)
	RegisterHam(Ham_Weapon_PrimaryAttack	, "weapon_shotgun", "Shotgun_PrimaryAttack_Post", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack	, "weapon_crossbow", "Crossbow_PrimaryAttack_Post", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack	, "weapon_tripmine", "TripminePrimaryAttack_Pre", 0)
	RegisterHam(Ham_Weapon_PrimaryAttack	, "weapon_snark", "Snark_PrimaryAttack_Post", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack	, "weapon_handgrenade", "Grenade_PrimaryAttack_Post", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack	, "weapon_gauss", "Gauss_Attack_Post", 1)
	
	RegisterHam(Ham_Weapon_SecondaryAttack	, "weapon_shotgun"		, "Shotgun_SecondaryAttack_Pre" , 0)
	RegisterHam(Ham_Weapon_SecondaryAttack	, "weapon_shotgun"		, "Shotgun_SecondaryAttack_Post", 1)
	RegisterHam(Ham_Weapon_SecondaryAttack	, "weapon_snark"		, "Snark_SecondaryAttack_Post", 1)
	RegisterHam(Ham_Weapon_SecondaryAttack	, "weapon_handgrenade"	, "Grenade_SecondaryAttack_Pre", 0)
	RegisterHam(Ham_Weapon_SecondaryAttack	, "weapon_handgrenade"	, "Grenade_SecondaryAttack_Post", 1)
	RegisterHam(Ham_Weapon_SecondaryAttack	, "weapon_crossbow"		, "Crossbow_SecondaryAttack_Post", 1)
	RegisterHam(Ham_Weapon_SecondaryAttack	, "weapon_tripmine"		, "Tripmine_SecondaryAttack_Pre", 0)
	RegisterHam(Ham_Weapon_SecondaryAttack	, "weapon_crowbar"		, "Crowbar_SecondaryAttack_Post", 1 )
	RegisterHam(Ham_Weapon_SecondaryAttack	, "weapon_gauss", "Gauss_Attack_Post", 1)
	
	RegisterHam(Ham_Weapon_Reload			, "weapon_shotgun"		, "Shotgun_Reload_Pre" , 0)
	RegisterHam(Ham_Weapon_Reload			, "weapon_shotgun"		, "Shotgun_Reload_Post", 1)	
	RegisterHam(Ham_Weapon_Reload			, "weapon_crossbow"		, "Crossbow_Reload_Post", 1)
	
	RegisterHam(Ham_Touch					, "grenade"				, "Grenade_Touch", 0)
	
	RegisterHam(Ham_Spawn					, "monster_tripmine"	, "TripMine_Spawn_Post", 0)
	RegisterHam(Ham_Spawn					, "player"				, "Player_Spawn_Pre", 0)
	RegisterHam(Ham_Spawn					, "player"				, "Player_Spawn_Post", 1)
	
	RegisterHam(Ham_Killed					, "player"				, "Player_Death_Post", 1)
	
	RegisterHam(Ham_Think					, "monster_tripmine"	, "TripMine_Think_Post", 1)
	
	RegisterHam(Ham_TraceAttack			  	, "player"				, "fw_TraceAttack")
	RegisterHam(Ham_TraceAttack			  	, "worldspawn"			, "fw_TraceAttackWorld")
	
	RegisterHam(Ham_TakeDamage			  	, "player"				, "fw_TakeDamage")
	
	RegisterHam(Ham_Item_PostFrame				, "weapon_gauss", "Gauss_Attack_Post", 1)
	
	register_forward(FM_EmitSound			, "fwd_EmitSound")
	register_forward(FM_SetModel			, "fwd_SetModel")
	register_forward(FM_GetGameDescription	, "fwd_GetGameDescription")
	register_forward(FM_PlayerPreThink	, "OnPlayerPreThink")
	
	register_message(get_user_msgid("Flashlight")	, "msg_FlashLight")
	register_message(get_user_msgid("StatusValue")	, "msg_StatusValue")
	register_message(SVC_TEMPENTITY					, "msg_TempEntity" )
	
	register_cvar("SevModAMXXversion", VERSION	, FCVAR_SERVER|FCVAR_EXTDLL|FCVAR_SPONLY)
	register_cvar("SevModAMXXauthor", AUTHOR	, FCVAR_SERVER|FCVAR_EXTDLL|FCVAR_SPONLY)
	
	g_pcvar_flashlight_style 				= register_cvar("sev_flashlight_style"	, "1")
	g_pcvar_snark_style 					= register_cvar("sev_snark_style"		, "1")
	g_pcvar_status_style 					= register_cvar("sev_status_style"		, "1")
	g_pcvar_hornet_style 					= register_cvar("sev_hornet_style"		, "1")
	g_pcvar_tripmine_style 					= register_cvar("sev_tripmine_style"	, "1")
	g_pcvar_death_info						= register_cvar("sev_death_info"		, "1")
	g_pcvar_spawnprotect_time				= register_cvar("sev_sp_time"			, "1.0")
	g_pcvar_remove_map_equip				= register_cvar("sev_remove_map_equip"	, "1")
	g_pcvar_shotgun_gibs					= register_cvar("sev_shotgun_gibs"		, "1")
	g_pcvar_shotgun_blod					= register_cvar("sev_shotgun_bloodspray", "1")
	
	g_pcvar_fraglimit 						= get_cvar_pointer("mp_fraglimit")
	g_pcvar_timelimit 						= get_cvar_pointer("mp_timelimit")
	
	g_GrenadeAllocString = engfunc(EngFunc_AllocString, "grenade")
	g_HudSyncObj = CreateHudSyncObj()
	g_MaxPlayers = get_maxplayers()
	start_map()
}

public plugin_precache()
{
	precache_sound("gonarch/gon_alert1.wav")
	precache_sound("gonarch/gon_alert2.wav")
	precache_sound("gonarch/gon_alert3.wav")
	precache_sound("debris/beamstart4.wav")
	precache_sound("weapons/glauncher.wav")
	precache_sound("items/gunpickup2.wav")
	precache_sound("weapons/glauncher.wav")
	precache_sound("weapons/glauncher2.wav")
	precache_sound(g_CrowbarSounds[0])
	precache_sound(g_CrowbarSounds[1])
	
	precache_model("models/chumtoad.mdl")
	precache_model("sprites/b-tele1.spr")
	precache_model("models/w_grenade.mdl")
	precache_model("models/w_chainammo.mdl")
}

public start_map()
{
	new cfg_dir[64]	
	new map_name[32]
	new equip_file[128]
	new no_eqip_file
	new ent
	new i
	
	while((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", "info_player_deathmatch")))
	{
		g_SpawnsId[i++] = ent
		if(i == sizeof g_SpawnsId)
			break
	}
	
	get_localinfo("amxx_configsdir", cfg_dir, charsmax(cfg_dir))
	get_mapname(map_name, charsmax(map_name)) 
	format(equip_file, charsmax(equip_file), "%s/maps/%s.ini", cfg_dir, map_name)
	
	if(!file_exists(equip_file))
	{
		format(equip_file, charsmax(equip_file), "%s/equipment.ini", cfg_dir)
		
		if(!file_exists(equip_file))
		{
			log_amx("No equipment file found.")
			return
		}		
	}
	else
		no_eqip_file = 1
	
	if(file_size(equip_file) < 8)
	{
		log_amx("Equipment file is too small.")
		return
	}
	
	new text[36]
	new equip_name[32]
	new equip_num[3]
	new line
	new textsize
	
	ent = 0
	
	if(no_eqip_file || get_pcvar_num(g_pcvar_remove_map_equip))
	{
		while((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", "game_player_equip")))
			engfunc(EngFunc_RemoveEntity, ent)	
	}
	
	ent = create_entity("game_player_equip")
	
	log_amx("Reading equipment file: ^"%s^"", equip_file)
	
	while(read_file(equip_file, line, text, charsmax(text), textsize))
	{
		line++
		trim(text)
		
		if(text[0] == ';')
			continue
		
		parse(text, equip_name, charsmax(equip_name), equip_num, charsmax(equip_num))
		
		if(!str_to_num(equip_num))
			continue
		
		DispatchKeyValue(ent, equip_name , equip_num)
		
		if(line > 48)
			break
		
		equip_name = ""
		equip_num = ""
	}
	DispatchSpawn(ent)
}

// ===================================================================== SHOTGUN & CROWBAR POWER =========================

public fw_TraceAttack(victim, inflictor, Float:damage, Float:direction[3], traceresult, damagebits)
{
    if (!PLUGIN_ENABLED) 
        return HAM_IGNORED;

    static weapon
    static Float:hitpoint[3]
    static Float:vector[3]
    static Float:bloodstart[3]

    // Only call get_user_weapon if inflictor is a valid player
    if (1 <= inflictor <= g_MaxPlayers) {
        weapon = get_user_weapon(inflictor)

        if(weapon == HLW_SHOTGUN)
        {
            if (!g_enable_shotgun) return HAM_IGNORED;
            SetHamParamFloat(3, g_DamagePerShot)

            if(!get_pcvar_num(g_pcvar_shotgun_blod))
                return HAM_IGNORED

            get_tr2(traceresult, TR_vecEndPos, hitpoint)

            xs_vec_mul_scalar(direction, random_float(100.0, 400.0), vector)
            xs_vec_mul_scalar(direction, 50.0, bloodstart)
            xs_vec_add(hitpoint, bloodstart, bloodstart)

            message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
            write_byte(TE_BLOODSTREAM)
            write_coord(floatround(bloodstart[0]))
            write_coord(floatround(bloodstart[1]))
            write_coord(floatround(bloodstart[2]))
            write_coord(floatround(vector[0])) // x
            write_coord(floatround(vector[1])) // y
            write_coord(floatround(vector[2])) // z
            write_byte(70) // color
            write_byte(150) // speed
            message_end()
            return HAM_IGNORED
        }

        if(weapon == HLW_CROWBAR)        
        {
            if (!g_enable_crowbar) return HAM_IGNORED;
            SetHamParamFloat(3, g_DamageCrowbar)
        }
    }

    return HAM_IGNORED
}

public fw_TraceAttackWorld(victim, inflictor, Float:damage, Float:direction[3], traceresult, damagebits)
{
	if (!PLUGIN_ENABLED) return HAM_IGNORED;
	
	static Float:hitpoint[3]
	get_tr2(traceresult, TR_vecEndPos, hitpoint)
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_SPARKS)
	write_coord(floatround(hitpoint[0]))
	write_coord(floatround(hitpoint[1]))
	write_coord(floatround(hitpoint[2]))
	message_end()
	return HAM_HANDLED
}

// ===================================================================== GIBS ==================================

public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type)
{
	if (!PLUGIN_ENABLED || !g_enable_shotgun || damage < g_GibsDmg || !(1 <= inflictor <= g_MaxPlayers) || !get_pcvar_num(g_pcvar_shotgun_gibs))
		return HAM_IGNORED;
	
	if(get_user_weapon(inflictor) == HLW_SHOTGUN)
		SetHamParamInteger(5, DMG_ALWAYSGIB);
	
	return HAM_IGNORED;
}

// ===================================================================== SHOTGUN SPEED =========================

public Shotgun_PrimaryAttack_Pre (const shotgun)
{
	if (!PLUGIN_ENABLED || !g_enable_shotgun) return;
	new player = get_pdata_cbase(shotgun, m_pPlayer, LINUX_OFFSET_WEAPONS)
	g_OldClip[player] = get_pdata_int(shotgun, m_iClip, LINUX_OFFSET_WEAPONS)
}

public Shotgun_PrimaryAttack_Post (const shotgun)
{
	if (!PLUGIN_ENABLED || !g_enable_shotgun) return;
	new player = get_pdata_cbase(shotgun, m_pPlayer, LINUX_OFFSET_WEAPONS)
	
	if (g_OldClip[player] <= 0)
		return
	
	set_pdata_float(shotgun, m_flNextPrimaryAttack  , 0.6, LINUX_OFFSET_WEAPONS)
	set_pdata_float(shotgun, m_flNextSecondaryAttack, 0.6, LINUX_OFFSET_WEAPONS)
	
	if (get_pdata_int(shotgun, m_iClip, LINUX_OFFSET_WEAPONS) != 0)
		set_pdata_float(shotgun, m_flTimeWeaponIdle, 2.0, LINUX_OFFSET_WEAPONS)
	else
		set_pdata_float(shotgun, m_flTimeWeaponIdle, 0.3, LINUX_OFFSET_WEAPONS)
}

public Shotgun_SecondaryAttack_Pre (const shotgun)
{
	if (!PLUGIN_ENABLED || !g_enable_shotgun) return;
	new player = get_pdata_cbase(shotgun, m_pPlayer, LINUX_OFFSET_WEAPONS)
	g_OldClip[player] = get_pdata_int(shotgun, m_iClip, LINUX_OFFSET_WEAPONS)
}

public Shotgun_SecondaryAttack_Post (const shotgun)
{
	if (!PLUGIN_ENABLED || !g_enable_shotgun) return;
	new player = get_pdata_cbase(shotgun, m_pPlayer, LINUX_OFFSET_WEAPONS)
	
	if (g_OldClip[player] <= 1)
		return
	
	set_pdata_float(shotgun, m_flNextPrimaryAttack  , 0.4, LINUX_OFFSET_WEAPONS)
	set_pdata_float(shotgun, m_flNextSecondaryAttack, 0.8, LINUX_OFFSET_WEAPONS)
	
	if (get_pdata_int(shotgun, m_iClip, LINUX_OFFSET_WEAPONS) != 0)
		set_pdata_float(shotgun, m_flTimeWeaponIdle, 3.0, LINUX_OFFSET_WEAPONS)
	else
		set_pdata_float(shotgun, m_flTimeWeaponIdle, 0.85, LINUX_OFFSET_WEAPONS)
}

public Shotgun_Reload_Pre (const shotgun)
{
	if (!PLUGIN_ENABLED || !g_enable_shotgun) return;
	new player = get_pdata_cbase(shotgun, m_pPlayer, LINUX_OFFSET_WEAPONS)
	g_OldSpecialReload[player] = get_pdata_int(shotgun, m_fInSpecialReload, LINUX_OFFSET_WEAPONS)
}

public Shotgun_Reload_Post (const shotgun)
{
	if (!PLUGIN_ENABLED || !g_enable_shotgun) return;
	new player = get_pdata_cbase(shotgun, m_pPlayer, LINUX_OFFSET_WEAPONS)
	
	switch (g_OldSpecialReload[player])
	{
		case 0 :
		{
			if (get_pdata_int(shotgun, m_fInSpecialReload, LINUX_OFFSET_WEAPONS) == 1)
			{
				set_pdata_float( player , m_flNextAttack, 0.3 )
				set_pdata_float( shotgun, m_flTimeWeaponIdle     , 0.1, LINUX_OFFSET_WEAPONS)
				set_pdata_float( shotgun, m_flNextPrimaryAttack  , 0.4, LINUX_OFFSET_WEAPONS)
				set_pdata_float( shotgun, m_flNextSecondaryAttack, 0.5, LINUX_OFFSET_WEAPONS)
			}
		}
		case 1 :
		{
			if (get_pdata_int(shotgun, m_fInSpecialReload, LINUX_OFFSET_WEAPONS) == 2)
				set_pdata_float(shotgun, m_flTimeWeaponIdle, 0.1, LINUX_OFFSET_WEAPONS)
		}
	}
}

// ===================================================================== CROSSBOW SPEED ========================

public Crossbow_PrimaryAttack_Post (const crossbow)
{
	if (!PLUGIN_ENABLED || !g_enable_crossbow) return;
	set_pdata_float(crossbow, m_flNextPrimaryAttack  , 0.4, LINUX_OFFSET_WEAPONS)
}

public Crossbow_SecondaryAttack_Post(const crossbow)
{
	if (!PLUGIN_ENABLED || !g_enable_crossbow) return;
	set_pdata_float(crossbow, m_flNextSecondaryAttack, 0.5, LINUX_OFFSET_WEAPONS)
}

public Crossbow_Reload_Post (const crossbow)
{
	if (!PLUGIN_ENABLED || !g_enable_crossbow) return;
	new player = get_pdata_cbase(crossbow, m_pPlayer, LINUX_OFFSET_WEAPONS)
	
	set_pdata_float(player , m_flNextAttack, 2.0)
	set_pdata_float(crossbow, m_flTimeWeaponIdle	 , 2.9, LINUX_OFFSET_WEAPONS)
	set_pdata_float(crossbow, m_flNextPrimaryAttack  , 2.1, LINUX_OFFSET_WEAPONS)
	set_pdata_float(crossbow, m_flNextSecondaryAttack, 2.1, LINUX_OFFSET_WEAPONS)
}

// ===================================================================== SNARK MODEL & SOUND ===================

public  fwd_EmitSound(ent, channel, sample[], Float:volume, Float:attn, flags, pitch) 
{
	if (!PLUGIN_ENABLED) return FMRES_IGNORED;
	if(g_BlockSound)
		return FMRES_SUPERCEDE
	
	new classname[32]
	pev(ent, pev_classname, classname, 31)
	
	if(equal(classname, "monster_tripmine")  &&  equal(sample, "weapons/mine_activate.wav"))
	{
		TripMine_Beam(ent)
		return FMRES_HANDLED
	}
	
	if(!get_pcvar_num(g_pcvar_snark_style) || !equal(classname, "monster_snark") || !g_enable_snark)
		return FMRES_IGNORED
	
	replace (sample, 64, "squeek/sqk_hunt", "gonarch/gon_alert") 
	
	emit_sound(ent, channel, sample, volume, attn, 0, pitch)
	return FMRES_SUPERCEDE
}

public fwd_SetModel(ent, model[])
{	
	if (!PLUGIN_ENABLED) return FMRES_IGNORED;
	if(get_pcvar_num(g_pcvar_snark_style) && equal(model, "models/w_squeak.mdl") && g_enable_snark)
	{
		engfunc(EngFunc_SetModel, ent, "models/chumtoad.mdl")
		return FMRES_SUPERCEDE
	}
	return FMRES_IGNORED
}

// ===================================================================== SNARK INTERVAL ========================

public Snark_PrimaryAttack_Post(weapon)
{
	if (!PLUGIN_ENABLED || !g_enable_snark) return;
	set_pdata_float(weapon, m_flNextPrimaryAttack, g_SnarkThrowInterval, LINUX_OFFSET_WEAPONS)
}

// ===================================================================== SNARK TELEPORT ========================

public Snark_SecondaryAttack_Post(id)
{
	if (!PLUGIN_ENABLED || !g_enable_snark) return;
	new spawnId
	new Float:origin[3]
	new Float:angles[3]
	new player = pev(id, pev_owner)
	
	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "cycler_sprite"))
	
	set_pev(ent, pev_rendermode, kRenderTransAdd)
	engfunc(EngFunc_SetModel, ent, "sprites/b-tele1.spr")
	
	set_pev(ent, pev_renderamt, 255.0)
	set_pev(ent, pev_animtime, 1.0)
	set_pev(ent, pev_framerate, 50.0)
	set_pev(ent, pev_frame, 10)
	
	pev(player, pev_origin, origin)
	
	set_pev(ent,  pev_origin, origin)
	dllfunc(DLLFunc_Spawn, ent)
	set_pev(ent, pev_solid, SOLID_NOT)
	
	emit_sound(ent, CHAN_AUTO, "debris/beamstart4.wav", 0.8, ATTN_NORM, 0, PITCH_NORM)
	
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_DLIGHT)
	write_coord(floatround(origin[0]))
	write_coord(floatround(origin[1]))
	write_coord(floatround(origin[2]))
	write_byte(35)
	write_byte(80)
	write_byte(255)
	write_byte(100)
	write_byte(80)
	write_byte(60)
	message_end()
	
	spawnId = g_SpawnsId[random_num(0, strlen(g_SpawnsId) - 1)]
	
	pev(spawnId, pev_origin, origin)
	pev(spawnId, pev_angles, angles)
	
	set_pev(player, pev_origin, origin)
	set_pev(player, pev_angles, angles)
	set_pev(player, pev_fixangle, 1)
	set_pev(player, pev_velocity, {0.0, 0.0, 0.0})
	
	emit_sound(player, CHAN_AUTO, "debris/beamstart4.wav", 0.5, ATTN_NORM, 0, PITCH_NORM)
	
	message_begin(MSG_ONE, get_user_msgid("ScreenFade"), {0,0,0}, player)
	write_short(1<<10) 
	write_short(1<<3)
	write_short(0)
	write_byte(100)
	write_byte(255)
	write_byte(100)
	write_byte(150)
	message_end()	
	
	set_pdata_float(id, m_flNextSecondaryAttack, 60.0, LINUX_OFFSET_WEAPONS)
	set_task(0.5, "remove_telesprite_task", ent + 33453)
}

public remove_telesprite_task(ent)
{
	ent -= 33453
	if(pev_valid(ent))
		engfunc(EngFunc_RemoveEntity, ent)
}

// ===================================================================== GRENADE SECONDARY =====================

public Grenade_SecondaryAttack_Pre(weapon)
{
	if (!PLUGIN_ENABLED || !g_enable_grenade) return HAM_SUPERCEDE;
	new player = pev(weapon, pev_owner);
	
	// Синхронізуємо альтернативний лічильник з m_rgAmmo
	new ammo = get_pdata_int(player, m_rgAmmo + iHandGrenadeAmmoIndex, LINUX_OFFSET_AMMO);
	if (g_grenade_alt_counter[player] != ammo)
		g_grenade_alt_counter[player] = ammo;
	
	if (g_grenade_alt_counter[player] <= 0)
		return HAM_SUPERCEDE;
	
	new g_GrenadeSounds[2][48] = {"weapons/glauncher.wav", "weapons/glauncher2.wav"};
	
	new Float:origin[3];
	new Float:velocity[3];
	new Float:avelocity[3];
	new Float:v_ofs[3];
	new Float:angles[3];
	
	// Зменшуємо обидва лічильники!
	g_grenade_alt_counter[player]--;
	set_pdata_int(player, m_rgAmmo + iHandGrenadeAmmoIndex, g_grenade_alt_counter[player], LINUX_OFFSET_AMMO);
	
	new ent = engfunc(EngFunc_CreateNamedEntity, g_GrenadeAllocString);
	
	pev(player, pev_origin, origin);
	pev(player, pev_view_ofs, v_ofs);
	pev(player, pev_angles, angles);
	
	origin[0] += v_ofs[0];
	origin[1] += v_ofs[1];
	origin[2] += v_ofs[2];
	
	velocity_by_aim(player, 800, velocity);
	
	avelocity[0] = random_float(-500.0, 100.0);
	avelocity[2] = random_float(-100.0, 100.0);
	
	set_pev(ent, pev_avelocity, avelocity);
	set_pev(ent, pev_origin, origin);
	set_pev(ent, pev_angles, angles);
	set_pev(ent, pev_owner, player);
	set_pev(ent, pev_gravity, 0.5);
	set_pev(ent, pev_velocity, velocity);
	
	dllfunc(DLLFunc_Spawn, ent);
	set_pev(ent, pev_takedamage, DAMAGE_YES);
	set_pev(ent, pev_health, 100.0);
	engfunc(EngFunc_SetModel, ent, "models/w_grenade.mdl");
	
	UTIL_PlayWeaponAnimation(player, 5);
	
	if (g_grenade_alt_counter[player] > 0)
		set_task(1.0, "grenade_draw_anim", player + 4454);
	
	emit_sound(ent, CHAN_WEAPON, g_GrenadeSounds[random_num(0, 1)], 1.0, ATTN_NORM, 0, PITCH_NORM);
	return HAM_HANDLED;
}

public Grenade_SecondaryAttack_Post(weapon)
{
	if (!PLUGIN_ENABLED || !g_enable_grenade) return;
	set_pdata_float (weapon, m_flNextSecondaryAttack, 5.0, LINUX_OFFSET_WEAPONS)
}

public grenade_draw_anim(player)
{
	if (!PLUGIN_ENABLED || !g_enable_grenade) return;
	player -= 4454
	if(get_user_weapon(player) == HLW_HANDGRENADE)
		UTIL_PlayWeaponAnimation(player, 7)
}

public Grenade_Pickup(player)
{
	g_grenade_alt_counter[player] = get_pdata_int(player, m_rgAmmo + iHandGrenadeAmmoIndex, LINUX_OFFSET_AMMO)
}

public Grenade_Touch(ent)
{
	if (!PLUGIN_ENABLED || !g_enable_grenade) return;
	ExecuteHam(Ham_TakeDamage, ent, 0, 0, 1000.0, 0)
}

public Grenade_PrimaryAttack_Post(weapon)
{
	if (!PLUGIN_ENABLED || !g_enable_grenade) return;
	set_pdata_float (weapon, m_flNextSecondaryAttack, 1.0, LINUX_OFFSET_WEAPONS)
}

// ===================================================================== CROWBAR SECONDARY =====================	

public Crowbar_SecondaryAttack_Post(weapon)
{
	if (!PLUGIN_ENABLED || !g_enable_crowbar) return;
	new player = pev(weapon, pev_owner)
	set_pdata_float (weapon, m_flNextSecondaryAttack, 2.0, LINUX_OFFSET_WEAPONS)
	emit_sound(player, CHAN_VOICE, g_CrowbarSounds[random_num(0,1)], 1.0, ATTN_NORM, 0, PITCH_NORM)
}

// ===================================================================== HORNET COLOR ==========================	

public msg_TempEntity()
{
	if (!PLUGIN_ENABLED) return PLUGIN_CONTINUE;
	static r
	static g
	static b
	static _max
	static Float:multiplier
	static classname[32]
	
	if(!get_pcvar_num(g_pcvar_hornet_style) || get_msg_arg_int(1) != TE_BEAMFOLLOW)
		return PLUGIN_CONTINUE
	
	pev(get_msg_arg_int(2), pev_classname, classname, 31)
	
	if(!equal(classname, "hornet"))
		return PLUGIN_CONTINUE
	
	r = random_num(0, 255)
	g = random_num(0, 255)
	b = random_num(0, 255)
	
	_max = max(r, max(g, b))
	
	if(_max < 255)
	{
		multiplier = 255.0 / _max
		r =  floatround(r * multiplier)
		g =  floatround(g * multiplier)
		b =  floatround(b * multiplier)
	}
	
	set_msg_arg_int(4, ARG_BYTE, g_HornetTrailTime)
	set_msg_arg_int(6, ARG_BYTE, r)
	set_msg_arg_int(7, ARG_BYTE, g)
	set_msg_arg_int(8, ARG_BYTE, b)
	set_msg_arg_int(9, ARG_BYTE, 200)
	return PLUGIN_CONTINUE
}

// ===================================================================== TRIPMINE SECONDARY ====================	

public TripminePrimaryAttack_Pre(weapon)
{
    // Тепер тільки перевірка на PLUGIN_ENABLED
    if (!PLUGIN_ENABLED) {
        // Reset the weapon state when disabled
        new player = pev(weapon, pev_owner);
        set_pdata_float(weapon, m_flNextPrimaryAttack, 0.5, LINUX_OFFSET_WEAPONS);
        set_pdata_float(weapon, m_flNextSecondaryAttack, 0.5, LINUX_OFFSET_WEAPONS);
        g_LastTripmineAttack[player] = 0;
        return HAM_SUPERCEDE;
    }
    
    new player = pev(weapon, pev_owner);
    g_LastTripmineAttack[player] = 1;
    return HAM_HANDLED;
}   

public Tripmine_SecondaryAttack_Pre(weapon)
{
    // Тут залишаємо перевірку на g_enable_tripmine
    if (!PLUGIN_ENABLED || !get_pcvar_num(g_pcvar_tripmine_style) || !g_enable_tripmine) {
        // Reset the weapon state when disabled
        new player = pev(weapon, pev_owner);
        set_pdata_float(weapon, m_flNextPrimaryAttack, 0.5, LINUX_OFFSET_WEAPONS);
        set_pdata_float(weapon, m_flNextSecondaryAttack, 0.5, LINUX_OFFSET_WEAPONS);
        g_LastTripmineAttack[player] = 0;
        return HAM_SUPERCEDE;
    }
    
    new player = pev(weapon, pev_owner);
    g_LastTripmineAttack[player] = 2;
    ExecuteHam(Ham_Weapon_PrimaryAttack, weapon);
    set_pdata_float(weapon, m_flNextSecondaryAttack, 0.3, LINUX_OFFSET_WEAPONS);
    return HAM_SUPERCEDE;
}

public TripMine_Spawn_Post(tripmine)
{
	if (!PLUGIN_ENABLED || !g_enable_tripmine) return;
	new player = pev(tripmine, pev_owner)
	if(g_LastTripmineAttack[player] == 2)
	{
		set_pev(tripmine, pev_iuser4, player)
		UTIL_PlayWeaponAnimation (player, 6)
	}	
}

public TripMine_Beam(tripmine)
{
	if (!PLUGIN_ENABLED || !get_pcvar_num(g_pcvar_tripmine_style) || !g_enable_tripmine)
		return HAM_IGNORED
	
	new player = pev(tripmine, pev_iuser4)
	new beam = get_pdata_cbase(tripmine, m_pBeam, 5)
	
	if(player)
	{
		set_pev(beam, pev_body, 30)
		set_pev(tripmine, pev_dmg, 225.0) // 150% damage
	}
	else
		set_pev(beam, pev_body, 2)
	
	set_pev(beam, pev_renderamt, 100.0)
	set_pev(beam, pev_scale, 10.0)
	
	TripMine_Think_Post(tripmine)
	return false
}

public TripMine_Think_Post(tripmine)
{
	if (!PLUGIN_ENABLED || !get_pcvar_num(g_pcvar_tripmine_style) || !pev_valid(tripmine) || !g_enable_tripmine)
		return HAM_IGNORED
	
	static Float:color_time
	
	pev(tripmine, pev_fuser1, color_time)
	
	if(color_time < get_gametime())
	{
		new Float:rgb[3]
		new beam = get_pdata_cbase(tripmine, m_pBeam, 5)
		
		if(!pev_valid(beam))
			return HAM_IGNORED
		
		rgb[0] = random_float(0.0, 255.0)
		rgb[1] = random_float(0.0, 255.0)
		rgb[2] = random_float(0.0, 255.0)
		
		set_pev(beam, pev_animtime, random_float(100.0, 255.0))
		set_pev(beam, pev_rendercolor, rgb)
		set_pev(tripmine, pev_fuser1, get_gametime() + random_float(3.0, 20.0))
	}
	return HAM_IGNORED
}

// ===================================================================== SPAWN PROTECT & SPAWN SOUND ===========		

public Player_Spawn_Pre(player)
{
	if (!PLUGIN_ENABLED) return;
	g_BlockSound = 1
}

public Player_Spawn_Post(player)
{
	if (!PLUGIN_ENABLED) return;
	const Float:opacity = 128.0
	new Float:sp_time = get_pcvar_float(g_pcvar_spawnprotect_time)
	g_BlockSound = 0	
	
	emit_sound(player, CHAN_AUTO, "items/gunpickup2.wav", 0.8, ATTN_NORM, 0, PITCH_NORM)
	
	// Синхронізуємо альтернативний лічильник з m_rgAmmo
	g_grenade_alt_counter[player] = get_pdata_int(player, m_rgAmmo + iHandGrenadeAmmoIndex, LINUX_OFFSET_AMMO)
	
	if(sp_time > 0)
	{
		set_pev(player, pev_takedamage, DAMAGE_NO)
		set_pev(player, pev_rendermode, kRenderTransAlpha)
		set_pev(player, pev_renderamt, opacity)
		set_task(sp_time, "unset_spawn_protection", player + 8712)
	}
}


public unset_spawn_protection(player)
{
	if (!PLUGIN_ENABLED) return;
	player -= 8712
	if(pev_valid(player))
	{
		set_pev(player, pev_takedamage, DAMAGE_AIM)
		set_pev(player, pev_rendermode, kRenderNormal)
		set_pev(player, pev_renderamt, 16.0)
	}
}

// ===================================================================== PLAYER INFO ===========================

public msg_StatusValue(iMsgID, iDest, iClient)
{
	if (!PLUGIN_ENABLED) return PLUGIN_CONTINUE;
	if(!get_pcvar_num(g_pcvar_status_style))
		return PLUGIN_CONTINUE
	
	if(get_pcvar_num(g_pcvar_status_style) == 2 && !is_user_admin(iClient))
		return PLUGIN_HANDLED
	
	static value, status[2]
	
	value = get_msg_arg_int(2)
	
	if(value && get_msg_arg_int(1) == 1)
	{
		status[0] = iClient
		status[1] = value
		show_status(status)
	}
	return PLUGIN_HANDLED
}

public show_status(status[])
{
	if (!PLUGIN_ENABLED) return;
	const 	Float:x = -1.0
	const 	Float:y = 0.55
	
	const 	r = 180
	const 	g = 180
	const 	b = 255
	
	new 	id
	new 	body
	new 	name[32]
	new		model[32]
	
	get_user_name(status[1], name, 31)
	get_user_info(status[1], "model", model, 31)
	
	get_user_aiming(status[0], id, body)
	
	if(id != status[1])
		return
	
	set_hudmessage(r, g, b, x, y, 0, 0.0, 0.8, 0.1, 0.5, -1)
	ShowSyncHudMsg(status[0], g_HudSyncObj, "%s^n(%s)", name, model)
	set_task(1.5 , "show_status" , status[0] + 4090 , status , 3)
}

// ===================================================================== FLASHLIGHT ============================

public msg_FlashLight(msg_id, msg_dest, player)
{
	if (!PLUGIN_ENABLED) return PLUGIN_CONTINUE;
	if(!get_pcvar_num(g_pcvar_flashlight_style))
		return PLUGIN_CONTINUE
	
	if(get_msg_arg_int(1))
		set_pev(player, pev_effects, pev(player, pev_effects) | EF_BRIGHTLIGHT)						
	else 
		set_pev(player, pev_effects, pev(player, pev_effects) & ~EF_BRIGHTLIGHT)
	return PLUGIN_CONTINUE
}

// ===================================================================== DEATH INFO ============================

public Player_Death_Post(player)
{
	if (!PLUGIN_ENABLED) return;
	if(!get_pcvar_num(g_pcvar_death_info))
		return
	
	new mapname[32]
	new message[128]
	new time_left[32]
	
	new fraglimit = get_pcvar_num(g_pcvar_fraglimit)
	new timelimit = get_pcvar_num(g_pcvar_timelimit)
	
	g_grenade_alt_counter[player] = get_pdata_int(player, m_rgAmmo + iHandGrenadeAmmoIndex, LINUX_OFFSET_AMMO)
	
	get_mapname(mapname, 31)
	format_time(time_left, 31, "%M min %S sec", get_timeleft())
	
	if(!fraglimit && !timelimit)
		formatex(message, 127, "Map '%s' no time limit", mapname)
	else if(!fraglimit && timelimit)
		formatex(message, 127, "Map '%s' for %d minutes (%s left)", mapname , timelimit, time_left)
	else if(fraglimit && !timelimit)
		formatex(message, 127, "Map '%s' no time limit (%d frags left)", get_fragsleft())
	else
		formatex(message, 127, "Map '%s' for %d minutes (%s or %d frags left)", mapname , timelimit, time_left, get_fragsleft())
	
	set_hudmessage(255, 128, 50, -1.0, 0.6, 0, 2.0, 8.0, 0.1, 1.5, 4) 
	show_hudmessage(player, "Running Severian's AMXX Mod v.%s by LetiLetiLepestok^n^n^n%s", VERSION, message) 
}

public get_fragsleft()
{
	if (!PLUGIN_ENABLED) return 0;
	new i
	new frags
	new frags_max = -32767
	
	for(i = 1; i <= g_MaxPlayers; i++)
	{
		if(is_user_connected(i))
		{
			frags = get_user_frags(i)
			if(frags > frags_max)
				frags_max = frags
		}
	}
	return clamp(get_pcvar_num(g_pcvar_fraglimit) - frags_max, 0)
}

// ===================================================================== GAME DESCRIPTION ======================

public fwd_GetGameDescription()
{ 
	if (!PLUGIN_ENABLED) return FMRES_IGNORED;
	forward_return(FMV_STRING, GAME_DESCRIPTION)
	return FMRES_SUPERCEDE
}

// ===================================================================== STOCKS ================================	

stock UTIL_PlayWeaponAnimation (const Player, const Sequence)
{
	set_pev (Player, pev_weaponanim, Sequence)
	
	message_begin (MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, .player = Player)
	write_byte(Sequence)
	write_byte(0)
	message_end()
}

//================================================== GAUSS AMMO ================================================

public Gauss_Attack_Post(iItem) {
	if (!PLUGIN_ENABLED || !g_enable_gauss_ammo) return HAM_IGNORED;
	if (!pev_valid(iItem)) return HAM_IGNORED
	
	new id = get_pdata_cbase(iItem, m_pPlayer, LINUX_OFFSET_WEAPONS)
	if (!is_user_alive(id)) return HAM_IGNORED
	
	set_pdata_int(id, m_rgAmmo + iUraniumAmmoIndex, MAX_GAUSS_AMMO, LINUX_OFFSET_AMMO)
	
	return HAM_IGNORED
}

