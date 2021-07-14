/*	                Areas
	This is the Areas package of Lib, for
	generation on area creation and on the fly.
*/

/*
	Scripts:
		#define floor_fill(_x, _y, _w, _h, _type)
*/

//For internal use, adds the script to be easily usable.
#define addScript(name)
	var ref = mod_variable_get("mod", "lib", "scriptReferences");
	lq_set(ref, name, ["mod", mod_current, name]);
	mod_variable_set("mod", "lib", "scriptReferences", ref);

#define init
	script_ref_call(["mod", "lib", "updateRef"]);
	
#define floor_fill(_x, _y, _w, _h, _type)
	/*
		Creates a rectangular area of floors around the given position
		The type can be "" for default, "round" for no corners, or "ring" for no inner floors
		
		Ex:
			floor_fill(x, y, 3, 3, "")
				###
				###
				###
				
			floor_fill(x, y, 5, 4, "round")
				 ###
				#####
				#####
				 ###
				 
			floor_fill(x, y, 4, 4, "ring")
				####
				#  #
				#  #
				####
	*/
	
	var	_ow = 32,
		_oh = 32;
		
	_w *= _ow;
	_h *= _oh;
	
	 // Center & Align:
	_x -= (_w / 2);
	_y -= (_h / 2);
	var _gridPos = floor_align(_x, _y, _w, _h, _type);
	_x = _gridPos[0];
	_y = _gridPos[1];
	
	 // Floors:
	var	_ax   = global.floor_align_x,
		_ay   = global.floor_align_y,
		_aw   = global.floor_align_w,
		_ah   = global.floor_align_h,
		_inst = [];
		
	floor_set_align(_x, _y, _ow, _oh);
	
	for(var _oy = 0; _oy < _h; _oy += _oh){
		for(var _ox = 0; _ox < _w; _ox += _ow){
			var _make = true;
			
			 // Type-Specific:
			switch(_type){
				case "round": // No Corner Floors
					_make = ((_ox != 0 && _ox != _w - _ow) || (_oy != 0 && _oy != _h - _oh));
					break;
					
				case "ring": // No Inner Floors
					_make = (_ox == 0 || _oy == 0 || _ox == _w - _ow || _oy == _h - _oh);
					break;
			}
			
			if(_make){
				array_push(_inst, floor_set(_x + _ox, _y + _oy, true));
			}
		}
	}
	
	floor_set_align(_ax, _ay, _aw, _ah);
	
	return _inst;
	
