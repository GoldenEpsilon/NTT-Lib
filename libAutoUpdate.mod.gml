/*	                AutoUpdate
	This is the AutoUpdate package of Lib, for
	automatically updating your mods!
	It takes a bit more setup than other packages,
	but the payoff is quite nice.
*/

/*
	Scripts:
		#define autoupdate(_name, _url, _version)
		#define generate_json
*/


#define init
global.updatables = [];
global.forks = 0;


#define generate_json(_version)
	if(fork()){
		while("forks" in global && global.forks != 0){wait(0);}
		if(!instance_exists(self)){return;}
		var arr = [];
		global.forks = 0;
		wait file_find_all("", arr);
		files = [];
		if(array_length(arr) == 0){
			files = [selected];
		}else{
			recursive_search(self, arr, "", "");
		}
		while(global.forks != 0){wait(0);}
		var json = {
			version : _version,
			files : files
		};
		string_save(json_encode(json), "version.json");
		exit;
	}

#define autoupdate(_name, _url, _version)
chat_comp_add("update"+_name, "Force-Updates "+_name+" to the latest version.");
array_push(global.updatables, [_name, _url, _version]);

//don't download anything in multiplayer
if(player_is_active(1) || player_is_active(2) || player_is_active(3)){
	return;
}

//loading the previous version file. 
//The version file is a json-encoded file that has "version" as the version number 
//and an array "files" as the files to grab from the github.
//This file is how the mod knows whether to download a new version.
file_load(_name+"version.json");
while (!file_loaded(_name+"version.json")) {wait 1;}
var oldjson;
if(file_exists(_name+"version.json")){
	oldjson = json_decode(string_load(_name+"version.json"));
}

//downloading the new version file over the old one
//I delete for safety, there's a chance it isn't necessary
file_delete(_name+"version.json");
while (file_exists(_name+"version.json")) {wait 1;}
wait file_unload(_name+"version.json");
wait file_download(_url + "version.json", _name+"version.json");
file_load(_name+"version.json");
while (!file_loaded(_name+"version.json")) {wait 1;}
while (!file_exists(_name+"version.json")) {wait 1;}
var newjson = json_decode(string_load(_name+"version.json"));
wait file_unload(_name+"version.json");

//When this if statement runs it replaces the files, so if you want to implement a backup here is where you do it
if(!is_undefined(oldjson) && newjson != json_error && real(oldjson.version) < real(newjson.version) || newjson != json_error && _version < real(newjson.version)){
	trace("There is an update for "+_name+"! updating...");
	updateFiles(newjson, _name, _url);
	script_ref_call(["mod", "lib", "loadText"], "../../mods/" + _name + "/" + "main.txt");
}

#define updateFiles(json, _name, _url)
	if(json != json_error){
		for(var i = 0; i < array_length(json.files); i++){
			//This appears to be safe, not deleting anything from the mods directory.
			file_delete(json.files[i]);
			while (file_exists(json.files[i])) {wait 1;}
			if(fork()){
				global.forks++;
				wait file_download(_url + json.files[i], "../../mods/" + _name + "/" + json.files[i]);
				global.forks--;
				exit;
			}
		}
		while(global.forks > 0){wait(1);}
	}else{
		trace("There was an error when updating, loading mod anyway");
	}

#define chat_command(command, parameter, player)
with(global.updatables){
	if(command == "update"+self[0]){
		if(fork()){
			//downloading the new version file over the old one
			//I delete for safety, there's a chance it isn't necessary
			file_delete(self[0]+"version.json");
			while (file_exists(self[0]+"version.json")) {wait 1;}
			wait file_unload(self[0]+"version.json");
			wait file_download(self[1] + "version.json", self[0]+"version.json");
			file_load(self[0]+"version.json");
			while (!file_loaded(self[0]+"version.json")) {wait 1;}
			while (!file_exists(self[0]+"version.json")) {wait 1;}
			var newjson = json_decode(string_load(self[0]+"version.json"));
			wait file_unload(self[0]+"version.json");
			
			updateFiles(newjson, self[0], self[1]);
			mod_loadtext("../../mods/" + self[0] + "/" + "main.txt");
			exit;
		}
		return 1;
	}
}



#define recursive_search(window, arr, _path, p)
if(fork()){
	global.forks++;
	for(var i = 0; i < array_length(arr); i++){
		if(arr[i].is_dir){
			if(arr[i].name == ".git"){
				continue;
			}
			var _arr = [];
			wait file_find_all(_path + "/" + p + "/" + arr[i].name, _arr);
			if(!instance_exists(window)){global.forks--;exit;}
			recursive_search(window, _arr, _path, (p == "" ? "" : p + "/") + arr[i].name);
		}else{
			if(arr[i].name == ".gitattributes"){
				continue;
			}
			array_push(window.files, (p == "" ? "" : p + "/") + arr[i].name);
		}
	}
	global.forks--;
	exit;
}