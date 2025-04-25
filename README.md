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
    * Infinite ammo for gauss

If you want to enable or disable some improvements add the next text to the cvars.ini        Or change sev.ini
"sev_mod"			          "0" "1"			             "u"   -disable/enable plugin
"sev_flashlight_style"  "0" "1"                  "u"   -classsic/severian flashlight
"sev_snark_style"       "0" "1"                  "u"   -classic/severian snark
"sev_status_style"      "0" "1" "2"              "u"   -classic/severian/disabled status when player aim
"sev_hornet_style"      "0" "1"                  "u"   -classic/severian colored hornets
"sev_tripmine_style"    "0" "1"                  "u"   -classic/severian tripmine
"sev_death_info"        "0" "1"                  "u"   -disable/enable hud messeage after death
"sev_sp_time"           "0" "0.5" "1.0" "2.0"    "u"   -Spawn protection time in seconds.
"sev_remove_map_equip"  "0" "1"                  "u"   -Remove in map spawn equipment
"sev_shotgun_gibs"      "0" "1"                  "u"   -Make gibs if damage for shotgun exeeds 180 pts.
"sev_shotgun_bloodspray""0" "1"                  "u"   -Make blood spray bigger
