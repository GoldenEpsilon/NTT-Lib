/*						Lib
	This is Lib, an all-in-one NTT library mod meant
	to combine all the strengths of the current
	generation of mods into one easily-usable library.
*/

#define init
global.loadedPackages = {};

#define import(package)
/* Creator: Golden Epsilon
Description: 
	Lets you import parts of the library in for use.
	If you do not use this function, you cannot access
	the features of this mod.
Usage:
	script_call(["mod", "lib", "import"], "libPackageName");
*/
if(!lq_exists(global.loadedPackages, package)){
	lq_set(global.loadedPackages, package, 1);
	mod_load(package);
}