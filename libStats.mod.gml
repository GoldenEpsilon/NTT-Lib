/*	                 Stats
	This is the Stats package of Lib, for any and
	all modifications of player stats.
*/

/*
	Scripts:
		#define heal(obj, amount)
		#define changeHP(player, amount)
		#define changeAccuracy(player, amount)
		#define changeSpeed(player, amount)
*/

//For internal use, adds the script to be easily usable.
#define addScript(name)
	var ref = mod_variable_get("mod", "lib", "scriptReferences");
	lq_set(ref, name, ["mod", mod_current, name]);
	mod_variable_set("mod", "lib", "scriptReferences", ref);

#define init
	addScript("heal");
	addScript("changeHP");
	addScript("changeAccuracy");
	addScript("changeSpeed");
	script_ref_call(["mod", "lib", "updateRef"]);

#define heal(obj, amount)
/* Creator: Golden Epsilon
Description: 
	Heals a hitme by the amount.
	Does not heal past the hitme's Max HP.
Usage:
	with(Player) {
		script_ref_call(["mod", "libStats", "heal"], self, 4);
	}
*/
obj.my_health = min(obj.my_health + amount, obj.maxhealth);

#define changeHP(player, amount)
/* Creator: Golden Epsilon
Description: 
	Changes a player's Maximum HP by the amount.
	Heals the player if Max HP increases, cannot kill by removing max HP.
Usage:
	with(Player) {
		script_ref_call(["mod", "libStats", "changeHP"], self, 4);
	}
*/
player.maxhealth += amount;
player.maxhealth = max(player.maxhealth, 1);
player.my_health = min(player.my_health, player.maxhealth);

#define changeAccuracy(player, amount)
/* Creator: Golden Epsilon
Description: 
	Changes a player's Accuracy by the amount.
	A value of 0.5 means the player has double the accuracy.
	A value of 2 means the player has half the accuracy.
Usage:
	with(Player) {
		script_ref_call(["mod", "libStats", "changeAccuracy"], self, 2);
	}
*/
player.accuracy *= amount;

#define changeSpeed(player, amount)
/* Creator: Golden Epsilon
Description: 
	Changes a player's Speed by the amount.
	Speed is limited to between 0.1 and 25 for being reasonable.
	(Does not clamp speed if the player already has max speed faster or slower)
	NOTE: 25 can still clip the player out of bounds just by walking around.
Usage:
	with(Player) {
		script_ref_call(["mod", "libStats", "changeAccuracy"], self, 2);
	}
*/
if(player.maxspeed > 0.1 && player.maxspeed < 25){
	player.maxspeed += amount;
	player.maxspeed = min(max(player.maxspeed, 0.1), 25);
}