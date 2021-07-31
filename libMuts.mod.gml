/*	                
	This is the Muts package of Lib, for
	functions that help with making mutations
*/

/*
	Scripts:
		#define skill_get_category(mut)
		#define skill_get_avail(_mut)
		#define get_skills(is_avail)
		#define get_ultras
		#define skill_decide
		#define skill_get_image(_mut)
		#define skill_get_icon(_mut)
		#define skill_is_ultra(_mut)
*/

//For internal use, adds the script to be easily usable.
#define addScript(name)
	var ref = mod_variable_get("mod", "lib", "scriptReferences");
	lq_set(ref, name, ["mod", mod_current, name]);
	mod_variable_set("mod", "lib", "scriptReferences", ref);

#define init
	addScript("skill_get_category");
	addScript("skill_get_avail");
	addScript("get_skills");
	addScript("get_ultras");
	addScript("skill_decide");
	addScript("skill_get_image");
	addScript("skill_get_icon");
	addScript("skill_is_ultra");
	script_ref_call(["mod", "lib", "updateRef"]);
	
	//Mutation categories, donated by wildebee from metamorphosis
	global.mut_categories = {
		offensive: [mut_gamma_guts, mut_scarier_face, mut_long_arms, mut_shotgun_shoulders, mut_laser_brain, mut_eagle_eyes, mut_impact_wrists, mut_bolt_marrow, mut_stress, mut_trigger_fingers, mut_sharp_teeth],
		defensive: [mut_rhino_skin, mut_bloodlust, mut_second_stomach, mut_boiling_veins, mut_strong_spirit],
		utility: [mut_extra_feet, mut_plutonium_hunger, mut_throne_butt, mut_euphoria, mut_last_wish, mut_patience, mut_hammerhead, mut_heavy_heart],
		ammo: [mut_rabbit_paw, mut_lucky_shot, mut_back_muscle, mut_recycle_gland, mut_open_mind]
	}

#define skill_get_category(mut)
	if(is_string(mut) and mod_script_call("skill", mut, "skill_type") != undefined) {
		return string_lower(mod_script_call("skill", mut, "skill_type"));
	}else if(is_string(mut) and skill_is_ultra(mut)){
		return "ultra";
	}else for(var i = 0; i < lq_size(global.mut_categories); i++) {
		if(is_array(lq_get_value(global.mut_categories, i))){
			var length = array_length(lq_get_value(global.mut_categories, i));
			for(var i2 = 0; i2 < length; i2++) {
				if(array_find_index(lq_get_value(global.mut_categories, i), mut) != -1) {
					return lq_get_key(global.mut_categories, i);
				}
			}
		}
	}
	//if it can't find a category for the mut it returns -1
	return -1;

#define skill_get_avail(_mut)
/* Creator: Golden Epsilon
Description: 
	Checks to see if the given mutation can be picked at random.
	Can take either a vanilla mutation (number) or a modded mutation (string)
	Can also take an array, returns false if any of the mutations are not available.
*/

if(is_array(_mut)){
	with(_mut){
		if(!skill_get_avail(self)){
			return false;
		}
	}
	return true;
}
if(is_real(_mut)){
	return !skill_get(_mut) && skill_get_active(_mut);
}
if(is_string(_mut)){
	var avail = true;
	if(!mod_exists("skill", _mut)){
		avail = false;
	}else if(mod_script_exists("skill", _mut, "skill_avail") && !mod_script_call("skill", _mut, "skill_avail")){
		avail = false;
	}
	return avail && !skill_get(_mut) && skill_get_active(_mut);
}
return false;

#define get_skills(is_avail)
/* Creator: Golden Epsilon
Description: 
	Returns all mutations that exist.
	if is_avail is true, only returns mutations that can be chosen by the game.
*/

var allskills=[]
var modskills = mod_get_names("skill");
for (var i = 1; i <= 29; i += 1){
	if(is_avail){
		if(skill_get_avail(i)){
			array_push(allskills,i);
		}
	}else{
		array_push(allskills,i);
	}
}
for(i = 0; i < array_length_1d(modskills); i++){
	if(mod_exists("skill", modskills[i])){
		if(mod_script_exists("skill", modskills[i], "skill_ultra")){
			var ult = mod_script_call("skill", modskills[i], "skill_ultra");
			if(is_string(ult) && (mod_exists("race", ult) || string_count(string_lower(ult), "fish crystal eyes melting plant venuz steroids robot chicken rebel horror rogue skeleton frog")) || is_real(ult) && ult != -1){
				continue;
			}
		}
		if(is_avail){
			if(skill_get_avail(modskills[i])){
				array_push(allskills,modskills[i]);
			}
		}else{
			array_push(allskills,modskills[i]);
		}
	}
}
return allskills;

