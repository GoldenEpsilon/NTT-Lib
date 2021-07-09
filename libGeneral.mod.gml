/*	                General
	This is the General package of Lib, for
	most of your Lib needs.
	If you're using Lib, you probably want
	to load this.
*/

/*
	Scripts:
		#define obj_create(_x, _y, _name)
		#define instances_in_rectangle(_x1, _y1, _x2, _y2, _obj)
		#define instances_meeting(_x, _y, _obj)
		#define instance_nearest_rectangle(_x1, _y1, _x2, _y2, _obj)
		#define player_swap(_player)
		#define projectile_create(inst, x, y, obj, ?dir=0, ?spd=0)
		#define projectile_euphoria(_inst)
		#define sound_play_at (x, y, sound, ?pitch=1, ?volume=1, ?fadeDis=64, ?fadeFactor=1)
		#define pool(_pool)
*/

//For internal use, adds the script to be easily usable.
#define addScript(name)
	mod_variable_set("mod", "lib", "scriptReferences", ["mod", mod_current, name]);

#define init
	addScript("obj_setup");
	addScript("obj_setup_ext");
	addScript("obj_create");
	addScript("instances_in_rectangle");
	addScript("instances_meeting");
	addScript("instance_nearest_rectangle");
	addScript("player_swap");
	addScript("projectile_create");
	addScript("projectile_euphoria");
	addScript("sound_play_at");
	addScript("pool");
	script_ref_call(["mod", "lib", "updateRef"]);
	
	global.objects = ds_map_create();
	
#define obj_setup(_mod, _name)
/* Creator: Golden Epsilon
Description: 
	Sets up a custom object to be created using obj_create.
	Should only be run from .mod.gml-style mods
Arguments:
	_mod : the name of the mod that has the relevant scripts
	_name : the name of the object (make sure this is unique) (can be an array)
*/
	if(is_array(_name)){
		for(var i = 0; i < array_length(_name); i++){
			obj_setup(_mod, _name[i]);
		}
		return;
	}
	global.objects[? _name] = {
		setup : false,
		type : "mod", 
		modName : _mod, 
		name : _name
	};
	
#define obj_setup_ext(_mod, _name, _type)
/* Creator: Golden Epsilon
Description: 
	Sets up a custom object to be created using obj_create.
Arguments:
	_mod : the name of the mod that has the relevant scripts
	_name : the name of the object (make sure this is unique) (can be an array)
	_type : the type of the mod that has the object's scripts
*/
	if(is_array(_name)){
		for(var i = 0; i < array_length(_name); i++){
			obj_setup_ext(_mod, _name[i], _type);
		}
		return;
	}
	global.objects[? _name] = {
		setup : false,
		type : _type, 
		modName : _mod, 
		name : _name
	};

