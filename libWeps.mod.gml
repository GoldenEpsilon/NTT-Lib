/*	                
	This is the Weps package of Lib, for
	functions that help with making weapons
*/

//todo: eat hook, script for robot eating

/*
	Scripts:
		add_junk(_name, _obj, _type, _cost, _pwr)
		superforce_push(obj, ?force, ?direction, ?friction, ?canwallhit, ?dontwait)
		bullet_recycle(_baseChance, _return, _patron)
		wep_raw(_wep)
		weapon_get(_name, _wep)
		weapon_fire_init(_wep)
		weapon_ammo_fire(_wep)
		weapon_ammo_hud(_wep)
		draw_ammo(_index, _primary, _steroids, _ammo, _ammoMin)
		run_movescan(_proj, _mod)
*/

//For internal use, adds the script to be easily usable.
#define addScript(name)
	var ref = mod_variable_get("mod", "lib", "scriptReferences");
	lq_set(ref, name, ["mod", mod_current, name]);
	mod_variable_set("mod", "lib", "scriptReferences", ref);

#define init
	addScript("add_junk");
	addScript("superforce_push");
	addScript("bullet_recycle");
	addScript("weapon_get");
	addScript("weapon_fire_init");
	addScript("weapon_ammo_fire");
	addScript("weapon_ammo_hud");
	addScript("draw_ammo");
	addScript("run_movescan");
	script_ref_call(["mod", "lib", "updateRef"]);
	global.isLoaded = true;

	global.sprRecycleShine = sprite_add_base64("iVBORw0KGgoAAAANSUhEUgAAABIAAAAJCAYAAAA/33wPAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAAZdEVYdFNvZnR3YXJlAHBhaW50Lm5ldCA0LjAuMjHxIGmVAAAATElEQVQoU82NwQ0AIAgDGc3R3FwFwZQmJvz0kn7OUqV1SRkLdiX46K8hHQnQI9Fjn45veNVwZbja4M/+bqBHosf+lCM8oinBR4+HRCYsc5eZijx2CwAAAABJRU5ErkJggg==",2,5,5);
	
	global.junk = {
		laser: {obj: Laser, typ: 5, cost: 1, pwr: 4},
		bullet: {obj: Bullet1, typ: 1, cost: 1, pwr: 1},
		shell: {obj: Bullet2, typ: 2, cost: 1, pwr: 0.2}
	};

#define add_junk(_name, _obj, _type, _cost, _pwr)
//adds a projectile to the "junk" pool of projectiles to spawn (basically, random projectile but balanced)
	lq_set(global.junk, string_lower(_name), {obj:_obj, typ:_typ, cost:_cost, pwr:_pwr});
	
#define superforce_push
//obj, ?force, ?direction, ?friction, ?canwallhit, ?dontwait, ?disableeffects, ?hook_merge
//Thank you JSBurg and Karmelyth for letting me use this from Defpack!
//Use for crazy knockback mechanics
//Usable hooks are: hook_kill, hook_step, hook_hit, hook_bounce, hook_wallhit, hook_wallkill
//Set the variable of the hook to a script reference, and it'll be called when appropriate.
//IMPORTANT: for all the hooks, such as hook_wallhit, if you return 1 you override the usual code
//           Useful for cool stuff, but completely ignorable.
//on_hit passes in the hit object and itself
//Also, on_merge is different than the other hooks - the first argument is the object that will stay, the second is the one that will be destroyed. Leave as-is to have the latest object completely override the previous superforce.
	with argument[0] if !instance_is(self, prop) with instance_create(x, y, CustomObject)
	{
		name         = "SuperForce";
		team         = other.team;
		creator      = other;
		or_maxspeed  = "maxspeed" in other ? other.maxspeed : -1
		mask_index   = other.mask_index;
		sprite_index = mskNothing;
		timer = 4
		if(argument_count > 1){
			superforce = argument[1];
		}else{
			superforce = 18
		}
		if(argument_count > 2){
			superdirection = argument[2];
		}else{
			superdirection = other.direction
		}
		if(argument_count > 3){
			superfriction = argument[3];
		}else{
			superfriction = 1
		}
		if(argument_count > 4){
			canwallhit = argument[4];
		}else{
			canwallhit = true
		}
		if(argument_count > 5){
			dontwait = argument[5];
		}else{
			dontwait = false
		}
		if(argument_count > 6){
			disableeffects = argument[6];
		}else{
			disableeffects = false
		}
		motion_set(superdirection, superforce); // for easier direction manipulation on wall hit

		on_step = script_ref_create(superforce_step);
		
		with instances_matching_ne(instances_matching(CustomObject, "name", "SuperForce"), "id", self)
		{
			if creator == argument[0]
			{
				if(argument_count > 7){
					script_ref_call(argument[7], other, self);
				}
				instance_delete(self);
			}
		}
		return self;
	}
	