#define area_generate(_area, _subarea, _loops, _x, _y, _setArea, _overlapFloor, _scrSetup)
	/*
		Deactivates the game, generates a given area, and reactivates the game
		Returns the ID of the GenCont used to create the area, or null if the area couldn't be generated
		
		Args:
			area/subarea/loops - Area to generate
			x/y                - Spawn position
			setArea            - Set the current area to the generated area
			                       True  : Sets the area, background_color, BackCont vars, TopCont vars, and calls .mod level_start scripts
			                       False : Maintains the current area and deletes new IDPD spawns
			overlapFloor       - Number 0 to 1, determines the percent of current level floors that can be overlapped
			scrSetup           - Script reference, called right before floor generation
			
		Ex:
			var _genID = area_generate(area_scrapyards, 3, GameCont.loops, x, y, false, 0, null);
			with(instances_matching_gt(chestprop, "id", _genID)){
				instance_delete(self);
			}
	*/
	
	if(is_real(_area) || is_string(_area)){
		var	_lastArea            = GameCont.area,
			_lastSubarea         = GameCont.subarea,
			_lastLoops           = GameCont.loops,
			_lastBackgroundColor = background_color,
			_lastLetterbox       = game_letterbox,
			_lastViewObj         = [],
			_lastViewPan         = [],
			_lastViewShk         = [],
			_lastObjVars         = [],
			_lastSolid           = [];
			
		 // Remember Stuff:
		for(var i = 0; i < maxp; i++){
			_lastViewObj[i] = view_object[i];
			_lastViewPan[i] = view_pan_factor[i];
			_lastViewShk[i] = view_shake[i];
		}
		with([BackCont, TopCont]){
			var	_obj  = self,
				_vars = [];
				
			with(variable_instance_get_names(_obj)){
				if(array_find_index(["id", "object_index", "bbox_bottom", "bbox_top", "bbox_right", "bbox_left", "image_number", "sprite_yoffset", "sprite_xoffset", "sprite_height", "sprite_width"], self) < 0){
					array_push(_vars, [self, variable_instance_get(_obj, self)]);
				}
			}
			array_push(_lastObjVars, [_obj, _vars]);
		}
		
		 // Fix Ghost Collision:
		with(instances_matching(all, "solid", true)){
			solid = false;
			array_push(_lastSolid, self);
		}
		
		 // Clamp to Grid:
		with(instance_nearest_bbox(_x, _y, Floor)){
			_x = x + pfloor(_x - x, 16);
			_y = y + pfloor(_y - y, 16);
		}
		
		 // Floor Overlap Fixing:
		var	_overlapFloorBBox = [],
			_overlapFloorFill = [];
			
		if(_overlapFloor < 1){
			var	_floor = FloorNormal,
				_num = array_length(_floor) * (1 - _overlapFloor);
				
			with(array_shuffle(_floor)){
				if(_num-- > 0){
					array_push(_overlapFloorBBox, [bbox_left, bbox_top, bbox_right, bbox_bottom]);
				}
				else break;
			}
		}
		
		 // No Duplicates:
		with(BackCont) with(self){
			event_perform(ev_other, ev_room_end);
			instance_destroy();
		}
		with(TopCont) with(self){
			darkness = true;
			event_perform(ev_other, ev_room_end);
			instance_destroy();
		}
		with(SubTopCont){
			instance_destroy();
		}
		
		 // Deactivate Objects:
		game_deactivate();
		
		 // No Boss Death Music:
		if(_setArea){
			with(MusCont){
				alarm_set(3, -1);
			}
		}
		
		 // Generate Level:
		GameCont.area    = _area;
		GameCont.subarea = _subarea;
		GameCont.loops   = _loops;
		var _genID = instance_create(0, 0, GenCont);
		with(_genID) with(self){
			var	_ox = (_x - 10016),
				_oy = (_y - 10016);
				
			 // Music:
			if(_setArea){
				with(MusCont){
					alarm_set(11, 1);
				}
			}
			
			 // Delete Loading Spirals:
			with(SpiralCont  ) instance_destroy();
			with(Spiral      ) instance_destroy();
			with(SpiralStar  ) instance_destroy();
			with(SpiralDebris) instance_destroy(); // *might play a 0.1 pitched sound
			
			 // Custom Code:
			if(is_array(_scrSetup)){
				script_ref_call(_scrSetup);
			}
			
			 // Floors:
			var	_tries    = 100,
				_floorNum = 0;
				
			while(instance_exists(FloorMaker) && _tries-- > 0){
				with(FloorMaker){
					xprevious = x;
					yprevious = y;
					event_perform(ev_step, ev_step_normal);
				}
				if(instance_number(Floor) > _floorNum){
					_floorNum = instance_number(Floor);
					_tries    = 300;
				}
			}
			with(FloorMaker){
				instance_destroy();
			}
			
			 // Safe Spawns & Misc:
			event_perform(ev_alarm, 2);
			
			 // Remove Overlapping Floors:
			with(_overlapFloorBBox){
				var	_x1 = self[0] - _ox,
					_y1 = self[1] - _oy,
					_x2 = self[2] - _ox,
					_y2 = self[3] - _oy;
					
				with(instance_rectangle_bbox(_x1, _y1, _x2, _y2, Floor)){
					array_push(_overlapFloorFill, [bbox_left + _ox, bbox_top + _oy, bbox_right + _ox, bbox_bottom + _oy]);
					instance_destroy();
				}
				with(instance_rectangle_bbox(_x1, _y1, _x2, _y2, SnowFloor)){
					if(point_in_rectangle(bbox_center_x, bbox_center_y, _x1, _y1, _x2 + 1, _y2 + 1)){
						instance_destroy();
					}
				}
				with(instance_rectangle_bbox(_x1, _y1, _x2, _y2, [chestprop, RadChest])){
					instance_delete(self);
				}
			}
			
			 // Populate Level:
			with(KeyCont) with(self){
				event_perform(ev_create, 0); // reset player counter
			}
			event_perform(ev_alarm, 0);
			if(!_setArea){
				with(WantPopo) instance_delete(self);
				with(WantVan ) instance_delete(self);
			}
			var _clearID = instance_max;
			event_perform(ev_alarm, 1);
			
			 // Player Reset:
			if(game_letterbox == false){
				game_letterbox = _lastLetterbox;
			}
			for(var i = 0; i < maxp; i++){
				if(view_object[i]     == noone) view_object[i]     = _lastViewObj[i];
				if(view_pan_factor[i] == null ) view_pan_factor[i] = _lastViewPan[i];
				if(view_shake[i]      == 0    ) view_shake[i]      = _lastViewShk[i];
				
				with(instances_matching(Player, "index", i)){
					 // Fix View:
					var	_vx1   = x - (game_width / 2),
						_vy1   = y - (game_height / 2),
						_vx2   = view_xview[i],
						_vy2   = view_yview[i],
						_shake = UberCont.opt_shake;
						
					UberCont.opt_shake = 1;
					gunangle = point_direction(_vx1, _vy1, _vx2, _vy2);
					weapon_post(0, point_distance(_vx1, _vy1, _vx2, _vy2), 0);
					UberCont.opt_shake = _shake;
					
					 // Delete:
					repeat(4) with(instance_nearest(x, y, PortalL)){
						instance_destroy();
					}
					instance_delete(self);
					break;
				}
			}
			with(instances_matching_gt(PortalClear, "id", _clearID)){
				instance_destroy();
			}
			
			 // Move Objects:
			with(instances_matching_ne(instances_matching_ne(instances_matching_gt(all, "id", _genID), "x", null), "y", null)){
				if(x != 0 || y != 0){
					x         += _ox;
					y         += _oy;
					xprevious += _ox;
					yprevious += _oy;
					xstart    += _ox;
					ystart    += _oy;
				}
			}
		}
		
		 // Call Funny Mod Scripts:
		if(_setArea){
			with(mod_get_names("mod")){
				try{
					mod_script_call_nc("mod", self, "level_start");
				}
				catch(_error){
					trace(_error);
				}
			}
		}
		
		 // Reactivate Objects:
		game_activate();
		with(_lastSolid){
			solid = true;
		}
		
		 // Overlap Fixes:
		var	_overlapObject = [Floor, Wall, InvisiWall, TopSmall, TopPot, Bones],
			_overlapObj    = array_clone(_overlapObject);
			
		while(array_length(_overlapObj)){
			var _obj = _overlapObj[0];
			
			 // New Overwriting Old:
			var _objNew = instances_matching_gt(_obj, "id", _genID);
			with(instances_matching_lt(_overlapObj, "id", _genID)){
				if(place_meeting(x, y, _obj) && array_length(instances_meeting(x, y, _objNew))){
					if(object_index == Floor){
						array_push(_overlapFloorFill, [bbox_left, bbox_top, bbox_right, bbox_bottom]);
					}
					instance_delete(self);
				}
			}
			
			 // Advance:
			_overlapObj = array_slice(_overlapObj, 1, array_length(_overlapObj) - 1);
			
			 // Old Overwriting New:
			var _objOld = instances_matching_lt(_obj, "id", _genID);
			with(instances_matching_gt(_overlapObj, "id", _genID)){
				if(place_meeting(x, y, _obj) && array_length(instances_meeting(x, y, _objOld))){
					instance_delete(self);
				}
			}
		}
		var _wallOld = instances_matching_lt(Wall, "id", _genID);
		with(instances_matching_lt(hitme, "id", _genID)){
			if(place_meeting(x, y, Wall) && !array_length(instances_meeting(x, y, _wallOld))){
				wall_clear(x, y);
			}
		}
		
		 // Fill Gaps:
		with(_overlapFloorFill){
			var	_x1 = self[0],
				_y1 = self[1],
				_x2 = self[2] + 1,
				_y2 = self[3] + 1;
				
			with(other){
				for(var _fx = _x1; _fx < _x2; _fx += 16){
					for(var _fy = _y1; _fy < _y2; _fy += 16){
						if(!position_meeting(_fx, _fy, Floor)){
							with(instance_create(_fx, _fy, FloorExplo)){
								with(instances_meeting(x, y, _overlapObject)){
									instance_delete(self);
								}
							}
						}
					}
				}
			}
		}
		
		 // Reset Area:
		if(!_setArea){
			GameCont.area    = _lastArea;
			GameCont.subarea = _lastSubarea;
			GameCont.loops   = _lastLoops;
			background_color = _lastBackgroundColor;
			with(_lastObjVars){
				var	_obj  = self[0],
					_vars = self[1];
					
				with(_obj){
					with(_vars){
						variable_instance_set(other, self[0], self[1]);
					}
				}
			}
		}
		with(_lastObjVars){
			var	_obj  = self[0],
				_vars = self[1];
				
			if(_obj == TopCont){
				with(_vars){
					if(self[0] == "fogscroll"){
						with(_obj){
							variable_instance_set(self, other[0], other[1]);
						}
						break;
					}
				}
			}
		}
		
		return _genID;
	}
	
	return null;
	
