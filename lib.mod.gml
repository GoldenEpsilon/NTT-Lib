/*						Lib
	This is Lib, an all-in-one NTT library mod meant
	to combine all the strengths of the current
	generation of mods into one easily-usable library.
*/

#define init
global.loadedPackages = {};
global.scriptReferences = {};
global.activeReferences = [];
global.lastid = instance_create(0, 0, DramaCamera);
global.level_loading = false;
global.canLoad = undefined;
global.bind_late_step = noone;
global.bind_end_step = noone;

global.mutations = [];

addScript("import");

//wait for sideloading
while(!mod_sideload()){wait 1;}

//wait in case libloader's already done the work for you
wait(2);
if(global.canLoad == undefined){
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
while(global.canLoad == undefined){wait(1)}
if(global.canLoad){
	if(!lq_exists(global.loadedPackages, package) && !mod_exists("mod", package)){
		lq_set(global.loadedPackages, package, 1);
		file_delete("../../mods/lib/" + package + ".mod.gml");
		while (file_exists("../../mods/lib/" + package + ".mod.gml")) {wait 1;}
		file_download(URL + package + ".mod.gml", "../../mods/lib/" + package + ".mod.gml");
		while (!file_loaded("../../mods/lib/" + package + ".mod.gml")) {wait 1;}

		if(file_exists("../../mods/lib/" + package + ".mod.gml")){
			mod_load("../../mods/lib/" + package);
			while(!mod_exists("mod", package)){wait(1);}
		}else{
			trace("Could not find package " + package);
		}
	}
}else{
	if(!lq_exists(global.loadedPackages, package) && !mod_exists("mod", package)){
		lq_set(global.loadedPackages, package, 1);
		while (!file_loaded("../../mods/lib/" + package + ".mod.gml")) {wait 1;}
		if(file_exists("../../mods/lib/" + package + ".mod.gml")){
			mod_load("../../mods/lib/" + package);
			while(!mod_exists("mod", package)){wait(1);}
		}else{
			trace("Could not find package " + package);
		}
	}
}

#define cleanup
     // Unbind Script on Mod Unload:
    with(global.bind_late_step){
        instance_destroy();
    }
    with(global.bind_end_step){
        instance_destroy();
    }

#define getRef(_type, _mod, _name)
// _type should be the type of mod file ("mod", "race", "weapon", etc)
// _mod should be the mod file name (mod_current, basically)
// _name should be the name of the *global* variable you want to use.

// sets the global variable given to this function to a LWO of script references.
// For example, if you run this on a variable global.scr with
// script_ref_call(["mod", "lib", "getRef"], "mod", mod_current, "scr");
// (assuming you are calling it from a .mod.gml file), you can then run
// script_ref_call(global.scr.obj_create, 0, 0, Bandit);
// instead of
// script_ref_call(["mod", "libGeneral", "obj_create"], 0, 0, Bandit);

// ALSO, calling this function makes this mod call function hooks automatically.
// Hooks are:
// update : gets called whenever a new object is created, and passes in the latest ID from the frame before.
//          (does NOT include Effect objects or Custom Script objects)
// level_start : gets called when the level starts
// mutation_update : gets called when there are new/removed mutations
// You use a hook just by having a function with the right name (for example, #define update)
// The function will be called when needed as long as the mod's called getRef at some point.

mod_variable_set(_type, _mod, _name, global.scriptReferences);

//ensure that there are no duplicates
with(global.activeReferences){
	if(self[0] == _type && self[1] == _mod && self[2] == _name){
		return;
	}
}
array_push(global.activeReferences, [_type, _mod, _name]);

#define functionList
// prints to the chat all loaded functions.
// Mainly for a reference for modders, I don't expect this to be used much though.
// Only traces the module name and function name, does NOT print parameters.
with(global.scriptReferences){
	trace(self[1] + ": " + self[2]);
}

#define ping()
	//Check internet connection
	file_download("http://worldclockapi.com/api/json/est/now", "ping.txt");
	var d = 0;
	while (!file_loaded("ping.txt")){
		if d++ > 240 {
			trace("Server timed out, using already downloaded files");
			global.canLoad = false;
			exit;
		}
		wait 1;
	}
	var str = string_load("ping.txt");
	global.canLoad = true;
	if(is_undefined(str)){
		global.canLoad = false;
	}else{
		var json = json_decode(str)
		if(json == json_error){
			global.canLoad = false;
		}
	}

	//Don't download anything if you're in multiplayer
	for(var i = 1;i<maxp;i++){
		if player_is_active(i){
			trace("Cannot download in multiplayer, using already downloaded files");
			global.canLoad = false;
			break;
		}
	}

#define updateRef
// For internal use.
with(global.activeReferences){
	mod_variable_set(self[0], self[1], self[2], global.scriptReferences);
}

#define loadText(path)
// For internal use.
mod_loadtext(path);

//For internal use, adds the script to be easily usable.
#define addScript(name)
	var ref = mod_variable_get("mod", "lib", "scriptReferences");
	lq_set(ref, name, ["mod", mod_current, name]);
	mod_variable_set("mod", "lib", "scriptReferences", ref);

#macro URL "https://raw.githubusercontent.com/GoldenEpsilon/NTT-Lib/main/"


#define step
	//level_start
	if(instance_exists(GenCont) || instance_exists(Menu)){
		global.level_loading = true;
	}
	else if(global.level_loading){
		global.level_loading = false;
		with(global.activeReferences){
			script_ref_call([self[0], self[1], "level_start"]);
		}
	}
	
	//binded steps
    if(!instance_exists(global.bind_late_step)){
        global.bind_late_step = script_bind_step(late_step, 0);
    }
    if(!instance_exists(global.bind_end_step)){
        global.bind_end_step = script_bind_end_step(end_step, 0);
    }
	
	var mutations = [];
	while(skill_get_at(array_length(mutations)) != null){
		array_push(mutations, skill_get_at(array_length(mutations)));
	}
	
	for(var i = 0; i < array_length(global.mutations); i++){
		if(i >= array_length(mutations) || global.mutations[i] != mutations[i]){
			with(global.activeReferences){
				script_ref_call([self[0], self[1], "mutation_update"], global.mutations);
			}
			global.mutations = mutations;
			break;
		}
	}

#define late_step
	//late step
	with(global.activeReferences){
		script_ref_call([self[0], self[1], "late_step"]);
	}
	
#define end_step
	//update
	var newID = instance_create(0, 0, DramaCamera);
	var updateid = global.lastid;
	var lid = global.lastid;
	while(updateid++ < newID){
		if(instance_exists(updateid)){
			if("object_index" in updateid){
				var obj = updateid.object_index;
				if(object_get_parent(obj) == Effect || obj == Effect || object_get_parent(obj) == CustomScript || obj == CustomScript){
					lid++;
				}
			}else{
				lid++;
			}
		}else{
			lid++;
		}
	}
	if(newID > lid){
		with(global.activeReferences){
			script_ref_call([self[0], self[1], "update"], global.lastid, newID);
		}
	}
	global.lastid = newID;
	
	//end step
	with(global.activeReferences){
		script_ref_call([self[0], self[1], "end_step"]);
	}