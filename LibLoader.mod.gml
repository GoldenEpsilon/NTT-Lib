// This mod downloads the latest version of Lib from github and loads it.
// This mod requires sideload permissions, if you do not give them the user will be prompted.

// IF YOU ARE LOOKING TO USE LIB IN YOUR MOD, THIS IS THE ONLY FILE YOU NEED.

#define init
//if lib is already loaded we do not need to reload it
if(!mod_exists("mod", "lib")){

	//if you don't mind keeping it as a folder download, you can allowmod by using multiple txt files
	//(load this mod in the first txt file, then load a second txt file and have the allowmod command in that second txt file)
	while(!mod_sideload()){wait 1;}
	
	//Check internet connection
	file_download("http://worldclockapi.com/api/json/est/now", "ping.txt");
	var d = 0;
	while (!file_loaded("ping.txt")){
		if d++ > 240 exit;
		wait 1;
	}
	global.err = false;
	var str = string_load("ping.txt");
	if(is_undefined(str)){
		trace("Cannot connect to the internet, using already downloaded files");
		global.err = true;
	}else{
		var json = json_decode(str)
		if(json == json_error){
			trace("Cannot connect to the internet, using already downloaded files");
			global.err = true;
		}
	}

	//Don't download anything if you're in multiplayer
	if(player_is_active(1) || player_is_active(2) || player_is_active(3)){
		trace("Cannot download in multiplayer, using already downloaded files");
		global.err = true;
	}
	
	if(!global.err){
		//downloading lib (no version checking because that would slow the process further)
		//I delete for safety, there's a chance it isn't necessary
		file_delete("../../mods/lib/lib.mod.gml");
		file_delete("../../mods/lib/main.txt");
		file_delete("../../mods/lib/main2.txt");
		while (file_exists("../../mods/lib/lib.mod.gml")) {wait 1;}
		while (file_exists("../../mods/lib/main.txt")) {wait 1;}
		while (file_exists("../../mods/lib/main2.txt")) {wait 1;}
		file_download(URL + "lib.mod.gml", "../../mods/lib/lib.mod.gml");
		file_download(URL + "main.txt", "../../mods/lib/main.txt");
		file_download(URL + "main2.txt", "../../mods/lib/main2.txt");
		while (!file_loaded("../../mods/lib/lib.mod.gml")) {wait 1;}
		while (!file_loaded("../../mods/lib/main.txt")) {wait 1;}
		while (!file_loaded("../../mods/lib/main2.txt")) {wait 1;}
	}

	mod_loadtext("../../mods/lib/main.txt");
	wait(1);
	mod_variable_set("mod", "lib", "canLoad", !global.err);
}

#macro URL "https://raw.githubusercontent.com/GoldenEpsilon/NTT-Lib/main/"