#define superforce_step
	//apply "super force" to enemies
	if timer > 0 && dontwait = false{timer -= current_time_scale; exit}
	if !instance_exists(creator) ||instance_is(creator, Nothing) ||instance_is(creator, TechnoMancer) ||instance_is(creator, Turret) ||instance_is(creator, MaggotSpawn) ||instance_is(creator, Nothing) ||instance_is(creator, LilHunterFly) || instance_is(creator, RavenFly){instance_delete(self); exit}
	var pass_step = false
	if("hook_step" in self){
		pass_step = script_ref_call(hook_step);
	}
	if(!pass_step){
		with creator
		{
			if(!other.disableeffects) repeat(2) with instance_create(x, y, Dust){motion_add(other.direction + random_range(-8, 8), choose(1, 2, 2, 3)); sprite_index = sprExtraFeet}
			other.x = x;
			other.y = y;
			if "maxspeed" in self maxspeed = other.superforce
			motion_set(other.direction, other.superforce);
			var _s = "size" in self ? size : 0;
			other.superforce -= other.superfriction * max(1, _s);
			if other.superforce <= 0 {with other {
				if or_maxspeed > -1 {
					other.maxspeed = or_maxspeed
				}
				instance_delete(self)
				exit}
			}
		}
		if(!disableeffects) if superforce >= 3 with instance_create(creator.x + random_range(-3, 3), creator.y + random_range(-3, 3), ImpactWrists){
			var _fac = .6
			image_xscale = _fac
			image_yscale = _fac
			image_speed = .75
			motion_add(other.creator.direction, random_range(1, 3) + 1)
			image_angle = direction
		}
		if place_meeting(x + hspeed, y + vspeed, Wall) && canwallhit = true
		{
			var pass_bounce = false
			if("hook_bounce" in self){
				pass_bounce = script_ref_call(hook_bounce);
			}
			if(!pass_bounce){
				if(!disableeffects) with instance_create(x, y, MeleeHitWall){image_angle = other.direction} 
				move_bounce_solid(false);
				if(!disableeffects) {
					sound_play_pitchvol(sndImpWristKill, 1.2, .8)
					sound_play_pitchvol(sndWallBreak, .7, .8)
					sound_play_pitchvol(sndHitRock, .8, .8)
					sleep(32)
					view_shake_at(x, y, 8 * clamp(creator.size, 1, 3))
					repeat(creator.size) instance_create(x, y, Debris)
				}
			}
			if superforce > 4 with creator
			{
				var pass_wallhit = false
				if("hook_wallhit" in other){
					pass_wallhit = script_ref_call(other.hook_wallhit);
				}
				if(!pass_wallhit){
				//trace("wall hit")
					projectile_hit(self,round(ceil(other.superforce * 1.5)),1 ,direction)
					if my_health <= 0
					{	
						var pass_wallkill = false
						if("hook_wallkill" in other){
							pass_wallkill = script_ref_call(other.hook_wallkill);
						}
						if(!pass_wallkill){
							if(!other.disableeffects) {
								sleep(30)
								view_shake_at(x, y, 16)
								repeat(3) instance_create(x, y, Dust){sprite_index = sprExtraFeet}
							}
						}
					}
				}
			}
			if(!pass_bounce){
				superforce *= .7
				/*with instance_create(x+lengthdir_x(12,direction),y+lengthdir_y(12,direction),AcidStreak){
					sprite_index = spr.SonicStreak
					image_angle = other.direction + random_range(-32, 32) - 90
					motion_add(image_angle+90,12)
					friction = 2.1
				}*/
				if(!disableeffects) {
					with instance_create(x, y, ChickenB) image_speed = .65
					repeat(max(1, creator.size)) with instance_create(x, y, ImpactWrists){
						var _fac = random_range(.2, .5)
						image_xscale = _fac
						image_yscale = _fac * 1.5
						image_speed = 1 - _fac
						motion_add(random(360), random_range(1, 3) + 1)
						image_angle = direction
					}
				}
			}
		}
		if place_meeting(x + hspeed, y + vspeed, hitme)
		{
			var _h = instance_nearest(x + hspeed, y + vspeed, hitme);
			if !instance_is(_h, Player) && _h != creator && projectile_canhit_melee(_h)
			{
				var pass_hit = false
				if("hook_hit" in self){
					pass_hit = script_ref_call(hook_hit, _h, self);
				}
				if(!pass_hit){
					var _d = "meleedamage" in creator ? creator.meleedamage * 2 : 5;
					var _s = (ceil(superforce) + _h.size) + _d;
					if(!disableeffects) {
						sleep(_s / 3 * max(1, _h.size))
						view_shake_at(x, y, _s / 3 * max(1, _h.size))
					}
					projectile_hit(_h,_s, superforce, direction);
					projectile_hit(creator, round(superforce / 2), 0, direction);
					//trace("enemy hit")
					superforce *= .85 + .15 * min(skill_get(mut_impact_wrists), 1);
				}
			}
		}
	}
	

