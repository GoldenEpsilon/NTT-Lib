/*	                Areas
	This is the Areas package of Lib, for
	generation on area creation and on the fly.
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
	script_ref_call(["mod", "lib", "updateRef"]);