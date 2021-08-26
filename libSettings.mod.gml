/*	                Settings
	This is the Settings package of Lib, for
	EXTREMELY basic settings.
	Use this if you want people to be able to 
	change stuff in your mod but you don't
	want to spend a day doing it right.
*/

/*
	Scripts:
	#define settings_add(_modName, _variableName, _visualName)
*/

//For internal use, adds the script to be easily usable.
#define addScript(name)
	var ref = mod_variable_get("mod", "lib", "scriptReferences");
	lq_set(ref, name, ["mod", mod_current, name]);
	mod_variable_set("mod", "lib", "scriptReferences", ref);

#define init
	
	addScript("settings_add");
	script_ref_call(["mod", "lib", "updateRef"]);
	global.isLoaded = true;

	script_ref_call(["mod", "lib", "import"], "libMenu");
	
	script_ref_call(["mod", "lib", "getRef"], "mod", mod_current, "scr");
	
	global.settings = [];
	global.open = 1;
	global.offset = 0;
	
	global.a = 1;
	settings_add("libSettings", "a", "testVar");
	settings_add("libSettings", "a", "testVar");
	settings_add("libSettings", "a", "testVar");
	settings_add("libSettings", "a", "testVar");
	settings_add("libSettings", "a", "testVar");
	settings_add("libSettings", "a", "testVar");

#define draw_gui
	draw_set_font(fntSmall);
	draw_set_color(c_white);
	if(call(scr.menubutton_check, game_width - 40, game_height - 6, 38, 4, 2, 1) != -1){
		draw_set_color(c_lime);
	}
	draw_text(game_width - 40, game_height - 6, "[SETTINGS]");
	draw_set_font(fntM0);
	draw_set_color(c_black);
	
	if(call(scr.menubutton_check, game_width - 40, game_height - 6, 38, 4, 0, 1) != -1){
		global.open = !global.open;
	}
	
	if(global.open){
		draw_set_color(c_white);
		var offset = global.offset;
		for(var i = 0; i < array_length(global.settings); i++){
			var v = mod_variable_get("mod", global.settings[i][1], global.settings[i][2]);
			draw_sprite(sprScoreSplat, 2, game_width/2 - 65, 42 + offset * 10);
			draw_sprite(sprScoreSplat, 2, game_width/2 + 5, 42 + offset * 10);
			offset++;
		}
		offset = global.offset;
		for(var i = 0; i < array_length(global.settings); i++){
			var v = mod_variable_get("mod", global.settings[i][1], global.settings[i][2]);
			if(is_real(v)){
				draw_set_halign(2);
				draw_text(game_width/2, 40 + offset * 10, global.settings[i][3] + " ");
				draw_set_halign(1);
				draw_text(game_width/2, 40 + offset * 10, ":");
				draw_set_halign(0);
				draw_text(game_width/2, 40 + offset * 10, " " + string(v));
			}
			offset++;
		}
		draw_set_color(c_black);
	}
	
#define add_setting(_modName, _variableName, _visualName)
	array_push(global.settings, ["mod", _modName, _variableName, _visualName]);
	
#define add_setting_ext(_modName, _modType, _variableName, _visualName)
	array_push(global.settings, [_modType, _modName, _variableName, _visualName]);
	
#macro scr global.scr
#macro call script_ref_call