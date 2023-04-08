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
        minetest.get_meta(pos):set_string("infotext", S("Vent"))
        ctg_airs.Tube:after_place_node(pos)
        return false
    end,

    after_dig_node = function(pos, oldnode, oldmetadata, digger)
        ctg_airs.Tube:after_dig_node(pos)
    end,

    on_push_air = function(pos, dir)
        local tube_dir = minetest.get_meta(pos):get_int("tube_dir")
        minetest.log(tostring(tube_dir))
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
