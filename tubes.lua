-- North, East, South, West, Down, Up
local dirs_to_check = {1, 2, 3, 4, 5, 6}

local Tube = tubelib2.Tube:new({
    dirs_to_check = dirs_to_check,
    max_tube_length = 25,
    show_infotext = true,
    primary_node_names = {"ctg_airs:air_duct_S", "ctg_airs:air_duct_S2", "ctg_airs:air_duct_A", "ctg_airs:air_duct_A2"},
    secondary_node_names = {"ctg_airs:air_duct_junc", "ctg_airs:air_duct_vent", "ctg_airs:air_duct_vent_dirty",
                            "ctg_airs:air_duct_vent_lite", "ctg_airs:air_duct_vent_lite_dirty",
                            "ctg_airs:lv_air_handler", "ctg_airs:lv_air_handler_active", "ctg_airs:lv_air_handler_wait",
                            "ctg_airs:lv_air_fan", "ctg_airs:mv_air_handler", "ctg_airs:mv_air_handler_active",
                            "ctg_airs:mv_air_handler_wait", "ctg_airs:lv_air_fan", "ctg_airs:lv_air_fan_active",
                            "ctg_airs:mv_air_fan", "ctg_airs:mv_air_fan_active", "ctg_airs:lv_air_purifier",
                            "ctg_airs:lv_air_purifier_active", "ctg_airs:lv_air_purifier_dirty"},
    after_place_tube = function(pos, param2, tube_type, num_tubes)
        -- minetest.log("type: " .. tube_type .. " num: " .. num_tubes .. " param2:" .. param2)
        if num_tubes == 2 then
            minetest.set_node(pos, {
                name = "ctg_airs:air_duct_" .. tube_type .. "2",
                param2 = param2
            })
        else
            minetest.set_node(pos, {
                name = "ctg_airs:air_duct_" .. tube_type,
                param2 = param2
            })
        end
    end
})

Tube:set_valid_sides("ctg_airs:lv_air_handler", {"U"})
Tube:set_valid_sides("ctg_airs:lv_air_handler_active", {"U"})
Tube:set_valid_sides("ctg_airs:mv_air_handler", {"U"})
Tube:set_valid_sides("ctg_airs:mv_air_handler_active", {"U"})

Tube:set_valid_sides("ctg_airs:lv_air_fan", {"U"})
Tube:set_valid_sides("ctg_airs:lv_air_fan_active", {"U"})
Tube:set_valid_sides("ctg_airs:mv_air_fan", {"U"})
Tube:set_valid_sides("ctg_airs:mv_air_fan_active", {"U"})

Tube:set_valid_sides("ctg_airs:lv_air_purifier", {"L", "R"})
Tube:set_valid_sides("ctg_airs:lv_air_purifier_active", {"L", "R"})

ctg_airs.Tube = Tube
