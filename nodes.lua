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

if (minetest.get_modpath("scifi_nodes")) then
    local plastic_tex = "scifi_nodes_white2.png";

    minetest.register_node("ctg_airs:plastic_block_embedded_tube", {
        description = S("Airtight plastic embedded tube"),
        tiles = {plastic_tex, plastic_tex, plastic_tex, plastic_tex,
                 plastic_tex .. "^pipeworks_tube_connection_metallic.png",
                 plastic_tex .. "^pipeworks_tube_connection_metallic.png"},
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
            key = "node_sound_stone_defaults"
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

-- this is a static border between air and vacuum...
minetest.register_node("ctg_airs:atmos_border", {
	description = "Atmosphere Air Border",
	drawtype = "liquid",
	tiles = {"atmos_static.png"},
	paramtype = "light",
	sunlight_propagates = true,
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
	use_texture_alpha = "blend",
	inventory_image = "atmos2_inv.png",
	wield_image = "atmos2_inv.png",
	post_effect_color = {a = 8, r = 20, g = 50, b = 100},
	groups = {not_in_creative_inventory = 1, atmosphere = 4},
	drowning = 1,
	waving = 3,
    light_level = 3
})

minetest.register_abm({
    label = "atmos static particles",
    nodenames = {"ctg_airs:atmos_border"},
    neighbors = {"air", "vacuum:vacuum", "vacuum:atmos_thin"},
    interval = 2,
    chance = 3,
    min_y = vacuum.vac_heights.space.start_height,
    action = vacuum.throttle(5000, function(pos)
        ctg_airs.spawn_particle2(pos, math.random(-0.01, 0.01), math.random(-0.005, 0.007),
                    math.random(-0.01, 0.01), 0, math.random(-0.008, 0.002), 0, math.random(2.0, 3.5), 13, 3)
    end)
})