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

if(array_length(string_split(_repo, "/")) != 2){trace("You need to format the string you pass into autoupdate this way: GitHubUsername/RepoName (it's in the url for the regular repo, there should only be 1 slash)");}
var new = true;
with(global.updatables){
	if(self[0] == _name && self[1] == _repo){
		new = false; 
		break;
	}
}
if(new){
	chat_comp_add("update"+_name, "Force-Updates "+_name+" to the latest version.");
	array_push(global.updatables, [_name, _repo]);
}

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
	updateFiles(_name, _repo);
	script_ref_call(["mod", "lib", "loadText"], "../../mods/" + _name + "/" + "main.txt");
	return 1;
}
//When this if statement runs it replaces the files, so if you want to implement a backup here is where you do it
if(oldjson != json_error && is_array(oldjson) && "sha" in oldjson[0] && newjson != json_error && is_array(newjson) && "sha" in newjson[0] && oldjson[0].sha != newjson[0].sha){
	trace("There is an update for "+_name+"! updating...");
	updateFiles(_name, _repo);
	script_ref_call(["mod", "lib", "loadText"], "../../mods/" + _name + "/" + "main.txt");
	return 1;
}
return 0;

#define updateFiles(_name, _repo)
	file_delete(_name+"branches.json");
	while (file_exists(_name+"branches.json")) {wait 1;}
	wait file_unload(_name+"branches.json");
	wait file_download("https://api.github.com/repos/" + _repo + "/branches", _name+"branches.json");
	file_load(_name+"branches.json");
	while (!file_loaded(_name+"branches.json")) {wait 1;}
	while (!file_exists(_name+"branches.json")) {wait 1;}
	var branches = json_decode(string_load(_name+"branches.json"));
	wait file_unload(_name+"branches.json");
	
	if(branches != json_error){
		if(is_array(branches)){
			file_delete(_name+"tree.json");
			while (file_exists(_name+"tree.json")) {wait 1;}
			wait file_unload(_name+"tree.json");
			wait file_download("https://api.github.com/repos/" + _repo + "/git/trees/"+branches[0].commit.sha+"?recursive=1", _name+"tree.json");
			file_load(_name+"tree.json");
			while (!file_loaded(_name+"tree.json")) {wait 1;}
			while (!file_exists(_name+"tree.json")) {wait 1;}
			var tree = json_decode(string_load(_name+"tree.json"));
			wait file_unload(_name+"tree.json");
			if(tree != json_error){
				with(tree.tree){
					if(type == "blob" && fork()){
						global.forks++;
						//Replace a file
						file_delete("../../mods/" + _name + "/" + path);
						while (file_exists("../../mods/" + _name + "/" + path)) {wait 1;}
						wait file_download("https://raw.githubusercontent.com/" + _repo + "/" + branches[0].name + "/" + path, "../../mods/" + _name + "/" + path);
						while (!file_exists("../../mods/" + _name + "/" + path)) {wait 1;}
						global.forks--;
						exit;
					}
				}
				wait(1);
				while(global.forks > 0){wait(1);}
			}else{
				//set it to download again when it can
				file_delete(_name+"tree.json");
				trace("ERROR. Were you downloading too much at once?");
			}
			if("message" in tree){
				trace(tree.message);
			}
		}else{
			//set it to download again when it can
			file_delete(_name+"branches.json");
			trace("ERROR. Were you downloading too much at once?");
		}
		if("message" in branches){
			trace(branches.message);
		}
	}
	trace("Update for " + _name + " complete!");

#define chat_command(command, parameter, player)
with(global.updatables){
	if(command == "update"+self[0]){
		if(fork()){
			trace("Updating "+self[0]);
			while(global.forks > 0){wait(1);}
			updateFiles(self[0], self[1]);
			script_ref_call(["mod", "lib", "loadText"], "../../mods/" + self[0] + "/" + "main.txt");
			exit;
		}
		return 1;
	}
}