/*						Lib
	This is Lib, an all-in-one NTT library mod meant
	to combine all the strengths of the current
	generation of mods into one easily-usable library.
*/

#define init
//global variable storage
if(array_length(instances_matching(CustomObject, "name", "libGlobal")) != 1){
	with(instances_matching(CustomObject, "name", "libGlobal")){
		instance_destroy();
	}
	with(instance_create(0,0,CustomObject)){
		name = "libGlobal";
		loadedPackages = {};
		scriptReferences = {};
		activeReferences = [];
		activeHooks = [];
		updateid = instance_create(0, 0, DramaCamera);
		endupdateid = instance_create(0, 0, DramaCamera);
		level_loading = false;
		canLoad = undefined;
		bind_late_step = noone;
		bind_end_step = noone;
		mutations = [];
		persistent = true;
	}
}
global.loadedPackages = Global.loadedPackages;
global.scriptReferences = Global.scriptReferences;
global.activeHooks = Global.activeHooks;
global.updateid = Global.updateid;
global.endupdateid = Global.endupdateid;
global.level_loading = Global.level_loading;
global.canLoad = Global.canLoad;
global.bind_late_step = Global.bind_late_step;
global.bind_end_step = Global.bind_end_step;
global.mutations = Global.mutations;

addScript("import");
addScript("getRef");

//wait for sideloading
while(!mod_sideload()){wait 1;}

//wait in case libloader's already done the work for you
wait(2);
if(Global.canLoad == undefined){
	ping();
}
//libGeneral is important for the rest of lib, so it's loaded by default
import("libGeneral");

#define import(package)
/* Creator: Golden Epsilon
Description: 
	Lets you import parts of the library in for use.
	If you do not use this function, you cannot access
	the features of this mod.
Usage:
	script_ref_call(["mod", "lib", "import"], "libPackageName");
*/
while(Global.canLoad == undefined){wait(1)}
if(Global.canLoad){
	if(!lq_exists(Global.loadedPackages, package) && !mod_exists("mod", package)){
		lq_set(Global.loadedPackages, package, 1);
		file_delete("../../mods/lib/" + package + ".mod.gml");
		while (file_exists("../../mods/lib/" + package + ".mod.gml")) {wait 1;}
		file_download(URL + package + ".mod.gml", "../../mods/lib/" + package + ".mod.gml");
		while (!file_loaded("../../mods/lib/" + package + ".mod.gml")) {wait 1;}
		var timeout = 300;
		while (!file_exists("../../mods/lib/" + package + ".mod.gml") && timeout > 0) {wait 1;timeout--;}

		if(file_exists("../../mods/lib/" + package + ".mod.gml")){
			mod_load("../../mods/lib/" + package);
			while(!mod_exists("mod", package)){wait(1);}
			while(!mod_variable_get("mod", package, "isLoaded")){wait(1);}
		}else{
			trace("Could not find package " + package);
		}
	}
}else{
	if(!lq_exists(Global.loadedPackages, package) && !mod_exists("mod", package)){
		lq_set(Global.loadedPackages, package, 1);
		file_load("../../mods/lib/" + package + ".mod.gml");
		while (!file_loaded("../../mods/lib/" + package + ".mod.gml")) {wait 1;}
		if(file_exists("../../mods/lib/" + package + ".mod.gml")){
			mod_load("../../mods/lib/" + package);
			while(!mod_exists("mod", package)){wait(1);}
			while(!mod_variable_get("mod", package, "isLoaded")){wait(1);}
		}else{
			trace("Could not find package " + package);
		}
	}
}

#define cleanup
     // Unbind Script on Mod Unload:
    with(Global.bind_late_step){
        instance_destroy();
    }
    with(Global.bind_end_step){
        instance_destroy();
    }

#define getRef(_type, _mod, _name)
// _type should be the type of mod file ("mod", "race", "weapon", etc)
// _mod should be the mod file name (mod_current, basically)
// _name should be the name of the *global* variable you want to use.

// ALSO, calling this function makes this mod call function hooks automatically.

getScr(_type, _mod, _name);
getHooks(_type, _mod);

#define getScr(_type, _mod, _name)
// sets the global variable given to this function to a LWO of script references.
// _type should be the type of mod file ("mod", "race", "weapon", etc)
// _mod should be the mod file name (mod_current, basically)
// _name should be the name of the *global* variable you want to use.
//
// For example, if you run this on a variable global.scr with
// script_ref_call(["mod", "lib", "getScr"], "mod", mod_current, "scr");
// (assuming you are calling it from a .mod.gml file), you can then run
// script_ref_call(global.scr.obj_create, 0, 0, Bandit);
// instead of
// script_ref_call(["mod", "libGeneral", "obj_create"], 0, 0, Bandit);
//
// (you can also do "#macro scr global.scr" and "#macro call script_ref_call" to make it easier)