#define area_set(_area, _subarea, _loops)
	/*
		Sets the area and remembers the last non-secret area
		Also turns Crystal Caves into Cursed Crystal Caves if a Player has a cursed weapon
	*/
	
	with(GameCont){
		 // Remember:
		if(!area_get_secret(area)){
			lastarea    = area;
			lastsubarea = subarea;
		}
		
		 // Set Area:
		area    = _area;
		subarea = _subarea;
		loops   = _loops;
		
		 // Cursed:
		if(area == area_caves){
			with(Player) if(curse > 0 || bcurse > 0){
				other.area = area_cursed_caves;
				break;
			}
		}
	}
	
#define area_get_name(_area, _subarea, _loops)
	/*
		Returns the given area's name as it would appear on the map
	*/
	
	var _name = [_area, "-", _subarea];
	
	 // Custom Area:
	if(is_string(_area)){
		_name = ["MOD"];
		if(mod_script_exists("area", _area, "area_name")){
			var _custom = mod_script_call("area", _area, "area_name", _subarea, _loops);
			if(is_string(_custom)){
				_name = [_custom];
			}
		}
	}
	
	 // Secret Area:
	else if(area_get_secret(_area)){
		switch(_area){
			case area_vault : _name = ["???"];             break;
			case area_hq    : _name = ["HQ", _subarea];    break;
			case area_crib  : _name = ["$$$"];             break;
			default         : _name = [_area - 100, "-?"];
		}
	}
	
	 // Victory:
	if(GameCont.win == true){
		if(_area == area_palace || _area == area_hq){
			_name = ["END", (area_get_secret(_area) ? 2 : 1)];
		}
	}
	
	 // Loop:
	if(real(_loops) > 0){
		array_push(_name, " " + ((UberCont.hardmode == true) ? "H" : "L"));
		array_push(_name, _loops);
	}
	
	 // Compile Name:
	var _text = "";
	with(_name){
		_text += (
			(is_real(self) && frac(self) != 0)
			? string_format(self, 0, 2)
			: string(self)
		);
	}
	
	return _text;
	
