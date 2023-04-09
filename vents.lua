local S = minetest.get_translator(minetest.get_current_modname())

minetest.register_node("ctg_airs:air_duct_vent", {
    description = S("Air Vent"),
    -- up, down, right, left, back, front
    tiles = {"ctg_air_duct.png", "ctg_air_duct.png", "ctg_air_duct.png", "ctg_air_duct.png", "ctg_air_duct.png",
             "ctg_air_duct_vent.png"},
    paramtype2 = "facedir",
    sunlight_propagates = true,
    sounds = default.node_sound_metal_defaults(),
    groups = {
        cracky = 3,
        level = 1,
        metal = 1
    },
    is_ground_content = false,

    after_place_node = function(pos, placer, itemstack, pointed_thing)
        minetest.get_meta(pos):set_int("active", 0)
        minetest.get_meta(pos):set_string("infotext", S("Vent"))
        ctg_airs.Tube:after_place_node(pos)
        return false
    end,

    after_dig_node = function(pos, oldnode, oldmetadata, digger)
        ctg_airs.Tube:after_dig_node(pos)
    end

    -- on_place = minetest.rotate_node,
})

-- check if enabled
ctg_airs.vent_active = function(meta)
    return meta:get_int("active") == 1
end