mod_variable_set(_type, _mod, _name, Global.scriptReferences);

//ensure that there are no duplicates
with(Global.activeReferences){
	if(self[0] == _type && self[1] == _mod && self[2] == _name){
		return;
	}
}
array_push(Global.activeReferences, [_type, _mod, _name]);

#define getHooks(_type, _mod)
// Hooks are functions that are called by lib, that work like step(), draw(), game_start(), etc work for base NTT.
// Call this function to opt-in the calling mod for these hooks.
// _type should be the type of mod file ("mod", "race", "weapon", etc)
// _mod should be the mod file name (mod_current, basically)
//
// Hooks are:
// late_step: gets called after the normal step, useful for doing stuff after, say, projectile creation.
// end_step: gets called after collision and other such things
// update(startID, endID) : gets called whenever a new object is created, and passes in the latest ID from the frame before.
//          (does NOT include Effect objects, CustomObject objects, or CustomScript objects)
// end_update(startID, endID) : like update, but occurs at the same time as end_step
// level_start : gets called when the level starts
// mutation_update(currentmutations, previousmutations) : gets called when there are new/removed mutations
// weapon_prefire(specfire, weapon) : gets called when the player is going to fire that frame. (also calls on non-weapon mods!)
// You use a hook just by having a function with the right name (for example, #define update)
// The function will be called when needed as long as the mod's called getRef at some point.
// NOTE: when you use a hook in a weapon file you have an additional parameter, before all the others,
// 		saying whether the weapon is in the primary or secondary slot.

//ensure that there are no duplicates
with(Global.activeHooks){
	if(self[0] == _type && self[1] == _mod){
		return;
	}
}
array_push(Global.activeHooks, [_type, _mod]);

#define functionList
// prints to the chat all loaded functions.
// Mainly for a reference for modders, I don't expect this to be used much though.
// Only traces the module name and function name, does NOT print parameters.
with(Global.scriptReferences){
	trace(self[1] + ": " + self[2]);
}

#define ping()
	//Check internet connection
	file_download("http://worldclockapi.com/api/json/est/now", "ping.txt");
	var d = 0;
	while (!file_loaded("ping.txt")){
		if d++ > 150 {
			trace("Server timed out, using already downloaded files");
			Global.canLoad = false;
			return;
		}
		wait 1;
	}
	var str = string_load("ping.txt");
	Global.canLoad = true;
	if(is_undefined(str)){
		Global.canLoad = false;
		return;
	}else{
		var json = json_decode(str)
		if(json == json_error){
			Global.canLoad = false;
			return;
		}
	}

#define updateRef
// For internal use.
with(Global.activeReferences){
	mod_variable_set(self[0], self[1], self[2], Global.scriptReferences);
}

#define loadText(path)
// For internal use.
mod_loadtext(path);

//For internal use, adds the script to be easily usable.
#define addScript(name)
	lq_set(instances_matching(CustomObject, "name", "libGlobal")[0].scriptReferences, name, ["mod", mod_current, name]);

#macro URL "https://raw.githubusercontent.com/GoldenEpsilon/NTT-Lib/main/"


