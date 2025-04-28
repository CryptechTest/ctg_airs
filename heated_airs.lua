
local get_particle = function (player, pos, hot)
    local size = 16
    local color = hot == true and "#ff0000" or "#ff2891"
    local texture = {
        name = "ctg_air_vent_vapor_anim.png^[colorize:" .. color .. "33",
        blend = "alpha",
        alpha = 0.5,
        alpha_tween = {0.5, 0.1},
    }
    local p ={
        pos = pos,
        velocity = {x=0, y=0, z=0},
        acceleration = {x=0, y=0, z=0},
        -- Spawn particle at pos with velocity and acceleration 
        expirationtime = 1,
        -- Disappears after expirationtime seconds
        size = size,
        -- Scales the visual size of the particle texture.
        -- If `node` is set, size can be set to 0 to spawn a randomly-sized
        -- particle (just like actual node dig particles).
        collisiondetection = false,
        -- If true collides with `walkable` nodes and, depending on the
        -- `object_collision` field, objects too.
        collision_removal = false,
        -- If true particle is removed when it collides.
        -- Requires collisiondetection = true to have any effect.
        object_collision = false,
        -- If true particle collides with objects that are defined as
        -- `physical = true,` and `collide_with_objects = true,`.
        -- Requires collisiondetection = true to have any effect.
        vertical = false,
        -- If true faces player using y axis only
        texture = texture,
        -- The texture of the particle
        -- v5.6.0 and later: also supports the table format described in the
        -- following section, but due to a bug this did not take effect
        -- (beyond the texture name).
        -- v5.9.0 and later: fixes the bug.
        -- Note: "texture.animation" is ignored here. Use "animation" below instead.
        playername = player or nil,
        -- Optional, if specified spawns particle only on the player's client
        animation = {
            type = "vertical_frames",   
            aspect_w = 16,
            -- Width of a frame in pixels
            aspect_h = 16,
            -- Height of a frame in pixels
            length = 1,
            -- Full loop length
        },
        -- Optional, specifies how to animate the particle texture
        glow = 2,
        -- Optional, specify particle self-luminescence in darkness.
        -- Values 0-14.
        --node = {name = "ignore", param2 = 0},
        -- Optional, if specified the particle will have the same appearance as
        -- node dig particles for the given node.
        -- `texture` and `animation` will be ignored if this is set.
        --node_tile = 0,
        -- Optional, only valid in combination with `node`
        -- If set to a valid number 1-6, specifies the tile from which the
        -- particle texture is picked.
        -- Otherwise, the default behavior is used. (currently: any random tile)
        drag = {x=0, y=0, z=0},
        -- v5.6.0 and later: Optional drag value, consult the following section
        -- Note: Only a vector is supported here. Alternative forms like a single
        -- number are not supported.
        --jitter = {min = ..., max = ..., bias = 0},
        -- v5.6.0 and later: Optional jitter range, consult the following section
        --bounce = {min = ..., max = ..., bias = 0},
        -- v5.6.0 and later: Optional bounce range, consult the following section
    }
    return p
end


-- this is just like air, but warm...
minetest.register_node("ctg_airs:atmos_warm", {
	description = "Atmosphere Air Warm",
	drawtype = "airlike",
    tiles = {"atmos_warm.png"},
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
    on_construct = function(pos)
        local players = minetest.get_objects_inside_radius(pos, 10)
        for _, player in ipairs(players) do
            if player:is_player() then
                local p = get_particle(player, pos)
                minetest.add_particle(p)
            end
        end
    end

})

-- this is just like air, but hot...
minetest.register_node("ctg_airs:atmos_hot", {
	description = "Atmosphere Air Hot",
	drawtype = "airlike",
    tiles = {"atmos_hot.png"},
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
    on_construct = function(pos)
        local players = minetest.get_objects_inside_radius(pos, 10)
        for _, player in ipairs(players) do
            if player:is_player() then
                local p = get_particle(player, pos)
                minetest.add_particle(p)
            end
        end
    end
})

minetest.register_abm({
    label = "hot air to warm air",
    nodenames = {"ctg_airs:atmos_hot"},
    neighbors = {"air", "vacuum:atmos_thin", "default:water_source"},
    interval = 3,
    chance = 2,
    min_y = vacuum.air_heights.planet.start_height,
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
    min_y = vacuum.air_heights.planet.start_height,
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
    min_y = vacuum.air_heights.planet.start_height,
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
    min_y = vacuum.air_heights.planet.start_height,
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
    min_y = vacuum.air_heights.planet.start_height,
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
    min_y = vacuum.air_heights.planet.start_height,
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
    min_y = vacuum.air_heights.planet.start_height,
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
    min_y = vacuum.air_heights.planet.start_height,
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
    min_y = vacuum.air_heights.planet.start_height,
    action = vacuum.throttle(2500, function(pos)
        minetest.set_node(pos, {
            name = "ctg_airs:atmos_hot"
        })
    end)
})