#define obj_create(_x, _y, _name)
/* Creator: Yokin (modified by Golden Epsilon)
Description: 
	Creates an object, vanilla or custom, and sets up scripts for it automatically.
	If it is a custom object, run obj_setup for it before running obj_create 
	(you only need to run obj_setup once for each object, though)
Arguments:
	_x : the x position of the object when created
	_y : the y position of the object when created
	_name : the name of the object to create (can be an array bcuz wynaut)
Returns:
	The created object.
*/
	if(is_array(_name)){
		var _insts = [];
		for(var i = 0; i < array_length(_name); i++){
			array_push(_insts, obj_create(_x, _y, _name[i]));
		}
		return _insts;
	}
    
     // Normal Object:
    if(is_real(_name) && object_exists(_name)){
        return instance_create(_x, _y, _name);
    }
	
     // Custom Object:
    if(ds_map_exists(global.objects, _name)){
		var obj = global.objects[? _name];
		if(!obj.setup){
			global.objects[? _name].setup = true;
			 // Auto Script Binding (thanks bee):
			with([
				
				 // General:
				"_begin_step",
				"_step",
				"_end_step",
				"_draw",
				"_destroy",
				"_cleanup",
				
				 // Hitme/Enemy:
				"_hurt",
				"_death",
				
				 // Projectile:
				"_anim",
				"_wall",
				"_hit",
				
				 // Slash:
				"_grenade",
				"_projectile"
			]){
				var _var =  "on" + self,
					_scr = _name + self;
				
				if(mod_script_exists(obj.type, obj.modName, _scr)){
					var _ref = script_ref_create_ext(obj.type, obj.modName, _scr);
					variable_instance_set(global.objects[? _name], _var, _ref);
				} else {
					variable_instance_set(global.objects[? _name], _var, undefined);
				}
			}
		
			for(var i = 0; i <= 11; i++) {
				var _alrm = "_alrm" + string(i);
				
				if(mod_script_exists(obj.type, obj.modName, string(_name) + _alrm)){
					var _ref = script_ref_create_ext(obj.type, obj.modName, string(_name) + _alrm);
					variable_instance_set(global.objects[? _name], "on" + _alrm, _ref);
				} else {
					variable_instance_set(global.objects[? _name], "on" + _alrm, undefined);
				}
			}
			
			//need to update obj because setup probably added stuff to the variable behind it
			obj = global.objects[? _name];
		}
		
		var _inst = script_ref_call([obj.type, obj.modName, obj.name + "_create"], _x, _y);
            
         // No Return Value:
        if(is_undefined(_inst) || _inst == 0){
            _inst = noone;
        }
        
         // Auto Assign Things:
        if(is_real(_inst) && instance_exists(_inst)){
			with([
				
				 // General:
				"_begin_step",
				"_step",
				"_end_step",
				"_draw",
				"_destroy",
				"_cleanup",
				
				 // Hitme/Enemy:
				"_hurt",
				"_death",
				
				 // Projectile:
				"_anim",
				"_wall",
				"_hit",
				
				 // Slash:
				"_grenade",
				"_projectile"
			]){
				var _var =  "on" + self;
				if(variable_instance_get(global.objects[? _name], _var) != undefined){
					variable_instance_set(_inst, _var, variable_instance_get(global.objects[? _name], _var));
				}
				
				else {
					switch(self) {
						case "_step": 
							if(instance_is(_inst, CustomEnemy)) _inst.on_step = script_ref_create_ext(obj.type, obj.modName, "enemy_step"); 
							else if(instance_is(_inst, CustomHitme)) _inst.on_step = script_ref_create_ext(obj.type, obj.modName, "hitme_step"); 
						break;
						case "_hurt": if(instance_is(_inst, hitme)) _inst.on_hurt = script_ref_create_ext(obj.type, obj.modName, "enemy_hurt"); break;
						case "_death": if(instance_is(_inst, CustomEnemy)) _inst.on_death = script_ref_create_ext(obj.type, obj.modName, "enemy_death"); break;
						case "_draw": if(instance_is(_inst, CustomEnemy)) _inst.on_draw = script_ref_create_ext(obj.type, obj.modName, "draw_self_enemy"); break;
					}
				}
			}
			
			for(var i = 0; i <= 11; i++) {
				var _alrm = "_alrm" + string(i);
				
				if(variable_instance_get(global.objects[? _name], "on" + _alrm) != undefined){
					variable_instance_set(_inst, "on" + _alrm, variable_instance_get(global.objects[? _name], "on" + _alrm));
				}
			}
					
			if(instance_is(_inst, hitme)) {
				if(variable_instance_exists(_inst, "spr_idle")) _inst.sprite_index = _inst.spr_idle;
				if(instance_is(_inst, CustomEnemy)) _inst.target = noone;
			}
		}
        
        return _inst;
    }
    
     // Return List of Objects:
    if(is_undefined(_name)){
        var _list = [];
        
        for(var i = lq_size(global.objects) - 1; i >= 0; i--){
            array_push(_list, lq_get_key(global.objects, i));
        }
        
        return _list;
    }
    
    return noone;
	
