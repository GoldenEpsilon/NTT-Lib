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
*/

//For internal use, adds the script to be easily usable.
#define addScript(name)
	var ref = mod_variable_get("mod", "lib", "scriptReferences");
	lq_set(ref, name, ["mod", mod_current, name]);
	mod_variable_set("mod", "lib", "scriptReferences", ref);

#define init
	addScript("");
	script_ref_call(["mod", "lib", "updateRef"]);
	global.isLoaded = true;
	
	global.junk = {
		laser: {obj: Laser, typ: 5, cost: 1, pwr: 4},
		bullet: {obj: Bullet1, typ: 1, cost: 1, pwr: 1},
		shell: {obj: Bullet2, typ: 2, cost: 1, pwr: 0.2}
	};

#define add_junk(_name, _obj, _type, _cost, _pwr)
	lq_set(global.junk, string_lower(_name), {obj:_obj, typ:_typ, cost:_cost, pwr:_pwr});
	
#define superforce(_obj)
	with _obj if !instance_is(self, prop) with instance_create(x, y, CustomObject)
	{
		with instances_matching(CustomObject, "name", "SuperForce")
		{
			if creator == _obj
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
		canwallhit   = _cwh
		timer = 4
		dontwait = _dwt
		with _explo
		{
			if "force"          in self other.superforce 	 = force else {other.superforce = 18};
			if "superfriction"  in self other.superfriction  = superfriction else other.superfriction = 1;
			if "superdirection" in self other.superdirection = superdirection;
		}
		motion_set("superdirection" in self ? superdirection : other.direction, superforce); // for easier direction manipulation on wall hit

		on_step = superforce_step;
	}