#define area_get_subarea(_area)
	/*
		Returns how many subareas are in the given area
	*/
	
	 // Custom Area:
	if(is_string(_area)){
		var _scrt = "area_subarea";
		if(mod_script_exists("area", _area, _scrt)){
			return mod_script_call("area", _area, _scrt);
		}
	}
	
	 // Normal Area:
	else if(is_real(_area)){
		 // Secret Areas:
		if(_area == area_hq) return 3;
		if(_area >= 100) return 1;
		
		 // Transition Area:
		if((_area % 2) == 0) return 1;
		
		return 3;
	}
	
	return 1;
	
#define area_get_secret(_area)
	/*
		Returns whether or not an area is secret
		
		Means the area:
			Is not returned to from other secret areas like Crib, IDPD HQ, Crown Vault, etc.
			Has no Proto Statues
			Doesn't spawn IDPD on new Crowns
			Doesn't create rad canisters when below the desired amount
			..?
	*/
	
	 // Custom Area:
	if(is_string(_area)){
		var _scrt = "area_secret";
		if(mod_script_exists("area", _area, _scrt)){
			return mod_script_call("area", _area, _scrt);
		}
	}
	
	 // Normal Area:
	else if(is_real(_area)){
		return (_area >= 100);
	}
	
	return false;
	
#define area_get_underwater(_area)
	/*
		Returns if a given area is underwater, like Oasis
	*/
	
	 // Custom Area:
	if(is_string(_area)){
		var _scrt = "area_underwater";
		if(mod_script_exists("area", _area, _scrt)){
			return mod_script_call("area", _area, _scrt);
		}
	}
	
	 // Normal Area:
	return (_area == area_oasis);
	
