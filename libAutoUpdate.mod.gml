/*	                AutoUpdate
	This is the AutoUpdate package of Lib, for
	automatically updating your mods!
	It takes a bit more setup than other packages,
	but the payoff is quite nice.
*/

/*
	Scripts:
		#define autoupdate(_name, _repo)
*/

//For internal use, adds the script to be easily usable.
#define addScript(name)
	var ref = mod_variable_get("mod", "lib", "scriptReferences");
	lq_set(ref, name, ["mod", mod_current, name]);
	mod_variable_set("mod", "lib", "scriptReferences", ref);

#define init
	addScript("autoupdate");
	script_ref_call(["mod", "lib", "updateRef"]);
	global.updatables = [];
	global.forks = 0;

#define autoupdate(_name, _repo)
//returns 1 if it updated, 0 if it didn't.

if(array_length(string_split(_repo, "/")) != 2){trace("You need to format the string you pass into autoupdate this way: GitHubUsername/RepoName (it's in the url for the regular repo, there should only be 1 slash)");}
chat_comp_add("update"+_name, "Force-Updates "+_name+" to the latest version.");
array_push(global.updatables, [_name, _repo]);

//don't download anything in multiplayer
if(player_is_active(1) || player_is_active(2) || player_is_active(3)){
	return 0;
}

//loading the previous version file. 
//The version file is a list of commits github provides, this mod just checks the sha
file_load(_name+"version.json");
while (!file_loaded(_name+"version.json")) {wait 1;}
var oldjson = false;
if(file_exists(_name+"version.json")){
	oldjson = json_decode(string_load(_name+"version.json"));
}

//downloading the new version file over the old one
//I delete for safety, there's a chance it isn't necessary
file_delete(_name+"version.json");
while (file_exists(_name+"version.json")) {wait 1;}
wait file_unload(_name+"version.json");
wait file_download("https://api.github.com/repos/" + _repo + "/commits", _name+"version.json");
file_load(_name+"version.json");
while (!file_loaded(_name+"version.json")) {wait 1;}
while (!file_exists(_name+"version.json")) {wait 1;}
var newjson = json_decode(string_load(_name+"version.json"));
wait file_unload(_name+"version.json");
while(global.forks > 0){wait(1);}
if(oldjson == false){
	trace("Updating "+_name);
	updateFiles(_name, _repo, "");
	script_ref_call(["mod", "lib", "loadText"], "../../mods/" + self[0] + "/" + "main.txt");
	return 1;
}
//When this if statement runs it replaces the files, so if you want to implement a backup here is where you do it
if(oldjson != json_error && is_array(oldjson) && "sha" in oldjson[0] && newjson != json_error && is_array(newjson) && "sha" in newjson[0] && oldjson[0].sha != newjson[0].sha){
	trace("There is an update for "+_name+"! updating...");
	updateFiles(_name, _repo, "");
	script_ref_call(["mod", "lib", "loadText"], "../../mods/" + _name + "/" + "main.txt");
	return 1;
}
return 0;

#define updateFiles(_name, _repo, _sub)
	file_delete(_sub+"/"+_name+"files.json");
	while (file_exists(_sub+"/"+_name+"files.json")) {wait 1;}
	wait file_unload(_sub+"/"+_name+"files.json");
	wait file_download("https://api.github.com/repos/" + _repo + "/contents/" + _sub, _sub+"/"+_name+"files.json");
	file_load(_sub+"/"+_name+"files.json");
	while (!file_loaded(_sub+"/"+_name+"files.json")) {wait 1;}
	while (!file_exists(_sub+"/"+_name+"files.json")) {wait 1;}
	var json = json_decode(string_load(_sub+"/"+_name+"files.json"));
	wait file_unload(_sub+"/"+_name+"files.json");
	if(json != json_error){
		with(json){
			if("name" in self){
				trace(name);
				if("size" in self && size > 0){
					//Replace a file
					if(fork()){
						file_delete("../../mods/" + _sub + "/" + _name + "/" + name);
						while (file_exists("../../mods/" + _sub + "/" + _name + "/" + name)) {wait 1;}
						global.forks++;
						wait file_download("https://raw.githubusercontent.com/" + _repo + "/" + _sub + "/" + name, "../../mods/" + _sub + "/" + _name + "/" + name);
						global.forks--;
						exit;
					}
				}else if("size" in self && name != ""){
					//it was a folder, load folder stuff
					if(fork()){
						global.forks++;
						var sub = _sub;
						if(sub != ""){sub += "/";}
						sub += name;
						updateFiles(_name, _repo, sub);
						global.forks--;
						exit;
					}
				}
			}else{
				trace("ERROR. Were you downloading too much at once?");
			}
			if("message" in self){
				trace(message);
			}
		}
		if(_sub == ""){
			while(global.forks > 0){wait(1);}
		}
	}else{
		trace("There was an error when updating, loading mod anyway");
	}

#define chat_command(command, parameter, player)
with(global.updatables){
	if(command == "update"+self[0]){
		if(fork()){
			trace("Updating "+self[0]);
			while(global.forks > 0){wait(1);}
			updateFiles(self[0], self[1], "");
			script_ref_call(["mod", "lib", "loadText"], "../../mods/" + self[0] + "/" + "main.txt");
			exit;
		}
		return 1;
	}
}