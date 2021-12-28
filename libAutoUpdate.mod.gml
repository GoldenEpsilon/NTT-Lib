/*	                AutoUpdate
	This is the AutoUpdate package of Lib, for
	automatically updating your mods!
*/

/*
	Scripts:
		#define autoupdate(_name, _repo)
*/

//For internal use, adds the script to be easily usable.
#define addScript(name)
	lq_set(instances_matching(CustomObject, "name", "libGlobal")[0].scriptReferences, name, ["mod", mod_current, name]);

#define init
	addScript("autoupdate");
	
	script_ref_call(["mod", "lib", "updateRef"]);
	global.isLoaded = true;
	
	global.updatables = [];
	global.forks = 0;
	global.updating = 0; //if you want to check for the autoupdate to finish, this will only be 0 when it's not updating something
	global.autoupdate = false; //if this is set to true mods will autoupdate without asking the user - for the user to set, not mod devs

#define autoupdate(_name, _repo)
/* Creator: Golden Epsilon
Description: 
	Checks for an update, updates if there is one.
	Also adds in a chat command to force updating.
Arguments:
	_name : The name of the mod. This *must* be the name of the folder the person loads for this system to work correctly.
	_repo : The github repository for the mod. Other sites don't work. you need to pass in the string in the format "GitHubUsername/RepoName".
*/

if(array_length(string_split(_repo, "/")) != 2){trace("You need to format the string you pass into autoupdate this way: GitHubUsername/RepoName (it's in the url for the regular repo, there should only be 1 slash)");}
global.updating++;
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

//check if lib can download; if it can't, this can't.
if(!mod_variable_get("mod", "lib", "canLoad")){
	global.updating--;
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
	if(global.autoupdate){
		trace("Updating "+_name);
		if(newjson != json_error && is_array(newjson) && array_length(newjson) && "commit" in newjson[0] && "message" in newjson[0].commit){
			trace('Latest commit message: '+chr(10)+'"'+newjson[0].commit.message+'"');
		}
		updateFiles(_name, _repo);
		script_ref_call(["mod", "lib", "loadText"], "../../mods/" + _name + "/" + "main.txt");
	}else{
		wait(0);
		trace("There is an update available for "+_name+"!");
		trace("Run the command /update"+_name+" to download it!");
		if(newjson != json_error && is_array(newjson) && array_length(newjson) && "commit" in newjson[0] && "message" in newjson[0].commit){
			trace('Latest commit message: '+chr(10)+'"'+newjson[0].commit.message+'"');
		}
	}
	global.updating--;
	return 1;
}
//When this if statement runs it replaces the files, so if you want to implement a backup here is where you do it
if(oldjson != json_error && is_array(oldjson) && "sha" in oldjson[0] && newjson != json_error && is_array(newjson) && array_length(newjson) && "sha" in newjson[0] && oldjson[0].sha != newjson[0].sha){
	if(global.autoupdate){
		trace("There is an update for "+_name+"! updating...");
		if("commit" in newjson[0] && "message" in newjson[0].commit){
			trace('Latest commit message: '+chr(10)+'"'+newjson[0].commit.message+'"');
		}
		updateFiles(_name, _repo);
		script_ref_call(["mod", "lib", "loadText"], "../../mods/" + _name + "/" + "main.txt");
	}else{
		wait(0);
		trace("There is an update available for "+_name+"!");
		trace("Run the command /update"+_name+" to download it!");
		if("commit" in newjson[0] && "message" in newjson[0].commit){
			trace('Latest commit message: '+chr(10)+chr(10)+newjson[0].commit.message);
		}
	}
	global.updating--;
	return 1;
}
global.updating--;
return 0;

#define updateFiles(_name, _repo)
	trace("Updating Files!");
	
	file_delete(_name+"branches.json");
	while (file_exists(_name+"branches.json")) {wait 1;}
	wait file_unload(_name+"branches.json");
	trace("Downloading branches...");
	wait file_download("https://api.github.com/repos/" + _repo + "/branches", _name+"branches.json");
	trace("Branches downloaded...");
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
			trace("Downloading commit data...");
			wait file_download("https://api.github.com/repos/" + _repo + "/git/trees/"+branches[0].commit.sha+"?recursive=1", _name+"tree.json");
			file_load(_name+"tree.json");
			trace("Commit data downloaded...");
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
				wait(0);
				var forks = global.forks;
				while(global.forks > 0){
					trace("Update for "+_name+" is "+string(round((1-(global.forks/forks))*100))+"% done.");
					wait(30);
				}
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
			global.updating++;
			if(!mod_variable_get("mod", "lib", "canLoad")){
				trace("can't autoupdate - you're either in multiplayer or can't connect to the internet");
				global.updating--;
				exit;
			}
			trace("Updating "+self[0]);
			while(global.forks > 0){wait(1);}
			updateFiles(self[0], self[1]);
			script_ref_call(["mod", "lib", "loadText"], "../../mods/" + self[0] + "/" + "main.txt");
			global.updating--;
			exit;
		}
		return 1;
	}
}