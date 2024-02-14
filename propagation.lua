-- thick atmos propagation base
-- seed propagations from vents
minetest.register_abm({
    label = "thin atmos + vacuum -> atmos replacement",
    nodenames = {"vacuum:atmos_thin", "vacuum:vacuum"},
    neighbors = {"ctg_airs:air_duct_vent", "ctg_airs:air_duct_vent_lite"},
    interval = 5,
    chance = 3,
    min_y = vacuum.vac_heights.space.start_height,
    action = vacuum.throttle(200, function(pos)
        if vacuum.near_powered_airpump(pos, 10) then
            if vacuum.has_in_range(pos, "vacuum:atmos_thin", 1, 5) and ctg_airs.near_active_vent(pos, 3) then
                minetest.set_node(pos, {
                    name = "vacuum:atmos_thick"
                })
            elseif ctg_airs.near_active_vent(pos, 1) then
                minetest.set_node(pos, {
                    name = "vacuum:atmos_thin"
                })
            end
        end
    end)
})

-- disable vents abm
minetest.register_abm({
    label = "vent + vacuum -> vents off",
    nodenames = {"ctg_airs:air_duct_vent", "ctg_airs:air_duct_vent_lite"},
    neighbors = {"vacuum:vacuum"},
    interval = 10,
    chance = 2,
    min_y = vacuum.vac_heights.space.start_height,
    action = vacuum.throttle(1000, function(pos)
        minetest.get_meta(pos):set_int("active", 0)
    end)
})
