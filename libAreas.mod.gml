/*	                Areas
	This is the Areas package of Lib, for
	generation on area creation and on the fly.
*/

/*
	Scripts:
*/

//For internal use, adds the script to be easily usable.
#define addScript(name)
	mod_variable_set("mod", "lib", "scriptReferences", ["mod", mod_current, name]);

#define init
	script_ref_call(["mod", "lib", "updateRef"]);