local S = minetest.get_translator(minetest.get_current_modname())

local straight = function(pos, node, velocity, stack)
    return {velocity}
end

if (minetest.get_modpath("ctg_world")) then

    local alumin_tex = "ctg_aluminum_block_top.png"
    local nickel_tex = "ctg_nickel_block_top.png"
    local ssteal_tex = "technic_stainless_steel_block.png"

    minetest.register_node("ctg_airs:aluminum_block_embedded_tube", {
        description = S("Airtight aluminum embedded tube"),
        tiles = {alumin_tex, alumin_tex, alumin_tex, alumin_tex,
                 alumin_tex .. "^pipeworks_tube_connection_metallic.png",
                 alumin_tex .. "^pipeworks_tube_connection_metallic.png"},
        paramtype = "light",
        paramtype2 = "facedir",
        groups = {
            cracky = 1,
            oddly_breakable_by_hand = 1,
            tubedevice = 1,
            dig_glass = 2,
            pickaxey = 5
        },
        _mcl_hardness = 1.6,
        legacy_facedir_simple = true,
        _sound_def = {
            key = "node_sound_metal_defaults"
        },
        tube = {
            connect_sides = {
                front = 1,
                back = 1
            },
            priority = 50,
            can_go = straight,
            can_insert = function(pos, node, stack, direction)
                local dir = minetest.facedir_to_dir(node.param2)
                return vector.equals(dir, direction) or vector.equals(vector.multiply(dir, -1), direction)
            end
        },
        after_place_node = pipeworks.after_place,
        after_dig_node = pipeworks.after_dig,
        on_rotate = pipeworks.on_rotate
    })

    minetest.register_node("ctg_airs:nickel_block_embedded_tube", {
        description = S("Airtight nickel embedded tube"),
        tiles = {nickel_tex, nickel_tex, nickel_tex, nickel_tex,
                 nickel_tex .. "^pipeworks_tube_connection_metallic.png",
                 nickel_tex .. "^pipeworks_tube_connection_metallic.png"},
        paramtype = "light",
        paramtype2 = "facedir",
        groups = {
            cracky = 1,
            oddly_breakable_by_hand = 1,
            tubedevice = 1,
            dig_glass = 2,
            pickaxey = 5
        },
        _mcl_hardness = 1.6,
        legacy_facedir_simple = true,
        _sound_def = {
            key = "node_sound_metal_defaults"
        },
        tube = {
            connect_sides = {
                front = 1,
                back = 1
            },
            priority = 50,
            can_go = straight,
            can_insert = function(pos, node, stack, direction)
                local dir = minetest.facedir_to_dir(node.param2)
                return vector.equals(dir, direction) or vector.equals(vector.multiply(dir, -1), direction)
            end
        },
        after_place_node = pipeworks.after_place,
        after_dig_node = pipeworks.after_dig,
        on_rotate = pipeworks.on_rotate
    })

    minetest.register_node("ctg_airs:stainless_steel_block_embedded_tube", {
        description = S("Airtight stainless steel embedded tube"),
        tiles = {ssteal_tex, ssteal_tex, ssteal_tex, ssteal_tex,
                 ssteal_tex .. "^pipeworks_tube_connection_metallic.png",
                 ssteal_tex .. "^pipeworks_tube_connection_metallic.png"},
        paramtype = "light",
        paramtype2 = "facedir",
        groups = {
            cracky = 1,
            -- oddly_breakable_by_hand = 1,
            tubedevice = 1,
            -- dig_glass = 2,
            pickaxey = 5
        },
        _mcl_hardness = 1.6,
        legacy_facedir_simple = true,
        _sound_def = {
            key = "node_sound_metal_defaults"
        },
        tube = {
            connect_sides = {
                front = 1,
                back = 1
            },
            priority = 50,
            can_go = straight,
            can_insert = function(pos, node, stack, direction)
                local dir = minetest.facedir_to_dir(node.param2)
                return vector.equals(dir, direction) or vector.equals(vector.multiply(dir, -1), direction)
            end
        },
        after_place_node = pipeworks.after_place,
        after_dig_node = pipeworks.after_dig,
        on_rotate = pipeworks.on_rotate
    })
end
