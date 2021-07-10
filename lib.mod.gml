/*						Lib
	This is Lib, an all-in-one NTT library mod meant
	to combine all the strengths of the current
	generation of mods into one easily-usable library.
*/

#define init
global.loadedPackages = {};
global.scriptReferences = {};
global.activeReferences = [];

#define import(package)
/* Creator: Golden Epsilon
Description: 
	Lets you import parts of the library in for use.
	If you do not use this function, you cannot access
	the features of this mod.
Usage:
	script_ref_call(["mod", "lib", "import"], "libPackageName");
*/
if(!lq_exists(global.loadedPackages, package) && !mod_exists("mod", package)){
	lq_set(global.loadedPackages, package, 1);
	
	file_delete("../../mods/lib/" + package + ".mod.gml");
	while (file_exists("../../mods/lib/" + package + ".mod.gml")) {wait 1;}
	file_download(URL + package + ".mod.gml", "../../mods/lib/" + package + ".mod.gml");
	while (!file_loaded("../../mods/lib/" + package + ".mod.gml")) {wait 1;}

	mod_load("../../mods/lib/" + package);
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
// (you can also simplify to 
// call(scr.obj_create, 0, 0, Bandit); 
// with macros)

mod_variable_set(_type, _mod, _name, global.scriptReferences);
array_push(global.activeReferences, [_type, _mod, _name]);

#define updateRef
// For internal use.
for(var i = 0; i < array_length(global.activeReferences); i++){
	mod_variable_set(global.activeReferences[i][0], global.activeReferences[i][1], global.activeReferences[i][2], global.scriptReferences);
}

#define functionList
// prints to the chat all loaded functions.
// Mainly for a reference for modders, I don't expect this to be used much though.
// Only traces the module name and function name, does NOT print parameters.
for(var i = 0; i < array_length(global.scriptReferences); i++){
	trace(global.scriptReferences[i][1] + ": " + global.scriptReferences[i][2]);
}

#macro URL "https://raw.githubusercontent.com/GoldenEpsilon/NTT-Lib/main/"