#define area_get_back_color(_area)
	/*
		Returns a given area's background color, but also supports custom areas
	*/
	
	 // Custom Area:
	if(is_string(_area)){
		var _scrt = "area_background_color";
		if(mod_script_exists("area", _area, _scrt)){
			return mod_script_call("area", _area, _scrt);
		}
	}
	
	 // Normal Area:
	return area_get_background_color(_area);
	
#define area_get_shad_color(_area)
	/*
		Return's a given area's shadow color, but also supports custom areas
	*/
	
	 // Custom Area:
	if(is_string(_area)){
		var _scrt = "area_shadow_color";
		if(mod_script_exists("area", _area, _scrt)){
			return mod_script_call("area", _area, _scrt);
		}
	}
	
	 // Normal Area:
	return area_get_shadow_color(_area);
	
#define area_get_sprite(_area, _spr)
	/*
		Returns a given area's variant of the given sprite
		
		Ex:
			area_get_sprite(area_sewers, sprFloor1) == sprFloor2
			area_get_sprite(area_city, sprDebris1)  == sprDebris5
			area_get_sprite(area_caves, sprBones)   == sprCaveDecal
	*/
	
	 // Store Sprites:
	if(!mod_variable_exists("mod", mod_current, "area_sprite_map")){
		var _map = ds_map_create();
		_map[? 0  ] = [sprFloor0,   sprFloor0,    sprFloor0Explo,   sprWall0Trans,   sprWall0Bot,   sprWall0Out,   sprWall0Top,   sprDebris0,   sprDetail0,   sprNightBones,      sprNightDesertTopDecal];
		_map[? 1  ] = [sprFloor1,   sprFloor1B,   sprFloor1Explo,   sprWall1Trans,   sprWall1Bot,   sprWall1Out,   sprWall1Top,   sprDebris1,   sprDetail1,   sprBones,           sprDesertTopDecal     ];
		_map[? 2  ] = [sprFloor2,   sprFloor2B,   sprFloor2Explo,   sprWall2Trans,   sprWall2Bot,   sprWall2Out,   sprWall2Top,   sprDebris2,   sprDetail2,   sprSewerDecal,      sprTopDecalSewers     ];
		_map[? 3  ] = [sprFloor3,   sprFloor3B,   sprFloor3Explo,   sprWall3Trans,   sprWall3Bot,   sprWall3Out,   sprWall3Top,   sprDebris3,   sprDetail3,   sprScrapDecal,      sprTopDecalScrapyard  ];
		_map[? 4  ] = [sprFloor4,   sprFloor4B,   sprFloor4Explo,   sprWall4Trans,   sprWall4Bot,   sprWall4Out,   sprWall4Top,   sprDebris4,   sprDetail4,   sprCaveDecal,       sprTopDecalCave       ];
		_map[? 5  ] = [sprFloor5,   sprFloor5B,   sprFloor5Explo,   sprWall5Trans,   sprWall5Bot,   sprWall5Out,   sprWall5Top,   sprDebris5,   sprDetail5,   sprIceDecal,        sprTopDecalCity       ];
		_map[? 6  ] = [sprFloor6,   sprFloor6B,   sprFloor6Explo,   sprWall6Trans,   sprWall6Bot,   sprWall6Out,   sprWall6Top,   sprDebris6,   sprDetail6,   -1,                 -1                    ];
		_map[? 7  ] = [sprFloor7,   sprFloor7B,   sprFloor7Explo,   sprWall7Trans,   sprWall7Bot,   sprWall7Out,   sprWall7Top,   sprDebris7,   -1,           -1,                 sprPalaceTopDecal     ];
		_map[? 100] = [sprFloor100, sprFloor100B, sprFloor100Explo, sprWall100Trans, sprWall100Bot, sprWall100Out, sprWall100Top, sprDebris100, -1,           -1,                 -1                    ];
		_map[? 101] = [sprFloor101, sprFloor101B, sprFloor101Explo, sprWall101Trans, sprWall101Bot, sprWall101Out, sprWall101Top, sprDebris101, sprDetail101, sprCoral,           -1                    ];
		_map[? 102] = [sprFloor102, sprFloor102B, sprFloor102Explo, sprWall102Trans, sprWall102Bot, sprWall102Out, sprWall102Top, sprDebris102, sprDetail102, sprPizzaSewerDecal, sprTopDecalPizzaSewers];
		_map[? 103] = [sprFloor103, sprFloor103B, sprFloor103Explo, sprWall103Trans, sprWall103Bot, sprWall103Out, sprWall103Top, sprDebris103, -1,           -1,                 -1                    ];
		_map[? 104] = [sprFloor104, sprFloor104B, sprFloor104Explo, sprWall104Trans, sprWall104Bot, sprWall104Out, sprWall104Top, sprDebris104, sprDetail104, sprInvCaveDecal,    sprTopDecalInvCave    ];
		_map[? 105] = [sprFloor105, sprFloor105B, sprFloor105Explo, sprWall105Trans, sprWall105Bot, sprWall105Out, sprWall105Top, sprDebris105, -1,           sprJungleDecal,     sprTopDecalJungle     ];
		_map[? 106] = [sprFloor106, sprFloor106B, sprFloor106Explo, sprWall106Trans, sprWall106Bot, sprWall106Out, sprWall106Top, sprDebris106, -1,           -1,                 sprTopPot             ];
		_map[? 107] = [sprFloor107, sprFloor107B, sprFloor107Explo, sprWall107Trans, sprWall107Bot, sprWall107Out, sprWall107Top, sprDebris107, -1,           -1,                 -1                    ];
		global.area_sprite_map = _map;
	}
	
	 // Convert to Desert Sprite:
	if(sprite_exists(_spr)){
		with(ds_map_values(global.area_sprite_map)){
			var i = array_find_index(self, _spr);
			if(i >= 0){
				_spr = global.area_sprite_map[? 1][i];
				if(_spr == sprDesertTopDecal) _spr = sprTopPot;
				break;
			}
		}
	}
	
	 // Custom:
	if(is_string(_area)){
		var s = mod_script_call("area", _area, "area_sprite", _spr);
		if(s != 0 && is_real(s)){
			return s;
		}
	}
	
	 // Normal:
	if(ds_map_exists(global.area_sprite_map, _area)){
		var	_list = global.area_sprite_map[? _area],
			i = array_find_index(global.area_sprite_map[? 1], _spr);
			
		if(i >= 0 && i < array_length(_list)){
			return _list[i];
		}
	}
	
	return -1;
	
