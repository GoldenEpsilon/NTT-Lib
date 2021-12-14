#define init
	//this is set to true when lib is done loading, check this before using lib in step events and such
	global.libLoaded = false;
	if(fork()){
		//wait for lib to be loaded, first of all.
		while(!mod_exists("mod", "lib")){wait(1);}

		//This tells lib to check this mod for hooks and to give the global variable (in this case global.scr) the list of functions lib can use
		script_ref_call(["mod", "lib", "getRef"], "mod", mod_current, "scr");

		//This is where you put what modules you want to load.
		var modules = ["libImprovements"];
		with(modules) call(scr.import, self);
		
		//Lib is done loading, set the global variable.
		global.libLoaded = true;
		exit;
	}

	//Continue the rest of your init here
	
//For internal use, adds the script to be easily usable.
#define addScript(name)
	lq_set(instances_matching(CustomObject, "name", "libGlobal")[0].scriptReferences, name, ["mod", mod_current, name]);

//These are macros to slot in to make it easier to call lib functions.
#macro scr global.scr
#macro call script_ref_call