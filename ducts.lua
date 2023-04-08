local S = minetest.get_translator(minetest.get_current_modname())

--                    North, East, South, West, Down, Up
-- local dirs_to_check = {1,2,3,4}  -- horizontal only
local dirs_to_check = {1, 2, 3, 4, 5, 6}
-- if hyperloop.free_tube_placement_enabled then
--	dirs_to_check = {1,2,3,4,5,6}  -- all directions
-- end

local Tube = tubelib2.Tube:new({
    dirs_to_check = dirs_to_check,
    max_tube_length = 25,
    show_infotext = true,
    primary_node_names = {"ctg_airs:air_duct_S", "ctg_airs:air_duct_S2", "ctg_airs:air_duct_A", "ctg_airs:air_duct_A2"},
    secondary_node_names = {"ctg_airs:air_duct_junc", "ctg_airs:air_duct_vent", "ctg_airs:lv_air_handler",
                            "ctg_airs:lv_air_handler_active", "ctg_airs:lv_air_handler_wait", "ctg_airs:lv_air_fan",
                            "ctg_airs:lv_air_fan_active"},
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

ctg_airs.Tube = Tube

local P2S = function(pos)
    if pos then
        return minetest.pos_to_string(pos)
    end
end

minetest.register_node("ctg_airs:air_duct_S", {
    description = S("Air Ducting"),
    -- tiles = {"ctg_aluminum_block_top.png"},

    -- up, down, right, left, back, front
    tiles = {"ctg_air_duct.png", "ctg_air_duct.png", "ctg_air_duct.png", "ctg_air_duct.png", "ctg_air_duct_top.png",
             "ctg_air_duct_top.png"},
    -- paramtype = "light",
    paramtype2 = "facedir",
    sunlight_propagates = true,
    sounds = default.node_sound_metal_defaults(),
    groups = {
        cracky = 3,
        level = 1,
        metal = 1
    },
    is_ground_content = false,

    drop = "ctg_airs:air_duct_S",

    after_place_node = function(pos, placer, itemstack, pointed_thing)
        if not Tube:after_place_tube(pos, placer, pointed_thing) then
            minetest.remove_node(pos)
            return true
        end
        return false
    end,

    after_dig_node = function(pos, oldnode, oldmetadata, digger)
        Tube:after_dig_tube(pos, oldnode, oldmetadata)
    end,

    on_rotate = screwdriver.disallow -- important!
    -- on_place = minetest.rotate_node,
})

minetest.register_node("ctg_airs:air_duct_S2", {
    description = S("Air Ducting Junction"),

    -- up, down, right, left, back, front
    tiles = {"ctg_air_duct.png", "ctg_air_duct.png", "ctg_air_duct.png", "ctg_air_duct.png", "ctg_air_duct.png",
             "ctg_air_duct_top.png"},
    paramtype2 = "facedir",
    sunlight_propagates = true,
    sounds = default.node_sound_metal_defaults(),
    groups = {
        cracky = 3,
        level = 1,
        metal = 1,
        not_in_creative_inventory = 1
    },
    is_ground_content = false,

    drop = "ctg_airs:air_duct_S",

    after_dig_node = function(pos, oldnode, oldmetadata, digger)
        Tube:after_dig_tube(pos, oldnode, oldmetadata)
    end,

    on_rotate = screwdriver.disallow -- important!
    -- on_place = minetest.rotate_node,
})

minetest.register_node("ctg_airs:air_duct_A", {
    description = S("Air Ducting Junction"),
    -- up, down, right, left, back, front
    tiles = {"ctg_air_duct.png", "ctg_air_duct.png", "ctg_air_duct.png", "ctg_air_duct.png", "ctg_air_duct_top.png",
             "ctg_air_duct_top.png"},
    paramtype2 = "facedir",
    sunlight_propagates = true,
    sounds = default.node_sound_metal_defaults(),
    groups = {
        cracky = 3,
        level = 1,
        metal = 1,
        not_in_creative_inventory = 1
    },
    is_ground_content = false,

    drop = "ctg_airs:air_duct_S",

    after_dig_node = function(pos, oldnode, oldmetadata, digger)
        Tube:after_dig_tube(pos, oldnode, oldmetadata)
    end,

    on_rotate = screwdriver.disallow -- important!
    -- on_place = minetest.rotate_node,
})

minetest.register_node("ctg_airs:air_duct_A2", {
    description = S("Air Ducting Junction"),
    -- up, down, right, left, back, front
    tiles = {"ctg_air_duct.png", "ctg_air_duct_top.png", "ctg_air_duct.png", "ctg_air_duct.png", "ctg_air_duct.png",
             "ctg_air_duct_top.png"},
    paramtype2 = "facedir",
    sunlight_propagates = true,
    sounds = default.node_sound_metal_defaults(),
    groups = {
        cracky = 3,
        level = 1,
        metal = 1,
        not_in_creative_inventory = 1
    },
    is_ground_content = false,

    drop = "ctg_airs:air_duct_S",

    after_dig_node = function(pos, oldnode, oldmetadata, digger)
        Tube:after_dig_tube(pos, oldnode, oldmetadata)
    end,

    on_rotate = screwdriver.disallow -- important!
    -- on_place = minetest.rotate_node,
})

minetest.register_node("ctg_airs:air_duct_junc", {
    description = S("Air Ducting Junction"),
    tiles = {"ctg_air_duct_junc.png"},
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
        minetest.get_meta(pos):set_string("infotext", S("Junction"))
        ctg_airs.Tube:after_place_node(pos)
        return false
    end,

    after_dig_node = function(pos, oldnode, oldmetadata, digger)
        ctg_airs.Tube:after_dig_node(pos)
    end,

    on_push_air = function(pos, dir)
        local tube_dir = minetest.get_meta(pos):get_int("tube_dir")
        if dir == tubelib2.Turn180Deg[tube_dir] then
            local s = minetest.get_meta(pos):get_string("peer_pos")
            if s and s ~= "" then
                -- push_item(S2P(s))
                minetest.log(s)
                return true
            end
        end
    end

    -- on_place = minetest.rotate_node,
})

minetest.register_node("ctg_airs:air_duct_block", {
    description = S("Air Duct Cap"),
    tiles = {"ctg_air_duct.png"},
    -- paramtype2 = "facedir",
    sunlight_propagates = true,
    sounds = default.node_sound_metal_defaults(),
    groups = {
        cracky = 3,
        level = 1,
        metal = 1
    },
    is_ground_content = false

    -- on_place = minetest.rotate_node,
})

