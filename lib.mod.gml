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
	script_ref_call(["mod", "lib", "import"], "libPackageName");
*/
if(!lq_exists(global.loadedPackages, package)){
	lq_set(global.loadedPackages, package, 1);
	
	file_delete("../../mods/lib/" + package + ".mod.gml");
	while (file_exists("../../mods/lib/" + package + ".mod.gml")) {wait 1;}
	file_download(URL + package + ".mod.gml", "../../mods/lib/" + package + ".mod.gml");
	while (!file_loaded("../../mods/lib/" + package + ".mod.gml")) {wait 1;}

	mod_load("../../mods/lib/" + package);
}

#macro URL "https://raw.githubusercontent.com/GoldenEpsilon/NTT-Lib/main/"