#define bullet_recycle(_baseChance,_return,_patron)
//Thanks Class!
//_baseChance is the chance for the bullet to be returned, the vanilla chance is 60 So it should be that.
//_return is the amount of bullets to return to the player.
//_patron is who to return the bullets to. by default this isn't creator if you use that for other things.
var _odds = _baseChance * skill_get(mut_recycle_gland)
if random(100) < _odds{
	with _patron if instance_is(self, Player){
	ammo[1] = min(ammo[1] + _return, typ_amax[1])	//return the ammo
	}
		sound_play(sndRecGlandProc)
		if _return == 1{	//Use the default effect if theres only 1 bullet being returned
			instance_create(x, y, RecycleGland)
		}else{
		repeat(_return){
			name = "RecycleGlandCasing"
			with instance_create(x,y,CustomObject){
			direction = 90 - random_range(135,-135)
			speed = random(0.8) + 0.8
			sprite_index = sprBulletShell
			spin = choose(5,-5,8,-8,3,-3)
			lifetime = 15 + irandom_range(2,-2);
			image_alpha = -1
			z = 10 / 4;	//This thing fucks with the z axis
			z_velocity = 12 /4;
			z_gravity = 1.1 /3;
			on_step = RecycleFXStep
			on_draw = RecycleFXDraw
				}
			}
		}
	}
	
#define RecycleFXStep
z = max(0,z + z_velocity * current_time_scale) //z position is capped at zero

z_velocity -= z_gravity * current_time_scale //I don't think I need to clamp, these don't go too fast

image_angle += spin	//SPEEEEEEEEEEEEEN
lifetime -= current_time_scale

if lifetime == 0{	//Delete the fucker from existance when prompted
with instance_create(x,y-z,CaveSparkle){
sprite_index = global.sprRecycleShine
}
instance_destroy()
}
	
#define RecycleFXDraw

depth = lerp(-3 ,-7, min(4,z)/2) //Set depth

image_angle = point_direction(x,y,x+hspeed,y-z_velocity)

