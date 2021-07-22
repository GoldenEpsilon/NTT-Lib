/*	                Unlocks
	This is the Unlocks package of Lib, for
	various things to lock and unlock!
*/

/*
||||||||||||||||||||||||UNFINISHED PACKAGE||||||||||||||||||||||||||||
*/

/*
	Scripts:
*/

//For internal use, adds the script to be easily usable.
#define addScript(name)
	var ref = mod_variable_get("mod", "lib", "scriptReferences");
	lq_set(ref, name, ["mod", mod_current, name]);
	mod_variable_set("mod", "lib", "scriptReferences", ref);

#define init
	addScript("");
	script_ref_call(["mod", "lib", "updateRef"]);
	
#define unlock_get(_name)
	return mod_script_call_nc("mod", "teassets", "unlock_get", _name);
	
#define unlock_set(_name, _value)
	return mod_script_call_nc("mod", "teassets", "unlock_set", _name, _value);
	
#define unlock_get_name(_name)
	/*
		Returns the title associated with a given unlock's corner splat
	*/
	
	var _split = string_split(_name, ":");
	
	if(array_length(_split) >= 2){
		switch(_split[0]){
			
			case "pack": // PACK
				
				var _pack = _split[1];
				
				switch(_pack){
					case "coast"  : return "BEACH GUNS";
					case "oasis"  : return "BUBBLE GUNS";
					case "trench" : return "TECH GUNS";
					case "lair"   : return "SAWBLADE GUNS";
					case "red"    : return `@3(${spr.RedText}:-0.8) GUNS`;
					case "crown"  : return "CROWNS";
				}
					
				return _pack;
				
			case "race": // CHARACTER
				
				return race_get_title(_split[1]);
				
			case "skin": // SKIN
				
				var	_race = "",
					_skin = _split[1];
					
				 // Race Mod:
				if(array_length(_split) > 2){
					_race = _skin;
					_skin = real(_split[2]);
				}
				
				 // Skin Mod:
				else if(mod_exists("skin", _skin)){
					_race = mod_script_call("skin", _skin, "skin_race");
				}
				
				 // Get Unlock Name:
				var _skinName = string_upper(skin_get_name(_race, _skin));
				if(string_delete(_skinName, 1, string_length(_skinName) - 5) == " SKIN"){
					_skinName = race_get_title(_race) + " " + _skinName;
				}
				else{
					_skinName = _skinName + " " + race_get_title(_race);
				}
				
				return _skinName;
				
			case "wep": // WEAPON
				
				return weapon_get_name(_split[1]);
				
			case "crown": // CROWN
				
				return crown_get_name(_split[1]);
				
			case "loadout": // LOADOUT
				
				switch(_split[1]){
					
					case "wep":
						
						return weapon_get_name(unlock_get(_name));
						
					case "crown":
						
						if(array_length(_split) > 2){
							return crown_get_name(_split[2]) + "@s";
						}
						
						break;
						
				}
				
				break;
				
		}
	}
	
	return "";
	
#define unlock_get_text(_name)
	/*
		Returns the description associated with a given unlock's corner splat
	*/
	
	var _split = string_split(_name, ":");
	
	if(array_length(_split) >= 2){
		switch(_split[0]){
			
			case "pack": // PACK
				
				switch(_split[1]){
					case "coast"  : return "GRAB YOUR FRIENDS";
					case "oasis"  : return "SOAP AND WATER";
					case "trench" : return "TERRORS FROM THE DEEP";
					case "lair"   : return "DEVICES OF TORTURE";
					case "red"    : return "SPACE BENDS AND BREAKS";
				}
				
				break;
				
			case "race": // CHARACTER
				
				var	_race = _split[1],
					_text = mod_script_call("race", _race, "race_unlock");
					
				 // Loading Tip:
				if(!is_string(_text)){
					_text = mod_script_call("skin", _race, "race_ttip");
				}
				
				if(is_string(_text)){
					return _text;
				}
				
				break;
				
			case "skin": // SKIN
				
				var	_skin = _split[1],
					_text = "";
					
				 // Race Mod:
				if(array_length(_split) > 2){
					var _race = _skin;
					_skin = real(_split[2]);
					_text = mod_script_call("race", _race, "race_skin_unlock", _skin);
				}
				
				 // Skin Mod:
				else if(mod_exists("skin", _skin)){
					_text = mod_script_call("skin", _skin, "skin_unlock");
					
					 // Loading Tip:
					if(!is_string(_text)){
						_text = mod_script_call("skin", _skin, "skin_ttip");
					}
				}
				
				if(is_string(_text)){
					return _text;
				}
				
				break;
				
			case "wep": // WEAPON
				
				var	_wep  = _split[1],
					_text = mod_script_call("weapon", _wep, "weapon_unlock", _wep);
					
				 // Loading Tip:
				if(!is_string(_text)){
					_text = mod_script_call("weapon", _wep, "weapon_text", _wep);
				}
				
				if(is_string(_text)){
					return _text;
				}
				
				break;
				
			case "crown": // CROWN
				
				var	_crown = _split[1],
					_text  = mod_script_call("crown", _crown, "crown_unlock");
				
				 // Loading Tip:
				if(!is_string(_text)){
					_text = mod_script_call("weapon", _crown, "crown_tip");
				}
				
				if(is_string(_text)){
					return _text;
				}
				
				break;
				
			case "loadout": // LOADOUT
				
				switch(_split[1]){
					case "wep"   : return "STORED!";
					case "crown" : return "FOR @w" + ((array_length(_split) > 3) ? race_get_title(_split[3]) : "EVERYONE");
				}
				
				break;
		}
	}
	
	return "";
	
#define unlock_splat(_name, _text, _sprite, _sound)
	 // Make Sure UnlockCont Exists:
	if(!array_length(instances_matching(CustomObject, "name", "UnlockCont"))){
		obj_create(0, 0, "UnlockCont");
	}
	
	 // Add New Unlock:
	var _unlock = {
		"nam" : [_name, _name], // [splash popup, gameover popup]
		"txt" : _text,
		"spr" : _sprite,
		"img" : 0,
		"snd" : _sound
	};
	
	with(instances_matching(CustomObject, "name", "UnlockCont")){
		if(splash_index >= array_length(unlock) - 1 && splash_timer <= 0){
			splash_delay = 40;
		}
		array_push(unlock, _unlock);
	}
	
	return _unlock;