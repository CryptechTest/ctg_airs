local S = minetest.get_translator(minetest.get_current_modname())

local P2S = function(pos)
    if pos then
        return minetest.pos_to_string(pos)
    end
end

minetest.register_node("ctg_airs:air_duct_S", {
    description = S("Air Ducting"),

    -- up, down, right, left, back, front
    tiles = {"ctg_air_duct.png", "ctg_air_duct.png", "ctg_air_duct.png", "ctg_air_duct.png", "ctg_air_duct_top.png",
             "ctg_air_duct_top.png"},
    -- paramtype = "light",
    paramtype2 = "facedir",
    --sunlight_propagates = true,
    sounds = default.node_sound_metal_defaults(),
    groups = {
        cracky = 3,
        level = 1,
        metal = 1,
        duct = 1
    },
    is_ground_content = false,

    drop = "ctg_airs:air_duct_S",

    after_place_node = function(pos, placer, itemstack, pointed_thing)
        if not ctg_airs.Tube:after_place_tube(pos, placer, pointed_thing) then
            minetest.remove_node(pos)
            return true
        end
        return false
    end,

    after_dig_node = function(pos, oldnode, oldmetadata, digger)
        ctg_airs.Tube:after_dig_tube(pos, oldnode, oldmetadata)
    end,

    on_rotate = screwdriver.disallow -- important!
    -- on_place = minetest.rotate_node,
})

minetest.register_node("ctg_airs:air_duct_S2", {
    description = S("Air Ducting"),

    -- up, down, right, left, back, front
    tiles = {"ctg_air_duct.png", "ctg_air_duct.png", "ctg_air_duct.png", "ctg_air_duct.png", "ctg_air_duct.png",
             "ctg_air_duct_top.png"},
    paramtype2 = "facedir",
    --sunlight_propagates = true,
    sounds = default.node_sound_metal_defaults(),
    groups = {
        cracky = 3,
        level = 1,
        metal = 1,
        not_in_creative_inventory = 1,
        duct = 1
    },
    is_ground_content = false,

    drop = "ctg_airs:air_duct_S",

    after_dig_node = function(pos, oldnode, oldmetadata, digger)
        ctg_airs.Tube:after_dig_tube(pos, oldnode, oldmetadata)
    end,

    on_rotate = screwdriver.disallow -- important!
    -- on_place = minetest.rotate_node,
})

minetest.register_node("ctg_airs:air_duct_A", {
    description = S("Air Ducting"),
    -- up, down, right, left, back, front
    tiles = {"ctg_air_duct.png", "ctg_air_duct.png", "ctg_air_duct.png", "ctg_air_duct.png", "ctg_air_duct_top.png",
             "ctg_air_duct_top.png"},
    paramtype2 = "facedir",
    --sunlight_propagates = true,
    sounds = default.node_sound_metal_defaults(),
    groups = {
        cracky = 3,
        level = 1,
        metal = 1,
        not_in_creative_inventory = 1,
        duct = 1
    },
    is_ground_content = false,

    drop = "ctg_airs:air_duct_S",

    after_dig_node = function(pos, oldnode, oldmetadata, digger)
        ctg_airs.Tube:after_dig_tube(pos, oldnode, oldmetadata)
    end,

    on_rotate = screwdriver.disallow -- important!
    -- on_place = minetest.rotate_node,
})

minetest.register_node("ctg_airs:air_duct_A2", {
    description = S("Air Ducting"),
    -- up, down, right, left, back, front
    tiles = {"ctg_air_duct.png", "ctg_air_duct_top.png", "ctg_air_duct.png", "ctg_air_duct.png", "ctg_air_duct.png",
             "ctg_air_duct_top.png"},
    paramtype2 = "facedir",
    --sunlight_propagates = true,
    sounds = default.node_sound_metal_defaults(),
    groups = {
        cracky = 3,
        level = 1,
        metal = 1,
        not_in_creative_inventory = 1,
        duct = 1
    },
    is_ground_content = false,

    drop = "ctg_airs:air_duct_S",

    after_dig_node = function(pos, oldnode, oldmetadata, digger)
        ctg_airs.Tube:after_dig_tube(pos, oldnode, oldmetadata)
    end,

    on_rotate = screwdriver.disallow -- important!
    -- on_place = minetest.rotate_node,
})

minetest.register_node("ctg_airs:air_duct_junc", {
    description = S("Air Ducting Junction"),
    _tt_help = S("Air Register Cost 3"),
    tiles = {"ctg_air_duct_junc.png"},
    paramtype2 = "facedir",
    --sunlight_propagates = true,
    sounds = default.node_sound_metal_defaults(),
    groups = {
        cracky = 3,
        level = 1,
        metal = 1,
        duct = 2
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
    --sunlight_propagates = true,
    sounds = default.node_sound_metal_defaults(),
    groups = {
        cracky = 3,
        level = 1,
        metal = 1,
        duct = 1
    },
    is_ground_content = false

    -- on_place = minetest.rotate_node,
})