//This section of code is for obj_create, based on Tildebee code from Relics. Thanks bee!
#macro  infinity                                                                                1/0
#macro  anim_end                                                                                (image_index + image_speed >= image_number) || (image_index + image_speed < 0)
#macro  enemy_sprite                                                                            (sprite_index != spr_hurt || anim_end) ? ((speed == 0) ? spr_idle : spr_walk) : sprite_index
#macro  target_visible                                                                          !collision_line(x, y, target.x, target.y, Wall, false, false)
#macro  target_direction                                                                        point_direction(x, y, target.x, target.y)
#macro  target_distance                                                                         point_distance(x, y, target.x, target.y)
#macro  alarm0_run                                                                              alarm0 && !--alarm0 && !--alarm0 && (script_ref_call(on_alrm0) || !instance_exists(self))
#macro  alarm1_run                                                                              alarm1 && !--alarm1 && !--alarm1 && (script_ref_call(on_alrm1) || !instance_exists(self))
#macro  alarm2_run                                                                              alarm2 && !--alarm2 && !--alarm2 && (script_ref_call(on_alrm2) || !instance_exists(self))
#macro  alarm3_run                                                                              alarm3 && !--alarm3 && !--alarm3 && (script_ref_call(on_alrm3) || !instance_exists(self))
#macro  alarm4_run                                                                              alarm4 && !--alarm4 && !--alarm4 && (script_ref_call(on_alrm4) || !instance_exists(self))
#macro  alarm5_run                                                                              alarm5 && !--alarm5 && !--alarm5 && (script_ref_call(on_alrm5) || !instance_exists(self))
#macro  alarm6_run                                                                              alarm6 && !--alarm6 && !--alarm6 && (script_ref_call(on_alrm6) || !instance_exists(self))
#macro  alarm7_run                                                                              alarm7 && !--alarm7 && !--alarm7 && (script_ref_call(on_alrm7) || !instance_exists(self))
#macro  alarm8_run                                                                              alarm8 && !--alarm8 && !--alarm8 && (script_ref_call(on_alrm8) || !instance_exists(self))
#macro  alarm9_run                                                                              alarm9 && !--alarm9 && !--alarm9 && (script_ref_call(on_alrm9) || !instance_exists(self))
#define chance(_numer, _denom)                                                          		return  random(_denom) < _numer;
#define chance_ct(_numer, _denom)                                                       		return  random(_denom) < _numer * current_time_scale;
#define orandom(_num)                                                                   		return  random_range(-_num, _num);
#define draw_self_enemy()                                                                       image_xscale *= right; draw_self(); image_xscale /= right;
#define draw_self_gun()																			if(gunangle <= 180) draw_weapon(spr_weap, 0, x, y, gunangle, 0, wkick, right, image_blend, image_alpha); draw_self_enemy(); if(gunangle > 180) draw_weapon(spr_weap, 0, x, y, gunangle, 0, wkick, right, image_blend, image_alpha);
#define enemy_walk(_dir, _num)                                                                  direction = _dir; walk = _num; if(speed < friction) speed = friction;
#define enemy_face(_dir)                                                                        _dir = ((_dir % 360) + 360) % 360; if(_dir < 90 || _dir > 270) right = 1; else if(_dir > 90 && _dir < 270) right = -1;
#define enemy_look(_dir)                                                                        _dir = ((_dir % 360) + 360) % 360; if(_dir < 90 || _dir > 270) right = 1; else if(_dir > 90 && _dir < 270) right = -1; if('gunangle' in self) gunangle = _dir;
#define enemy_target(_x, _y)                                                                    target = (instance_exists(Player) ? instance_nearest(_x, _y, Player) : ((instance_exists(target) && target >= 0) ? target : noone)); return (target != noone);

