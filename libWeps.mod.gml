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

		on_step = superforce_step;
		
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
					projectile_hit(self,round(ceil(other.superforce) * 1.5),1 ,direction)
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