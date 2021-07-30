#define step
if (instance_exists(LevCont)){
    // heavy heart support for skill_get_avail
    if (!global.wepmuted && GameCont.wepmuts >= 3){
        global.wepmuted = true;
    }
    
    // scrolling mutbuttons
    var button_count = instance_number(mutbutton);
    
    if (button_count){
        if ((button_count + 1) * sprite_get_width(sprSkillIcon) > game_width){
            var _animating = instances_matching_ge(mutbutton, "alarm0", 0);
            var animating_count = array_length(_animating);
            
            with(LevCont){
                if (!animating_count){
                    var _num = floor(maxselect / 2);
                    
                    if (select <= 0 || select >= maxselect){
                        select = _num;
                    }
                    
                    else{
                        if (select < _num){
                            with(mutbutton){
                                num += 1;
                            }
                            
                            select += 1;
                        }
                        
                        else if (select > _num){
                            with(mutbutton){
                                num -= 1;
                            }
                            
                            select -= 1;
                        }
                        
                        var _maxselect = maxselect;
                        
                        with(instances_matching_gt(mutbutton, "num", _maxselect)){
                            num -= (_maxselect + 1);
                        }
                        
                        with(instances_matching_lt(mutbutton, "num", 0)){
                            num += (_maxselect + 1);
                        }
                    }
                }
            }
        }
        
        // crown train sets num to decimal...
        else{
            LevCont.maxselect = button_count - 1;
            var _max = button_count;
            
            with(mutbutton){
                num = -- _max;
            }
        }
    }
}