#define enemy_step
	 // Alarms:
	if("on_alrm0" in self and alarm0_run) exit;
	if("on_alrm1" in self and alarm1_run) exit;
	if("on_alrm2" in self and alarm2_run) exit;
	if("on_alrm3" in self and alarm3_run) exit;
	if("on_alrm4" in self and alarm4_run) exit;
	if("on_alrm5" in self and alarm5_run) exit;
	if("on_alrm6" in self and alarm6_run) exit;
	if("on_alrm7" in self and alarm7_run) exit;
	if("on_alrm8" in self and alarm8_run) exit;
	if("on_alrm9" in self and alarm9_run) exit;
	
	 // Movement:
	if(walk > 0){
		walk -= current_time_scale;
		speed += walkspeed * current_time_scale;
	}
	if(speed > maxspeed){
		speed = maxspeed;
	}
	
	 // Animate:
	sprite_index = enemy_sprite;
	
#define hitme_step
	if(place_meeting(x + hspeed, y + vspeed, Wall)) move_bounce_solid(true);
	
	 // Handle enemies:
	with(instances_meeting(x, y, enemy)){
		if(projectile_canhit_melee(other) && "canmelee" in self && canmelee && meleedamage > 0){
			projectile_hit(other, meleedamage);
		}
		
		with(other){
			if(projectile_canhit_melee(other)){
				projectile_hit(other, 3);
				sound_play_pitch(sndFreakMelee, 1.2 + random(0.4));
			}
		}
	}

#define draw_weapon(_sprite, _image, _x, _y, _angle, _angleMelee, _kick, _flip, _blend, _alpha)
	/*
		Drawing weapon sprites
		
		Ex:
			draw_weapon(sprBanditGun, gunshine, x, y, gunangle, 0, wkick, right, image_blend, image_alpha)
			draw_weapon(sprPipe, 0, x, y, gunangle, wepangle, wkick, wepflip, image_blend, image_alpha)
	*/
	
	 // Context Fix:
	if(!is_real(self) || !instance_exists(self)){
		with(UberCont){
			return draw_weapon(_sprite, _image, _x, _y, _angle, _angleMelee, _kick, _flip, _blend, _alpha);
		}
	}
	
	 // Melee Offset:
	if(_angleMelee != 0){
		_angle += _angleMelee * (1 - (_kick / 20));
	}
	
	 // Kick:
	if(_kick != 0){
		_x -= lengthdir_x(_kick, _angle);
		_y -= lengthdir_y(_kick, _angle);
	}
	
	 // Draw:
	draw_sprite_ext(_sprite, _image, _x, _y, 1, _flip, _angle, _blend, _alpha);
	
#define enemy_hurt(_damage, _force, _direction)
	my_health -= _damage;           // Damage
	nexthurt = current_frame + 6;   // I-Frames
	motion_add(_direction, _force); // Knockback
	sound_play_hit(snd_hurt, 0.2);  // Sound
	
	 // Hurt Sprite:
	sprite_index = spr_hurt;
	image_index  = 0;
	
#define enemy_death
	pickup_drop(20, 0);

//Now back to your regularly scheduled module code

#define instances_in_rectangle(_x1, _y1, _x2, _y2, _obj)
	/*
		Returns all instances of the given object whose positions overlap the given rectangle
		Much better performance than checking 'point_in_rectangle()' on every instance
		
		Args:
			x1/y1/x2/y2 - The rectangular area to search
			obj         - The object(s) to search
	*/
	
	return (
		instances_matching_le(
		instances_matching_le(
		instances_matching_ge(
		instances_matching_ge(
		_obj,
		"x", _x1),
		"y", _y1),
		"x", _x2),
		"y", _y2)
	);

#define instances_meeting(_x, _y, _obj)
	/*
		Returns all instances whose bounding boxes overlap the calling instance's bounding box at the given position
		Much better performance than manually performing 'place_meeting(x, y, other)' on every instance
	*/
	
	var	_tx = x,
		_ty = y;
		
	x = _x;
	y = _y;
	
	var _inst = instances_matching_ne(instances_matching_le(instances_matching_ge(instances_matching_le(instances_matching_ge(_obj, "bbox_right", bbox_left), "bbox_left", bbox_right), "bbox_bottom", bbox_top), "bbox_top", bbox_bottom), "id", id);
	
	x = _tx;
	y = _ty;
	
	return _inst;

