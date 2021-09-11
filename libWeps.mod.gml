/*	                
	This is the Weps package of Lib, for
	functions that help with making weapons
*/

/*
||||||||||||||||||||||||UNFINISHED PACKAGE||||||||||||||||||||||||||||
*/

//todo: eat hook, script for robot eating

/*
	Scripts:
		add_junk(_name, _obj, _type, _cost, _pwr)
		superforce(obj, ?superforce, ?canwallhit, ?dontwait, ?superfriction, ?superdirection)
*/

//For internal use, adds the script to be easily usable.
#define addScript(name)
	var ref = mod_variable_get("mod", "lib", "scriptReferences");
	lq_set(ref, name, ["mod", mod_current, name]);
	mod_variable_set("mod", "lib", "scriptReferences", ref);

#define init
	addScript("add_junk");
	addScript("superforce");
	script_ref_call(["mod", "lib", "updateRef"]);
	global.isLoaded = true;
	
	global.junk = {
		laser: {obj: Laser, typ: 5, cost: 1, pwr: 4},
		bullet: {obj: Bullet1, typ: 1, cost: 1, pwr: 1},
		shell: {obj: Bullet2, typ: 2, cost: 1, pwr: 0.2}
	};

#define add_junk(_name, _obj, _type, _cost, _pwr)
//adds a projectile to the "junk" pool of projectiles to spawn (basically, random projectile but balanced)
	lq_set(global.junk, string_lower(_name), {obj:_obj, typ:_typ, cost:_cost, pwr:_pwr});
	
#define superforce
//obj, ?superforce, ?canwallhit, ?dontwait, ?superfriction, ?superdirection
//Thank you JSBurg and Karmelyth for letting me use this from Defpack!
//Use for crazy knockback mechanics
	with argument[0] if !instance_is(self, prop) with instance_create(x, y, CustomObject)
	{
		with instances_matching(CustomObject, "name", "SuperForce")
		{
			if creator == argument[0]
			{
				instance_delete(self);
				exit;
			}
		}
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
			canwallhit = argument[2];
		}else{
			canwallhit = true
		}
		if(argument_count > 3){
			dontwait = argument[3];
		}else{
			dontwait = false
		}
		if(argument_count > 4){
			superfriction = argument[4];
		}else{
			superfriction = 1
		}
		if(argument_count > 5){
			superdirection = argument[5];
		}else{
			superdirection = other.direction
		}
		with argument[0]
		{
			if "force"          in self other.superforce 	 = force else {other.superforce = 18};
			if "superfriction"  in self other.superfriction  = superfriction else other.superfriction = 1;
			if "superdirection" in self other.superdirection = superdirection;
		}
		motion_set(superdirection, superforce); // for easier direction manipulation on wall hit

		on_step = superforce_step;
	}
	
#define superforce_step
	//apply "super force" to enemies
	if timer > 0 && dontwait = false{timer -= current_time_scale; exit}
	if !instance_exists(creator) ||instance_is(creator, Nothing) ||instance_is(creator, TechnoMancer) ||instance_is(creator, Turret) ||instance_is(creator, MaggotSpawn) ||instance_is(creator, Nothing) ||instance_is(creator, LilHunterFly) || instance_is(creator, RavenFly){instance_delete(self); exit}
	with creator
	{
		repeat(2) with instance_create(x, y, Dust){motion_add(other.direction + random_range(-8, 8), choose(1, 2, 2, 3)); sprite_index = sprExtraFeet}
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
	if superforce >= 3 with instance_create(creator.x + random_range(-3, 3), creator.y + random_range(-3, 3), ImpactWrists){
		var _fac = .6
		image_xscale = _fac
		image_yscale = _fac
		image_speed = .75
		motion_add(other.creator.direction, random_range(1, 3) + 1)
		image_angle = direction
	}
	if place_meeting(x + hspeed, y + vspeed, Wall) && canwallhit = true
	{
	  with instance_create(x, y, MeleeHitWall){image_angle = other.direction} move_bounce_solid(false);
		sound_play_pitchvol(sndImpWristKill, 1.2, .8)
		sound_play_pitchvol(sndWallBreak, .7, .8)
		sound_play_pitchvol(sndHitRock, .8, .8)
		sleep(32)
		view_shake_at(x, y, 8 * clamp(creator.size, 1, 3))
		repeat(creator.size) instance_create(x, y, Debris)
		if superforce > 4 with creator
		{
			//trace("wall hit")
			projectile_hit(self,round(ceil(other.superforce) * 1.5),1 ,direction)
			if my_health <= 0
			{
				sleep(30)
				view_shake_at(x, y, 16)
				repeat(3) instance_create(x, y, Dust){sprite_index = sprExtraFeet}
			}
		}
		superforce *= .7
		with instance_create(x+lengthdir_x(12,direction),y+lengthdir_y(12,direction),AcidStreak){
			sprite_index = spr.SonicStreak
			image_angle = other.direction + random_range(-32, 32) - 90
			motion_add(image_angle+90,12)
			friction = 2.1
		}
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
	if place_meeting(x + hspeed, y + vspeed, hitme)
	{
		var _h = instance_nearest(x + hspeed, y + vspeed, hitme);
		if !instance_is(_h, Player) && _h != creator && projectile_canhit_melee(_h)
		{
			var _d = "meleedamage" in creator ? creator.meleedamage * 2 : 5;
			var _s = (ceil(superforce) + _h.size) + _d;
			sleep(_s / 3 * max(1, _h.size))
			view_shake_at(x, y, _s / 3 * max(1, _h.size))
			projectile_hit(_h,_s, superforce, direction);
			projectile_hit(creator, round(superforce / 2), 0, direction);
			//trace("enemy hit")
			superforce *= .85 + .15 * min(skill_get(mut_impact_wrists), 1);
		}
	}