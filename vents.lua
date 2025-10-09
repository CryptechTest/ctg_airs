local S = minetest.get_translator(minetest.get_current_modname())

minetest.register_node("ctg_airs:air_duct_vent", {
    description = S("Air Vent"),
    _tt_help = S("Register Cost 10"),
    -- up, down, right, left, back, front
    tiles = {"ctg_air_duct.png", "ctg_air_duct.png", "ctg_air_duct.png", "ctg_air_duct.png", "ctg_air_duct.png",
             "ctg_air_duct_vent.png"},
    paramtype2 = "facedir",
    --sunlight_propagates = true,
    sounds = default.node_sound_metal_defaults(),
    groups = {
        cracky = 3,
        level = 1,
        metal = 1,
        duct = 3,
        vent = 10,
        vent_dirty = 0
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

minetest.register_node("ctg_airs:air_duct_vent_dirty", {
    description = S("Dirty Air Vent"),
    _tt_help = S("Register Cost 12"),
    -- up, down, right, left, back, front
    tiles = {"ctg_air_duct.png", "ctg_air_duct.png", "ctg_air_duct.png", "ctg_air_duct.png", "ctg_air_duct.png",
             "ctg_air_duct_vent_dirty.png"},
    paramtype2 = "facedir",
    --sunlight_propagates = true,
    sounds = default.node_sound_metal_defaults(),
    groups = {
        cracky = 3,
        level = 1,
        metal = 1,
        duct = 3,
        vent = 10,
        vent_dirty = 2
    },
    is_ground_content = false,

    after_place_node = function(pos, placer, itemstack, pointed_thing)
        minetest.get_meta(pos):set_int("active", 0)
        minetest.get_meta(pos):set_string("infotext", S("Dirty Vent"))
        ctg_airs.Tube:after_place_node(pos)
        return false
    end,

    after_dig_node = function(pos, oldnode, oldmetadata, digger)
        ctg_airs.Tube:after_dig_node(pos)
    end,

    on_punch = function(pos, node, puncher, pointed_thing)
        if puncher:is_player() then
            if puncher:get_wielded_item():get_name() == "ctg_world:nickel_dust" then
                minetest.set_node(pos, {
                    name = "ctg_airs:air_duct_vent",
                    param2 = node.param2
                })
                minetest.get_meta(pos):set_string("infotext", S("Vent"))
                local new_item = ItemStack(puncher:get_wielded_item())
                new_item:take_item(1)
                puncher:set_wielded_item(new_item)
            end
        end
    end

    -- on_place = minetest.rotate_node,
})

minetest.register_node("ctg_airs:air_duct_vent_lite", {
    description = S("Air Vent Lite"),
    _tt_help = S("Register Cost 7"),
    -- up, down, right, left, back, front
    tiles = {"ctg_air_duct.png", "ctg_air_duct.png", "ctg_air_duct.png", "ctg_air_duct.png", "ctg_air_duct.png",
             "ctg_air_duct_vent_lite.png"},
    paramtype2 = "facedir",
    --sunlight_propagates = true,
    sounds = default.node_sound_metal_defaults(),
    groups = {
        cracky = 3,
        level = 1,
        metal = 1,
        duct = 3,
        vent = 7,
        vent_dirty = 0
    },
    is_ground_content = false,

    after_place_node = function(pos, placer, itemstack, pointed_thing)
        minetest.get_meta(pos):set_int("active", 0)
        minetest.get_meta(pos):set_string("infotext", S("Lite Vent"))
        ctg_airs.Tube:after_place_node(pos)
        return false
    end,

    after_dig_node = function(pos, oldnode, oldmetadata, digger)
        ctg_airs.Tube:after_dig_node(pos)
    end

    -- on_place = minetest.rotate_node,
})

minetest.register_node("ctg_airs:air_duct_vent_lite_dirty", {
    description = S("Dirty Air Vent Lite"),
    _tt_help = S("Register Cost 8"),
    -- up, down, right, left, back, front
    tiles = {"ctg_air_duct.png", "ctg_air_duct.png", "ctg_air_duct.png", "ctg_air_duct.png", "ctg_air_duct.png",
             "ctg_air_duct_vent_lite_dirty.png"},
    paramtype2 = "facedir",
    --sunlight_propagates = true,
    sounds = default.node_sound_metal_defaults(),
    groups = {
        cracky = 3,
        level = 1,
        metal = 1,
        duct = 3,
        vent = 7,
        vent_dirty = 1
    },
    is_ground_content = false,

    after_place_node = function(pos, placer, itemstack, pointed_thing)
        minetest.get_meta(pos):set_int("active", 0)
        minetest.get_meta(pos):set_string("infotext", S("Dirty Lite Vent"))
        ctg_airs.Tube:after_place_node(pos)
        return false
    end,

    after_dig_node = function(pos, oldnode, oldmetadata, digger)
        ctg_airs.Tube:after_dig_node(pos)
    end,

    on_punch = function(pos, node, puncher, pointed_thing)
        if puncher:is_player() then
            if puncher:get_wielded_item():get_name() == "ctg_world:nickel_dust" then
                minetest.set_node(pos, {
                    name = "ctg_airs:air_duct_vent_lite",
                    param2 = node.param2
                })
                minetest.get_meta(pos):set_string("infotext", S("Lite Vent"))
                local new_item = ItemStack(puncher:get_wielded_item())
                new_item:take_item(1)
                puncher:set_wielded_item(new_item)
            end
        end
    end

    -- on_place = minetest.rotate_node,
})

-- check if enabled
ctg_airs.vent_active = function(meta)
    return meta:get_int("active") == 1
end

-- vents monitor check
minetest.register_abm({
    label = "vents reset monitor",
    nodenames = {"ctg_airs:air_duct_vent", "ctg_airs:air_duct_vent_lite", "ctg_airs:air_duct_vent_dirty", "ctg_airs:air_duct_vent_lite_dirty"},
    --neighbors = {"vacuum:vacuum"},
    interval = 20,
    chance = 1,
    --min_y = vacuum.vac_heights.space.start_height,
    action = function(pos)
        
        local node = core.get_node(pos)
        local meta = core.get_meta(pos)
        local name = node.name

        local t0_us = core.get_us_time();
        local t2_us = tonumber(meta:get_string("time_run")) or 0
        local elapsed_time_in_seconds = (t0_us - t2_us) / 1000000.0;
        if elapsed_time_in_seconds <= 30 then
            return
        end

        if meta:get_int("active") > 0 then
            meta:set_int("active", 0)
        end

        if name == "ctg_airs:air_duct_vent" then
            meta:set_string("infotext", S("Vent"))
        elseif name == "ctg_airs:air_duct_vent_lite" then
            meta:set_string("infotext", S("Lite Vent"))
        elseif name == "ctg_airs:air_duct_vent_dirty" then
            meta:set_string("infotext", S("Dirty Vent"))
        elseif name == "ctg_airs:air_duct_vent_lite_dirty" then
            meta:set_string("infotext", S("Dirty Lite Vent"))
        end

    end
})