#define instance_nearest_rectangle(_x1, _y1, _x2, _y2, _obj)
	/*
		Returns the instance closest to a given rectangle based on their position
		If multiple instances are equally distant from the rectangle, a bias exists for the one closer to its center
		Accepts an array argument like 'instance_nearest_array()' does
		
		Ex:
			instance_nearest_rectangle(x, y, x + 160, y + 64, chestprop)
	*/
	
	var	_cx      = (_x1 + _x2) / 2,
		_cy      = (_y1 + _y2) / 2,
		_disAMax = infinity,
		_disBMax = infinity,
		_nearest = noone;
		
	with(instances_matching_ne(_obj, "id")){
		var	_disA = point_distance(x, y, clamp(x, _x1, _x2), clamp(y, _y1, _y2)),
			_disB = point_distance(x, y, _cx, _cy);
			
		if(_disA < _disAMax || (_disA == _disAMax && _disB < _disBMax)){
			_disAMax = _disA;
			_disBMax = _disB;
			_nearest = self;
		}
	}
	
	return _nearest;

#define player_swap(_player)
	/*
		Cycles the given player's weapon slots
	*/
	
	with(["%wep", "%curse", "%reload", "%wkick", "%wepflip", "%wepangle", "%can_shoot", "%clicked", "%interfacepop", "drawempty%"]){
		var	_name = [string_replace(self, "%", ""), string_replace(self, "%", "b")],
			_temp = variable_instance_get(_player, _name[0], 0);
			
		variable_instance_set(_player, _name[0], variable_instance_get(_player, _name[1], 0));
		variable_instance_set(_player, _name[1], _temp);
	}

#define projectile_create // inst, x, y, obj, dir=0, spd=0
	/*
		Creates a given projectile with the given motion applied
		Automatically sets 'team', 'creator', and 'hitid' based on the given instance
		Automatically applies Euphoria to the projectile if the creator is an enemy
		
		Ex:
			projectile_create(self, x, y, Bullet2, gunangle + orandom(30 * accuracy), 16)
			projectile_create(self, x, y, "DiverHarpoon", gunangle, 7)
			projectile_create(self, x, y, Explosion)
	*/
	
	var	_inst = argument[0],
		_x    = argument[1],
		_y    = argument[2],
		_obj  = argument[3],
		_dir  = ((argument_count > 4) ? argument[4] : 0),
		_spd  = ((argument_count > 5) ? argument[5] : 0),
		_proj = obj_create(_x, _y, _obj);
		
	with(_proj){
		 // Motion:
		direction += _dir;
		if(_spd != 0){
			motion_add(_dir, _spd);
		}
		image_angle += direction;
		
		 // Auto Setup:
		var	_team    = (("team" in _inst) ? _inst.team : (("team" in self) ? team : -1)),
			_creator = (("creator" in _inst && !instance_is(_inst, hitme)) ? _inst.creator : _inst);
			
		projectile_init(_team, _creator);
		
		if("team"    in self) team    = _team;
		if("creator" in self) creator = _creator;
		if("hitid"   in self) hitid   = (("hitid" in _inst) ? _inst.hitid : hitid);
		
		 // Euphoria:
		if(
			is_string(_obj)
			&& skill_get(mut_euphoria) != 0
			&& (instance_exists(_creator) ? instance_is(_creator, enemy) : (_team != 2))
			&& !instance_is(self, EnemyBullet1)
			&& !instance_is(self, EnemyBullet3)
			&& !instance_is(self, EnemyBullet4)
			&& !instance_is(self, HorrorBullet)
			&& !instance_is(self, IDPDBullet)
			&& !instance_is(self, PopoPlasmaBall)
			&& !instance_is(self, LHBouncer)
			&& !instance_is(self, FireBall)
			&& !instance_is(self, ToxicGas)
			&& !instance_is(self, Shank)
			&& !instance_is(self, Slash)
			&& !instance_is(self, EnemySlash)
			&& !instance_is(self, GuitarSlash)
			&& !instance_is(self, CustomSlash)
			&& !instance_is(self, BloodSlash)
			&& !instance_is(self, LightningSlash)
			&& !instance_is(self, EnergyShank)
			&& !instance_is(self, EnergySlash)
			&& !instance_is(self, EnergyHammerSlash)
			&& !instance_is(other, FireCont)
		){
			script_bind_begin_step(projectile_euphoria, 0, self);
		}
	}
	
	return _proj;
	