y -= z
draw_sprite_ext(sprite_index, image_index, x, y, image_xscale, image_yscale, image_angle, image_blend, 1);	//actually draw the fucking sprite poggers

y += z

#define wep_raw(_wep)
	/*
		For use with LWO weapons
		Call a weapon's "weapon_raw" script in case of wrapper weapons
		
		Ex:
			wep_raw({ wep:{ wep:{ wep:123 }}}) == 123
	*/
	
	var _raw = _wep;
	
	 // Find Base Weapon:
	while(is_object(_raw)){
		_raw = (("wep" in _raw) ? _raw.wep : wep_none);
	}
	
	 // Wrapper:
	if(is_string(_raw) && mod_script_exists("weapon", _raw, "weapon_raw")){
		_raw = mod_script_call("weapon", _raw, "weapon_raw", _wep);
	}
	
	return _raw;

#define weapon_get(_name, _wep)
	/*
		Calls the given script from a weapon mod and fetches its return value
	*/
	
	var _raw = _wep;
	
	 // Find Base Weapon:
	while(is_object(_raw) && "wep" in _raw){
		_raw = _raw.wep;
	}
	
	 // Call Script:
	if(is_string(_raw)){
		var _scrt = "weapon_" + _name;
		if(mod_script_exists("weapon", _raw, _scrt)){
			return mod_script_call_self("weapon", _raw, _scrt, _wep);
		}
	}
	
	 // Default:
	switch(_name){
		
		case "avail":
		case "burst":
			
			return 1;
			
		case "loadout":
			
			switch(_raw){
				case wep_revolver                : return sprRevolverLoadout;
				case wep_golden_revolver         : return sprGoldRevolverLoadout;
				case wep_chicken_sword           : return sprChickenSwordLoadout;
				case wep_rogue_rifle             : return sprRogueRifleLoadout;
				case wep_rusty_revolver          : return sprRustyRevolverLoadout;
				case wep_golden_wrench           : return sprGoldWrenchLoadout;
				case wep_golden_machinegun       : return sprGoldMachinegunLoadout;
				case wep_golden_shotgun          : return sprGoldShotgunLoadout;
				case wep_golden_crossbow         : return sprGoldCrossbowLoadout;
				case wep_golden_grenade_launcher : return sprGoldGrenadeLauncherLoadout;
				case wep_golden_laser_pistol     : return sprGoldLaserPistolLoadout;
				case wep_golden_screwdriver      : return sprGoldScrewdriverLoadout;
				case wep_golden_assault_rifle    : return sprGoldAssaultRifleLoadout;
				case wep_golden_slugger          : return sprGoldSluggerLoadout;
				case wep_golden_splinter_gun     : return sprGoldSplintergunLoadout;
				case wep_golden_bazooka          : return sprGoldBazookaLoadout;
				case wep_golden_plasma_gun       : return sprGoldPlasmaGunLoadout;
				case wep_golden_nuke_launcher    : return sprGoldNukeLauncherLoadout;
				case wep_golden_disc_gun         : return sprGoldDiscgunLoadout;
				case wep_golden_frog_pistol      : return sprGoldToxicGunLoadout;
			}
			
			break;
			
		case "raw":
			
			return (is_object(_wep) ? wep_none : _wep);
			
	}
	
	return 0;
	