#define step
	//global variable storage
	if(array_length(instances_matching(CustomObject, "name", "libGlobal")) != 1){
		with(instances_matching(CustomObject, "name", "libGlobal")){
			instance_destroy();
		}
		with(instance_create(0,0,CustomObject)){
			name = "libGlobal";
			loadedPackages = global.loadedPackages;
			scriptReferences = global.scriptReferences;
			activeReferences = global.activeReferences;
			activeHooks = global.activeHooks;
			updateid = global.updateid;
			endupdateid = global.endupdateid;
			level_loading = global.level_loading;
			canLoad = global.canLoad;
			bind_late_step = global.bind_late_step;
			bind_end_step = global.bind_end_step;
			mutations = global.mutations;
			persistent = true;
		}
	}else{
		global.loadedPackages = Global.loadedPackages;
		global.scriptReferences = Global.scriptReferences;
		global.activeReferences = Global.activeReferences;
		global.activeHooks = Global.activeHooks;
		global.updateid = Global.updateid;
		global.endupdateid = Global.endupdateid;
		global.level_loading = Global.level_loading;
		global.canLoad = Global.canLoad;
		global.bind_late_step = Global.bind_late_step;
		global.bind_end_step = Global.bind_end_step;
		global.mutations = Global.mutations;
	}
	
	//binded steps
    if(!instance_exists(Global.bind_late_step)){
        Global.bind_late_step = script_bind_step(late_step, 0);
    }
    if(!instance_exists(Global.bind_end_step)){
        Global.bind_end_step = script_bind_end_step(end_step, 0);
    }
	
	//level_start
	if(instance_exists(GenCont) || instance_exists(Menu)){
		Global.level_loading = true;
	}
	else if(Global.level_loading){
		Global.level_loading = false;
		with(Global.activeHooks){
			switch(self[0]){
				case "skill":
					with(GameCont){
						if(skill_get(other[1])){
							script_ref_call([other[0], other[1], "level_start"]);
						}
					}
					break;
				case "race":
					with(Player){
						if(race == other[1]){
							script_ref_call([other[0], other[1], "level_start"]);
						}
					}
					break;
				case "wep":
				case "weapon":
					with(Player){
						if(wep == other[1] || (is_object(wep) && wep.wep == other[1])){
							script_ref_call([other[0], other[1], "level_start"], 1);
						}
						if(bwep == other[1] || (is_object(bwep) && bwep.wep == other[1])){
							script_ref_call([other[0], other[1], "level_start"], 0);
						}
					}
					break;
				default:
					with(GameCont){
						script_ref_call([other[0], other[1], "level_start"]);
					}
			}
		}
	}
	
	//mutation_update
	var mutations = [];
	while(skill_get_at(array_length(mutations)) != null){
		array_push(mutations, skill_get_at(array_length(mutations)));
	}
	for(var i = 0; i < array_length(Global.mutations) || i < array_length(mutations); i++){
		if(i >= array_length(mutations) || i >= array_length(Global.mutations) || Global.mutations[i] != mutations[i]){
			with(Global.activeHooks){
				switch(self[0]){
					case "skill":
						with(GameCont){
							if(skill_get(other[1])){
								script_ref_call([other[0], other[1], "mutation_update"], mutations, Global.mutations);
							}
						}
						break;
					case "race":
						with(Player){
							if(race == other[1]){
								script_ref_call([other[0], other[1], "mutation_update"], mutations, Global.mutations);
							}
						}
						break;
					case "wep":
					case "weapon":
						with(Player){
							if(wep == other[1] || (is_object(wep) && wep.wep == other[1])){
								script_ref_call([other[0], other[1], "mutation_update"], 1, mutations, Global.mutations);
							}
							if(bwep == other[1] || (is_object(bwep) && bwep.wep == other[1])){
								script_ref_call([other[0], other[1], "mutation_update"], 0, mutations, Global.mutations);
							}
						}
						break;
					default:
						with(GameCont){
							script_ref_call([other[0], other[1], "mutation_update"], mutations, Global.mutations);
						}
				}
			}
			Global.mutations = mutations;
			break;
		}
	}
	
	//weapon_prefire
	with(Player){
		var _auto = weapon_get_auto(wep);
		var secondary = 0;
		var specfire = 0;
		var fired = 0;
		if(race == "steroids" && _auto >= 0){
			_auto = true;
		}
		if(race == "steroids" && bcan_shoot && canspec && (((_auto && bwep != 0) ? button_check(index, "spec") : button_pressed(index, "spec")) || usespec) && (ammo[weapon_get_type(bwep)] >= weapon_get_cost(bwep) || infammo != 0)){
			secondary = 1;
			specfire = 1;
			fired = 1;
		}
		if(can_shoot){
			if(race == "skeleton" && canspec && (button_pressed(index, "spec") || usespec) && weapon_get_cost(wep) > 0){
				specfire = 1;
				fired = 1;
			}
			else if(race == "venuz" && canspec && (button_pressed(index, "spec") || usespec) && weapon_get_type(wep) != 0 && (ammo[weapon_get_type(wep)] >= weapon_get_cost(wep) * floor(2 + (2 * skill_get(mut_throne_butt))) || infammo != 0)){
				specfire = 1;
				fired = 1;
			}
			else if(canfire && ((_auto && wep != 0) ? button_check(index, "fire") : (clicked || button_pressed(index, "fire"))) && (ammo[weapon_get_type(wep)] >= weapon_get_cost(wep) || infammo != 0)){
				fired = 1;
			}
		}
		if(fired){
			with(Global.activeHooks){
				switch(self[0]){
					case "skill":
						with(other){
							if(skill_get(other[1])){
								script_ref_call([other[0], other[1], "weapon_prefire"], specfire, secondary ? bwep : wep);
							}
						}
						break;
					case "race":
						with(other){
							if(race == other[1]){
								script_ref_call([other[0], other[1], "weapon_prefire"], specfire, secondary ? bwep : wep);
							}
						}
						break;
					case "wep":
					case "weapon":
						with(other){
							if(wep == other[1] || (is_object(wep) && wep.wep == other[1])){
								script_ref_call([other[0], other[1], "weapon_prefire"], 1, specfire, secondary ? bwep : wep);
							}
							if(bwep == other[1] || (is_object(bwep) && bwep.wep == other[1])){
								script_ref_call([other[0], other[1], "weapon_prefire"], 0, specfire, secondary ? bwep : wep);
							}
						}
						break;
					default:
						with(other){
							script_ref_call([other[0], other[1], "weapon_prefire"], specfire, secondary ? bwep : wep);
						}
				}
			}
		}
	}