#define projectile_euphoria(_inst)
	with(_inst){
		speed *= power(0.8, skill_get(mut_euphoria));
	}
	instance_destroy();

#define sound_play_at // x, y, sound, pitch=1, volume=1, fadeDis=64, fadeFactor=1
	/*
		Plays the given sound with a volume based on the given position's distance to the nearest local Player
		Also takes advantage of surround sound systems like headphones to make the sound appear "3D"
		Volume = (playerDis / fadeDis) ^ -fadeFactor
		
		Args:
			x/y        - The sound's position
			sound      - The sound index to play
			pitch      - The played sound's initial pitch, defaults to 1
			volume     - The played sound's initial volume, defaults to 1 (combines with the fade effect)
			fadeDis    - The distance at which the sound begins to fade in volume
			fadeFactor - Determines how fast the sound's volume falls off after the 'fadeDis'
			
		Ex:
			sound_play_at(x, y, snd_hurt, 1 + orandom(0.1))
			sound_play_at(x, y, sndExplosion, 1 + orandom(0.1), 1, 320)
	*/
	
	var	_x          = argument[0],
		_y          = argument[1],
		_sound      = argument[2],
		_pitch      = ((argument_count > 3) ? argument[3] : 1),
		_volume     = ((argument_count > 4) ? argument[4] : 1),
		_fadeDis    = ((argument_count > 5) ? argument[5] : 64),
		_fadeFactor = ((argument_count > 6) ? argument[6] : 1),
		_listenX    = view_xview_nonsync + (game_width  / 2),
		_listenY    = view_yview_nonsync + (game_height / 2);
		
	 // Determine Listener Position:
	if(instance_exists(Player)){
		var _disMax = infinity;
		with(Player){
			var _dis = point_distance(x, y, _x, _y);
			if(_dis < _disMax){
				if(player_is_local_nonsync(index)){
					_disMax = _dis;
					_listenX = x;
					_listenY = y;
				}
			}
		}
	}
	
	 // Play Sound:
	audio_stop_sound(_sound);
	var _snd = audio_play_sound_at(_sound, _listenX - _x, _listenY - _y, 0, _fadeDis, 320, _fadeFactor, false, 0);
	audio_sound_pitch(_snd, _pitch);
	audio_sound_gain(_snd, _volume * audio_sound_get_gain(_snd), 0);
	
	return _snd;
	
#define pool(_pool)
	/*
		Accepts a LWO or array of value:weight pairs, and returns one of the values based on random chance
		
		Ex:
			pool({
				"A" : 4, // 50%
				"B" : 3, // 37.5%
				"C" : 1  // 12.5%
			})
			pool([
				[Bandit,    5], // 50%
				[Scorpion,  3], // 30%
				[BigMaggot, 1], // 10%
				[Maggot,    1]  // 10%
			])
	*/
	
	 // Turn LWO Into Array:
	if(is_object(_pool)){
		var _poolNew = [];
		for(var i = 0; i < lq_size(_pool); i++){
			array_push(_poolNew, [lq_get_key(_pool, i), lq_get_value(_pool, i)]);
		}
		_pool = _poolNew;
	}
	
	 // Roll Max Number:
	var _roll = 0;
	with(_pool){
		_roll += self[1];
	}
	_roll -= random(_roll);
	
	 // Find Rolled Value:
	if(_roll > 0){
		with(_pool){
			_roll -= self[1];
			if(_roll <= 0){
				return self[0];
			}
		}
	}
	
	return null;