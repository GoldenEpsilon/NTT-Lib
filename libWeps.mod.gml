/*	                
	This is the Weps package of Lib, for
	functions that help with making weapons
*/

/*
||||||||||||||||||||||||UNFINISHED PACKAGE||||||||||||||||||||||||||||
*/

//todo: eat hook, script for robot eating

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
	global.isLoaded = true;