#define late_step
	//update
	var newID = instance_create(0, 0, DramaCamera);
	var updateid = Global.updateid;
	var lastid = Global.updateid;
	while(updateid++ < newID){
		if(instance_exists(updateid)){
			if("object_index" in updateid){
				var obj = updateid.object_index;
				if(object_get_parent(obj) == Effect || obj == Effect || object_get_parent(obj) == CustomScript || obj == CustomScript || obj == CustomObject){
					lastid++;
				}
			}else{
				lastid++;
			}
		}else{
			lastid++;
		}
	}
	if(newID > lastid){
		with(Global.activeHooks){
			switch(self[0]){
				case "skill":
					with(GameCont){
						if(skill_get(other[1])){
							script_ref_call([other[0], other[1], "update"], Global.updateid, newID);
						}
					}
					break;
				case "race":
					with(Player){
						if(race == other[1]){
							script_ref_call([other[0], other[1], "update"], Global.updateid, newID);
						}
					}
					break;
				default:
					with(GameCont){
						script_ref_call([other[0], other[1], "update"], Global.updateid, newID);
					}
			}
		}
	}
	Global.updateid = newID;
	
	//late step
	with(Global.activeHooks){
		switch(self[0]){
			case "skill":
				with(GameCont){
					if(skill_get(other[1])){
						script_ref_call([other[0], other[1], "late_step"]);
					}
				}
				break;
			case "race":
				with(Player){
					if(race == other[1]){
						script_ref_call([other[0], other[1], "late_step"]);
					}
				}
				break;
			default:
				with(GameCont){
					script_ref_call([other[0], other[1], "late_step"]);
				}
		}
	}
	
#define end_step
	//end_update
	var newID = instance_create(0, 0, DramaCamera);
	var updateid = Global.endupdateid;
	var lastid = Global.endupdateid;
	while(updateid++ < newID){
		if(instance_exists(updateid)){
			if("object_index" in updateid){
				var obj = updateid.object_index;
				if(object_get_parent(obj) == Effect || obj == Effect || object_get_parent(obj) == CustomScript || obj == CustomScript || obj == CustomObject){
					lastid++;
				}
			}else{
				lastid++;
			}
		}else{
			lastid++;
		}
	}
	if(newID > lastid){
		with(Global.activeHooks){
			switch(self[0]){
				case "skill":
					with(GameCont){
						if(skill_get(other[1])){
							script_ref_call([other[0], other[1], "end_update"], Global.endupdateid, newID);
						}
					}
					break;
				case "race":
					with(Player){
						if(race == other[1]){
							script_ref_call([other[0], other[1], "end_update"], Global.endupdateid, newID);
						}
					}
					break;
				default:
					with(GameCont){
						script_ref_call([other[0], other[1], "end_update"], Global.endupdateid, newID);
					}
			}
		}
	}
	Global.endupdateid = newID;
	
	//end step
	with(Global.activeHooks){
		switch(self[0]){
			case "skill":
				with(GameCont){
					if(skill_get(other[1])){
						script_ref_call([other[0], other[1], "end_step"]);
					}
				}
				break;
			case "race":
				with(Player){
					if(race == other[1]){
						script_ref_call([other[0], other[1], "end_step"]);
					}
				}
				break;
			default:
				with(GameCont){
					script_ref_call([other[0], other[1], "end_step"]);
				}
		}
	}

#define chat_command(command, parameter, player)

#macro Global instances_matching(CustomObject, "name", "libGlobal")[0]