#define weapon_fire_init(_wep)
	/*
		Called from a 'weapon_fire' script to do some basic weapon firing setup
		Returns a LWO with some useful variables
		
		Vars:
			wep     - The weapon's value, may be modified from the given argument
			creator - The actual instance firing, for 'player_fire_ext()' support
			primary - The weapon is in the primary slot (true) or secondary slot (false)
			wepheld - The weapon is physically stored in the creator's 'wep' variable
			spec    - The weapon is being shot by an active (YV, Steroids, Skeleton)
			burst   - The current burst shot (starts at 1)
	*/
	
	var _fire = {
		"wep"     : _wep,
		"creator" : noone,
		"primary" : true,
		"wepheld" : false,
		"spec"    : false,
		"burst"   : 1
	};
	
	 // Creator:
	_fire.creator = self;
	if(instance_is(self, FireCont) && "creator" in self){
		_fire.creator = creator;
	}
	
	 // Weapon Held by Creator:
	_fire.wepheld = (variable_instance_get(_fire.creator, "wep") == _fire.wep);
	
	 // Active / Secondary Firing:
	_fire.spec = variable_instance_get(self, "specfiring", false);
	if(race == "steroids" && _fire.spec){
		_fire.primary = false;
	}
	
	 // LWO Setup:
	var _lwo = mod_variable_get("weapon", wep_raw(_fire.wep), "lwoWep");
	if(is_object(_lwo)){
		if(!is_object(_fire.wep)){
			_fire.wep = { "wep" : _fire.wep };
			if(_fire.wepheld){
				_fire.creator.wep = _fire.wep;
			}
		}
		for(var i = lq_size(_lwo) - 1; i >= 0; i--){
			var _key = lq_get_key(_lwo, i);
			if(_key not in _fire.wep){
				lq_set(_fire.wep, _key, lq_get_value(_lwo, i));
			}
		}
	}
	
	 // Extra Systems:
	var _other = other;
	with(instance_exists(_fire.creator) ? _fire.creator : self){
		
		 // Normal Weapon:
		{
			 // Melee:
			if(weapon_is_melee(_fire.wep)){
				other.wepangle *= -1;
			}
		}
	}
	
	return _fire;

#define weapon_ammo_fire(_wep)
	/*
		Called from a 'weapon_fire' script to process LWO weapons with internal ammo
		Returns 'true' if the weapon had enough internal ammo to fire, 'false' otherwise
	*/
	
	 // Gun Warrant:
	if(infammo != 0){
		return true;
	}
	
	 // Ammo Cost:
	var _cost = lq_defget(_wep, "cost", 1);
	with(_wep) if(ammo >= _cost){
		ammo -= _cost;
		
		 // Can Fire:
		return true;
	}
	
	 // Not Enough Ammo:
	reload = variable_instance_get(self, "reloadspeed", 1) * current_time_scale;
	if("anam" in _wep){
		if(button_pressed(index, (specfiring ? "spec" : "fire"))){
			wkick = -2;
			sound_play(sndEmpty);
			with(instance_create(x, y, PopupText)){
				target = other.index;
				text   = ((_wep.ammo > 0) ? "NOT ENOUGH " + _wep.anam : "EMPTY");
			}
		}
	}
	
	return false;
	
#define weapon_ammo_hud(_wep)
	/*
		Called from a 'weapon_sprt_hud' script to draw HUD for LWO weapons with internal ammo
		Returns the weapon's normal sprite for easy returning
		
		Ex:
			#define weapon_sprt_hud(w)
				return weapon_ammo_hud(w);
	*/
	
	 // Draw Ammo:
	if(
		instance_is(self, Player)
		&& (instance_is(other, TopCont) || instance_is(other, UberCont))
		&& is_object(_wep)
	){
		var	_ammo    = lq_defget(_wep, "ammo", 0),
			_ammoMax = lq_defget(_wep, "amax", _ammo),
			_ammoMin = lq_defget(_wep, "amin", round(_ammoMax * 0.2));
			
		draw_ammo(index, (bwep != _wep), (race == "steroids"), _ammo, _ammoMin);
	}
	
	 // Default Sprite:
	return weapon_get_sprt(_wep);
	
