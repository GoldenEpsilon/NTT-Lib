/*	                Stats
	This is the Stats package of Lib, for any and
	all modifications of player stats.
	Because this is relatively basic, this is also
	essentially the example module.
*/

#define changeHP(player, amount)
/* Creator: Golden Epsilon
Description: 
	Changes a player's Maximum HP by the amount.
	Heals the player if Max HP increases, cannot kill by removing max HP.
Usage:
	with(Player) {
		script_call(["mod", "libStats", "changeHP"], self, 4);
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
		script_call(["mod", "libStats", "changeAccuracy"], self, 2);
	}
*/
player.accuracy *= amount;