#define get_ultras
/* Creator: Golden Epsilon
Description: 
	Returns all ultras that exist.
	Vanilla mutations give their index, 
	modded mutations give either the name of the ultra mutation (cultras)
	or an array with the info related to the custom characters' ultra
*/

var ultraskills=[]
var modskills = mod_get_names("skill");
for(var i = char_fish; i <= char_frog; i++){
	for(var i2 = 1; i2 <= ultra_count(i); i2++){
		array_push(ultraskills, i*3+i2-4);
	}
}
with(mod_get_names("race")){
	var num = 1;
	while(mod_script_call("race", self, "race_ultra_name", num) != "" && mod_script_call("race", self, "race_ultra_name", num) != 0){
		array_push(ultraskills,[self, num, mod_script_call("race", self, "race_ultra_name", num), mod_script_call("race", self, "race_ultra_text", num)]);
		num++;
	}
}
for(i = 0; i < array_length_1d(modskills); i++){
	if(mod_exists("skill", modskills[i])){
		if(mod_script_exists("skill", modskills[i], "skill_ultra")){
			var ult = mod_script_call("skill", modskills[i], "skill_ultra");
			if(is_string(ult) && (mod_exists("race", ult) || string_count(string_lower(ult), "fish crystal eyes melting plant venuz steroids robot chicken rebel horror rogue skeleton frog")) || is_real(ult) && ult != -1){
				array_push(ultraskills,modskills[i]);
			}
		}
	}
}
return ultraskills;

#define skill_decide
/* Creator: Golden Epsilon
Description: 
	Returns a mutation out of the pool.
*/

var skills = get_skills(true);
return skills[irandom(array_length(skills) - 1)];

#define skill_get_image(_mut)
/* Creator: Golden Epsilon
Description: 
	Takes _mut as an input (number or string)
	Returns the button image for a mutation and image index in an array
	([sprite_index, image_index])
	Just for mutations, does not work with ultras
Usage:
	var temp = script_ref_call(["mod", "libMuts", "skill_get_image"], 5);
	draw_sprite(temp[0], temp[1], x, y);
*/

var retVal = [sprSkillIcon, 0];
//Using Effect to not mess with Update
with(instance_create(0,0,Effect)){
	if(is_real(_mut)){
			retVal = [sprSkillIcon, _mut]
	}else{
		sprite_index=sprSkillIcon;
		with(GameCont){t_mutindex = mutindex;}
		mod_script_call("skill",_mut,"skill_button")
		with(GameCont){mutindex = t_mutindex;}
		var retVal = [sprite_index, image_index];
	}
	instance_destroy();
}
return retVal;

#define skill_get_icon(_mut)
	/*
		Returns an array containing the [sprite_index, image_index] of a mutation's HUD icon
	*/
	
	if(is_real(_skill)){
		return [sprSkillIconHUD, _skill];
	}
	
	if(is_string(_skill) && mod_script_exists("skill", _skill, "skill_icon")){
		return [mod_script_call("skill", _skill, "skill_icon"), 0];
	}
	
	return [sprEGIconHUD, 2];

#define skill_is_ultra(_mut)
//returns whether the mut passed in is an ultra
if(is_real(_mut)){
	for(var i = char_fish; i <= char_frog; i++){
		for(var i2 = 1; i2 <= ultra_count(i); i2++){
			if(_mut == i*3+i2-4){
				return true;
			}
		}
	}
	return false;
}
if(mod_script_exists("skill", _mut, "skill_ultra")){
	var ult = mod_script_call("skill", _mut, "skill_ultra");
	if(is_string(ult) && (mod_exists("race", ult) || string_count(string_lower(ult), "fish crystal eyes melting plant venuz steroids robot chicken rebel horror rogue skeleton frog")) || is_real(ult) && ult != -1){
		return true;
	}
}
return false;