#define draw_ammo(_index, _primary, _steroids, _ammo, _ammoMin)
	/*
		Draws ammo HUD text
		
		Args:
			index    - The player to draw HUD for
			primary  - Is a primary weapon, true/false
			steroids - Player can dual wield, true/false
			ammo     - Ammo, can be a string or number
			ammoMin  - Low ammo threshold
	*/
	
	var _local = player_find_local_nonsync();
	
	if(player_is_active(_local) && player_get_show_hud(_index, _local)){
		if(!instance_exists(menubutton) || _index == _local){
			var	_x = view_xview_nonsync + (_primary ? 42 : 86),
				_y = view_yview_nonsync + 21;
				
			 // Co-op Offset:
			var _active = 0;
			for(var i = 0; i < maxp; i++){
				_active += player_is_active(i);
			}
			if(_active > 1){
				_x -= 19;
			}
			
			 // Color:
			var _text = "";
			if(is_real(_ammo)){
				_text += "@";
				if(_ammo > 0){
					if(_primary || _steroids){
						if(_ammo > _ammoMin){
							_text += "w";
						}
						else _text += "r";
					}
					else _text += "s";
				}
				else _text += "d";
			}
			_text += string(_ammo);
			
			 // !!!
			draw_set_halign(fa_left);
			draw_set_valign(fa_top);
			draw_set_projection(2, _index);
			draw_text_nt(_x, _y, _text);
			draw_reset_projection();
		}
	}
	
#define run_movescan(_proj, _mod)
with(_proj){
	var size = 0.8;
	repeat(_mod){
		if(!instance_exists(self)){continue;}
		event_perform(ev_step, ev_step_begin);
		if(!instance_exists(self)){continue;}
		event_perform(ev_step, ev_step_normal);
		if(!instance_exists(self)){continue;}
		if(!instance_exists(self)){continue;}
		if(image_index >= image_number){
			event_perform(ev_other, ev_animation_end)
		}
		image_index += image_speed_raw;
		with(instance_create(x,y,Effect)){
			sprite_index = other.sprite_index;
			image_index = other.image_index;
			image_speed = 0;
			image_xscale = other.image_xscale// * size;
			image_yscale = other.image_yscale// * size;
			image_alpha = other.image_alpha * size;
			image_angle = other.image_angle;
			if(fork()){
				if(instance_exists(self)){
					image_alpha *= 0.5;
					//image_xscale *= 0.8;
					//image_yscale *= 0.8;
				}
				wait(1);
				if(instance_exists(self)){
					image_alpha *= 0.5;
					//image_xscale *= 0.8;
					//image_yscale *= 0.8;
				}
				wait(1);
				if(instance_exists(self)){
					image_alpha *= 0.5;
					//image_xscale *= 0.8;
					//image_yscale *= 0.8;
				}
				wait(1);
				if(instance_exists(self)){
					instance_destroy();
				}
				exit;
			}
		}
		xprevious = x;
		yprevious = y;
		x += hspeed_raw;
		y += vspeed_raw;
		var _inst = call(scr.instances_meeting, x, y, [projectile, hitme, Wall]);
		with(_inst){
			if(!instance_exists(_proj)){continue;}
			if("nexthurt" in self){nexthurt -= current_time_scale;}
			with(_proj){
				event_perform(ev_collision, other.object_index);
				if(!instance_exists(self)){continue;}
			}
		}
		if(!instance_exists(self)){continue;}
		event_perform(ev_step, ev_step_end);
		size += 0.2/_mod
	}
	if(!instance_exists(self)){continue;}
	with(instance_create(x,y,Effect)){
		sprite_index = other.sprite_index;
		image_index = other.image_index;
		image_speed = 0;
		image_xscale = other.image_xscale// * size;
		image_yscale = other.image_yscale// * size;
		image_alpha = other.image_alpha * size;
		image_angle = other.image_angle;
		if(fork()){
			if(instance_exists(self)){
				image_alpha *= 0.5;
				//image_xscale *= 0.8;
				//image_yscale *= 0.8;
			}
			wait(1);
			if(instance_exists(self)){
				image_alpha *= 0.5;
				//image_xscale *= 0.8;
				//image_yscale *= 0.8;
			}
			wait(1);
			if(instance_exists(self)){
				image_alpha *= 0.5;
				//image_xscale *= 0.8;
				//image_yscale *= 0.8;
			}
			wait(1);
			if(instance_exists(self)){
				instance_destroy();
			}
			exit;
		}
	}
}