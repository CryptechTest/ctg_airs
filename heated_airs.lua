
-- this is just like air, but warm...
minetest.register_node("ctg_airs:atmos_warm", {
	description = "Atmosphere Air Warm",
	drawtype = "liquid",
    tiles = {"atmos_warm.png^[colorize:#ebc6bc40"},
	paramtype = "light",
	sunlight_propagates = true,
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
	is_ground_content = false,
	use_texture_alpha = "blend",
	inventory_image = "atmos_warm_inv.png",
	wield_image = "atmos_warm_inv.png",
	post_effect_color = {a = 18, r = 73, g = 67, b = 40},
	groups = {not_in_creative_inventory = 1, atmosphere = 10},
	waving = 3,
	drop = {},
})

-- this is just like air, but hot...
minetest.register_node("ctg_airs:atmos_hot", {
	description = "Atmosphere Air Hot",
	drawtype = "liquid",
    tiles = {"atmos_hot.png^[colorize:#ebc6bc50"},
	paramtype = "light",
	sunlight_propagates = true,
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
	is_ground_content = false,
	use_texture_alpha = "blend",
	inventory_image = "atmos_warm_inv.png",
	wield_image = "atmos_warm_inv.png",
	post_effect_color = {a = 28, r = 80, g = 54, b = 50},
	groups = {not_in_creative_inventory = 1, atmosphere = 11},
	waving = 3,
	drop = {},
})

minetest.register_abm({
    label = "hot air to warm air",
    nodenames = {"ctg_airs:atmos_hot"},
    neighbors = {"air", "vacuum:atmos_thin", "default:water_source"},
    interval = 3,
    chance = 2,
    min_y = vacuum.vac_heights.space.start_height,
    action = vacuum.throttle(2500, function(pos)
        minetest.set_node(pos, {
            name = "ctg_airs:atmos_warm"
        })
    end)
})

minetest.register_abm({
    label = "hot air to warm air - random",
    nodenames = {"ctg_airs:atmos_hot"},
    neighbors = {"group:stone", "group:soil", "group:sand", "group:cracky"},
    interval = 5,
    chance = 5,
    min_y = vacuum.vac_heights.space.start_height,
    action = vacuum.throttle(2500, function(pos)
        minetest.set_node(pos, {
            name = "ctg_airs:atmos_warm"
        })
    end)
})

minetest.register_abm({
    label = "warm air to hot air",
    nodenames = {"ctg_airs:atmos_warm"},
    neighbors = {"ctg_airs:atmos_hot"},
    interval = 7,
    chance = 3,
    min_y = vacuum.vac_heights.space.start_height,
    action = vacuum.throttle(2500, function(pos)
        if vacuum.has_in_range(pos, "ctg_airs:atmos_hot", 1, 7) then
            minetest.set_node(pos, {
                name = "ctg_airs:atmos_hot"
            })
        end
    end)
})

minetest.register_abm({
    label = "warm air - random",
    nodenames = {"ctg_airs:atmos_warm"},
    --neighbors = {},
    interval = 10,
    chance = 8,
    min_y = vacuum.vac_heights.space.start_height,
    action = vacuum.throttle(2500, function(pos)
        if not vacuum.has_in_range(pos, "ctg_airs:atmos_hot", 1, 5) then
            minetest.set_node(pos, {
                name = "air"
            })
        end
    end)
})

minetest.register_abm({
    label = "warm air to normal air",
    nodenames = {"ctg_airs:atmos_warm"},
    neighbors = {"air", "vacuum:atmos_thin", "default:ice", "default:snowblock"},
    interval = 4,
    chance = 2,
    min_y = vacuum.vac_heights.space.start_height,
    action = vacuum.throttle(2500, function(pos)
        if vacuum.has_in_range(pos, "air", 1, 5) then
            minetest.set_node(pos, {
                name = "air"
            })
        elseif vacuum.has_in_range(pos, "default:ice", 1, 3) then
            minetest.set_node(pos, {
                name = "air"
            })
        elseif vacuum.has_in_range(pos, "default:snowblock", 1, 5) then
            minetest.set_node(pos, {
                name = "air"
            })
        end
    end)
})

minetest.register_abm({
    label = "hot air next to cold nodes",
    nodenames = {"ctg_airs:atmos_hot"},
    neighbors = {"default:ice", "default:snowblock"},
    interval = 5,
    chance = 2,
    min_y = vacuum.vac_heights.space.start_height,
    action = vacuum.throttle(2500, function(pos)
        minetest.set_node(pos, {
            name = "ctg_airs:atmos_warm"
        })
    end)
})


minetest.register_abm({
    label = "cold nodes next to hot and warm",
    nodenames = {"default:ice", "default:snowblock", "default:water_source"},
    neighbors = {"ctg_airs:atmos_hot", "ctg_airs:atmos_warm"},
    interval = 5,
    chance = 5,
    min_y = vacuum.vac_heights.space.start_height,
    action = vacuum.throttle(2500, function(pos)
        local node = core.get_node(pos)
        if node.name == "default:ice" then
            if vacuum.has_in_range(pos, "ctg_airs:atmos_hot", 1, 3) then
                minetest.set_node(pos, {
                    name = "default:water_source"
                })
            elseif vacuum.has_in_range(pos, "ctg_airs:atmos_warm", 1, 5) then
                minetest.set_node(pos, {
                    name = "default:water_source"
                })
            end
        elseif node.name == "default:snowblock" then
            minetest.set_node(pos, {
                name = "vacuum:atmos_thin"
            })
        elseif node.name == "default:water_source" then
            if vacuum.has_in_range(pos, "ctg_airs:atmos_hot", 1, 3) then
                minetest.set_node(pos, {
                    name = "vacuum:atmos_thin"
                })
            end
        end
        
    end)
})


minetest.register_abm({
    label = "thin atmos next to hot",
    nodenames = {"vacuum:atmos_thin"},
    neighbors = {"ctg_airs:atmos_hot"},
    interval = 5,
    chance = 3,
    min_y = vacuum.vac_heights.space.start_height,
    action = vacuum.throttle(2500, function(pos)
        minetest.set_node(pos, {
            name = "ctg_airs:atmos_warm"
        })
    end)
})


minetest.register_abm({
    label = "air next to hot",
    nodenames = {"ctg_airs:atmos_warm", "air"},
    neighbors = {"group:lava"},
    interval = 4,
    chance = 2,
    min_y = vacuum.vac_heights.space.start_height,
    action = vacuum.throttle(2500, function(pos)
        minetest.set_node(pos, {
            name = "ctg_airs:atmos_hot"
        })
    end)
})