#define floor_walls()
	var	_x1    = bbox_left   - 16,
		_y1    = bbox_top    - 16,
		_x2    = bbox_right  + 16 + 1,
		_y2    = bbox_bottom + 16 + 1,
		_minID = instance_max;
		
	for(var _x = _x1; _x < _x2; _x += 16){
		for(var _y = _y1; _y < _y2; _y += 16){
			if(_x == _x1 || _y == _y1 || _x == _x2 - 16 || _y == _y2 - 16){
				if(!position_meeting(_x, _y, Floor)){
					instance_create(_x, _y, Wall);
				}
			}
		}
	}
	
	return _minID;

#define floor_bones(_num, _chance, _linked)
	/*
		Checks if the current Floor is a vertical hallway and then creates Bones decals on the Walls left and right of the current Floor
		
		Args:
			num    - How many decals can be made vertically
			chance - Chance to create each decal
			linked - Decal should always spawn with one on the other side, true/false
			
		Ex:
			floor_bones(2, 1,    false) == DESERT / CAMPFIRE
			floor_bones(1, 1/10, true ) == SEWERS / PIZZA SEWERS / JUNGLE
			floor_bones(2, 1/7,  false) == SCRAPYARDS / FROZEN CITY
			floor_bones(2, 1/9,  false) == CRYSTAL CAVES / CURSED CRYSTAL CAVES / OASIS
	*/
	
	var _inst = [];
	
	if(!collision_rectangle(bbox_left - 16, bbox_top, bbox_right + 16, bbox_bottom, Floor, false, true)){
		for(var _y = bbox_top; _y < bbox_bottom + 1; _y += (32 / _num)){
			var _create = true;
			for(var _side = 0; _side <= 1; _side++){
				if(_side == 0 || !_linked){
					_create = (random(1) < _chance);
				}
				if(_create){
					var _x = lerp(bbox_left, bbox_right + 1, _side);
					with(obj_create(_x, _y, "WallDecal")){
						image_xscale = ((_side > 0.5) ? -1 : 1);
						array_push(_inst, self);
					}
				}
			}
		}
	}
	
	return _inst;