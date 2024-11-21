-- leaves in atmos
minetest.register_abm({
    label = "space vacuum plants",
    nodenames = {"vacuum:atmos_thin"},
    neighbors = {"group:leaves"},
    interval = 1,
    chance = 1,
    min_y = vacuum.vac_heights.space.start_height,
    action = vacuum.throttle(3000, function(pos)
        minetest.set_node(pos, {
            name = "air"
        })
        if math.random(0, 1) == 0 then
            vacuum.spawn_particle(pos, math.random(-0.001, 0.001), math.random(-0.001, 0.001),
                math.random(-0.001, 0.001), math.random(-0.002, 0.002), math.random(0.001, 0.037),
                math.random(-0.002, 0.002), math.random(2.1, 3.6), 13, 1)
        end
    end)
})

minetest.register_abm({
    label = "space vacuum plants",
    nodenames = {"group:leaves"},
    neighbors = {"vacuum:atmos_thin", "vacuum:vacuum", "asteroid:atmos"},
    interval = 1,
    chance = 1,
    min_y = vacuum.vac_heights.space.start_height,
    action = vacuum.throttle(3000, function(pos)

        local pos1 = vector.subtract(pos, {
            x = math.random(1, 2),
            y = math.random(1, 2),
            z = math.random(1, 2)
        })
        local pos2 = vector.add(pos, {
            x = math.random(1, 2),
            y = math.random(2, 3),
            z = math.random(1, 2)
        })

        local nodes = minetest.find_nodes_in_area(pos1, pos2, {"vacuum:atmos_thin", "vacuum:vacuum", "asteroid:atmos"})
        for _, node in ipairs(nodes) do
            minetest.set_node(node.pos, {
                name = "air"
            })

            if math.random(0, 2) > 0 then
                vacuum.spawn_particle(node.pos, math.random(-0.001, 0.001), math.random(-0.001, 0.001),
                    math.random(-0.001, 0.001), math.random(-0.002, 0.002), math.random(0.001, 0.037),
                    math.random(-0.002, 0.002), math.random(2.1, 3.6), 12, 1)
            end
        end

    end)
})
