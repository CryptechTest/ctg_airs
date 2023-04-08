local S = minetest.get_translator(minetest.get_current_modname())

local function process_leaves(pos)
    if not pos then
        return power
    end

    local node = minetest.get_node(pos)
    local dir_x = 0.001
    local dir_z = 0.001

    local acl_x = 0.2 * (dir_x)
    local acl_z = 0.2 * (dir_z)

    spawn_particle(pos, dir_x, dir_z, acl_x, acl_z)

    local count = 0

    for j = 1, 4 do
        local sz = j
        local pos1 = vector.subtract(pos, {
            x = sz,
            y = sz,
            z = sz
        })
        local pos2 = vector.add(pos, {
            x = sz,
            y = sz,
            z = sz
        })

        local nodes_thin = minetest.find_nodes_in_area(pos1, pos2, {"vacuum:atmos_thin"})
        for i, node in ipairs(nodes_thin) do
            if node ~= nil then
                if (vacuum.has_in_range(node, "vacuum:atmos_thick", 1, 3)) then
                    -- minetest.log("update thin")
                    minetest.set_node(node, {
                        name = "vacuum:atmos_thick"
                    })
                    count = count + 1
                end
            end
        end

        if count > 5 and j > 1 then
            break
        end
    end

    minetest.log("nature making atmos..")
end

-- producing nodes in thing atmos
minetest.register_abm({
    label = "space vacuum sublimate",
    nodenames = {"group:leaves"},
    neighbors = {"vacuum:atmos_thin"},
    interval = 2,
    chance = 1,
    min_y = vacuum.space_height,
    action = vacuum.throttle(100, function(pos)
        if not vacuum.is_pos_in_space(pos) then
            return
        end
        process_leaves(pos)
    end)
})
